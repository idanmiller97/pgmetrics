# pgmetrics Executable Locations Guide

This guide shows exactly where the pgmetrics executables will be created after running the build scripts.

## Current Project Directory

Your project is located at:
```
C:\Program Files (x86)\Visual Studio Code\Visual Studio Code\pgmetrics\pgmetrics\
```

## After Running build-linux.ps1

When you successfully run `.\build-linux.ps1`, the following files will be created:

### 1. Linux Executable
**Location:** `C:\Program Files (x86)\Visual Studio Code\Visual Studio Code\pgmetrics\pgmetrics\pgmetrics`
- **File name:** `pgmetrics` (no extension)
- **Type:** Linux ELF binary
- **Size:** ~10-15 MB
- **Usage:** Copy this file to your Linux system

### 2. Archive File
**Location:** `C:\Program Files (x86)\Visual Studio Code\Visual Studio Code\pgmetrics\pgmetrics\`
- **File name:** `pgmetrics_linux_amd64_YYYYMMDD_HHMMSS.tar.gz`
- **Type:** Compressed archive containing:
  - `pgmetrics` (Linux executable)
  - `README.md`
  - `LICENSE`

## After Running build.ps1 (Windows)

When you run `.\build.ps1`, the following files will be created:

### 1. Windows Executable
**Location:** `C:\Program Files (x86)\Visual Studio Code\Visual Studio Code\pgmetrics\pgmetrics\pgmetrics.exe`
- **File name:** `pgmetrics.exe`
- **Type:** Windows executable
- **Usage:** Run on Windows systems only

### 2. Archive File
**Location:** `C:\Program Files (x86)\Visual Studio Code\Visual Studio Code\pgmetrics\pgmetrics\`
- **File name:** `pgmetrics_windows_amd64_YYYYMMDD_HHMMSS.zip`
- **Type:** ZIP archive containing:
  - `pgmetrics.exe` (Windows executable)
  - `README.md`
  - `LICENSE`

## How to Find Your Executables

### Using File Explorer
1. Navigate to: `C:\Program Files (x86)\Visual Studio Code\Visual Studio Code\pgmetrics\pgmetrics\`
2. Look for files named:
   - `pgmetrics` (Linux binary - no extension)
   - `pgmetrics.exe` (Windows binary)
   - `pgmetrics_linux_amd64_*.tar.gz` (Linux archive)
   - `pgmetrics_windows_amd64_*.zip` (Windows archive)

### Using PowerShell
```powershell
# List all pgmetrics files
Get-ChildItem -Name "*pgmetrics*"

# List executables
Get-ChildItem -Name "pgmetrics*" | Where-Object { $_.Name -notlike "*.ps1" -and $_.Name -notlike "*.md" -and $_.Name -notlike "*.bat" }

# Show file details
Get-ChildItem -Name "pgmetrics" | Format-List Name, Length, LastWriteTime
```

## File Verification

### Linux Binary Verification
```powershell
# Check if it's a Linux binary (will show "ELF" if correct)
Get-Content "pgmetrics" -Encoding Byte -TotalCount 4 | ForEach-Object { [char][int]$_ }
# Should show "ELF" at the beginning

# Check file size (should be ~10-15 MB)
(Get-Item "pgmetrics").Length / 1MB
```

### Windows Binary Verification
```powershell
# Check if it's a Windows executable
Get-Content "pgmetrics.exe" -Encoding Byte -TotalCount 2 | ForEach-Object { [char][int]$_ }
# Should show "MZ" at the beginning

# Check file size (should be ~10-15 MB)
(Get-Item "pgmetrics.exe").Length / 1MB
```

## Deployment Instructions

### For Linux Systems
1. **Copy the Linux binary:**
   ```bash
   scp "C:\Program Files (x86)\Visual Studio Code\Visual Studio Code\pgmetrics\pgmetrics\pgmetrics" user@your-linux-server:/usr/local/bin/
   ```

2. **Make it executable:**
   ```bash
   chmod +x /usr/local/bin/pgmetrics
   ```

3. **Test it:**
   ```bash
   /usr/local/bin/pgmetrics --help
   ```

### For Windows Systems
1. **Copy the Windows executable:**
   ```cmd
   copy "C:\Program Files (x86)\Visual Studio Code\Visual Studio Code\pgmetrics\pgmetrics\pgmetrics.exe" C:\Windows\System32\
   ```

2. **Test it:**
   ```cmd
   pgmetrics.exe --help
   ```

## Troubleshooting

### "File not found" errors
- Ensure you're in the correct directory
- Check that the build completed successfully
- Verify the file exists: `Test-Path "pgmetrics"`

### "Permission denied" on Linux
- Make the file executable: `chmod +x pgmetrics`
- Check file permissions: `ls -la pgmetrics`

### "Exec format error" on Linux
- Ensure you're using the Linux binary (`pgmetrics`), not the Windows binary (`pgmetrics.exe`)
- Verify it's compiled for the correct architecture

## Quick Commands

```powershell
# Build for Linux
.\build-linux.ps1

# Build for Windows
.\build.ps1

# List all build artifacts
Get-ChildItem -Name "*pgmetrics*" | Sort-Object LastWriteTime -Descending

# Show the most recent executable
Get-ChildItem -Name "pgmetrics*" | Where-Object { $_.Name -notlike "*.ps1" -and $_.Name -notlike "*.md" -and $_.Name -notlike "*.bat" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
``` 