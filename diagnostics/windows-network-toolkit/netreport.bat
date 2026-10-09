@ECHO OFF
REM ---------------------------------------------------------------------------
REM netreport.bat - collect a full network diagnostic snapshot into one file.
REM
REM Usage:  netreport.bat [HOST]          (default HOST: www.msftconnecttest.com)
REM
REM Runs the standard Windows diagnostic commands in a fixed order and saves
REM their output to reports\netreport_<timestamp>.txt. Take one snapshot when
REM things work and one when they don't, then compare the two.
REM
REM Read-only, no admin rights needed. The trace step takes up to a minute.
REM
REM PRIVACY: the report contains this PC's name, MAC addresses, local IPs and
REM Wi-Fi network name. It's for your own use. Don't post it publicly as-is.
REM reports\ is git-ignored for that reason.
REM ---------------------------------------------------------------------------
SETLOCAL EnableExtensions
SET "TARGET=%~1"
IF "%TARGET%"=="" SET "TARGET=www.msftconnecttest.com"
SET "PUBLIC_IP=1.1.1.1"

SET "REPORT_DIR=%~dp0reports"
IF NOT EXIST "%REPORT_DIR%" MKDIR "%REPORT_DIR%"
FOR /F %%T IN ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') DO SET "STAMP=%%T"
SET "REPORT=%REPORT_DIR%\netreport_%STAMP%.txt"

>"%REPORT%" ECHO Network report %STAMP%, target %TARGET%
ECHO Writing %REPORT%

CALL :section "Adapters and addresses"        ipconfig /all
CALL :section "IPv4 routing table"            route print -4
CALL :section "Per-interface IPv4 settings"   netsh interface ipv4 show config
CALL :section "Wi-Fi link (signal, band)"     netsh wlan show interfaces
CALL :section "ARP cache (LAN neighbours)"    arp -a
CALL :section "System proxy"                  netsh winhttp show proxy
CALL :section "Firewall profiles"             netsh advfirewall show allprofiles state
CALL :section "DNS lookup of %TARGET%"        nslookup %TARGET%
CALL :section "Ping %PUBLIC_IP%"              ping -n 4 %PUBLIC_IP%
CALL :section "Route to %PUBLIC_IP%"          tracert -d -h 15 -w 1000 %PUBLIC_IP%
CALL :section "Listening TCP ports"           netstat -an -p tcp

ECHO Done. For per-hop packet loss, also run:  pathping -n %PUBLIC_IP%  (about 5 minutes)
EXIT /B 0

REM :section "TITLE" COMMAND [ARGS...] - append a header, then the command's output
:section
ECHO   %~1
>>"%REPORT%" ECHO.
>>"%REPORT%" ECHO ==== %~1 ====
>>"%REPORT%" ECHO ^> %2 %3 %4 %5 %6 %7 %8 %9
%2 %3 %4 %5 %6 %7 %8 %9 >>"%REPORT%" 2>&1
EXIT /B 0
