# Manual pgmetrics Build Script
# This script assumes Go is already installed

Write-Host "pgmetrics Manual Build Script" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check if Go is available
try {
    $goVersion = go version
    Write-Host "Go found: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Go is not installed or not in PATH" -ForegroundColor Red
    Write-Host "" -ForegroundColor White
    Write-Host "To install Go manually:" -ForegroundColor Yellow
    Write-Host "1. Download Go from: https://go.dev/dl/" -ForegroundColor White
    Write-Host "2. Run the installer (go1.24.1.windows-amd64.msi)" -ForegroundColor White
    Write-Host "3. Restart your terminal/PowerShell" -ForegroundColor White
    Write-Host "4. Run this script again" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "Or try running: .\build.bat" -ForegroundColor Yellow
    exit 1
}

# Navigate to the pgmetrics directory if needed
if (Test-Path "pgmetrics") {
    Set-Location "pgmetrics"
    Write-Host "Changed to pgmetrics directory" -ForegroundColor Yellow
}

# Download dependencies
Write-Host "Downloading dependencies..." -ForegroundColor Yellow
go mod download

# Build the project
Write-Host "Building pgmetrics..." -ForegroundColor Yellow

# Set build environment variables
$env:CGO_ENABLED = "0"
$env:GOOS = "windows"
$env:GOARCH = "amd64"

try {
    go build -a -trimpath -ldflags "-s -w -X main.version=1.0.0" -o pgmetrics.exe ./cmd/pgmetrics
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "Binary created: pgmetrics.exe" -ForegroundColor Green
} catch {
    Write-Host "Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create archive
Write-Host "Creating archive..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archiveName = "pgmetrics_windows_amd64_$timestamp"

# Create a temporary directory for the archive contents
$tempDir = "temp_archive"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy files to temp directory
Copy-Item "pgmetrics.exe" $tempDir\
Copy-Item "README.md" $tempDir\
Copy-Item "LICENSE" $tempDir\

# Create zip file (Windows native)
$zipName = "$archiveName.zip"
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipName -Force
Write-Host "Archive created: $zipName" -ForegroundColor Green

# Clean up temp directory
Remove-Item $tempDir -Recurse -Force

Write-Host "Build process completed!" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Yellow
Write-Host "  - pgmetrics.exe (executable)" -ForegroundColor White
Write-Host "  - $zipName (archive)" -ForegroundColor White 