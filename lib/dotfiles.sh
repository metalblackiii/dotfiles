#!/bin/bash
# Shared utilities for dotfiles install/uninstall scripts

# Symlink source to target, backing up any existing non-symlink file.
# Usage: symlink_with_backup <source> <target>
symlink_with_backup() {
    local source="$1"
    local target="$2"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup_path
        backup_path="${target}.backup.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up $target to $backup_path"
        mv "$target" "$backup_path"
    elif [ -L "$target" ]; then
        rm "$target"
    fi

    echo "  Linking $target -> $source"
    ln -s "$source" "$target"
}

# Remove a symlink if it exists. Warns if target exists but isn't a symlink.
# Usage: remove_symlink <target>
remove_symlink() {
    local target="$1"

    if [ -L "$target" ]; then
        echo "  Removing symlink $target"
        rm "$target"
    elif [ -e "$target" ]; then
        echo "  $target is not a symlink, skipping (remove manually if desired)"
    fi
}
