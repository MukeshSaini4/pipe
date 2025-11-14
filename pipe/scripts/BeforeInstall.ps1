# BeforeInstall.ps1
# Stop IIS, backup existing site, clean target folder

Import-Module WebAdministration

Write-Host "BeforeInstall: stopping Default Web Site..."
Stop-WebSite -Name "Default Web Site" -ErrorAction SilentlyContinue

# Backup current wwwroot to C:\backup\wwwroot\<timestamp>
$srcPath = "C:\inetpub\wwwroot"
$backupRoot = "C:\backup\wwwroot"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $backupRoot $stamp
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Write-Host "Backing up existing site to $backup ..."
Copy-Item -Path $srcPath\* -Destination $backup -Recurse -Force -ErrorAction SilentlyContinue

# Clean target folder
Write-Host "Cleaning $srcPath ..."
Get-ChildItem -Path $srcPath -Recurse -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "BeforeInstall completed."
