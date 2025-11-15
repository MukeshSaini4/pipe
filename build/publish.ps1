try {
  $pubRoot = Join-Path (Get-Location) $env:PUBLISH_DIR;
  if (-not (Test-Path $pubRoot)) { New-Item -ItemType Directory -Force -Path $pubRoot | Out-Null };

  Get-ChildItem -Recurse -Filter *.csproj | ForEach-Object {
    $projPath = $_.FullName
    if (Select-String -Path $projPath -Pattern 'Microsoft.NET.Sdk.Web' -Quiet) {
      Write-Host "Publishing $projPath"
      $outDir = Join-Path $pubRoot ($_.BaseName)
      & "C:\dotnet\dotnet.exe" publish $projPath -c $env:CONFIGURATION -o $outDir
    }
  }

  $dist = Join-Path (Get-Location) "dist"
  if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
  New-Item -ItemType Directory -Force -Path (Join-Path $dist "app") | Out-Null

  Copy-Item -Path (Join-Path $pubRoot "*") -Destination (Join-Path $dist "app") -Recurse -Force

  if (Test-Path "appspec.yml") { Copy-Item "appspec.yml" $dist -Force }
  if (Test-Path "scripts") { Copy-Item "scripts\*" (Join-Path $dist "scripts") -Recurse -Force }

  if (Test-Path "artifact.zip") { Remove-Item "artifact.zip" -Force }
  Compress-Archive -Path (Join-Path $dist "*") -DestinationPath "artifact.zip" -Force

  Write-Host "artifact.zip created"
  exit 0
} catch {
  Write-Host "ERROR: $($_.Exception.Message)"
  exit 1
}
