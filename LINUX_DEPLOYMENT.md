# pgmetrics Linux Deployment Guide

This guide explains how to resolve the "Exec format error" when running pgmetrics on Linux systems.

## Problem

You're getting this error when trying to run pgmetrics on Linux:
```
OSError: [Errno 8] Exec format error: 'pgmetrics'
```

This happens because you compiled pgmetrics on Windows, but Windows executables (.exe) cannot run on Linux systems.

## Solutions

### Solution 1: Cross-compile for Linux (Recommended)

If you have Go installed on Windows, you can cross-compile for Linux:

1. **Install Go on Windows** (if not already installed):
   - Download from https://go.dev/dl/
   - Install the Windows MSI package
   - Restart your terminal

2. **Cross-compile for Linux**:
   ```powershell
   # Set environment variables for Linux build
   $env:CGO_ENABLED = "0"
   $env:GOOS = "linux"
   $env:GOARCH = "amd64"
   
   # Build for Linux
   go build -a -trimpath -ldflags "-s -w -X main.version=1.0.0" -o pgmetrics ./cmd/pgmetrics
   ```

3. **Create tar.gz archive**:
   ```powershell
   # Create archive
   $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
   $archiveName = "pgmetrics_linux_amd64_$timestamp"
   
   # Create temp directory
   mkdir temp_archive
   copy pgmetrics temp_archive\
   copy README.md temp_archive\
   copy LICENSE temp_archive\
   
   # Create tar.gz (if tar is available)
   tar -czf "$archiveName.tar.gz" -C temp_archive .
   
   # Clean up
   rmdir /s temp_archive
   ```

### Solution 2: Build on Linux (Best Practice)

Build pgmetrics directly on the Linux target system:

1. **Install Go on Linux**:
   ```bash
   # Download Go
   wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
   
   # Install to /usr/local
   sudo tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
   
   # Add to PATH
   echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
   source ~/.bashrc
   
   # Verify installation
   go version
   ```

2. **Clone and build pgmetrics**:
   ```bash
   # Clone the repository
   git clone https://github.com/rapidloop/pgmetrics.git
   cd pgmetrics
   
   # Download dependencies
   go mod download
   
   # Build
   go build -a -trimpath -ldflags "-s -w -X main.version=1.0.0" -o pgmetrics ./cmd/pgmetrics
   
   # Make executable
   chmod +x pgmetrics
   
   # Test
   ./pgmetrics --help
   ```

3. **Create tar.gz archive**:
   ```bash
   # Create archive
   timestamp=$(date +%Y%m%d_%H%M%S)
   archive_name="pgmetrics_linux_amd64_${timestamp}"
   
   # Create temp directory
   mkdir temp_archive
   cp pgmetrics temp_archive/
   cp README.md temp_archive/
   cp LICENSE temp_archive/
   
   # Create tar.gz
   tar -czf "${archive_name}.tar.gz" -C temp_archive .
   
   # Clean up
   rm -rf temp_archive
   ```

### Solution 3: Use Docker (Alternative)

If you prefer using Docker:

1. **Create a Dockerfile**:
   ```dockerfile
   FROM golang:1.24-alpine AS builder
   WORKDIR /app
   COPY . .
   RUN go mod download
   RUN CGO_ENABLED=0 GOOS=linux go build -a -trimpath -ldflags "-s -w -X main.version=1.0.0" -o pgmetrics ./cmd/pgmetrics
   
   FROM alpine:latest
   RUN apk --no-cache add ca-certificates
   WORKDIR /root/
   COPY --from=builder /app/pgmetrics .
   RUN chmod +x pgmetrics
   CMD ["./pgmetrics"]
   ```

2. **Build and run**:
   ```bash
   docker build -t pgmetrics .
   docker run --rm pgmetrics --help
   ```

## Deployment Steps

After building the Linux binary:

1. **Copy to Linux system**:
   ```bash
   scp pgmetrics user@your-linux-server:/usr/local/bin/
   ```

2. **Make executable**:
   ```bash
   chmod +x /usr/local/bin/pgmetrics
   ```

3. **Test the installation**:
   ```bash
   pgmetrics --help
   ```

4. **Update your Zabbix script**:
   ```python
   # In your pgmetrics.py script, ensure the path is correct
   cmd = ['/usr/local/bin/pgmetrics', '--format', 'json', '--host', host]
   ```

## Verification

To verify the binary is correct for Linux:

```bash
# Check file type
file pgmetrics

# Should show: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=..., not stripped

# Check if it's executable
ls -la pgmetrics

# Should show: -rwxr-xr-x (executable permissions)
```

## Troubleshooting

### Still getting "Exec format error"
- Ensure you're using the Linux binary, not the Windows .exe
- Check that the binary was compiled for the correct architecture (amd64)
- Verify the binary is executable: `chmod +x pgmetrics`

### Permission denied
- Make the binary executable: `chmod +x pgmetrics`
- Check file permissions: `ls -la pgmetrics`

### Library dependencies
- The cross-compiled version should be statically linked (no external dependencies)
- If using CGO, ensure all required libraries are available on the target system

## File Structure

After successful deployment:
```
/usr/local/bin/pgmetrics          # Linux executable
/usr/lib/zabbix/scripts/pgmetrics.py  # Your Zabbix script
```

The Linux binary should work correctly with your Zabbix monitoring setup. 