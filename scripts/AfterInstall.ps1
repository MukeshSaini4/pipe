Write-Host "AfterInstall.ps1 started."
Copy-Item -Path "C:\temp\app\*" -Destination "C:\inetpub\wwwroot\" -Recurse -Force
Write-Host "AfterInstall.ps1 completed."
