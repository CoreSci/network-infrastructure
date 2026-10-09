@ECHO OFF
REM ---------------------------------------------------------------------------
REM network-reset.bat - common Windows network fixes, least to most disruptive.
REM
REM Usage:  right-click > Run as administrator, then pick an option.
REM
REM   1. Flush the DNS cache        harmless; fixes stale or poisoned lookups
REM   2. Renew the DHCP lease       drops the connection for a few seconds
REM   3. Reset Winsock and TCP/IP   needs a restart; resets adapters to DHCP
REM
REM Run netcheck.bat first: it tells you which of these, if any, applies.
REM Option 3 discards static IP settings. Note them down first
REM ("ipconfig /all" or netreport.bat).
REM ---------------------------------------------------------------------------
SETLOCAL EnableExtensions

NET SESSION >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO This script needs administrator rights.
    ECHO Right-click it and choose "Run as administrator".
    EXIT /B 1
)

ECHO 1. Flush the DNS cache
ECHO 2. Renew the DHCP lease        - connection drops briefly
ECHO 3. Reset Winsock and TCP/IP    - restart needed, static IPs are lost
ECHO 4. Cancel
CHOICE /C 1234 /N /M "Choose 1-4: "
IF ERRORLEVEL 4 EXIT /B 0
IF ERRORLEVEL 3 GOTO full_reset
IF ERRORLEVEL 2 GOTO renew

:flush
ipconfig /flushdns
EXIT /B %ERRORLEVEL%

:renew
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ECHO Lease renewed. Run netcheck.bat to confirm.
EXIT /B 0

:full_reset
CHOICE /C YN /M "This resets all network settings and needs a restart. Continue"
IF ERRORLEVEL 2 EXIT /B 0
netsh winsock reset
netsh int ip reset
ipconfig /flushdns
ECHO Done. Restart Windows to finish, then run netcheck.bat.
EXIT /B 0
