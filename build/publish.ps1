# FILE: build/publish.ps1
# Put this file under folder 'build' in your repo (path: build\publish.ps1)
# This script auto-discovers the compiled output under any bin\Release\* folder,
# copies it to output\app, prepares dist\app and creates artifact.zip in repo root.


param()


try {
Write-Host "Starting publish script..."


# find first DLL under a bin\Release folder
$dll = Get-ChildItem -Path . -Recurse -Filter "*.dll" -File | Where-Object { $_.FullName -match "\\bin\\Release\\" } | Select-Object -First 1
if ($null -eq $dll) {
Write-Host "ERROR: no built dll found under any bin\\Release folder"
exit 1
}


$builtDir = Split-Path $dll.FullName -Parent
Write-Host "Found build directory:" $builtDir


$pubRoot = Join-Path (Get-Location) 'output'
$destApp = Join-Path $pubRoot 'app'
if (-not (Test-Path $pubRoot)) { New-Item -ItemType Directory -Force -Path $pubRoot | Out-Null }
if (Test-Path $destApp) { Remove-Item -Recurse -Force $destApp -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $destApp | Out-Null


Copy-Item -Path (Join-Path $builtDir '*') -Destination $destApp -Recurse -Force
Write-Host "Copied build output from" $builtDir "to" $destApp


$dist = Join-Path (Get-Location) 'dist'
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path (Join-Path $dist 'app') | Out-Null
Copy-Item -Path (Join-Path $destApp '*') -Destination (Join-Path $dist 'app') -Recurse -Force


if (Test-Path 'appspec.yml') { Copy-Item -Path 'appspec.yml' -Destination $dist -Force; Write-Host 'Copied appspec.yml to' $dist }
if (Test-Path 'scripts') { Copy-Item -Path 'scripts\\*' -Destination (Join-Path $dist 'scripts') -Recurse -Force; Write-Host 'Copied scripts to' (Join-Path $dist 'scripts') }


if (Test-Path 'artifact.zip') { Remove-Item 'artifact.zip' -Force }
Compress-Archive -Path (Join-Path $dist 'app\\*') -DestinationPath 'artifact.zip' -Force
Write-Host 'artifact.zip created at' (Join-Path (Get-Location) 'artifact.zip')


exit 0
} catch {
Write-Host "ERROR in publish.ps1: $($_.Exception.Message)"
exit 1
}
