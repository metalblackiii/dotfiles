#!/usr/bin/env bash
set -euo pipefail

REVIEWER="@me"
LIMIT=100
STALE_DAYS=7
SEARCH_QUERY=""
OUTPUT_FORMAT="markdown"
declare -a OWNERS=()
declare -a REPOS=()

usage() {
  cat <<'EOF'
Usage: pr-review-queue.sh [options]

Options:
  --reviewer <user>    Reviewer username (default: @me)
  --owner <org>        Filter by repo owner/org (repeatable)
  --repo <owner/repo>  Filter by specific repo (repeatable)
  --limit <n>          Max PRs to inspect per search (default: 100)
  --stale-days <n>     Mark PR as stale after n inactive days (default: 7)
  --search <query>     Additional GitHub search qualifiers
  --json               Output JSON instead of Markdown
  -h, --help           Show help
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
  printf '| PR | Repo | Author | Age | Your Review | Checks | Next Step |\n'
  printf '|---|---|---|---:|---|---|---|\n'

  while IFS=$'\t' read -r pr repo author age review checks next; do
    printf '| %s | %s | %s | %s | %s | %s | %s |\n' \
      "$(escape_cell "$pr")" \
      "$(escape_cell "$repo")" \
      "$(escape_cell "$author")" \
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
          .author,
          (.ageDays|tostring + "d"),
          .myReviewState,
          ("F:" + (.checks.failed|tostring) + " P:" + (.checks.pending|tostring) + " S:" + (.checks.success|tostring)),
          .nextAction
        ]
      | @tsv
    ' <<< "$report_json"
  )
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reviewer)
      REVIEWER="${2:-}"
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

# Resolve actual login for review matching in jq
if [[ "$REVIEWER" == "@me" ]]; then
  MY_LOGIN="$(gh api user -q .login)"
else
  MY_LOGIN="$REVIEWER"
fi

# Build shared search arguments
common_args=(
  --state open
  --limit "$LIMIT"
  --json number,title,url,repository,createdAt,updatedAt,isDraft
)

for owner in "${OWNERS[@]:-}"; do
  [[ -z "$owner" ]] && continue
  common_args+=(--owner "$owner")
done

for repo in "${REPOS[@]:-}"; do
  [[ -z "$repo" ]] && continue
  common_args+=(--repo "$repo")
done

# Two searches: PRs requesting my review + PRs I've already reviewed
requested_json="$(gh search prs ${SEARCH_QUERY:+"$SEARCH_QUERY"} --review-requested "$REVIEWER" "${common_args[@]}")"
reviewed_json="$(gh search prs ${SEARCH_QUERY:+"$SEARCH_QUERY"} --reviewed-by "$REVIEWER" "${common_args[@]}")"

# Merge and deduplicate by URL
search_json="$(jq -s 'add | unique_by(.url)' <<< "${requested_json}"$'\n'"${reviewed_json}")"

if [[ "$(jq 'length' <<< "$search_json")" -eq 0 ]]; then
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    jq -n --arg generatedAt "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --argjson staleDays "$STALE_DAYS" --arg reviewer "$MY_LOGIN" '
      {
        generatedAt: $generatedAt,
        staleDays: ($staleDays | tonumber),
        reviewer: $reviewer,
        totals: { all: 0, needsReview: 0, waitingOnAuthor: 0, approved: 0, watching: 0, stale: 0, draft: 0 },
        rows: []
      }
    '
  else
    echo "# PR Review Queue"
    echo
    echo "No open pull requests found for reviewer \`$MY_LOGIN\`."
  fi
  exit 0
fi

# Enrich each PR with detailed view
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
    gh pr view "$pr_url" \
      --json number,title,url,createdAt,updatedAt,isDraft,reviewDecision,mergeStateStatus,mergeable,reviewRequests,statusCheckRollup,latestReviews,commits,author 2>/dev/null
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
          statusCheckRollup: [],
          latestReviews: [],
          commits: [],
          author: { login: "unknown" }
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

# Classify and generate report
report_json="$(
  jq --argjson stale_days "$STALE_DAYS" --arg my_login "$MY_LOGIN" '
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

    def my_latest_review:
      [(.latestReviews // [])[] | select(.author.login == $my_login)] | .[0];

    def latest_commit_date:
      [(.commits // [])[] | .committedDate // empty] | if length > 0 then max else null end;

    def still_requested:
      [(.reviewRequests // [])[] | .login? // empty] | any(. == $my_login);

    def age_days:
      ((now - ((.updatedAt // .createdAt) | fromdateiso8601)) / 86400 | floor);

    def classify:
      . as $pr
      | ($pr | my_latest_review) as $my_review
      | ($pr | latest_commit_date) as $last_commit
      | ($pr | check_counts) as $checks
      | (still_requested) as $requested
      | (age_days) as $age
      | ($age >= $stale_days) as $is_stale
      | ($pr.isDraft == true) as $is_draft
      | (
          if $my_review != null and $last_commit != null then
            ($last_commit | fromdateiso8601) > ($my_review.submittedAt | fromdateiso8601)
          else false end
        ) as $new_commits
      | (
          if $my_review != null then $my_review.state
          else "PENDING" end
        ) as $review_state
      | (
          if $is_draft then
            "Draft"
          elif $my_review == null or $requested or $new_commits then
            "Needs your review"
          elif $review_state == "CHANGES_REQUESTED" then
            if $is_stale then "Stale" else "Waiting on author" end
          elif $review_state == "APPROVED" then
            if $is_stale then "Stale" else "Approved" end
          else
            if $is_stale then "Stale" else "Reviewed (watching)" end
          end
        ) as $bucket
      | (
          if $bucket == "Draft" then
            "Draft — no review needed yet"
          elif $bucket == "Needs your review" then
            if $new_commits then
              "New changes since your last review — re-review needed"
            elif $my_review != null then
              "Review re-requested"
            else
              "Submit your review"
            end
          elif $bucket == "Waiting on author" then
            "You requested changes — waiting for author to update"
          elif $bucket == "Approved" then
            if $checks.failed > 0 then
              "You approved; CI failing (author action needed)"
            elif $checks.pending > 0 then
              "You approved; CI running"
            elif $pr.reviewDecision == "APPROVED" then
              "Fully approved — ready to merge (author action)"
            else
              "You approved; waiting on other reviewers"
            end
          elif $bucket == "Stale" then
            "Inactive " + ($age | tostring) + "d — nudge author or unsubscribe"
          else
            "Watching — no action required"
          end
        ) as $next_action
      | {
          repo: $pr.repository.nameWithOwner,
          number: $pr.number,
          title: $pr.title,
          url: $pr.url,
          author: ($pr.author.login // "unknown"),
          myReviewState: (
            if $new_commits and $my_review != null then
              $review_state + " (stale)"
            else
              $review_state
            end
          ),
          reviewDecision: ($pr.reviewDecision // "UNKNOWN"),
          draft: $is_draft,
          checks: $checks,
          updatedAt: ($pr.updatedAt // $pr.createdAt),
          ageDays: $age,
          bucket: $bucket,
          nextAction: $next_action
        };

    # Exclude self-authored PRs — this is a reviewer queue
    map(select(.author.login != $my_login))
    | (map(classify)) as $rows
    | {
        generatedAt: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
        staleDays: $stale_days,
        reviewer: $my_login,
        totals: {
          all: ($rows | length),
          needsReview: ($rows | map(select(.bucket == "Needs your review")) | length),
          waitingOnAuthor: ($rows | map(select(.bucket == "Waiting on author")) | length),
          approved: ($rows | map(select(.bucket == "Approved")) | length),
          watching: ($rows | map(select(.bucket == "Reviewed (watching)")) | length),
          stale: ($rows | map(select(.bucket == "Stale")) | length),
          draft: ($rows | map(select(.bucket == "Draft")) | length)
        },
        rows: (
          $rows
          | sort_by(
              if .bucket == "Needs your review" then 0
              elif .bucket == "Waiting on author" then 1
              elif .bucket == "Approved" then 2
              elif .bucket == "Reviewed (watching)" then 3
              elif .bucket == "Stale" then 4
              else 5
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

echo "# PR Review Queue"
echo
echo "- Generated: $(jq -r '.generatedAt' <<< "$report_json")"
echo "- Reviewer: \`$MY_LOGIN\`"
echo "- PRs in queue: $(jq -r '.totals.all' <<< "$report_json")"
echo "- Needs your review: $(jq -r '.totals.needsReview' <<< "$report_json")"
echo "- Waiting on author: $(jq -r '.totals.waitingOnAuthor' <<< "$report_json")"
echo "- Approved (open): $(jq -r '.totals.approved' <<< "$report_json")"
echo "- Reviewed (watching): $(jq -r '.totals.watching' <<< "$report_json")"
echo "- Stale (>= ${STALE_DAYS}d inactive): $(jq -r '.totals.stale' <<< "$report_json")"
echo "- Drafts: $(jq -r '.totals.draft' <<< "$report_json")"

print_markdown_section "$report_json" "Needs your review" "Needs Your Review"
print_markdown_section "$report_json" "Waiting on author" "Waiting On Author"
print_markdown_section "$report_json" "Approved" "Approved (Open)"
print_markdown_section "$report_json" "Reviewed (watching)" "Reviewed (Watching)"
print_markdown_section "$report_json" "Stale" "Stale"
print_markdown_section "$report_json" "Draft" "Drafts"
