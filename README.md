# Linux Setup

One-command bootstrap for a fresh Ubuntu machine. Installs and configures the tools I use daily.

## What's included

| Tool | Install method |
|------|---------------|
| zsh + oh-my-zsh | apt + official installer |
| tmux | apt |
| Node.js + npm | nvm (latest, auto-detected) |
| uv | astral.sh installer |
| Docker | get.docker.com |
| Claude Code | install script |
| GitHub CLI (gh) | official apt repo |
| Google Cloud CLI | official apt repo |
| Neovim | latest stable AppImage |
| LazyVim | starter repo clone |

Config files copied to `~`:
- `.zshrc` — zsh config with oh-my-zsh and aliases
- `tm.sh` — tmux session helper (installed to `~/.local/bin/`)

## Usage

```bash
# 1. Clone this repo
git clone https://github.com/inkuxuan/linux-setup.git
cd linux-setup

# 2. Run the setup script
chmod +x setup.sh
./setup.sh
```

## Requirements

- Ubuntu (tested on 22.04+)
- A non-root user with `sudo` access
- Internet connection

## After setup

1. **Log out and back in** — picks up the docker group and zsh as default shell
2. `gh auth login` — authenticate GitHub CLI
3. `gcloud init` — configure Google Cloud
4. `claude` — set up Claude Code
5. Open `nvim` — LazyVim will install plugins on first launch

## Re-running

The script is idempotent. Running it again skips anything already installed and re-copies the config files.
