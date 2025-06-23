# Simple pgmetrics Build Script for Windows
# Assumes Go is already installed

Write-Host "pgmetrics Simple Build Script" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check if Go is available
try {
    $goVersion = go version
    Write-Host "Go found: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Go is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Go from https://go.dev/dl/" -ForegroundColor Yellow
    Write-Host "Or run the full build script: .\build.ps1" -ForegroundColor Yellow
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