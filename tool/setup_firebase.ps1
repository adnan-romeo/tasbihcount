param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$Platforms = "android,ios,web,windows,macos,linux"
)

$ErrorActionPreference = "Stop"

$env:Path = "C:\Program Files\Git\cmd;C:\Program Files\nodejs;C:\Users\adnan\AppData\Local\Pub\Cache\bin;C:\Users\adnan\AppData\Roaming\npm;" + $env:Path

Write-Host "Checking CLI tools..."
flutterfire --version
firebase.cmd --version

Write-Host "Logging into Firebase..."
firebase.cmd login --no-localhost

Write-Host "Configuring FlutterFire for project '$ProjectId'..."
flutterfire configure --project $ProjectId --platforms $Platforms --yes

Write-Host "Firebase setup completed."
Write-Host "Now run: flutter clean; flutter pub get; flutter run"
