# dotfiles

Personal configuration files, managed with Git and symlinks.

## Structure

```
dotfiles/
├── claude/              # Claude Code configuration
│   └── .claude/
│       ├── settings.json
│       ├── hooks/
│       ├── skills/
│       └── commands/
├── install.sh           # Symlink installer
└── .gitignore
```

## Installation

```bash
git clone https://github.com/metalblackiii/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
./install.sh
```

## Adding New Topics

To add more dotfiles (e.g., git, zsh):

```bash
mkdir -p topic-name/
# Add config files with their home directory structure
# e.g., git/.gitconfig for ~/.gitconfig
```

Then update `install.sh` to symlink the new topic.

## Notes

- Only config files are tracked; ephemeral data stays in original locations
- Original files are backed up with `.backup.TIMESTAMP` extension before symlinking
