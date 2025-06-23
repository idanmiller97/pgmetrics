# pgmetrics Build Instructions

This document provides instructions for building the pgmetrics project on Windows.

## Prerequisites

1. **Go Programming Language** (version 1.24.1 or later)
   - Download from: https://go.dev/dl/
   - Install the Windows MSI package (e.g., `go1.24.1.windows-amd64.msi`)
   - Restart your terminal/PowerShell after installation

## Build Options

### Option 1: Automatic Build (Recommended)
Run the batch file that handles Go installation and building:
```cmd
.\build.bat
```

### Option 2: Manual Build
If Go is already installed, use the manual build script:
```powershell
.\build-manual.ps1
```

### Option 3: Simple Build
For a quick build without Go installation:
```powershell
.\build-simple.ps1
```

## Manual Build Steps

If you prefer to build manually:

1. **Install Go** (if not already installed)
   - Download from https://go.dev/dl/
   - Run the installer
   - Restart your terminal

2. **Verify Go installation**
   ```cmd
   go version
   ```

3. **Download dependencies**
   ```cmd
   go mod download
   ```

4. **Build the project**
   ```cmd
   set CGO_ENABLED=0
   set GOOS=windows
   set GOARCH=amd64
   go build -a -trimpath -ldflags "-s -w -X main.version=1.0.0" -o pgmetrics.exe ./cmd/pgmetrics
   ```

5. **Create archive** (optional)
   ```powershell
   $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
   $archiveName = "pgmetrics_windows_amd64_$timestamp"
   mkdir temp_archive
   copy pgmetrics.exe temp_archive\
   copy README.md temp_archive\
   copy LICENSE temp_archive\
   Compress-Archive -Path "temp_archive\*" -DestinationPath "$archiveName.zip" -Force
   rmdir /s temp_archive
   ```

## Output Files

After a successful build, you should have:
- `pgmetrics.exe` - The main executable
- `pgmetrics_windows_amd64_YYYYMMDD_HHMMSS.zip` - Archive containing the executable and documentation

## Troubleshooting

### Go not found
- Ensure Go is installed and in your PATH
- Restart your terminal after installation
- Try running `go version` to verify installation

### Build errors
- Check that you're in the correct directory (pgmetrics subdirectory)
- Ensure all dependencies are downloaded: `go mod download`
- Verify Go version compatibility

### PowerShell console issues
- Try using the batch file instead: `.\build.bat`
- Or use Command Prompt instead of PowerShell

## Project Structure

```
pgmetrics/
├── cmd/pgmetrics/     # Main application code
├── collector/         # Data collection logic
├── model.go          # Data models
├── go.mod            # Go module definition
├── go.sum            # Dependency checksums
├── build.ps1         # Full build script (with Go installation)
├── build-simple.ps1  # Simple build script
├── build-manual.ps1  # Manual build script
├── build.bat         # Batch build script
└── BUILD_INSTRUCTIONS.md  # This file
``` 