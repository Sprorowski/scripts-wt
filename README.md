# scripts-wt

```bash
curl -fsSL https://raw.githubusercontent.com/Sprorowski/scripts-wt/main/install.sh | bash
```

Runs on **macOS and Linux**. `install.sh` checks for the tools it
needs and prints install hints for your package manager.

On Linux you also need `xdg-utils` (for `xdg-open`), which is how
`wt` opens the web app in a browser. Override the browser on either
platform with `WT_BROWSER` — an app name on macOS
(`WT_BROWSER="Brave Browser"`), an executable on Linux
(`WT_BROWSER=firefox`).

The tmux status bar uses Nerd Font glyphs, so set your terminal font
to a Nerd Font variant or swap the icons in `@wt_win_icon` inside
`tmux-statusbar.conf`. The Api and Web icons turn green while
something is listening on that worktree's port. Liveness is probed
with bash's `/dev/tcp`, falling back to `nc`, `ss`, then `lsof`;
force one with `WT_PORT_PROBE=nc`.
