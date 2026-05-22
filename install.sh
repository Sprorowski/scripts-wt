#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
COMPLETION_DIR="$HOME/.local/share/zsh/completions"
GITHUB_RAW="https://raw.githubusercontent.com/Sprorowski/scripts-wt/main"
SCRIPTS=(tmux-sessionizer wt)

# ── Tool dependency check ─────────────────────────────────────
REQUIRED_TOOLS=(
  tmux
  fzf
  git
  pnpm
  xdotool
  xrandr
  gdbus
  code
  brave-browser
  claude
  gt
  jq
)

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
  echo "  tmux          → sudo apt install tmux"
  echo "  fzf           → sudo apt install fzf"
  echo "  git           → sudo apt install git"
  echo "  pnpm          → npm install -g pnpm  OR  https://pnpm.io/installation"
  echo "  xdotool       → sudo apt install xdotool"
  echo "  xrandr        → sudo apt install x11-xserver-utils"
  echo "  gdbus         → sudo apt install dbus (usually pre-installed on GNOME)"
  echo "  code          → https://code.visualstudio.com/docs/setup/linux"
  echo "  brave-browser → https://brave.com/linux/"
  echo "  claude        → https://claude.ai/code  (Claude Code CLI)"
  echo "  gt            → npm install -g @withgraphite/graphite-cli"
  echo "  jq            → sudo apt install jq"
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

# ── PATH reminder ─────────────────────────────────────────────
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo ""
  echo "NOTE: $INSTALL_DIR is not in your PATH."
  echo "Add to ~/.bashrc or ~/.zshrc:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ── Zsh completion ────────────────────────────────────────────
mkdir -p "$COMPLETION_DIR"
comp_dst="$COMPLETION_DIR/_wt"
comp_tmp=$(mktemp)
trap "rm -f $comp_tmp" EXIT

echo "Fetching _wt completion..."
if curl -fsSL "$GITHUB_RAW/_wt" -o "$comp_tmp" 2>/dev/null; then
  cp "$comp_tmp" "$comp_dst"
  echo "Installed: $comp_dst"
else
  echo "WARNING: Could not download _wt completion — skipping"
fi

# Add COMPLETION_DIR to fpath in .zshrc if not already present
ZSHRC="$HOME/.zshrc"
FPATH_LINE="fpath=(\$HOME/.local/share/zsh/completions \$fpath)"
if [[ -f "$ZSHRC" ]] && ! grep -qF "$COMPLETION_DIR" "$ZSHRC"; then
  echo "" >> "$ZSHRC"
  echo "# wt completion" >> "$ZSHRC"
  echo "$FPATH_LINE" >> "$ZSHRC"
  echo "autoload -Uz compinit && compinit" >> "$ZSHRC"
  echo "Added zsh completion fpath to $ZSHRC"
  echo "Restart your shell or run: source ~/.zshrc"
fi

echo ""
echo "Done. tmux-sessionizer and wt installed to $INSTALL_DIR."
