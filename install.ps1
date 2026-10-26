# Install, reinstall or update the Claude Code plugins and skills listed in plugins.txt (Windows PowerShell / pwsh).
#
#   .\install.ps1                  all plugins: add missing marketplaces, install missing plugins, update the rest
#   .\install.ps1 caveman headroom   only the named plugins
#   .\install.ps1 -Pick            choose from a numbered list
#   .\install.ps1 -Export          add plugins installed on this machine but not yet listed in plugins.txt
#
# Remote one-liner (installs everything):
#   irm https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.ps1 | iex
# Remote with selection:
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.ps1))) -Pick
param(
    [switch]$Export,
    [switch]$Pick,
    [Parameter(ValueFromRemainingArguments)][string[]]$Names = @()
)
$ErrorActionPreference = 'Stop'

$RawUrl   = 'https://raw.githubusercontent.com/gudoy/claude-plugins/main/plugins.txt'
$Manifest = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'plugins.txt' } else { Join-Path (Get-Location) 'plugins.txt' }

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw 'claude CLI not found: https://docs.claude.com/en/docs/claude-code/setup'
}

# Clone GitHub repos over HTTPS so a machine without SSH keys still works.
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'url.https://github.com/.insteadOf'
$env:GIT_CONFIG_VALUE_0 = 'git@github.com:'

function Get-Marketplaces { claude plugin marketplace list --json 2>$null | Out-String | ConvertFrom-Json }
# Plugins synced from claude.ai (@synced) are managed by the account, not by this script.
function Get-LocalPlugins {
    (claude plugin list --json 2>$null | Out-String | ConvertFrom-Json) |
        Where-Object { $_.id -notlike '*@synced' } | ForEach-Object { $_.id }
}
function Get-ManifestIds([string]$Kind) {
    Get-Content $Manifest | Where-Object { $_ -match "^$Kind\s" } | ForEach-Object { ($_ -split '\s+')[1] }
}
function Get-MarketplaceSource([string]$Name) {
    Get-Content $Manifest | Where-Object { $_ -match "^marketplace\s+$([regex]::Escape($Name))\s" } |
        ForEach-Object { ($_ -split '\s+')[2] } | Select-Object -First 1
}
function Get-SkillSource([string]$Name) {
    Get-Content $Manifest | Where-Object { $_ -match "^skill\s+$([regex]::Escape($Name))\s" } |
        ForEach-Object { ($_ -split '\s+')[2] } | Select-Object -First 1
}

if (-not (Test-Path $Manifest)) {
    if ($Export) { throw '-Export needs a local clone of the repository.' }
    $Manifest = Join-Path ([IO.Path]::GetTempPath()) 'claude-plugins.txt'
    Invoke-WebRequest -UseBasicParsing $RawUrl -OutFile $Manifest
}

if ($Export) {
    $known = @(Get-ManifestIds 'plugin') + @(Get-ManifestIds 'exclude')
    $mkts  = @(Get-Marketplaces)
    $new   = @(Get-LocalPlugins | Where-Object { $known -notcontains $_ })
    foreach ($id in $new) {
        $mkt = $id.Split('@')[1]
        if (-not (Get-MarketplaceSource $mkt)) {
            $m = $mkts | Where-Object { $_.name -eq $mkt } | Select-Object -First 1
            $src = if ($m.repo) { $m.repo } elseif ($m.url) { $m.url } else { 'builtin' }
            Add-Content -Path $Manifest -Value "marketplace $mkt $src"
        }
        Add-Content -Path $Manifest -Value "plugin $id"
        Write-Host "+ $id"
    }
    Write-Host "Added $($new.Count) plugin(s) to $Manifest. Change 'plugin' to 'exclude' for any you do not want to share."
    return
}

$all = @(Get-ManifestIds 'plugin') + @(Get-ManifestIds 'skill')
if ($Pick) {
    for ($i = 0; $i -lt $all.Count; $i++) { Write-Host ('{0,3}) {1}' -f ($i + 1), $all[$i]) }
    $answer = Read-Host 'Numbers or ranges (e.g. "1 4 7-9"), or "all"'
    if ($answer.Trim() -eq 'all') { $selected = $all } else {
        $selected = foreach ($tok in ($answer -split '\s+' | Where-Object { $_ })) {
            if ($tok -match '^(\d+)-(\d+)$') { [int]$Matches[1]..[int]$Matches[2] | Where-Object { $_ -ge 1 -and $_ -le $all.Count } | ForEach-Object { $all[$_ - 1] } }
            elseif ($tok -match '^\d+$' -and [int]$tok -ge 1 -and [int]$tok -le $all.Count) { $all[[int]$tok - 1] }
            else { Write-Host "Ignored: $tok" }
        }
        $selected = @($selected | Select-Object -Unique)
    }
} elseif ($Names.Count) {
    $selected = foreach ($n in $Names) {
        $match = $all | Where-Object { $_ -eq $n -or $_ -like "$n@*" }
        if ($match) { $match } else { Write-Host "Not in plugins.txt: $n" }
    }
} else {
    $selected = $all
}
$selected = @($selected)
if (-not $selected.Count) { Write-Host 'Nothing selected.'; exit 1 }
# Plugin ids contain "@"; skill names do not.
$skills   = @($selected | Where-Object { $_ -notlike '*@*' })
$selected = @($selected | Where-Object { $_ -like '*@*' })

$haveMkt = @(Get-Marketplaces | ForEach-Object { $_.name })
$havePlg = @(Get-LocalPlugins)
$failed  = @()

foreach ($mkt in ($selected | ForEach-Object { $_.Split('@')[1] } | Sort-Object -Unique)) {
    $src = Get-MarketplaceSource $mkt
    if ($src -eq 'builtin') { continue }
    if ($haveMkt -contains $mkt) {
        Write-Host "↻ marketplace $mkt"
        claude plugin marketplace update $mkt *> $null; if ($LASTEXITCODE) { $failed += "marketplace update $mkt" }
    } elseif ($src) {
        Write-Host "+ marketplace $mkt ($src)"
        claude plugin marketplace add ($src -replace '^~', $HOME) *> $null; if ($LASTEXITCODE) { $failed += "marketplace add $src" }
    } else {
        $failed += "no 'marketplace $mkt' line in plugins.txt"
    }
}

foreach ($id in $selected) {
    if ($havePlg -contains $id) {
        Write-Host "↻ $id"
        claude plugin update $id *> $null; if ($LASTEXITCODE) { $failed += "update $id" }
    } else {
        Write-Host "+ $id"
        claude plugin install $id *> $null; if ($LASTEXITCODE) { $failed += "install $id" }
    }
}

# Standalone skills (no plugin marketplace) go through the Skills CLI; "add" also updates.
foreach ($name in $skills) {
    $src = Get-SkillSource $name
    Write-Host "+ skill $name ($src)"
    if ($src -like 'pypi:*') {
        if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { $failed += "skill $name (needs uv)"; continue }
        uv tool install --upgrade $src.Substring(5) *> $null
        if (-not $LASTEXITCODE) { & $name install *> $null }
        if ($LASTEXITCODE) { $failed += "skill $name" }
        continue
    }
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { $failed += "skill $name (needs Node.js/npx)"; continue }
    Push-Location $HOME
    npx -y skills add $src --skill $name --global --agent claude-code --yes *> $null
    if ($LASTEXITCODE) { $failed += "skill $name" }
    Pop-Location
}

Write-Host ''
if ($failed.Count) {
    Write-Host "Failed ($($failed.Count)):"; $failed | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host 'Done. Restart Claude Code (or run /reload-plugins) to load the changes.'
