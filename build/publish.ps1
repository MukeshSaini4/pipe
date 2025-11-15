Write-Host "Starting build + package..."

# 1) Install .NET
Invoke-WebRequest "https://dot.net/v1/dotnet-install.ps1" -OutFile "dotnet-install.ps1"
powershell -ExecutionPolicy Bypass -File ".\dotnet-install.ps1" -Version "8.0.405" -InstallDir "C:\dotnet"
& "C:\dotnet\dotnet.exe" --info

# 2) Restore
& "C:\dotnet\dotnet.exe" restore

# 3) Build
& "C:\dotnet\dotnet.exe" build -c Release

# 4) Auto-find build directory
$dll = Get-ChildItem -Recurse -Filter "*.dll" |
       Where-Object { $_.FullName -match "\\bin\\Release\\" } |
       Select-Object -First 1

if (-not $dll) {
    Write-Error "No DLL found in bin\Release"
    exit 1
}

$builtPath = Split-Path $dll.FullName -Parent
Write-Host "Found build output at $builtPath"

# 5) Prepare output/app
$output = "output\app"
if (Test-Path $output) { Remove-Item -Recurse -Force $output }
New-Item -ItemType Directory -Force -Path $output | Out-Null

Copy-Item -Path "$builtPath\*" -Destination $output -Recurse -Force

# 6) Prepare dist/app
$dist = "dist\app"
if (Test-Path "dist") { Remove-Item -Recurse -Force "dist" }
New-Item -ItemType Directory -Force -Path $dist | Out-Null
Copy-Item -Path "$output\*" -Destination $dist -Recurse -Force

# 7) Create ZIP
if (Test-Path "artifact.zip") { Remove-Item "artifact.zip" -Force }
Compress-Archive -Path "dist\app\*" -DestinationPath "artifact.zip" -Force

Write-Host "artifact.zip created successfully."
