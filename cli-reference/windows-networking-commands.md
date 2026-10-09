# Windows networking commands: quick reference

The built-in commands for inspecting and fixing a Windows network connection, grouped by the question they answer. None needs extra software. Commands marked 🛡️ need an administrator prompt.

Addresses and names below are placeholders: `192.168.1.1` is a typical home router, `192.0.2.10`, `198.51.100.0/24` and `203.0.113.0/24` are ranges reserved for documentation (RFC 5737), `00-00-5E-00-53-01` is a MAC address from the block reserved for documentation (RFC 7042), and `example.com` stands for any host name.

## What is my configuration?

| Command | Shows |
|---|---|
| `ipconfig` | IPv4/IPv6 address, subnet mask and default gateway per adapter |
| `ipconfig /all` | Also MAC address, DHCP server and lease times, DNS servers, adapter description |
| `netsh interface ipv4 show config` | Per interface: DHCP or static, gateway, DNS source |
| `netsh wlan show interfaces` | Wi-Fi: connected network, signal %, band/channel, link rate |
| `getmac /v` | MAC address of each adapter |
| `route print -4` | IPv4 routing table. The `0.0.0.0` route is the default gateway |
| PowerShell: `Get-NetIPConfiguration` | Compact summary: interface, IPv4, gateway, DNS servers |

## Can I reach it?

| Command | Use |
|---|---|
| `ping 192.168.1.1` | Is the router up? Look for `TTL=` in the replies |
| `ping -n 20 1.1.1.1` | 20 pings. Look at loss % and time spread (jitter) |
| `ping -t 1.1.1.1` | Ping until Ctrl+C. Good for catching intermittent drops |
| `ping -a 192.0.2.10` | Also look up the name for the address (reverse DNS). The name appears in the first line, `Pinging <name> [192.0.2.10]` |
| `ping -4 example.com` / `ping -6 example.com` | Force IPv4 or IPv6. Tells a problem on one protocol apart from the other, e.g. a site that fails only over IPv6 |
| `ping -f -l 1472 1.1.1.1` | Don't fragment, 1472-byte payload. Fails if the path MTU is below 1500 |
| `tracert -d 1.1.1.1` | Hops to the destination (`-d` skips slow name lookups) |
| `pathping -n 1.1.1.1` | Traceroute plus loss per hop, measured over ~5 minutes |
| PowerShell: `Test-NetConnection example.com -Port 443` | Can a TCP connection open? Works where ping is blocked |
| PowerShell: `Test-NetConnection example.com -TraceRoute` | Traceroute from PowerShell |

## Does the name resolve?

| Command | Use |
|---|---|
| `nslookup example.com` | Resolve using the configured DNS server. The server used is shown first |
| `nslookup example.com 1.1.1.1` | Resolve using a specific server, to compare against the local one |
| `nslookup -type=mx example.com` | Other record types: `mx`, `txt`, `aaaa`, `ns` |
| `ipconfig /displaydns` | What the local DNS cache holds |
| `ipconfig /flushdns` | Clear the local DNS cache |
| PowerShell: `Resolve-DnsName example.com -Server 1.1.1.1` | Same as `nslookup`, with objects instead of text |
| `nslookup 192.0.2.10` | Reverse lookup: which name does this address belong to (PTR record)? |

**Interactive mode**, for several lookups in a row against the same server. Run `nslookup` with no arguments. It prints the default server, then waits at a `>` prompt:

| At the `>` prompt | Does |
|---|---|
| `example.com` | Look up a name with the current settings |
| `server 1.1.1.1` | Switch the server for the rest of the session, e.g. to compare with the default one |
| `set type=a` / `set type=aaaa` / `set type=mx` | Choose the record type for the following lookups |
| `set type=ptr` then `192.0.2.10` | Reverse lookup of an address |
| `set debug` | Show the full query and response, including TTLs |
| `exit` | Leave interactive mode |

## Who is on the network, and what is listening?

| Command | Use |
|---|---|
| `arp -a` | IP ↔ MAC pairs this PC has recently talked to on the LAN |
| `arp -d 192.168.1.23` 🛡️ | Delete one entry, e.g. a stale one left after a device was replaced. It's re-learned on the next contact |
| `arp -d *` 🛡️ | Clear the whole ARP cache |
| `arp -s 192.168.1.23 00-00-5E-00-53-01` 🛡️ | Add a static entry: it doesn't age out like learned ones (`arp -a` shows its type as `static`). Rarely needed. For an entry explicitly stored across restarts, use `netsh interface ipv4 add neighbors "Wi-Fi" 192.168.1.23 00-00-5E-00-53-01`, which defaults to `store=persistent` |
| PowerShell: `Get-NetNeighbor -State Reachable,Stale` | The same table as `arp -a`, with each entry's state |
| `netstat -an` | All connections and listening ports, numeric |
| `netstat -ano` | Adds the process ID (PID) of each connection |
| `netstat -b` 🛡️ | Adds the program name of each connection |
| `tasklist /fi "PID eq 1234"` | Which program owns PID 1234 |

## Fixing things

| Command | Effect |
|---|---|
| `ipconfig /release` then `ipconfig /renew` 🛡️ | Ask DHCP for a new lease. The connection drops briefly |
| `ipconfig /flushdns` | Forget cached lookups (stale or wrong answers). Works without admin rights |
| `netsh winsock reset` 🛡️ | Reset the Winsock catalog (broken network layer, e.g. after removing a VPN or security product). Restart needed |
| `netsh int ip reset` 🛡️ | Rewrite TCP/IP settings to defaults. **Static IPs are lost.** Restart needed |
| `netsh advfirewall show allprofiles state` | Firewall on/off per profile (Domain, Private, Public) |
| `netsh winhttp show proxy` | System-wide proxy (used by services and some tools) |

## Changing routes

The routing table decides which gateway each packet leaves through. Changing it is rarely needed on a home network. The typical case is a second network behind another router on your LAN, e.g. a lab or test segment at `203.0.113.0/24` reached through `192.168.1.254`.

| Command | Effect |
|---|---|
| `route print -4` | Current table. The *Interface List* at the top gives each adapter's index number. *Persistent Routes* at the bottom lists routes that survive a restart |
| `route add 203.0.113.0 mask 255.255.255.0 192.168.1.254 metric 5` 🛡️ | Send traffic for `203.0.113.0/24` through `192.168.1.254`. Lasts until the next restart |
| `route -p add 203.0.113.0 mask 255.255.255.0 192.168.1.254` 🛡️ | The same, but **persistent**: stored and re-applied at every start |
| `route add 203.0.113.0 mask 255.255.255.0 192.168.1.254 if 12` 🛡️ | Pin the route to interface 12 (index from `route print`), when several adapters could carry it |
| `route change 203.0.113.0 mask 255.255.255.0 192.168.1.253` 🛡️ | Change the gateway or metric of an existing route |
| `route delete 203.0.113.0` 🛡️ | Remove the route (persistent ones too) |
| PowerShell: `New-NetRoute -DestinationPrefix 203.0.113.0/24 -NextHop 192.168.1.254 -InterfaceAlias "Wi-Fi"` 🛡️ | The same as `route -p add`. Persistent by default |

- The gateway must be reachable directly on one of the PC's own networks. Here, `192.168.1.254` has to be on the same LAN as the PC.
- A **lower metric wins** when two routes match the same destination equally well.
- Persistent routes are easy to forget, and a stale one can break connectivity months later. When a single destination misbehaves, check the *Persistent Routes* section first.

## Reading the results

| You see | It usually means |
|---|---|
| Address `169.254.x.x` | Self-assigned (APIPA): no DHCP server answered |
| `Request timed out` | No reply at all: host down, or ping blocked |
| `Destination host unreachable` from another IP | A router along the way has no route. `ping`'s exit code may still be 0 |
| `General failure` | The local stack or adapter can't send at all |
| `tracert` shows `* * *` for a hop but later hops answer | That router just doesn't answer traceroute. Not a problem |
| `nslookup` shows `Non-existent domain` | The DNS server answered "no such name". Compare against another server |
| `DNS request timed out` | The DNS server didn't answer at all |
| `ping -a` shows only the address, no name | No reverse DNS (PTR) record exists for it. Common, and harmless on its own |
| An entry in `route print`'s *Persistent Routes* that you don't recognise | Added manually or by software at some point. A frequent cause of "only this one network doesn't work" |

## Private and reserved address ranges

| Range | Meaning |
|---|---|
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | Private LAN addresses (RFC 1918), not routed on the internet |
| `169.254.0.0/16` | Link-local (APIPA): assigned by the PC itself when DHCP fails |
| `127.0.0.0/8` | Loopback: the PC itself |
| `100.64.0.0/10` | Carrier-grade NAT: the provider shares one public IP between subscribers |
| `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24` | Reserved for documentation and examples (RFC 5737) |
