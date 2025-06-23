@echo off
echo pgmetrics Build Script for Windows
echo ================================

REM Check if Go is available
go version >nul 2>&1
if %errorlevel% equ 0 (
    echo Go found: 
    go version
    goto :build
) else (
    echo Go not found. Installing Go 1.24.1...
    goto :install_go
)

:install_go
echo Downloading Go 1.24.1 for Windows...
powershell -Command "Invoke-WebRequest -Uri 'https://go.dev/dl/go1.24.1.windows-amd64.msi' -OutFile 'go1.24.1.windows-amd64.msi'"

if not exist "go1.24.1.windows-amd64.msi" (
    echo Failed to download Go installer
    exit /b 1
)

echo Installing Go...
msiexec /i go1.24.1.windows-amd64.msi /quiet

echo Waiting for installation to complete...
timeout /t 10 /nobreak >nul

echo Adding Go to PATH...
set "PATH=C:\Program Files\Go\bin;%PATH%"

echo Verifying Go installation...
"C:\Program Files\Go\bin\go.exe" version >nul 2>&1
if %errorlevel% equ 0 (
    echo Go installation successful
    del go1.24.1.windows-amd64.msi
    goto :build
) else (
    echo Go installation failed
    del go1.24.1.windows-amd64.msi
    exit /b 1
)

:build
echo Building pgmetrics...

REM Set build environment variables
set CGO_ENABLED=0
set GOOS=windows
set GOARCH=amd64

REM Download dependencies
echo Downloading dependencies...
"C:\Program Files\Go\bin\go.exe" mod download

REM Build the project
"C:\Program Files\Go\bin\go.exe" build -a -trimpath -ldflags "-s -w -X main.version=1.0.0" -o pgmetrics.exe ./cmd/pgmetrics

if %errorlevel% equ 0 (
    echo Build completed successfully!
    echo Binary created: pgmetrics.exe
    goto :create_archive
) else (
    echo Build failed
    exit /b 1
)

:create_archive
echo Creating archive...

REM Create timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,8%_%dt:~8,6%"

REM Create temporary directory
if exist temp_archive rmdir /s /q temp_archive
mkdir temp_archive

REM Copy files to temp directory
copy pgmetrics.exe temp_archive\
copy README.md temp_archive\
copy LICENSE temp_archive\

REM Create zip file
set "zipname=pgmetrics_windows_amd64_%timestamp%.zip"
powershell -Command "Compress-Archive -Path 'temp_archive\*' -DestinationPath '%zipname%' -Force"

REM Clean up temp directory
rmdir /s /q temp_archive

echo Archive created: %zipname%
echo Build process completed!
echo Files created:
echo   - pgmetrics.exe (executable)
echo   - %zipname% (archive)

pause 