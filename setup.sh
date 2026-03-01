#!/usr/bin/env bash
set -euo pipefail

# ─── Helpers ──────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${BLUE}[..]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }

section() {
  echo ""
  echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

has() { command -v "$1" &>/dev/null; }

# ─── Pre-flight ───────────────────────────────────────────────────────────────

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run this script as root. It will use sudo when needed."
  exit 1
fi

section "System update"
sudo apt-get update -qq
sudo apt-get install -y -qq curl wget unzip git build-essential > /dev/null
log "Base packages ready"

# ─── Git ──────────────────────────────────────────────────────────────────────

section "Git"
if has git; then
  log "git already installed ($(git --version))"
else
  sudo apt-get install -y -qq git > /dev/null
  log "git installed"
fi

# ─── Zsh ──────────────────────────────────────────────────────────────────────

section "Zsh"
if has zsh; then
  log "zsh already installed"
else
  sudo apt-get install -y -qq zsh > /dev/null
  log "zsh installed"
fi

# ─── Oh My Zsh ────────────────────────────────────────────────────────────────

section "Oh My Zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log "oh-my-zsh already installed"
else
  info "Installing oh-my-zsh..."
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  log "oh-my-zsh installed"
fi

# ─── Tmux + tm.sh ────────────────────────────────────────────────────────────

section "Tmux"
if has tmux; then
  log "tmux already installed"
else
  sudo apt-get install -y -qq tmux > /dev/null
  log "tmux installed"
fi

mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/tm.sh" "$HOME/.local/bin/tm.sh"
chmod +x "$HOME/.local/bin/tm.sh"
log "tm.sh copied to ~/.local/bin/"

# ─── .zshrc ───────────────────────────────────────────────────────────────────

section "Shell config"
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
log ".zshrc copied to ~/"

# ─── NVM + Node.js + npm ─────────────────────────────────────────────────────

section "Node.js (via nvm)"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$NVM_DIR" ]]; then
  log "nvm already installed"
else
  info "Installing nvm..."
  NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed 's/.*"v/v/;s/".*//')
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
  log "nvm installed"
fi

# Load nvm for use in this script
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck source=/dev/null
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

if has node; then
  log "Node.js already installed ($(node --version))"
else
  info "Installing Node.js LTS..."
  nvm install --lts
  nvm alias default node
  log "Node.js LTS installed ($(node --version))"
fi

# ─── uv ───────────────────────────────────────────────────────────────────────

section "uv (Python package manager)"
if has uv; then
  log "uv already installed ($(uv --version))"
else
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  log "uv installed ($(uv --version))"
fi

# ─── Docker ───────────────────────────────────────────────────────────────────

section "Docker"
if has docker; then
  log "Docker already installed ($(docker --version))"
else
  info "Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  log "Docker installed (log out and back in for group changes)"
fi

# ─── Claude Code ──────────────────────────────────────────────────────────────

section "Claude Code"
if has claude; then
  log "Claude Code already installed"
else
  info "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
  log "Claude Code installed"
fi

# ─── GitHub CLI ───────────────────────────────────────────────────────────────

section "GitHub CLI (gh)"
if has gh; then
  log "gh already installed ($(gh --version | head -1))"
else
  info "Installing gh..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq gh > /dev/null
  log "gh installed"
fi

# ─── Google Cloud CLI ─────────────────────────────────────────────────────────

section "Google Cloud CLI (gcloud)"
if has gcloud; then
  log "gcloud already installed ($(gcloud --version 2>/dev/null | head -1))"
else
  info "Installing gcloud..."
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq google-cloud-cli > /dev/null
  log "gcloud installed"
fi

# ─── Neovim (AppImage) ───────────────────────────────────────────────────────

section "Neovim"
if has nvim; then
  log "Neovim already installed ($(nvim --version | head -1))"
else
  info "Installing Neovim (latest stable AppImage)..."
  curl -fsSL -o /tmp/nvim.appimage \
    https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
  chmod +x /tmp/nvim.appimage

  # Try extracting (works without FUSE) — fallback to direct AppImage
  if (cd /tmp && /tmp/nvim.appimage --appimage-extract &>/dev/null); then
    sudo rm -rf /opt/nvim
    sudo mv /tmp/squashfs-root /opt/nvim
    sudo ln -sf /opt/nvim/AppRun /usr/local/bin/nvim
    rm /tmp/nvim.appimage
  else
    sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
  fi
  log "Neovim installed ($(nvim --version | head -1))"
fi

# ─── LazyVim ──────────────────────────────────────────────────────────────────

section "LazyVim"
NVIM_CFG="$HOME/.config/nvim"
if [[ -d "$NVIM_CFG" && -f "$NVIM_CFG/lua/config/lazy.lua" ]]; then
  log "LazyVim config already present"
else
  info "Installing LazyVim starter..."
  # Back up existing config if any
  [[ -d "$NVIM_CFG" ]] && mv "$NVIM_CFG" "$NVIM_CFG.bak.$(date +%s)"
  git clone https://github.com/LazyVim/starter "$NVIM_CFG"
  rm -rf "$NVIM_CFG/.git"
  log "LazyVim installed at ~/.config/nvim"
fi

# ─── Default shell ────────────────────────────────────────────────────────────

section "Default shell"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
ZSH_PATH="$(which zsh)"
if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
  log "Default shell is already zsh"
else
  info "Changing default shell to zsh..."
  chsh -s "$ZSH_PATH"
  log "Default shell set to zsh (takes effect on next login)"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}━━━ Setup complete! ━━━${NC}"
echo ""
echo "Installed: zsh, oh-my-zsh, tmux, node (nvm), uv, docker, claude,"
echo "           gh, gcloud, neovim, lazyvim"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (for docker group + zsh default shell)"
echo "  2. Run 'gh auth login' to authenticate GitHub CLI"
echo "  3. Run 'gcloud init' to configure Google Cloud"
echo "  4. Run 'claude' to set up Claude Code"
echo "  5. Open nvim to let LazyVim install plugins on first launch"
echo ""
