#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
GITHUB_RAW="https://raw.githubusercontent.com/Sprorowski/scripts-wt/mac"
SCRIPTS=(tmux-sessionizer wt)

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
  echo "  tmux          → brew install tmux"
  echo "  fzf           → brew install fzf"
  echo "  git           → brew install git"
  echo "  pnpm          → brew install pnpm  OR  https://pnpm.io/installation"
  echo "  code          → https://code.visualstudio.com  (install shell command via Command Palette)"
  echo "  claude        → https://claude.ai/code  (Claude Code CLI)"
  echo "  gt            → npm install -g @withgraphite/graphite-cli"
  echo "  jq            → brew install jq"
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

echo ""
echo "Done. tmux-sessionizer and wt installed to $INSTALL_DIR."
