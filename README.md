# Debian i3 Dotfiles

Personal dotfiles and bootstrap script for a lightweight Debian workstation using i3wm.

Tested on:

- Debian 12 Bookworm
- Lenovo ThinkPad X270
- i3wm on X11

## Included configuration

- i3 and i3status
- Bash aliases
- Vim settings
- Git identity and settings
- GNOME Terminal profile
- Flameshot
- Custom brightness helper
- Package lists

## Installation

Install Git and clone the repository:

```bash
sudo apt update
sudo apt install git

git clone https://github.com/kociamberozo/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Run the bootstrap script:

```bash
./bootstrap.sh
```

The script will:

- install packages from `packages/apt.txt`
- back up existing configuration files
- create symbolic links to the repository
- install `i3-brightness` in `/usr/local/bin`
- restore GNOME Terminal settings
- validate the i3 configuration

Existing files are preserved with a suffix similar to:

```text
.backup-20260727-153000
```

## Manual steps

The following steps are intentionally not automated.

### GitHub SSH access

Generate an SSH key:

```bash
ssh-keygen -t ed25519 -C "kai@skaza.org"
```

Copy the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Add it in:

```text
GitHub → Settings → SSH and GPG keys
```

Test authentication:

```bash
ssh -T git@github.com
```

Switch the repository to SSH:

```bash
cd ~/dotfiles
git remote set-url origin git@github.com:kociamberozo/dotfiles.git
```

### Dropbox and KeePassXC

Install and link the Dropbox Linux client or daemon.

Open the KeePass database from the synchronized local directory:

```text
~/Dropbox/.../passwords.kdbx
```

Confirm that changes made in KeePassXC are synchronized before opening the database on another device.

### Codex CLI

Install Codex CLI using the current official installation method, then complete interactive login.

Codex authentication files must not be committed to this repository.

### Windows dual boot

Debian may disable automatic detection of Windows in GRUB.

Install `os-prober`:

```bash
sudo apt install os-prober
```

Add this line to `/etc/default/grub`:

```text
GRUB_DISABLE_OS_PROBER=false
```

Regenerate GRUB:

```bash
sudo os-prober
sudo update-grub
```

Confirm that `Windows Boot Manager` is detected.

### Vim configuration for root files

Prefer `sudoedit`:

```bash
SUDO_EDITOR=vim sudoedit /etc/default/grub
```

Running `sudo vi` uses root's Vim configuration instead of the current user's `~/.vimrc`.

## Post-installation checks

Verify:

```text
F1              Toggle audio mute
F2              Lower volume
F3              Raise volume
F5              Lower brightness
F6              Raise brightness
Print Screen    Start Flameshot
Mod+Return      Open GNOME Terminal
Mod+d           Open dmenu
Mod+Shift+x     Lock the screen
```

Also test:

- Wi-Fi
- battery status
- closing the lid and suspend
- i3lock after wake-up
- Dropbox synchronization
- KeePassXC database saving
- Windows entry in GRUB

## Updating stored configuration

Export updated GNOME Terminal settings:

```bash
dconf dump /org/gnome/terminal/ > ~/dotfiles/gnome-terminal.dconf
```

Review and push changes:

```bash
cd ~/dotfiles
git status
git diff
git add .
git commit -m "Update desktop configuration"
git push
```

## Security

Never commit:

- private SSH keys
- KeePass databases or key files
- Dropbox credentials
- API tokens
- Codex authentication files
- browser cookies or profiles
- unencrypted passwords
