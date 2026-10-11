# Install, reinstall or update the Claude Code plugins listed in plugins.txt (Windows PowerShell / pwsh).
#
#   .\install.ps1           add missing marketplaces, install missing plugins, update the rest
#   .\install.ps1 -Export   rewrite plugins.txt from the plugins installed on this machine
#
# Remote one-liner:
#   irm https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.ps1 | iex
param([switch]$Export)
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

if ($Export) {
    $lines = @(
        '# Claude Code plugins manifest, read by install.sh / install.ps1.'
        '# Regenerate with: ./install.sh --export'
        "# marketplace <name> <source>   source = GitHub owner/repo, git URL, or 'builtin'"
        '# plugin <name@marketplace>'
        ''
    )
    $mkts = Get-Marketplaces | ForEach-Object {
        $src = if ($_.repo) { $_.repo } elseif ($_.url) { $_.url } else { 'builtin' }
        "marketplace $($_.name) $src"
    }
    $lines += $mkts | Sort-Object -Unique
    $lines += ''
    $plugins = @(Get-LocalPlugins | Sort-Object)
    $lines += $plugins | ForEach-Object { "plugin $_" }
    $lines | Set-Content -Path $Manifest -Encoding utf8
    Write-Host "Wrote $Manifest ($($plugins.Count) plugins)."
    return
}

if (-not (Test-Path $Manifest)) {
    $Manifest = Join-Path ([IO.Path]::GetTempPath()) 'claude-plugins.txt'
    Invoke-WebRequest -UseBasicParsing $RawUrl -OutFile $Manifest
}

$haveMkt = @(Get-Marketplaces | ForEach-Object { $_.name })
$havePlg = @(Get-LocalPlugins)
$failed  = @()
$entries = Get-Content $Manifest | Where-Object { $_ -match '^(marketplace|plugin) ' } | ForEach-Object { , ($_ -split '\s+') }

foreach ($e in $entries | Where-Object { $_[0] -eq 'marketplace' -and $_[2] -ne 'builtin' }) {
    $name, $src = $e[1], $e[2]
    if ($haveMkt -contains $name) {
        Write-Host "↻ marketplace $name"
        claude plugin marketplace update $name *> $null; if ($LASTEXITCODE) { $failed += "marketplace update $name" }
    } else {
        Write-Host "+ marketplace $name ($src)"
        claude plugin marketplace add $src *> $null; if ($LASTEXITCODE) { $failed += "marketplace add $src" }
    }
}

foreach ($e in $entries | Where-Object { $_[0] -eq 'plugin' }) {
    $id = $e[1]
    if ($havePlg -contains $id) {
        Write-Host "↻ $id"
        claude plugin update $id *> $null; if ($LASTEXITCODE) { $failed += "update $id" }
    } else {
        Write-Host "+ $id"
        claude plugin install $id *> $null; if ($LASTEXITCODE) { $failed += "install $id" }
    }
}

Write-Host ''
if ($failed.Count) {
    Write-Host "Failed ($($failed.Count)):"; $failed | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host 'Done. Restart Claude Code (or run /reload-plugins) to load the changes.'
