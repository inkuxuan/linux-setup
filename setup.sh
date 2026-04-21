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

AUTO_YES=false
if [[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]]; then
  AUTO_YES=true
fi

confirm() {
  if $AUTO_YES; then return 0; fi
  read -rp "$1 [Y/n] " answer
  case "${answer:-Y}" in
    [Yy]*) return 0 ;;
    *)     return 1 ;;
  esac
}

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
  if confirm "Install git?"; then
    sudo apt-get install -y -qq git > /dev/null
    log "git installed"
  else
    warn "Skipped git"
  fi
fi

# ─── Zsh ──────────────────────────────────────────────────────────────────────

section "Zsh"
if has zsh; then
  log "zsh already installed"
else
  if confirm "Install zsh?"; then
    sudo apt-get install -y -qq zsh > /dev/null
    log "zsh installed"
  else
    warn "Skipped zsh"
  fi
fi

# ─── Oh My Zsh ────────────────────────────────────────────────────────────────

section "Oh My Zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log "oh-my-zsh already installed"
else
  if confirm "Install oh-my-zsh?"; then
    info "Installing oh-my-zsh..."
    RUNZSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log "oh-my-zsh installed"
  else
    warn "Skipped oh-my-zsh"
  fi
fi

# ─── Tmux + tm.sh ────────────────────────────────────────────────────────────

section "Tmux"
if has tmux; then
  log "tmux already installed"
else
  if confirm "Install tmux?"; then
    sudo apt-get install -y -qq tmux > /dev/null
    log "tmux installed"
  else
    warn "Skipped tmux"
  fi
fi

if confirm "Copy tm.sh to ~/.local/bin/?"; then
  mkdir -p "$HOME/.local/bin"
  cp "$SCRIPT_DIR/tm.sh" "$HOME/.local/bin/tm.sh"
  chmod +x "$HOME/.local/bin/tm.sh"
  log "tm.sh copied to ~/.local/bin/"
else
  warn "Skipped tm.sh"
fi

# ─── .zshrc ───────────────────────────────────────────────────────────────────

section "Shell config"
if confirm "Copy .zshrc to ~/ (overwrites existing)?"; then
  cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
  log ".zshrc copied to ~/"
else
  warn "Skipped .zshrc"
fi

# ─── NVM + Node.js + npm ─────────────────────────────────────────────────────

section "Node.js (via nvm)"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$NVM_DIR" ]]; then
  log "nvm already installed"
else
  if confirm "Install nvm + Node.js LTS?"; then
    info "Installing nvm..."
    NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed 's/.*"v/v/;s/".*//')
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
    log "nvm installed"
  else
    warn "Skipped nvm + Node.js"
  fi
fi

# Load nvm for use in this script
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck source=/dev/null
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

if has node; then
  log "Node.js already installed ($(node --version))"
elif has nvm; then
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
  if confirm "Install uv?"; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    log "uv installed ($(uv --version))"
  else
    warn "Skipped uv"
  fi
fi

# ─── Docker ───────────────────────────────────────────────────────────────────

section "Docker"
if has docker; then
  log "Docker already installed ($(docker --version))"
else
  if confirm "Install Docker?"; then
    info "Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    log "Docker installed (log out and back in for group changes)"
  else
    warn "Skipped Docker"
  fi
fi

# ─── Claude Code ──────────────────────────────────────────────────────────────

section "Claude Code"
if has claude; then
  log "Claude Code already installed"
else
  if confirm "Install Claude Code?"; then
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    log "Claude Code installed"
  else
    warn "Skipped Claude Code"
  fi
fi

# ─── cht.sh ──────────────────────────────────────────────────────────────────

section "cht.sh (cheat sheet)"
if [[ -x "$HOME/.local/bin/cht.sh" ]] || has cht.sh; then
  log "cht.sh already installed"
else
  if confirm "Install cht.sh?"; then
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://cht.sh/:cht.sh > "$HOME/.local/bin/cht.sh"
    chmod +x "$HOME/.local/bin/cht.sh"
    log "cht.sh installed to ~/.local/bin/"
  else
    warn "Skipped cht.sh"
  fi
fi

# ─── NextTrace ───────────────────────────────────────────────────────────────

section "NextTrace (nxtrace)"
if has nexttrace; then
  log "nexttrace already installed"
else
  if confirm "Install NextTrace?"; then
    info "Installing NextTrace..."
    curl -sL https://nxtrace.org/nt | bash
    log "NextTrace installed"
  else
    warn "Skipped NextTrace"
  fi
fi

# ─── GitHub CLI ───────────────────────────────────────────────────────────────

section "GitHub CLI (gh)"
if has gh; then
  log "gh already installed ($(gh --version | head -1))"
else
  if confirm "Install GitHub CLI (gh)?"; then
    info "Installing gh..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh > /dev/null
    log "gh installed"
  else
    warn "Skipped gh"
  fi
fi

# ─── Google Cloud CLI ─────────────────────────────────────────────────────────

section "Google Cloud CLI (gcloud)"
if has gcloud; then
  log "gcloud already installed ($(gcloud --version 2>/dev/null | head -1))"
else
  if confirm "Install Google Cloud CLI (gcloud)?"; then
    info "Installing gcloud..."
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | sudo gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq google-cloud-cli > /dev/null
    log "gcloud installed"
  else
    warn "Skipped gcloud"
  fi
fi

# ─── Neovim ───────────────────────────────────────────────────────────────────

section "Neovim"
if has nvim; then
  log "Neovim already installed ($(nvim --version | head -1))"
else
  if confirm "Install Neovim?"; then
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)  NVIM_ARCH="x86_64" ;;
      aarch64) NVIM_ARCH="arm64" ;;
      *)       warn "Unsupported architecture: $ARCH — skipping Neovim"; NVIM_ARCH="" ;;
    esac

    if [[ -n "$NVIM_ARCH" ]]; then
      info "Installing Neovim (latest stable for $ARCH)..."
      curl -fsSL -o /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
      sudo rm -rf /opt/nvim
      sudo tar -xzf /tmp/nvim.tar.gz -C /opt
      sudo mv /opt/nvim-linux-* /opt/nvim
      sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
      rm /tmp/nvim.tar.gz
      log "Neovim installed ($(nvim --version | head -1))"
    fi
  else
    warn "Skipped Neovim"
  fi
fi

# ─── LazyVim ──────────────────────────────────────────────────────────────────

section "LazyVim"
NVIM_CFG="$HOME/.config/nvim"
if [[ -d "$NVIM_CFG" && -f "$NVIM_CFG/lua/config/lazy.lua" ]]; then
  log "LazyVim config already present"
else
  if confirm "Install LazyVim starter config?"; then
    info "Installing LazyVim starter..."
    # Back up existing config if any
    [[ -d "$NVIM_CFG" ]] && mv "$NVIM_CFG" "$NVIM_CFG.bak.$(date +%s)"
    git clone https://github.com/LazyVim/starter "$NVIM_CFG"
    rm -rf "$NVIM_CFG/.git"
    log "LazyVim installed at ~/.config/nvim"
  else
    warn "Skipped LazyVim"
  fi
fi

# ─── Default shell ────────────────────────────────────────────────────────────

section "Default shell"
if has zsh; then
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
  ZSH_PATH="$(which zsh)"
  if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
    log "Default shell is already zsh"
  else
    if confirm "Set zsh as default shell?"; then
      chsh -s "$ZSH_PATH"
      log "Default shell set to zsh (takes effect on next login)"
    else
      warn "Skipped changing default shell"
    fi
  fi
else
  warn "zsh not installed, skipping default shell change"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}━━━ Setup complete! ━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (for docker group + zsh default shell)"
echo "  2. Run 'gh auth login' to authenticate GitHub CLI"
echo "  3. Run 'gcloud init' to configure Google Cloud"
echo "  4. Run 'claude' to set up Claude Code"
echo "  5. Open nvim to let LazyVim install plugins on first launch"
echo ""
