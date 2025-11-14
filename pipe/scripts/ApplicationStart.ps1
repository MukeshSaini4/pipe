# ApplicationStart.ps1
# Start IIS site and warm-up

Import-Module WebAdministration

Write-Host "ApplicationStart: starting Default Web Site..."
Start-WebSite -Name "Default Web Site"

# Optional warm-up
try {
    $resp = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -TimeoutSec 15
    Write-Host "Warm-up status: $($resp.StatusCode)"
} catch {
    Write-Warning "Warm-up failed: $($_.Exception.Message)"
}

Write-Host "ApplicationStart completed."
