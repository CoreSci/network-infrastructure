# Networking fundamentals: layers, ports and MAC addresses

The minimum theory behind the tools in this repo: how a connection is built up in layers, which port numbers matter, and what a MAC address is. Each section ends with how it maps onto [`netcheck.bat`](../diagnostics/windows-network-toolkit/)'s six layers.

## Layers: why troubleshooting goes bottom up

Every network connection is a stack of jobs, each relying on the one below. A web page needs a working TCP connection, which needs a route to the server, which needs a local address, which needs a physical link. When something fails, every layer above it fails too, and the error message usually comes from the top ("site can't be reached"), far from the real cause.

Two models describe the stack. The **OSI model** splits it into seven layers and is the common vocabulary ("a layer-2 problem"). The **TCP/IP model** has four and matches how the internet's protocols are actually built. They describe the same thing at different levels of detail:

| OSI layer | TCP/IP layer | Its job | Unit of data | Examples |
|---|---|---|---|---|
| 7 Application | Application | What the program says: requests, responses, names | message | HTTP, DNS, DHCP, SMTP, SSH |
| 6 Presentation | Application | Encoding, compression, encryption | message | TLS (in practice), character encodings |
| 5 Session | Application | Keeping a conversation open across exchanges | message | RPC, SMB sessions |
| 4 Transport | Transport | Delivery between two *programs*: ports, reliability, ordering | segment (TCP) / datagram (UDP) | TCP, UDP |
| 3 Network | Internet | Delivery between two *hosts* across networks: addresses and routing | packet | IPv4, IPv6, ICMP (ping) |
| 2 Data link | Link | Delivery between two devices on the *same* network | frame | Ethernet, Wi-Fi, ARP, MAC addresses |
| 1 Physical | Link | Signals on a cable or radio channel | bits | cables, connectors, Wi-Fi radio |

On the way out, each layer wraps the data from the layer above in its own header: an HTTP request goes inside a TCP segment, inside an IP packet, inside an Ethernet frame. The receiver unwraps it in reverse order. Routers only look as far as layer 3, and switches as far as layer 2, which is why a switch problem and a router problem look different.

**Mapped to `netcheck.bat`:**

| netcheck layer | Tests | Model layers |
|---|---|---|
| 1. IP configuration | A default route, a gateway and a real (not `169.254.x.x`) address | 1–3: a link exists and DHCP worked |
| 2. TCP/IP stack | `ping 127.0.0.1` | 3–4 inside the PC itself |
| 3. Local network | `ping <gateway>` | 2–3 on the local network |
| 4. Internet by IP | `ping 1.1.1.1`, or TCP 443 | 3 across networks (routing) |
| 5. DNS | Resolving a name | 7 (DNS is an application-layer service) |
| 6. Service | A TCP connection to port 443 | 4, and the start of 7 |

## Ports: which program gets the data

An IP address gets a packet to the right *computer*. The **port number** in the TCP or UDP header gets it to the right *program* on that computer. Servers listen on well-known ports, and clients pick a random high port for their own end. That's the pairing `netstat -an` shows.

- **TCP** sets up a connection first (the three-way handshake), then guarantees delivery and order. It's used where every byte matters: web pages, file transfer, remote shells.
- **UDP** just sends. It's faster and simpler, and used where a lost packet is better retried or ignored than waited for: DNS queries, time sync, streaming, games.

Ports worth recognising:

| Port | Protocol | Transport | Used for |
|---|---|---|---|
| 20, 21 | FTP | TCP | File transfer (legacy, unencrypted) |
| 22 | SSH / SFTP | TCP | Encrypted remote shell and file transfer |
| 23 | Telnet | TCP | Unencrypted remote console (legacy devices only) |
| 25, 587 | SMTP | TCP | Sending email (server-to-server, and client submission) |
| 53 | DNS | UDP, and TCP for large answers | Name lookups |
| 67, 68 | DHCP | UDP | Automatic address assignment (server 67, client 68) |
| 80 | HTTP | TCP | Web, unencrypted |
| 123 | NTP | UDP | Clock synchronisation |
| 143, 993 | IMAP | TCP | Reading email (993 = encrypted) |
| 443 | HTTPS | TCP (and UDP for HTTP/3) | Web, encrypted |
| 445 | SMB | TCP | Windows file and printer sharing |
| 3389 | RDP | TCP | Windows Remote Desktop |

Ports below 1024 are the *well-known* range, assigned by IANA. A service can run on any port, so these are conventions, not guarantees.

**Mapped to `netcheck.bat`:** layer 6 opens a TCP connection to port 443. If layers 1–5 pass and layer 6 fails, the network is fine, and the problem is the service, or a firewall or proxy between you and it.

## MAC addresses: identity on the local network

A **MAC address** identifies a network adapter on its local network (layer 2). It's 48 bits, written as six bytes in hexadecimal. Windows separates them with hyphens (`00-00-5E-00-53-01`), and most other systems use colons (`00:00:5E:00:53:01`).

```
      00-00-5E   -   00-53-01
      └──┬───┘       └──┬───┘
   OUI: which organisation   assigned by that organisation
   made the adapter          to this one adapter
   (from the IEEE registry)
```

- The **first three bytes** are the *Organisationally Unique Identifier* (OUI), assigned to a manufacturer by the IEEE. Looking up an OUI in the public registry tells you who made a device, which is handy when working out what an unknown entry in `arp -a` is.
- Two bits of the first byte carry flags. **Multicast** (lowest bit set) addresses a group, not one adapter. **Locally administered** (second-lowest bit set) means the address was set by software, not burned in at the factory. Windows' *random hardware addresses* for Wi-Fi use such addresses, so an OUI lookup on them finds nothing, and the same laptop can show a different MAC on each network.
- `FF-FF-FF-FF-FF-FF` is the **broadcast** address: every device on the local network receives it. DHCP and ARP requests use it, because the sender doesn't know who to ask yet.

A MAC address never leaves its own network. **ARP** (layer 2) finds the MAC for an IP address on the same network. When a packet crosses a router, the router rewrites the MAC addresses for the next network, while the IP addresses stay the same end to end (apart from NAT, which a home or office router applies at its internet edge, rewriting the private source address).

**Mapped to `netcheck.bat`:** layer 3 (pinging the gateway) is the first test that needs ARP to work. If the gateway doesn't answer, `arp -a` shows whether the PC has even learned the gateway's MAC address. No entry for it points to a link or Wi-Fi problem rather than routing.

## Further reading

These courses cover the same ground in video form. They're listed as links only: no course material is reproduced here.

| Course (LinkedIn Learning) | Instructor |
|---|---|
| [Networking Foundations: Networking Basics](https://www.linkedin.com/learning/networking-foundations-networking-basics) | Kevin Wallace |
| [Learning Network Troubleshooting](https://www.linkedin.com/learning/learning-network-troubleshooting-2021) | Robert McMillen |

Primary sources: [RFC 1122](https://www.rfc-editor.org/rfc/rfc1122) (the TCP/IP layers, as specified for hosts), the [IANA port registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml) and the [IEEE OUI registry](https://regauth.standards.ieee.org/).
