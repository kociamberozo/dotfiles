#!/usr/bin/env bash

# Bootstrap script for restoring the Debian + i3 environment.
# The script installs required packages, backs up existing configuration
# files, creates symbolic links to this repository and restores selected
# application settings.

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

log() {
    printf '\n==> %s\n' "$*"
}

warn() {
    printf '\nWARNING: %s\n' "$*" >&2
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

# Create a symbolic link while preserving an existing target as a backup.
link_config() {
    local source_relative="$1"
    local target_relative="$2"

    local source_path="$REPO_DIR/$source_relative"
    local target_path="$HOME/$target_relative"
    local backup_path="${target_path}.backup-${BACKUP_TIMESTAMP}"

    if [[ ! -e "$source_path" ]]; then
        warn "Source file does not exist, skipping: $source_path"
        return
    fi

    mkdir -p "$(dirname "$target_path")"

    # Do nothing if the correct symbolic link already exists.
    if [[ -L "$target_path" ]] &&
       [[ "$(readlink -f "$target_path")" == "$(readlink -f "$source_path")" ]]; then
        printf 'Already linked: %s\n' "$target_path"
        return
    fi

    if [[ -L "$target_path" || -e "$target_path" ]]; then
        mv "$target_path" "$backup_path"
        printf 'Backup created: %s\n' "$backup_path"
    fi

    ln -s "$source_path" "$target_path"
    printf 'Linked: %s -> %s\n' "$target_path" "$source_path"
}

# Confirm that the script is running on a Debian-based system.
if [[ ! -r /etc/os-release ]]; then
    die "Cannot determine the operating system."
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "debian" ]]; then
    warn "This setup was prepared for Debian. Detected: ${PRETTY_NAME:-unknown}"
fi

if [[ ! -f "$REPO_DIR/packages/apt.txt" ]]; then
    die "Missing package list: $REPO_DIR/packages/apt.txt"
fi

log "Installing APT packages"

mapfile -t packages < <(
    grep -Ev '^[[:space:]]*(#|$)' "$REPO_DIR/packages/apt.txt"
)

if [[ "${#packages[@]}" -eq 0 ]]; then
    die "The APT package list is empty."
fi

sudo apt update
sudo apt install -y "${packages[@]}"

log "Linking user configuration files"

link_config "i3/config" ".config/i3/config"
link_config "i3status/config" ".config/i3status/config"
link_config "bash/bashrc" ".bashrc"
link_config "vim/vimrc" ".vimrc"
link_config "git/gitconfig" ".gitconfig"

if [[ -f "$REPO_DIR/flameshot/flameshot.ini" ]]; then
    link_config \
        "flameshot/flameshot.ini" \
        ".config/flameshot/flameshot.ini"
fi

log "Installing custom helper scripts"

if [[ -f "$REPO_DIR/bin/i3-brightness" ]]; then
    sudo install \
        -o root \
        -g root \
        -m 0755 \
        "$REPO_DIR/bin/i3-brightness" \
        /usr/local/bin/i3-brightness

    # Create the initial brightness value used by i3status.
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
    i3-brightness status || warn "Could not initialize the brightness status."
else
    warn "Brightness helper was not found in bin/i3-brightness."
fi

# Restore GNOME Terminal settings exported with:
# dconf dump /org/gnome/terminal/ > gnome-terminal.dconf
if [[ -s "$REPO_DIR/gnome-terminal.dconf" ]]; then
    if command -v dconf >/dev/null 2>&1; then
        log "Restoring GNOME Terminal settings"
        dconf load /org/gnome/terminal/ \
            < "$REPO_DIR/gnome-terminal.dconf"
    else
        warn "dconf is unavailable, GNOME Terminal settings were not restored."
    fi
fi

log "Validating the i3 configuration"

if command -v i3 >/dev/null 2>&1; then
    i3 -C -c "$HOME/.config/i3/config"
else
    warn "i3 is unavailable, configuration validation was skipped."
fi

log "Bootstrap completed"

cat <<'MESSAGE'

The configuration has been restored.

Recommended next steps:
  1. Log out and log back in.
  2. Verify audio keys: F1, F2 and F3.
  3. Verify brightness keys: F5 and F6.
  4. Verify screenshot capture with Print Screen.
  5. Verify suspend and i3lock by closing the laptop lid.
  6. Complete the manual setup steps described in README.md.

Existing configuration files were preserved with a timestamped
.backup-YYYYMMDD-HHMMSS suffix.
MESSAGE
