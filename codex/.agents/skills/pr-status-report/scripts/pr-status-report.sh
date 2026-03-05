#!/usr/bin/env bash
set -euo pipefail

AUTHOR="@me"
LIMIT=100
STALE_DAYS=7
SEARCH_QUERY=""
OUTPUT_FORMAT="markdown"
declare -a OWNERS=()
declare -a REPOS=()

usage() {
  cat <<'EOF'
Usage: pr-status-report.sh [options]

Options:
  --author <user>        PR author (default: @me)
  --owner <org>          Filter by repo owner/org (repeatable)
  --repo <owner/repo>    Filter by specific repo (repeatable)
  --limit <n>            Max PRs to inspect (default: 100)
  --stale-days <n>       Mark PR as stale after n inactive days (default: 7)
  --search <query>       Additional GitHub search qualifiers
  --json                 Output JSON instead of Markdown
  -h, --help             Show help
EOF
}

escape_cell() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//$'\n'/ }"
  value="${value//|/\\|}"
  value="${value//\[/\\[}"
  value="${value//\]/\\]}"
  value="${value//\`/\\\`}"
  printf '%s' "$value"
}

print_markdown_section() {
  local report_json="$1"
  local bucket="$2"
  local heading="$3"

  local count
  count="$(jq --arg bucket "$bucket" '[.rows[] | select(.bucket == $bucket)] | length' <<< "$report_json")"
  if [[ "$count" -eq 0 ]]; then
    return
  fi

  printf '\n## %s (%s)\n\n' "$heading" "$count"
  printf '| PR | Repo | Age | Review | Checks | Next Step |\n'
  printf '|---|---|---:|---|---|---|\n'

  while IFS=$'\t' read -r pr repo age review checks next; do
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$(escape_cell "$pr")" \
      "$(escape_cell "$repo")" \
      "$(escape_cell "$age")" \
      "$(escape_cell "$review")" \
      "$(escape_cell "$checks")" \
      "$(escape_cell "$next")"
  done < <(
    jq -r --arg bucket "$bucket" '
      .rows[]
      | select(.bucket == $bucket)
      | [
          ("#" + (.number|tostring) + " " + .title + " <" + .url + ">"),
          .repo,
          (.ageDays|tostring + "d"),
          (if .draft then "DRAFT" else .reviewDecision end),
          ("F:" + (.checks.failed|tostring) + " P:" + (.checks.pending|tostring) + " S:" + (.checks.success|tostring)),
          .nextAction
        ]
      | @tsv
    ' <<< "$report_json"
  )
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --author)
      AUTHOR="${2:-}"
      shift 2
      ;;
    --owner)
      OWNERS+=("${2:-}")
      shift 2
      ;;
    --repo)
      REPOS+=("${2:-}")
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      shift 2
      ;;
    --stale-days)
      STALE_DAYS="${2:-}"
      shift 2
      ;;
    --search)
      SEARCH_QUERY="${2:-}"
      shift 2
      ;;
    --json)
      OUTPUT_FORMAT="json"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -le 0 ]]; then
  echo "--limit must be a positive integer" >&2
  exit 1
fi

if ! [[ "$STALE_DAYS" =~ ^[0-9]+$ ]] || [[ "$STALE_DAYS" -lt 1 ]]; then
  echo "--stale-days must be an integer >= 1" >&2
  exit 1
fi

for dependency in gh jq; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    echo "Missing dependency: $dependency" >&2
    exit 1
  fi
done

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub auth not configured. Run: gh auth login" >&2
  exit 1
fi

search_cmd=(
  gh search prs
  --author "$AUTHOR"
  --state open
  --limit "$LIMIT"
  --json number,title,url,repository,createdAt,updatedAt,isDraft
)

for owner in "${OWNERS[@]:-}"; do
  [[ -z "$owner" ]] && continue
  search_cmd+=(--owner "$owner")
done

for repo in "${REPOS[@]:-}"; do
  [[ -z "$repo" ]] && continue
  search_cmd+=(--repo "$repo")
done

search_json="$("${search_cmd[@]}" ${SEARCH_QUERY:+"$SEARCH_QUERY"})"

if [[ "$(jq 'length' <<< "$search_json")" -eq 0 ]]; then
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    jq -n --arg generatedAt "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --argjson staleDays "$STALE_DAYS" '
      {
        generatedAt: $generatedAt,
        staleDays: $staleDays,
        totals: { all: 0, active: 0, draftFollowUp: 0, needsAction: 0, waiting: 0, ready: 0, stale: 0 },
        rows: []
      }
    '
  else
    echo "# PR Status Report"
    echo
    echo "No open pull requests found for author \`$AUTHOR\`."
  fi
  exit 0
fi

details='[]'
while IFS= read -r pr_url; do
  [[ -z "$pr_url" ]] && continue

  repository_name="$(
    jq -r --arg url "$pr_url" '.[] | select(.url == $url) | .repository.nameWithOwner' <<< "$search_json"
  )"
  base_item="$(
    jq -c --arg url "$pr_url" '.[] | select(.url == $url)' <<< "$search_json"
  )"

  if pr_view="$(
    gh pr view "$pr_url" --json number,title,url,createdAt,updatedAt,isDraft,reviewDecision,mergeStateStatus,mergeable,reviewRequests,statusCheckRollup 2>/dev/null
  )"; then
    :
  else
    pr_view="$(
      jq -n --argjson item "$base_item" '
        {
          number: $item.number,
          title: $item.title,
          url: $item.url,
          createdAt: $item.createdAt,
          updatedAt: $item.updatedAt,
          isDraft: $item.isDraft,
          reviewDecision: "UNKNOWN",
          mergeStateStatus: "UNKNOWN",
          mergeable: "UNKNOWN",
          reviewRequests: [],
          statusCheckRollup: []
        }
      '
    )"
  fi

  enriched="$(
    jq -n --argjson pr "$pr_view" --arg repo "$repository_name" '
      $pr + { repository: { nameWithOwner: $repo } }
    '
  )"
  details="$(jq -n --argjson list "$details" --argjson item "$enriched" '$list + [$item]')"
done < <(jq -r '.[].url' <<< "$search_json")

report_json="$(
  jq --argjson stale_days "$STALE_DAYS" '
    def in_list($value; $choices): ($choices | index($value)) != null;

    def check_counts:
      reduce (.statusCheckRollup // [])[] as $c (
        {total: 0, success: 0, failed: 0, pending: 0};
        .total += 1
        | if ($c.status? == "COMPLETED") then
            if in_list(($c.conclusion // "UNKNOWN"); ["SUCCESS", "NEUTRAL", "SKIPPED"]) then
              .success += 1
            elif in_list(($c.conclusion // "UNKNOWN"); ["FAILURE", "ERROR", "TIMED_OUT", "ACTION_REQUIRED", "CANCELLED", "STALE"]) then
              .failed += 1
            else
              .pending += 1
            end
          elif ($c.state? != null) then
            if in_list(($c.state // "UNKNOWN"); ["SUCCESS", "EXPECTED"]) then
              .success += 1
            elif in_list(($c.state // "UNKNOWN"); ["FAILURE", "ERROR"]) then
              .failed += 1
            else
              .pending += 1
            end
          else
            .pending += 1
          end
      );

    def requested_reviewers:
      [(.reviewRequests // [])[] |
        if .login? then .login
        elif .slug? then .slug
        else empty
        end];

    def age_days:
      ((now - ((.updatedAt // .createdAt) | fromdateiso8601)) / 86400 | floor);

    def classify:
      . as $pr
      | ($pr | check_counts) as $checks
      | (requested_reviewers) as $reviewers
      | (age_days) as $age
      | ($age >= $stale_days) as $is_stale
      | (
          ($pr.mergeable == "CONFLICTING")
          or ($pr.mergeStateStatus == "DIRTY")
        ) as $has_conflicts
      | ($pr.mergeStateStatus == "BEHIND") as $is_behind
      | ($pr.reviewDecision == "CHANGES_REQUESTED") as $changes_requested
      | ($checks.failed > 0) as $failing_checks
      | ($pr.isDraft == true) as $is_draft
      | (
          if $is_draft then
            "Draft follow-up"
          elif $has_conflicts or $changes_requested or $failing_checks or $is_behind then
            "Needs your action"
          elif ($pr.reviewDecision == "APPROVED" and $checks.failed == 0 and $checks.pending == 0 and ($has_conflicts | not)) then
            "Ready to merge"
          elif $is_stale then
            "Stale"
          else
            "Waiting on others"
          end
        ) as $bucket
      | (
          if $bucket == "Draft follow-up" then
            "General follow-up: keep context updated; mark ready when unblocked"
          elif $bucket == "Stale" then
            "Nudge reviewers or post a progress update"
          elif $has_conflicts then
            "Resolve conflicts (rebase or merge base branch)"
          elif $changes_requested then
            "Address requested changes and re-request review"
          elif $failing_checks then
            "Fix failing checks"
          elif $is_behind then
            "Update branch (rebase or merge base)"
          elif $pr.reviewDecision == "APPROVED" then
            "Merge or enable auto-merge"
          elif $checks.pending > 0 then
            "Wait for CI checks to complete"
          elif ($reviewers | length) > 0 then
            "Ping reviewers: " + (($reviewers | map("@" + .)) | join(", "))
          else
            "Request review or post context update"
          end
        ) as $next_action
      | {
          repo: $pr.repository.nameWithOwner,
          number: $pr.number,
          title: $pr.title,
          url: $pr.url,
          reviewDecision: ($pr.reviewDecision // "UNKNOWN"),
          mergeStateStatus: ($pr.mergeStateStatus // "UNKNOWN"),
          mergeable: ($pr.mergeable // "UNKNOWN"),
          hasConflicts: $has_conflicts,
          isBehind: $is_behind,
          draft: $is_draft,
          checks: $checks,
          reviewers: $reviewers,
          updatedAt: ($pr.updatedAt // $pr.createdAt),
          ageDays: $age,
          bucket: $bucket,
          nextAction: $next_action
        };

    (map(classify)) as $rows
    | {
        generatedAt: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
        staleDays: $stale_days,
        totals: {
          all: ($rows | length),
          active: ($rows | map(select(.draft | not)) | length),
          draftFollowUp: ($rows | map(select(.bucket == "Draft follow-up")) | length),
          needsAction: ($rows | map(select(.bucket == "Needs your action")) | length),
          waiting: ($rows | map(select(.bucket == "Waiting on others")) | length),
          ready: ($rows | map(select(.bucket == "Ready to merge")) | length),
          stale: ($rows | map(select(.bucket == "Stale")) | length)
        },
        rows: (
          $rows
          | sort_by(
              if .bucket == "Needs your action" then 0
              elif .bucket == "Waiting on others" then 1
              elif .bucket == "Ready to merge" then 2
              elif .bucket == "Stale" then 3
              else 4
              end,
              -(.ageDays),
              .repo,
              .number
            )
        )
      }
  ' <<< "$details"
)"

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  jq '.' <<< "$report_json"
  exit 0
fi

echo "# PR Status Report"
echo
echo "- Generated: $(jq -r '.generatedAt' <<< "$report_json")"
echo "- Author: \`$AUTHOR\`"
echo "- Open PRs: $(jq -r '.totals.all' <<< "$report_json")"
echo "- Active PRs (non-draft): $(jq -r '.totals.active' <<< "$report_json")"
echo "- Draft follow-up (excluded from normal status): $(jq -r '.totals.draftFollowUp' <<< "$report_json")"
echo "- Needs your action: $(jq -r '.totals.needsAction' <<< "$report_json")"
echo "- Waiting on others: $(jq -r '.totals.waiting' <<< "$report_json")"
echo "- Ready to merge: $(jq -r '.totals.ready' <<< "$report_json")"
echo "- Stale (>= ${STALE_DAYS}d inactive): $(jq -r '.totals.stale' <<< "$report_json")"

print_markdown_section "$report_json" "Needs your action" "Needs Your Action"
print_markdown_section "$report_json" "Waiting on others" "Waiting On Others"
print_markdown_section "$report_json" "Ready to merge" "Ready To Merge"
print_markdown_section "$report_json" "Stale" "Stale"
print_markdown_section "$report_json" "Draft follow-up" "Draft Follow-up"
