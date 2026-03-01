$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$sourceHook = Join-Path $repoRoot '.githooks\pre-commit'
$targetHook = Join-Path $repoRoot '.git\hooks\pre-commit'

if (-not (Test-Path $sourceHook)) {
    throw "Hook source not found: $sourceHook"
}

Copy-Item -Path $sourceHook -Destination $targetHook -Force

$gitExe = (Get-Command git).Source
$gitRoot = Split-Path (Split-Path $gitExe -Parent) -Parent
$shExe = Join-Path $gitRoot 'bin\sh.exe'

if (Test-Path $shExe) {
    $repoPathValue = (Resolve-Path $repoRoot).Path
    $repoPosixPath = ($repoPathValue -replace '\\', '/')
    $repoPosixPath = $repoPosixPath -replace '^([A-Za-z]):', '/$1'
    $repoPosixPath = [regex]::Replace($repoPosixPath, '^/([A-Za-z])/', { "/$($args[0].Groups[1].Value.ToLower())/" })

    & $shExe -lc "cd $repoPosixPath && chmod +x .git/hooks/pre-commit"
}

Write-Host 'Installed pre-commit hook at .git/hooks/pre-commit' -ForegroundColor Green
