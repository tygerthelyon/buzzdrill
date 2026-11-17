# build-apk.ps1 -- build and sign the Buzz Drill Android app.
#
# The app is a Trusted Web Activity: a thin Android shell that opens https://buzzdrill.qbdrill.workers.dev full screen
# (the site vouches for it at /.well-known/assetlinks.json). So the app rarely needs rebuilding: changes to the site
# reach it at once. Rebuild only to change the name, icon, colors, or Android version support: edit twa-manifest.json
# (raise appVersionCode, or phones won't take the update), run `npx @bubblewrap/cli@1.27.0 update --skipVersionUpgrade`
# here to regenerate the project, then this script.
#
# Signing: the key and its password live in "OneDrive\Buzz Drill signing key", never in this repo. Every update must
# be signed with that same key. (bubblewrap's own build step can't sign from a folder with spaces in its name, so this
# runs Gradle and apksigner itself.)
#
#   powershell -ExecutionPolicy Bypass -File build-apk.ps1     -> ..\dist\BuzzDrill.apk
$ErrorActionPreference = "Stop"
$keyDir = Join-Path $env:USERPROFILE "OneDrive\Buzz Drill signing key"
$readme = Join-Path $keyDir "README - keep this.txt"
if (-not (Test-Path $readme)) { throw "Signing key folder not found: $keyDir" }
$env:KSPW = ((Get-Content $readme | Select-String "^Password").ToString() -split ":\s*", 2)[1].Trim()
$env:JAVA_HOME = (Get-ChildItem "C:\Program Files\Microsoft" -Directory | Where-Object Name -like "jdk-17*" | Select-Object -First 1).FullName
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$buildTools = Get-ChildItem (Join-Path $env:ANDROID_HOME "build-tools") -Directory | Sort-Object { [version]$_.Name } | Select-Object -Last 1
$java = Join-Path $env:JAVA_HOME "bin\java.exe"

Set-Location $PSScriptRoot
Remove-Item Env:NoDefaultCurrentDirectoryInExePath -ErrorAction SilentlyContinue   # some shells won't run .\gradlew.bat otherwise
$ErrorActionPreference = "Continue"   # Gradle reports progress on stderr; exit codes decide
cmd /c ".\gradlew.bat assembleRelease --no-daemon --console=plain 2>&1"
if ($LASTEXITCODE -ne 0) { throw "Gradle build failed." }

$unsigned = "app\build\outputs\apk\release\app-release-unsigned.apk"
& (Join-Path $buildTools.FullName "zipalign.exe") -f -p 4 $unsigned "app-release-aligned.apk"
if ($LASTEXITCODE -ne 0) { throw "zipalign failed." }
& $java -jar (Join-Path $buildTools.FullName "lib\apksigner.jar") sign --ks (Join-Path $keyDir "buzzdrill-android.keystore") `
    --ks-key-alias buzzdrill --ks-pass env:KSPW --key-pass env:KSPW --out "app-release-signed.apk" "app-release-aligned.apk"
$signed = $LASTEXITCODE
Remove-Item Env:KSPW
if ($signed -ne 0) { throw "Signing failed." }

$dist = Join-Path (Split-Path -Parent $PSScriptRoot) "dist"
New-Item -ItemType Directory -Force $dist | Out-Null
Copy-Item "app-release-signed.apk" (Join-Path $dist "BuzzDrill.apk") -Force
Remove-Item "app-release-aligned.apk", "app-release-unsigned-aligned.apk" -ErrorAction SilentlyContinue
Write-Host ("Built {0} ({1:N1} MB)" -f (Join-Path $dist "BuzzDrill.apk"), ((Get-Item (Join-Path $dist "BuzzDrill.apk")).Length / 1MB))
