$ErrorActionPreference = 'Stop'

$blockedFilesPattern = '^(android/app/google-services\.json|ios/Runner/GoogleService-Info\.plist|lib/firebase_options\.dart)$'
$secretPatterns = 'AIza[0-9A-Za-z_-]{20,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9-]+'

$failed = $false

$stagedFiles = git diff --cached --name-only
$blockedFiles = @($stagedFiles | Where-Object { $_ -match $blockedFilesPattern })
if ($blockedFiles.Count -gt 0) {
    Write-Host 'ERROR: Blocked sensitive file(s) staged:' -ForegroundColor Red
    $blockedFiles | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    Write-Host 'Generate Firebase config locally, but do not commit it.' -ForegroundColor Yellow
    $failed = $true
}

$addedLines = @(git diff --cached -U0 --no-color | Where-Object { $_ -match '^\+[^+]' })
foreach ($line in $addedLines) {
    if ($line -match $secretPatterns) {
        Write-Host 'ERROR: Potential secret detected in staged changes.' -ForegroundColor Red
        Write-Host 'Remove sensitive values before committing.' -ForegroundColor Yellow
        $failed = $true
        break
    }
}

if ($failed) {
    Write-Host 'Commit blocked by pre-commit security checks.' -ForegroundColor Red
    exit 1
}

exit 0
