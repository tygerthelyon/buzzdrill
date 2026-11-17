# build-apk.ps1 -- build and sign the Buzz Drill Android app.
#
# The app is a Trusted Web Activity: a thin Android shell that opens https://buzzdrill.qbdrill.workers.dev full screen
# (the site vouches for it at /.well-known/assetlinks.json). So the app rarely needs rebuilding: changes to the site
# reach it at once. Rebuild only to change the name, icon, colors, or Android version support; then raise
# appVersionCode in twa-manifest.json first, or phones won't take the update.
#
# Signing: the key and its password live in "OneDrive\Buzz Drill signing key", never in this repo. Every update must
# be signed with that same key.
#
#   powershell -ExecutionPolicy Bypass -File build-apk.ps1     -> ..\dist\BuzzDrill.apk
$ErrorActionPreference = "Stop"
$keyDir = Join-Path $env:USERPROFILE "OneDrive\Buzz Drill signing key"
$readme = Join-Path $keyDir "README - keep this.txt"
if (-not (Test-Path $readme)) { throw "Signing key folder not found: $keyDir" }
$pw = ((Get-Content $readme | Select-String "^Password").ToString() -split ":\s*", 2)[1].Trim()
$env:BUBBLEWRAP_KEYSTORE_PASSWORD = $pw
$env:BUBBLEWRAP_KEY_PASSWORD = $pw
$env:JAVA_HOME = (Get-ChildItem "C:\Program Files\Microsoft" -Directory | Where-Object Name -like "jdk-17*" | Select-Object -First 1).FullName

Set-Location $PSScriptRoot
# bubblewrap runs "gradlew.bat" by bare name from this folder, which some shells forbid
Remove-Item Env:NoDefaultCurrentDirectoryInExePath -ErrorAction SilentlyContinue
$ErrorActionPreference = "Continue"   # wrangler-style tools print progress on stderr; the exit code decides
cmd /c "npx -y @bubblewrap/cli@1.27.0 build --skipPwaValidation < NUL 2>&1"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path "app-release-signed.apk")) { throw "Build failed." }

$dist = Join-Path (Split-Path -Parent $PSScriptRoot) "dist"
New-Item -ItemType Directory -Force $dist | Out-Null
Copy-Item "app-release-signed.apk" (Join-Path $dist "BuzzDrill.apk") -Force
Write-Host ("Built {0} ({1:N1} MB)" -f (Join-Path $dist "BuzzDrill.apk"), ((Get-Item (Join-Path $dist "BuzzDrill.apk")).Length / 1MB))
