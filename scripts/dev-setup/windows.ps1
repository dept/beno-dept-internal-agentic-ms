# MS developer setup for Windows 10/11 (DEPT Managed Services).
# Safe to re-run, and safe on a PC that is already set up: every step skips what is already there.
# Usage, in PowerShell (no admin needed, Windows asks when an installer needs it):
#   irm https://raw.githubusercontent.com/dept/beno-dept-internal-agentic-ms/main/scripts/dev-setup/windows.ps1 | iex
# Kept to plain ASCII and Windows PowerShell 5.1, so it runs on a fresh Windows install.
& {
# Continue, not Stop: Windows PowerShell 5.1 turns redirected stderr of git, gh and dotnet into errors.
# Every step checks its own result instead.
$ErrorActionPreference = 'Continue'
$TODO = New-Object System.Collections.Generic.List[string]
function Say($m)  { Write-Host "`n==> $m" -ForegroundColor Blue }
function Warn($m) { Write-Host "!!  $m" -ForegroundColor Yellow }
function Had($c)  { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Skip($m) { Write-Host "$m already installed, skipped." }
# winget installs do not reach the PATH of this session, so reload it after each install.
function Update-Path {
  $cur = $env:Path -split ';'
  $new = ([Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
    [Environment]::GetEnvironmentVariable('Path', 'User') + ";$HOME\.local\bin") -split ';' |
    Where-Object { $_ -and $cur -notcontains $_ }
  if ($new) { $env:Path = (@($new) + $cur) -join ';' }
}
# A failed install becomes a manual step, the rest still runs.
function Inst($id, $name) {
  winget install --id $id -e --source winget --silent --accept-package-agreements --accept-source-agreements
  # -1978335189 / -1978335135: already installed (the app is there, its command is just not on PATH)
  if ($LASTEXITCODE -notin 0, -1978335189, -1978335135) {
    Warn "Installing $name failed (winget $LASTEXITCODE)"; $TODO.Add("Install $name manually: winget install --id $id -e")
  }
  Update-Path
}
function Ensure($cmd, $id, $name) { if (Had $cmd) { Skip $name } else { Inst $id $name } }

if (-not (Had winget)) {
  Write-Host "winget is missing. Install 'App Installer' from the Microsoft Store, then run this again."
  return
}
Update-Path

# 1. CLI tools and apps: each one only when it is missing, so an existing setup is left alone
Say "CLI tools and apps"
Ensure git    Git.Git            "Git (with Git Bash, which Claude Code needs)"
Ensure gh     GitHub.cli         "GitHub CLI"
Ensure mise   jdx.mise           "mise"
Ensure jq     jqlang.jq          "jq"
Ensure code   Microsoft.VisualStudioCode "VS Code"
# The py launcher comes with python.org Python; plain 'python' can be the Microsoft Store stub.
Ensure py     Python.Python.3.13 "Python (for the bookmarks file)"
if (Had claude) { Skip "Claude Code" } else {
  # Its own PowerShell, so an exit inside the installer cannot end this script.
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
  if ($LASTEXITCODE -ne 0) { Warn "Claude Code install failed"; $TODO.Add("Install Claude Code: irm https://claude.ai/install.ps1 | iex") }
  Update-Path
}

# .NET is only for the .NET projects, so it is opt-in: answer y, or set $env:DOTNET = '1' first.
$sdks = if (Had dotnet) { (dotnet --list-sdks 2>$null) -join "`n" } else { '' }
$has8 = $sdks -match '(?m)^8\.'
# The current .NET major is fixed here: bump it (and the winget id below) when a new .NET LTS/STS ships.
$dotnetCurrent = 10
$hasNew = [bool](($sdks -split "`n") | Where-Object { $_ -match '^(\d+)\.' -and [int]$Matches[1] -ge $dotnetCurrent })
if ($has8 -and $hasNew) { Skip ".NET SDK 8 and current" } else {
  $a = if ($env:DOTNET -eq '1') { 'y' } else { Read-Host "Install .NET SDK 8 and current? Only needed for .NET projects. [y/N]" }
  if ($a -match '^[yY]') {
    if ($has8) { Skip ".NET SDK 8" } else { Inst Microsoft.DotNet.SDK.8 ".NET SDK 8" }
    if ($hasNew) { Skip ".NET SDK (current)" } else { Inst "Microsoft.DotNet.SDK.$dotnetCurrent" ".NET SDK $dotnetCurrent" }
  } else { Write-Host ".NET SDK skipped (re-run with `$env:DOTNET = '1' to add it later)." }
}

# 2. Node via mise: reads .nvmrc / .node-version per repo, Node LTS as global default.
# mise shims on the user PATH work in every terminal and in VS Code, no profile script needed.
# Skipped when Node already comes from somewhere else (nvm-windows, fnm, an installer): that setup stays as it is.
Say "Node (mise) and corepack"
if (Had node) { Skip "Node ($((Get-Command node).Source))" }
elseif (Had mise) {
  $shims = "$env:LOCALAPPDATA\mise\shims"
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (($userPath -split ';') -notcontains $shims) {
    [Environment]::SetEnvironmentVariable('Path', "$shims;$userPath", 'User')
  }
  Update-Path
  mise settings add idiomatic_version_file_enable_tools node 2>$null
  mise use -g node@lts
  if ($LASTEXITCODE -ne 0) { Warn "mise could not install Node"; $TODO.Add("Install Node: mise use -g node@lts (check VPN/proxy), then re-run this script.") }
  else {
    # Newer Node majors no longer bundle corepack, so install it when missing
    mise exec -- where.exe corepack *> $null
    if ($LASTEXITCODE -ne 0) { mise exec -- npm install -g corepack }
    mise exec -- corepack enable
    if ($LASTEXITCODE -ne 0) { $TODO.Add("Enable corepack: mise exec -- corepack enable") }
    mise reshim
    Update-Path
  }
} else { $TODO.Add("Install Node: mise was not installed, see the warnings above.") }

# 3. Git identity and defaults, only where nothing is set yet
Say "Git identity"
if (Had git) {
  if (-not (git config --global user.name)) {
    do { $v = Read-Host "Full name for git commits" } until ($v); git config --global user.name $v
  }
  if (-not (git config --global user.email)) {
    do { $v = Read-Host "DEPT email for git commits" } until ($v); git config --global user.email $v
  }
  if (-not (git config --global init.defaultBranch)) { git config --global init.defaultBranch main }
  if (-not (git config --global pull.rebase)) { git config --global pull.rebase false }
  # node_modules paths get longer than the old 260-character Windows limit
  if (-not (git config --global core.longpaths)) { git config --global core.longpaths true }
  Write-Host "Git commits as $(git config --global user.name) <$(git config --global user.email)>"
}

# 4. GitHub login (HTTPS through gh, no SSH key needed)
Say "GitHub CLI login"
$ghOk = $false
if (Had gh) {
  gh auth status *> $null
  if ($LASTEXITCODE -ne 0) { gh auth login --hostname github.com --git-protocol https --web }
  gh auth status *> $null
  $ghOk = $LASTEXITCODE -eq 0
  if (-not $ghOk) { $TODO.Add("Log in to GitHub: gh auth login --web, then re-run this script.") }
  # Any helper that already applies to github.com (for example Git Credential Manager from the Git
  # installer, in system config) is left as it is; gh becomes the helper only when there is none.
  elseif (-not (git config --get-urlmatch credential.helper https://github.com)) { gh auth setup-git }
}

# 5. MS project context + ms-agentic-context skill for Claude Code
Say "MS agentic context"
$ctx = "$HOME\.cache\ms-agentic-context"
if (Test-Path "$ctx\.git") { git -C $ctx pull --quiet --ff-only }
elseif ($ghOk) {
  gh repo clone dept/beno-dept-ms-agentic-context $ctx -- --depth 1
  if ($LASTEXITCODE -ne 0) { $TODO.Add("No access to dept/beno-dept-ms-agentic-context yet. Re-run this script once your GitHub access is granted.") }
}
if (Test-Path "$ctx\skills\ms-agentic-context") {
  $skills = "$HOME\.claude\skills"
  New-Item -ItemType Directory -Force $skills | Out-Null
  Remove-Item -Recurse -Force "$skills\ms-agentic-context" -ErrorAction SilentlyContinue
  Copy-Item -Recurse "$ctx\skills\ms-agentic-context" $skills
  Write-Host "Skill installed in $skills\ms-agentic-context"
}

# Bookmarks are generated from each project's context, so re-run this script for a fresh file.
# The real Downloads folder, also when it is moved or on OneDrive
$dl = try { (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path } catch { "$HOME\Downloads" }
if (-not $dl) { $dl = "$HOME\Downloads" }
$bm = "$dl\dept-ms-bookmarks.html"
$importHelp = "Import $bm in your browser (Chrome, Edge, Brave: Settings > Import bookmarks and settings > Bookmarks HTML file. Firefox: Ctrl+Shift+O > Import and Backup > Import Bookmarks from HTML). It adds a 'DEPT (MS)' folder with every project."
if (-not (Test-Path "$ctx\onboarding\bookmarks.py")) { }
elseif (-not (Had py)) { Warn "Python (py) not found, no bookmarks file"; $TODO.Add("Install Python (winget install --id Python.Python.3.13 -e), then re-run this script for the bookmarks file.") }
else {
  # PYTHONUTF8 makes Python read and write UTF-8; Start-Process hands it the file as stdout, so the
  # bytes stay as they are (PowerShell's own > would write UTF-16).
  $env:PYTHONUTF8 = '1'
  $proc = Start-Process py -ArgumentList '-3', "`"$ctx\onboarding\bookmarks.py`"" -RedirectStandardOutput "$bm.tmp" -NoNewWindow -Wait -PassThru
  if ($proc.ExitCode -eq 0) {
    Move-Item -Force "$bm.tmp" $bm
    $browsers = [ordered]@{}
    foreach ($p in @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")) {
      if (-not $browsers.Contains('Google Chrome') -and (Test-Path $p)) { $browsers['Google Chrome'] = @($p, 'chrome://settings/importData') }
    }
    foreach ($p in @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")) {
      if (-not $browsers.Contains('Microsoft Edge') -and (Test-Path $p)) { $browsers['Microsoft Edge'] = @($p, 'edge://settings/profiles/importBrowsingData') }
    }
    foreach ($p in @("$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe")) {
      if (-not $browsers.Contains('Brave') -and (Test-Path $p)) { $browsers['Brave'] = @($p, 'brave://settings/importData') }
    }
    foreach ($p in @("$env:ProgramFiles\Mozilla Firefox\firefox.exe", "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe")) {
      if (-not $browsers.Contains('Firefox') -and (Test-Path $p)) { $browsers['Firefox'] = @($p, $null) }
    }
    $names = @($browsers.Keys)
    $pick = $null
    if ($names.Count -gt 0) {
      Write-Host "Import the bookmarks into a browser now? Pick a number:"
      for ($i = 0; $i -lt $names.Count; $i++) { Write-Host "  $($i + 1)) $($names[$i])" }
      Write-Host "  $($names.Count + 1)) Skip"
      $n = 0
      if ([int]::TryParse((Read-Host "#"), [ref]$n) -and $n -ge 1 -and $n -le $names.Count) { $pick = $names[$n - 1] }
    }
    if ($pick) {
      # Show the file first: Explorer takes focus, so the browser opened after it ends up in front.
      Start-Process explorer.exe "/select,`"$bm`""
      Start-Sleep -Seconds 1
      $exe, $url = $browsers[$pick]
      if ($url) {
        # Windows often keeps the new browser window behind other windows, and some browsers ignore
        # settings URLs from the command line, so the URL also goes on the clipboard.
        Set-Clipboard -Value $url
        Start-Process $exe $url
        $how = "switch to $pick via the taskbar (Windows can open it behind other windows) and check it is your work profile. No import page? Press Ctrl+L, Ctrl+V, Enter to open $url (already on your clipboard). Choose 'Bookmarks HTML file', then Choose file."
      } else {
        Start-Process $exe
        $how = "press Ctrl+Shift+O (Library), click Import and Backup, then Import Bookmarks from HTML"
      }
      Say "Finish the import in $pick"
      Write-Host "1. $how"
      Write-Host "2. Pick $bm (also shown in an Explorer window behind the browser)"
      Write-Host "You get a 'DEPT (MS)' bookmarks folder with every project."
    } else { $TODO.Add($importHelp) }
  } else {
    Remove-Item -Force "$bm.tmp" -ErrorAction SilentlyContinue
    Warn "Could not generate the bookmarks file"
  }
}

# 6. Manual steps (Cato has no winget package)
if (-not ((Test-Path "$env:ProgramFiles\Cato Networks") -or (Test-Path "${env:ProgramFiles(x86)}\Cato Networks"))) {
  $TODO.Add("Install Cato Client VPN: https://clientdownload.catonetworks.com (ask for an account).")
}
$TODO.Add("Run 'claude' once and sign in to Claude Code.")
$TODO.Add("Something failed or unclear? Run 'claude' and paste the output: it can explain the error and fix your setup with you.")
$TODO.Add("Check access: GitHub teams, Jira/Confluence (dept-nl), Keeper, Datadog EU, Slack. See the 'MS Developer Onboarding' page in Confluence.")
Say "Done. Open a new terminal, then do these manual steps:"
foreach ($t in $TODO) { Write-Host "  - $t" }
}
