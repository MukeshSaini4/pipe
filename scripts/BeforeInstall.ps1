Import-Module WebAdministration
Stop-WebSite -Name "Default Web Site" -ErrorAction SilentlyContinue
Remove-Item -Path "C:\inetpub\wwwroot\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "BeforeInstall.ps1 completed."
