# AfterInstall.ps1
# Post-copy checks and permission fixes

Write-Host "AfterInstall: verifying deployment files..."

$target = "C:\inetpub\wwwroot"
# Basic sanity checks
if (!(Test-Path (Join-Path $target "web.config")) -and !(Get-ChildItem -Path $target | Where-Object { $_.Name -match '\.dll$' })) {
    Write-Error "AfterInstall: expected web.config or DLLs not found in $target"
    exit 1
}

# Ensure IIS user has access
Write-Host "Setting permissions for IIS_IUSRS on $target ..."
$acl = Get-Acl $target
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit, ObjectInherit","None","Allow")
$acl.SetAccessRule($rule)
Set-Acl $target $acl

Write-Host "AfterInstall completed."
