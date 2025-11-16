<#
  publish.ps1
  - Finds the ASP.NET Core web project (Microsoft.NET.Sdk.Web) or first csproj
  - Publishes it into a staging folder
  - Prepares dist\app with published files + appspec.yml + scripts
  - Creates artifact.zip at repo root (contains contents of dist\app)
  - Safe / idempotent (removes old folders)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "---- publish.ps1 started ----"

# helper to find dotnet
$dotnetCandidates = @("C:\dotnet\dotnet.exe","dotnet")
$dotnet = $dotnetCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $dotnet) {
  Write-Host "WARNING: dotnet not found at C:\dotnet\dotnet.exe and not on PATH. Trying 'dotnet'..."
  $dotnet = "dotnet"
}

Write-Host "Using dotnet executable: $dotnet"

# determine publish configuration
if (-not $env:CONFIGURATION -or $env:CONFIGURATION -eq "") { $config = "Release" } else { $config = $env:CONFIGURATION }
Write-Host "Publish configuration: $config"

# find project: prefer Web SDK projects
Write-Host "Searching for web project (.csproj with Microsoft.NET.Sdk.Web)..."
$webProj = Get-ChildItem -Recurse -Filter *.csproj -ErrorAction SilentlyContinue |
           Where-Object {
             try {
               Select-String -Path $_.FullName -Pattern 'Microsoft\.NET\.Sdk\.Web' -Quiet -SimpleMatch
             } catch {
               $false
             }
           } |
           Select-Object -First 1

if ($webProj) {
  $projPath = $webProj.FullName
  Write-Host "Found web project: $projPath"
} else {
  Write-Host "No explicit web project found. Picking first .csproj in repo."
  $firstProj = Get-ChildItem -Recurse -Filter *.csproj -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $firstProj) {
    Write-Error "No .csproj files found in repository. Exiting."
    exit 1
  }
  $projPath = $firstProj.FullName
  Write-Host "Selected project: $projPath"
}

# pick publish root: prefer env:PUBLISH_DIR if provided (used in some buildspecs)
if ($env:PUBLISH_DIR -and $env:PUBLISH_DIR -ne "") {
  $pubRoot = Join-Path (Get-Location) $env:PUBLISH_DIR
  Write-Host "Using PUBLISH_DIR from environment: $env:PUBLISH_DIR -> $pubRoot"
} else {
  $pubRoot = Join-Path (Get-Location) "output"
  Write-Host "Using default publish root: $pubRoot"
}

# clean previous outputs
if (Test-Path $pubRoot) {
  Write-Host "Removing existing publish root: $pubRoot"
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $pubRoot
}
if (Test-Path "dist") {
  Write-Host "Removing existing dist folder"
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "dist"
}
if (Test-Path "artifact.zip") {
  Write-Host "Removing existing artifact.zip"
  Remove-Item -Force "artifact.zip" -ErrorAction SilentlyContinue
}

# publish to pubRoot\app
$outDir = Join-Path $pubRoot "app"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "Running dotnet publish for project:"
Write-Host "  $projPath"
Write-Host "  output -> $outDir"
& $dotnet publish $projPath -c $config -o $outDir

Write-Host "dotnet publish completed. Published files count: " (Get-ChildItem -Recurse -Path $outDir | Measure-Object).Count

# Prepare dist/app for artifact (CodeDeploy expects artifact root with appspec.yml & scripts)
$distApp = Join-Path (Get-Location) "dist\app"
New-Item -ItemType Directory -Force -Path $distApp | Out-Null

# copy published output into dist\app
Write-Host "Copying published output to $distApp"
Copy-Item -Path (Join-Path $outDir '*') -Destination $distApp -Recurse -Force

# Include appspec.yml (if present) into dist root (not dist\app)
if (Test-Path "appspec.yml") {
  Write-Host "Copying appspec.yml to dist"
  Copy-Item -Path "appspec.yml" -Destination (Join-Path (Get-Location) "dist") -Force
} else {
  Write-Host "No appspec.yml found in repo root. Make sure you have one for CodeDeploy."
}

# Include scripts folder under dist/scripts (if present)
if (Test-Path "scripts") {
  Write-Host "Copying scripts folder to dist/scripts"
  Copy-Item -Path "scripts\*" -Destination (Join-Path (Get-Location) "dist\scripts") -Recurse -Force
} else {
  Write-Host "No scripts folder found in repo root. (That's OK if you don't use lifecycle scripts.)"
}

# create artifact.zip containing contents of dist (apps + appspec + scripts)
Write-Host "Creating artifact.zip from dist..."
Compress-Archive -Path (Join-Path (Get-Location) "dist\*") -DestinationPath (Join-Path (Get-Location) "artifact.zip") -Force
Write-Host "artifact.zip created: $(Get-Item artifact.zip).FullName"

Write-Host "---- publish.ps1 finished successfully ----"
exit 0
