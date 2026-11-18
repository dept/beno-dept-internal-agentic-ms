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
# A failed install (for example a sudo prompt that was cancelled) becomes a manual step, the rest still runs.
inst() { brew install "$@" || { warn "brew install $* failed"; TODO+=("Install manually: brew install $*"); }; }
for f in gh mise jq; do if had "$f"; then skip "$f"; else inst "$f"; fi; done
if had code || [[ -d "/Applications/Visual Studio Code.app" ]]; then skip "VS Code"; else inst --cask visual-studio-code; fi
if had claude; then skip "Claude Code"; else inst --cask claude-code; fi
# .NET is only for the .NET projects, so it is opt-in: answer y, or run with DOTNET=1.
SDKS=$(had dotnet && dotnet --list-sdks 2>/dev/null || true)
NEED_DOTNET=0
grep -q '^8\.' <<<"$SDKS" && grep -v '^8\.' <<<"$SDKS" | grep -q '^[0-9]' || NEED_DOTNET=1
[[ "$NEED_DOTNET" == "1" ]] || skip ".NET SDK 8 and current"
if [[ "$NEED_DOTNET" == "1" && "${DOTNET:-}" != "1" ]]; then
  a=""; [[ -t 0 ]] && { read -r -p "Install .NET SDK 8 and current? Only needed for .NET projects. [y/N] " a || true; }
  [[ "$a" == [yY]* ]] || { NEED_DOTNET=0; echo ".NET SDK skipped (re-run with DOTNET=1 to add it later)."; }
fi
if [[ "$NEED_DOTNET" == "1" ]]; then
  if grep -q '^8\.' <<<"$SDKS"; then skip ".NET SDK 8"; else inst --cask dotnet-sdk@8; fi
  if grep -v '^8\.' <<<"$SDKS" | grep -q '^[0-9]'; then skip ".NET SDK (current)"; else inst --cask dotnet-sdk; fi
fi

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
  # Browsers have no command-line import, so open the chosen browser's import page and show the file.
  BROWSERS=()
  for b in "Google Chrome" "Microsoft Edge" "Brave Browser" "Firefox" "Safari"; do
    [[ -d "/Applications/$b.app" || -d "$HOME/Applications/$b.app" ]] && BROWSERS+=("$b")
  done
  PICK="" HOW=""
  if [[ -t 0 && ${#BROWSERS[@]} -gt 0 ]]; then
    echo "Import the bookmarks into a browser now? Pick a number:"
    select PICK in "${BROWSERS[@]}" "Skip"; do break; done
  fi
  # Show the file first: Finder takes focus, so the browser opened after it ends up in front.
  [[ -n "$PICK" && "$PICK" != "Skip" ]] && { open -R "$BM" || true; }
  case "$PICK" in
    "Google Chrome"|"Microsoft Edge"|"Brave Browser")
      case "$PICK" in
        "Google Chrome") URL="chrome://settings/importData" ;;
        "Microsoft Edge") URL="edge://settings/profiles/importBrowsingData" ;;
        *) URL="brave://settings/importData" ;;
      esac
      # chrome:// style pages only open through AppleScript (macOS asks to let Terminal control the browser).
      if osascript -e "tell application \"$PICK\"" -e "activate" -e "if (count of windows) = 0 then make new window" \
        -e "tell front window to make new tab with properties {URL:\"$URL\"}" -e "end tell" >/dev/null; then
        HOW="in the import tab that just opened (check it is your work profile), choose 'Bookmarks HTML file', then Choose file"
      else
        warn "Could not open the import page in $PICK"
      fi
      ;;
    "Firefox") open -a Firefox || true
      HOW="press Cmd+Shift+O (Library), click Import and Backup, then Import Bookmarks from HTML" ;;
    "Safari") open -a Safari || true
      HOW="menu File > Import From > Bookmarks HTML File" ;;
  esac
  if [[ -n "$HOW" ]]; then
    say "Finish the import in $PICK"
    echo "1. $HOW"
    echo "2. Pick ~/Downloads/dept-ms-bookmarks.html (also shown in a Finder window behind the browser)"
    echo "You get a 'DEPT (MS)' bookmarks folder with every project."
  else
    TODO+=("Import ~/Downloads/dept-ms-bookmarks.html in your browser (every browser imports it. Chrome, Edge, Brave: Bookmarks > Import bookmarks and settings > Bookmarks HTML file. Firefox: Cmd+Shift+O > Import and Backup > Import Bookmarks from HTML. Safari: File > Import From > Bookmarks HTML File). It adds a 'DEPT (MS)' folder with every project.")
  fi
else
  rm -f "$BM.tmp"
fi

# 9. Manual steps (Cato has no Homebrew cask)
[[ -d /Applications/CatoClient.app ]] ||
  TODO+=("Install Cato Client VPN: https://clientdownload.catonetworks.com (ask for an account).")
TODO+=(
  "Run 'claude' once and sign in to Claude Code."
  "Something failed or unclear? Run 'claude' and paste the output: it can explain the error and fix your setup with you."
  "Check access: GitHub teams, Jira/Confluence (dept-nl), Keeper, Datadog EU, Slack. See the 'MS Developer Onboarding' page in Confluence."
)
say "Done. Open a new terminal, then do these manual steps:"
for t in "${TODO[@]}"; do echo "  - $t"; done
