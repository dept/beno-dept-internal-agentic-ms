#!/usr/bin/env bash
# MS developer setup for macOS (DEPT Managed Services).
# Safe to re-run, and safe on a Mac that is already set up: every step skips what is already there.
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/dev-setup/macos.sh)
set -euo pipefail

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!!  %s\033[0m\n' "$*"; }
TODO=()

[[ "$(uname -s)" == "Darwin" ]] || { echo "This script is for macOS only."; exit 1; }

# 1. Xcode command line tools (git, compilers)
say "Xcode command line tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  echo "Finish the installer dialog, then press Enter."
  read -r
fi

# 2. Homebrew
say "Homebrew"
had() { command -v "$1" >/dev/null 2>&1; }
skip() { echo "$1 already installed, skipped."; }
BREW_WAS_THERE=1
if ! had brew; then
  BREW_WAS_THERE=0
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
BREW=$( [[ -x /opt/homebrew/bin/brew ]] && echo /opt/homebrew/bin/brew || echo /usr/local/bin/brew )
eval "$("$BREW" shellenv)"

# 3. Packages: each one only when it is missing, so an existing setup is left alone
say "CLI tools and apps"
for f in gh mise jq; do if had "$f"; then skip "$f"; else brew install "$f"; fi; done
if had code || [[ -d "/Applications/Visual Studio Code.app" ]]; then skip "VS Code"; else brew install --cask visual-studio-code; fi
if had claude; then skip "Claude Code"; else brew install --cask claude-code; fi
SDKS=$(had dotnet && dotnet --list-sdks 2>/dev/null || true)
if grep -q '^8\.' <<<"$SDKS"; then skip ".NET SDK 8"; else brew install --cask dotnet-sdk@8; fi
if grep -v '^8\.' <<<"$SDKS" | grep -q '^[0-9]'; then skip ".NET SDK (current)"; else brew install --cask dotnet-sdk; fi

# 4. Shell config (zsh): only what this script set up
say "Shell config (~/.zshrc)"
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
add_line() { grep -qxF "$1" "$ZSHRC" || echo "$1" >> "$ZSHRC"; }
[[ "$BREW_WAS_THERE" == "1" ]] || add_line "eval \"\$($BREW shellenv)\""

# 5. Node via mise: reads .nvmrc / .node-version per repo, Node LTS as global default.
# Skipped when Node already comes from somewhere else (nvm, fnm, brew): that setup stays as it is.
say "Node (mise) and corepack"
if had node; then
  skip "Node ($(command -v node))"
else
  add_line 'eval "$(mise activate zsh)"'
  mise settings add idiomatic_version_file_enable_tools node 2>/dev/null || true
  mise use -g node@lts
  # Newer Node majors no longer bundle corepack, so install it when missing
  mise exec -- sh -c 'command -v corepack' >/dev/null || mise exec -- npm install -g corepack
  mise exec -- corepack enable
fi

# 6. Git identity and defaults, only where nothing is set yet
say "Git identity"
if [[ -z "$(git config --global user.name || true)" ]]; then
  read -r -p "Full name for git commits: " n; git config --global user.name "$n"
fi
if [[ -z "$(git config --global user.email || true)" ]]; then
  read -r -p "DEPT email for git commits: " e; git config --global user.email "$e"
fi
git config --global init.defaultBranch >/dev/null || git config --global init.defaultBranch main
git config --global pull.rebase >/dev/null || git config --global pull.rebase false

# 7. GitHub login (HTTPS through gh, no SSH key needed)
say "GitHub CLI login"
if ! gh auth status >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol https --web
fi
git config --global --get-regexp "^credential\.https://github\.com" >/dev/null || gh auth setup-git

# 8. MS project context + ms-agentic-context skill for Claude Code
say "MS agentic context"
CTX="$HOME/.cache/ms-agentic-context"
if [[ -d "$CTX/.git" ]]; then
  git -C "$CTX" pull --quiet --ff-only || true
elif ! gh repo clone dept/beno-dept-ms-agentic-context "$CTX" -- --depth 1; then
  TODO+=("No access to dept/beno-dept-ms-agentic-context yet. Re-run this script once your GitHub access is granted.")
fi
if [[ -d "$CTX/skills/ms-agentic-context" ]]; then
  mkdir -p "$HOME/.claude/skills"
  rm -rf "$HOME/.claude/skills/ms-agentic-context"
  cp -R "$CTX/skills/ms-agentic-context" "$HOME/.claude/skills/"
  echo "Skill installed in ~/.claude/skills/ms-agentic-context"
fi
# Bookmarks are generated from each project's context, so re-run this script for a fresh file.
BM="$HOME/Downloads/dept-ms-bookmarks.html"
if [[ -f "$CTX/onboarding/bookmarks.py" ]] && python3 "$CTX/onboarding/bookmarks.py" > "$BM.tmp"; then
  mv "$BM.tmp" "$BM"
  TODO+=("Import ~/Downloads/dept-ms-bookmarks.html in your browser (Chrome: Bookmarks > Import bookmarks and settings > Bookmarks HTML file). It adds a 'DEPT (MS)' folder with every project.")
else
  rm -f "$BM.tmp"
fi

# 9. Manual steps
TODO+=(
  "Install Cato Client VPN: https://clientdownload.catonetworks.com (ask for an account)."
  "Run 'claude' once and sign in to Claude Code."
  "Check access: GitHub teams, Jira/Confluence (dept-nl), Keeper, Datadog EU, Slack. See the 'MS Developer Onboarding' page in Confluence."
)
say "Done. Open a new terminal, then do these manual steps:"
for t in "${TODO[@]}"; do echo "  - $t"; done
