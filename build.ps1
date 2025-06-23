# pgmetrics Build Script for Windows
# This script downloads Go if not available and builds pgmetrics

param(
    [string]$GoVersion = "1.24.1",
    [string]$Architecture = "amd64",
    [string]$OS = "windows"
)

Write-Host "pgmetrics Build Script" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

# Function to check if Go is available
function Test-GoAvailable {
    try {
        $null = Get-Command go -ErrorAction Stop
        $goVersion = go version
        Write-Host "Go found: $goVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Go not found in PATH" -ForegroundColor Yellow
        return $false
    }
}

# Function to download and install Go
function Install-Go {
    param([string]$Version, [string]$Arch, [string]$OS)
    
    Write-Host "Downloading Go $Version for $OS-$Arch..." -ForegroundColor Yellow
    
    $goUrl = "https://go.dev/dl/go$Version.$OS-$Arch.msi"
    $goInstaller = "go$Version.$OS-$Arch.msi"
    
    try {
        # Download Go installer
        Invoke-WebRequest -Uri $goUrl -OutFile $goInstaller
        
        Write-Host "Installing Go..." -ForegroundColor Yellow
        Start-Process msiexec.exe -Wait -ArgumentList "/i $goInstaller /quiet"
        
        # Add Go to PATH for current session
        $env:PATH = "C:\Program Files\Go\bin;$env:PATH"
        
        Write-Host "Go installation completed" -ForegroundColor Green
        
        # Clean up installer
        Remove-Item $goInstaller -Force
    }
    catch {
        Write-Host "Failed to install Go: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Function to build pgmetrics
function Build-PgMetrics {
    Write-Host "Building pgmetrics..." -ForegroundColor Yellow
    
    # Set build environment variables
    $env:CGO_ENABLED = "0"
    $env:GOOS = "windows"
    $env:GOARCH = "amd64"
    
    # Build the project
    try {
        go build -a -trimpath -ldflags "-s -w -X main.version=1.0.0" -o pgmetrics.exe ./cmd/pgmetrics
        Write-Host "Build completed successfully!" -ForegroundColor Green
        Write-Host "Binary created: pgmetrics.exe" -ForegroundColor Green
    }
    catch {
        Write-Host "Build failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Function to create tar.gz archive
function Create-Archive {
    Write-Host "Creating archive..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $archiveName = "pgmetrics_windows_amd64_$timestamp.tar.gz"
    
    try {
        # Create a temporary directory for the archive contents
        $tempDir = "temp_archive"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        # Copy files to temp directory
        Copy-Item "pgmetrics.exe" $tempDir\
        Copy-Item "README.md" $tempDir\
        Copy-Item "LICENSE" $tempDir\
        
        # Create tar.gz using PowerShell (requires tar command)
        if (Get-Command tar -ErrorAction SilentlyContinue) {
            tar -czf $archiveName -C $tempDir .
            Write-Host "Archive created: $archiveName" -ForegroundColor Green
        } else {
            # Fallback: create zip file
            $zipName = "pgmetrics_windows_amd64_$timestamp.zip"
            Compress-Archive -Path "$tempDir\*" -DestinationPath $zipName
            Write-Host "Zip archive created: $zipName" -ForegroundColor Green
        }
        
        # Clean up temp directory
        Remove-Item $tempDir -Recurse -Force
    }
    catch {
        Write-Host "Failed to create archive: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
Write-Host "Checking Go installation..." -ForegroundColor Yellow

if (-not (Test-GoAvailable)) {
    Write-Host "Go not found. Installing Go $GoVersion..." -ForegroundColor Yellow
    Install-Go -Version $GoVersion -Arch $Architecture -OS $OS
    
    # Verify installation
    if (-not (Test-GoAvailable)) {
        Write-Host "Go installation verification failed" -ForegroundColor Red
        exit 1
    }
}

# Navigate to the pgmetrics directory
if (Test-Path "pgmetrics") {
    Set-Location "pgmetrics"
}

# Download dependencies
Write-Host "Downloading dependencies..." -ForegroundColor Yellow
go mod download

# Build the project
Build-PgMetrics

# Create archive
Create-Archive

Write-Host "Build process completed!" -ForegroundColor Green 