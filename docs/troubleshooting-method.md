# A method for network troubleshooting

The tools in this repo follow one method. It fits on a page and applies to any network, from a single PC to a small office.

## 1. Define the symptom precisely

"Nothing works" isn't a symptom. Pin it down first:

- **What** fails: every site, one site, one application, one device?
- **Who** is affected: this PC only, every device on the network, only Wi-Fi devices?
- **Since when**, and what changed just before (update, new router, new cable, VPN installed)?
- **Always or intermittent?** Intermittent problems need a log over time (`ping -t`, `pathping`), not a single test.

The answer to *who* alone splits the problem in half. If every device fails, look at the router or the provider. If one device fails, look at that device.

## 2. Test bottom up, one layer at a time

Each layer depends on the one below it, so test in this order and stop at the first failure:

| Layer | Question | Test |
|---|---|---|
| Physical / link | Is there a link at all? | Link light, Wi-Fi connected, `netsh wlan show interfaces` |
| Addressing | Did the PC get a valid address and gateway? | `ipconfig` (watch for `169.254.x.x`) |
| Local stack | Does TCP/IP itself work? | `ping 127.0.0.1` |
| Local network | Can the PC reach the router? | `ping <gateway>` |
| Internet routing | Can packets leave the building? | `ping 1.1.1.1`, or TCP 443 if ping is blocked |
| Name resolution | Do names turn into addresses? | `nslookup <name>`, then against a second server |
| Service | Does the specific service answer? | `Test-NetConnection <name> -Port <port>` |

`diagnostics/windows-network-toolkit/netcheck.bat` automates this table.

## 3. Compare against a known-good state

A snapshot taken when things work is the most useful reference you can have. `netreport.bat` saves one. When a problem appears, take a second snapshot and compare the two. Differences in gateway, DNS servers, routes or proxy settings stand out.

## 4. Change one thing, then retest

Apply the smallest fix that matches the failed layer, then rerun the same test. If it still fails, undo the change before trying the next one. Several changes at once make it impossible to know which one worked, or which one broke something else.

## 5. Write down what you found

Record the symptom, the failed layer, the fix and the result. Over time these notes become the fastest troubleshooting guide for that particular network.
