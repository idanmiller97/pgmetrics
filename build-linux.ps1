# Cross-compile pgmetrics for Linux from Windows
# This script builds a Linux binary that can run on the target system

Write-Host "pgmetrics Linux Cross-Compile Script" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Check if Go is available
try {
    $goVersion = go version
    Write-Host "Go found: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Go is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Go from https://go.dev/dl/" -ForegroundColor Yellow
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

# Build for Linux
Write-Host "Cross-compiling for Linux..." -ForegroundColor Yellow

# Set build environment variables for Linux
$env:CGO_ENABLED = "0"
$env:GOOS = "linux"
$env:GOARCH = "amd64"

try {
    go build -a -trimpath -ldflags "-s -w -X main.version=1.0.0" -o pgmetrics ./cmd/pgmetrics
    Write-Host "Linux build completed successfully!" -ForegroundColor Green
    Write-Host "Binary created: pgmetrics (Linux executable)" -ForegroundColor Green
} catch {
    Write-Host "Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create archive for Linux
Write-Host "Creating Linux archive..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archiveName = "pgmetrics_linux_amd64_$timestamp"

# Create a temporary directory for the archive contents
$tempDir = "temp_archive"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy files to temp directory
Copy-Item "pgmetrics" $tempDir\
Copy-Item "README.md" $tempDir\
Copy-Item "LICENSE" $tempDir\

# Create tar.gz file (Linux standard)
$tarName = "$archiveName.tar.gz"

# Check if tar is available
if (Get-Command tar -ErrorAction SilentlyContinue) {
    tar -czf $tarName -C $tempDir .
    Write-Host "Linux archive created: $tarName" -ForegroundColor Green
} else {
    # Fallback: create zip file
    $zipName = "$archiveName.zip"
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipName -Force
    Write-Host "Linux archive created: $zipName" -ForegroundColor Green
    Write-Host "Note: This is a zip file. For Linux, tar.gz is preferred." -ForegroundColor Yellow
}

# Clean up temp directory
Remove-Item $tempDir -Recurse -Force

Write-Host "Cross-compilation completed!" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Yellow
Write-Host "  - pgmetrics (Linux executable)" -ForegroundColor White
if (Get-Command tar -ErrorAction SilentlyContinue) {
    Write-Host "  - $tarName (Linux tar.gz archive)" -ForegroundColor White
} else {
    Write-Host "  - $zipName (zip archive)" -ForegroundColor White
}
Write-Host "" -ForegroundColor White
Write-Host "To deploy on Linux:" -ForegroundColor Yellow
Write-Host "1. Copy the 'pgmetrics' binary to your Linux system" -ForegroundColor White
Write-Host "2. Make it executable: chmod +x pgmetrics" -ForegroundColor White
Write-Host "3. Run: ./pgmetrics [options]" -ForegroundColor White 