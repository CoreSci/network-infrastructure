@ECHO OFF
REM ---------------------------------------------------------------------------
REM netcheck.bat - layer-by-layer connectivity check for a Windows PC.
REM
REM Usage:  netcheck.bat [HOST]          (default HOST: www.msftconnecttest.com)
REM
REM Tests from the bottom up and stops at the first layer that fails, so the
REM verdict points at where the problem is, not just "no internet":
REM
REM   1. IP configuration   default route, gateway, local address (APIPA?)
REM   2. TCP/IP stack        ping the loopback address
REM   3. Local network       ping the default gateway
REM   4. Internet by IP      ping a public IP; if ICMP is blocked, try TCP 443
REM   5. DNS                 resolve HOST, then retry with a public resolver
REM   6. Service             open a TCP connection to HOST on port 443
REM
REM The default HOST is the one Windows itself probes to decide whether it is
REM online (behind the "No internet" icon), so it is a fair test on any network.
REM
REM Read-only: it changes no settings. No admin rights needed.
REM Exit code: 0 = all layers OK, otherwise the number of the failed layer.
REM
REM Works on any display language: it parses the numeric route table and the
REM "TTL=" in ping replies, never the translated labels of ipconfig.
REM ---------------------------------------------------------------------------
SETLOCAL EnableExtensions
SET "TARGET=%~1"
IF "%TARGET%"=="" SET "TARGET=www.msftconnecttest.com"
SET "PUBLIC_IP=1.1.1.1"
SET "PUBLIC_DNS=1.1.1.1"

ECHO Network check - target %TARGET%
ECHO.

REM --- 1. IP configuration: first IPv4 default route in the routing table ---
SET "GW="
SET "MYIP="
FOR /F "tokens=1-4" %%A IN ('route print -4 0.0.0.0') DO (
    IF "%%A"=="0.0.0.0" IF "%%B"=="0.0.0.0" IF NOT DEFINED GW (
        SET "GW=%%C"
        SET "MYIP=%%D"
    )
)
IF NOT DEFINED GW (
    CALL :result FAIL 1 "No default gateway. The PC is not connected, or got no DHCP lease."
    ECHO        Next: check the cable or Wi-Fi, then run "ipconfig /all".
    EXIT /B 1
)
IF "%MYIP:~0,8%"=="169.254." (
    CALL :result FAIL 1 "Address %MYIP% is self-assigned (APIPA): no DHCP server answered."
    ECHO        Next: restart the router, or run network-reset.bat option 2 to renew the lease.
    EXIT /B 1
)
CALL :result OK 1 "Local address %MYIP%, default gateway %GW%"

REM --- 2. TCP/IP stack ------------------------------------------------------
CALL :ping 127.0.0.1
IF ERRORLEVEL 1 (
    CALL :result FAIL 2 "Loopback 127.0.0.1 does not answer: the TCP/IP stack is damaged."
    ECHO        Next: run network-reset.bat option 3, then restart.
    EXIT /B 2
)
CALL :result OK 2 "TCP/IP stack answers on 127.0.0.1"

REM --- 3. Local network: gateway (some routers ignore ping, so only a warning)
CALL :ping %GW%
IF ERRORLEVEL 1 (
    CALL :result WARN 3 "Gateway %GW% does not answer ping. Some routers block it; continuing."
) ELSE (
    CALL :result OK 3 "Gateway %GW% answers"
)

REM --- 4. Internet by IP (no DNS involved) ------------------------------------
CALL :ping %PUBLIC_IP%
IF NOT ERRORLEVEL 1 (
    CALL :result OK 4 "Internet reachable by IP (ping %PUBLIC_IP%)"
    GOTO dns
)
CALL :tcp %PUBLIC_IP% 443
IF ERRORLEVEL 1 (
    CALL :result FAIL 4 "No route to the internet: %PUBLIC_IP% fails by ping and by TCP 443."
    ECHO        Next: the problem is between the router and the provider. Check the router's WAN status.
    EXIT /B 4
)
CALL :result OK 4 "Internet reachable by IP (TCP 443 to %PUBLIC_IP%; ping is blocked)"

REM --- 5. DNS ----------------------------------------------------------------
:dns
CALL :resolve %TARGET%
IF NOT ERRORLEVEL 1 (
    CALL :result OK 5 "DNS resolves %TARGET%"
    GOTO service
)
CALL :resolve %TARGET% %PUBLIC_DNS%
IF ERRORLEVEL 1 (
    CALL :result FAIL 5 "%TARGET% does not resolve, even through %PUBLIC_DNS%."
    ECHO        Next: check the spelling. If it is right, DNS traffic may be blocked on this network.
) ELSE (
    CALL :result FAIL 5 "The configured DNS server fails, but %PUBLIC_DNS% resolves %TARGET%."
    ECHO        Next: run "ipconfig /flushdns", restart the router, or set a different DNS server.
)
EXIT /B 5

REM --- 6. Service: TCP 443 on the target ----------------------------------------
:service
CALL :tcp %TARGET% 443
IF ERRORLEVEL 1 (
    CALL :result FAIL 6 "%TARGET% resolves but does not accept connections on port 443."
    ECHO        Next: the site may be down, or a firewall or proxy blocks it. Try another site to compare.
    EXIT /B 6
)
CALL :result OK 6 "%TARGET% accepts connections on port 443"
ECHO.
ECHO All layers OK.
EXIT /B 0

REM === helpers ===================================================================

REM :ping HOST -> errorlevel 0 if at least one echo reply came back.
REM ping's own exit code is unreliable ("Destination host unreachable" replies
REM can still return 0), so look for "TTL=", which only real replies contain.
REM findstr, not find: a Unix find earlier in PATH (e.g. from Git) would shadow it.
:ping
ping -n 2 -w 1500 %1 | findstr /C:"TTL=" >NUL
EXIT /B %ERRORLEVEL%

REM :tcp HOST PORT -> errorlevel 0 if a TCP connection opens.
:tcp
powershell -NoProfile -Command "if (Test-NetConnection -ComputerName '%1' -Port %2 -InformationLevel Quiet -WarningAction SilentlyContinue) { exit 0 } else { exit 1 }"
EXIT /B %ERRORLEVEL%

REM :resolve NAME [SERVER] -> errorlevel 0 if NAME resolves (optionally via SERVER).
:resolve
SET "DNS_SERVER="
IF NOT "%~2"=="" SET "DNS_SERVER=-Server %2"
powershell -NoProfile -Command "try { Resolve-DnsName -Name '%1' %DNS_SERVER% -DnsOnly -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }"
EXIT /B %ERRORLEVEL%

REM :result LEVEL LAYER "MESSAGE"
:result
ECHO [%1] %2. %~3
EXIT /B 0
