#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
GITHUB_RAW="https://raw.githubusercontent.com/Sprorowski/scripts-wt/mac"
SCRIPTS=(tmux-sessionizer wt wt-tmux-status)

# ── Platform ──────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
  *)      echo "ERROR: unsupported platform '$(uname -s)'"; exit 1 ;;
esac

# Package-manager hint used in the "missing tools" message.
if [[ "$OS" == "macos" ]]; then
  PKG="brew install"
elif command -v apt-get &>/dev/null; then
  PKG="sudo apt install"
elif command -v dnf &>/dev/null; then
  PKG="sudo dnf install"
elif command -v pacman &>/dev/null; then
  PKG="sudo pacman -S"
elif command -v zypper &>/dev/null; then
  PKG="sudo zypper install"
else
  PKG="<your package manager> install"
fi

# ── Tool dependency check ─────────────────────────────────────
REQUIRED_TOOLS=(
  tmux
  fzf
  git
  pnpm
  code
  claude
  gt
  jq
)

# Opening the browser on Linux goes through xdg-open; on macOS
# `open` is always present.
if [[ "$OS" == "linux" ]]; then
  REQUIRED_TOOLS+=(xdg-open)
fi

missing=()
for tool in "${REQUIRED_TOOLS[@]}"; do
  command -v "$tool" &>/dev/null || missing+=("$tool")
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "ERROR: The following required tools are not installed:"
  for t in "${missing[@]}"; do
    echo "  - $t"
  done
  echo ""
  echo "Install hints:"
  echo "  tmux          → $PKG tmux"
  echo "  fzf           → $PKG fzf"
  echo "  git           → $PKG git"
  echo "  pnpm          → $PKG pnpm  OR  https://pnpm.io/installation"
  echo "  code          → https://code.visualstudio.com  (install shell command via Command Palette)"
  echo "  claude        → https://claude.ai/code  (Claude Code CLI)"
  echo "  gt            → npm install -g @withgraphite/graphite-cli"
  echo "  jq            → $PKG jq"
  if [[ "$OS" == "linux" ]]; then
    echo "  xdg-open      → $PKG xdg-utils"
  fi
  echo ""
  echo "Re-run this script after installing missing tools."
  exit 1
fi

echo "All required tools found."

# ── Install scripts ───────────────────────────────────────────
mkdir -p "$INSTALL_DIR"

for script in "${SCRIPTS[@]}"; do
  dst="$INSTALL_DIR/$script"
  tmp=$(mktemp)
  trap "rm -f $tmp" EXIT

  echo "Fetching $script..."
  if ! curl -fsSL "$GITHUB_RAW/$script" -o "$tmp"; then
    echo "ERROR: Failed to download $script from $GITHUB_RAW/$script"
    exit 1
  fi

  if [[ -f "$dst" ]]; then
    if diff -q "$tmp" "$dst" &>/dev/null; then
      echo "Up to date: $dst"
      continue
    fi

    echo ""
    echo "Changes in '$script' (incoming → will overwrite installed):"
    diff --color=always -u "$dst" "$tmp" || true
    echo ""
    read -r -p "Overwrite $dst? [Y/n] " answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
      echo "Skipped: $script"
      continue
    fi
  fi

  cp "$tmp" "$dst"
  chmod +x "$dst"
  echo "Installed: $dst"
done

# ── Status bar config ─────────────────────────────────────────
TMUX_CONF_DIR="$HOME/.config/wt"
TMUX_CONF="$TMUX_CONF_DIR/tmux-statusbar.conf"
mkdir -p "$TMUX_CONF_DIR"

tmp=$(mktemp)
echo "Fetching tmux-statusbar.conf..."
if ! curl -fsSL "$GITHUB_RAW/tmux-statusbar.conf" -o "$tmp"; then
  echo "ERROR: Failed to download tmux-statusbar.conf"
  exit 1
fi

if [[ -f "$TMUX_CONF" ]] && diff -q "$tmp" "$TMUX_CONF" &>/dev/null; then
  echo "Up to date: $TMUX_CONF"
else
  if [[ -f "$TMUX_CONF" ]]; then
    echo ""
    echo "Changes in 'tmux-statusbar.conf' (incoming → will overwrite installed):"
    diff --color=always -u "$TMUX_CONF" "$tmp" || true
    echo ""
    read -r -p "Overwrite $TMUX_CONF? [Y/n] " answer
  else
    answer=""
  fi

  if [[ "$answer" =~ ^[Nn]$ ]]; then
    echo "Skipped: tmux-statusbar.conf"
  else
    cp "$tmp" "$TMUX_CONF"
    echo "Installed: $TMUX_CONF"
  fi
fi
rm -f "$tmp"

# Wire it into ~/.tmux.conf if it isn't already.
SOURCE_LINE="source-file -q ~/.config/wt/tmux-statusbar.conf"
if ! grep -qF "tmux-statusbar.conf" "$HOME/.tmux.conf" 2>/dev/null; then
  {
    echo ""
    echo "# Status bar (managed by scripts-wt — see tmux-statusbar.conf in that repo)"
    echo "$SOURCE_LINE"
  } >> "$HOME/.tmux.conf"
  echo "Added source line to ~/.tmux.conf"
fi

# `pgrep -q` is a BSD extension and is absent from Linux procps,
# so redirect instead of relying on the flag.
if [[ -n "${TMUX:-}" ]] || pgrep tmux >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" 2>/dev/null \
    && echo "Reloaded running tmux config."
fi

# ── PATH reminder ─────────────────────────────────────────────
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo ""
  echo "NOTE: $INSTALL_DIR is not in your PATH."
  echo "Add to ~/.bashrc or ~/.zshrc:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "Done. tmux-sessionizer and wt installed to $INSTALL_DIR."
