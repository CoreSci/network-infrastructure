# Network & Infrastructure

Practical notes, scripts and command references for diagnosing and fixing everyday network problems on Windows, written for home and small-office networks, plus related PC infrastructure tasks such as disk management.

> **Generic by design:** every address and host name in this repo is a placeholder or a public service. Examples use the documentation ranges reserved by RFC 5737 (`192.0.2.0/24` and similar), a typical router address (`192.168.1.1`) or `example.com`. Nothing here describes a real network. The report script's output describes *your* network, so its `reports/` folder is git-ignored.

## Structure

| Folder | Contents |
|---|---|
| [`diagnostics/windows-network-toolkit/`](diagnostics/windows-network-toolkit/) | `netcheck.bat` (layer-by-layer check with a verdict), `netreport.bat` (full diagnostic snapshot to a file), `network-reset.bat` (standard fixes, least disruptive first) and a troubleshooting decision tree |
| [`cli-reference/`](cli-reference/) | [Windows networking commands](cli-reference/windows-networking-commands.md), grouped by the question they answer, with how to read the results |
| [`docs/`](docs/) | [A method for network troubleshooting](docs/troubleshooting-method.md): define the symptom, test bottom up, compare against a known-good state, change one thing at a time. [Networking fundamentals](docs/networking-fundamentals.md): OSI vs TCP/IP layers, common ports and MAC addresses, mapped onto `netcheck.bat`'s six layers |
| [`storage/`](storage/) | [Disk management with `diskpart`](storage/windows-diskpart.md): taking a disk offline, and removing partitions Disk Management won't delete, with the checks that keep it from wiping the wrong disk |

Each script lives next to the README that explains it, rather than in a separate scripts folder.

## Philosophy

Most network problems are quick to fix once you know which layer is broken, and slow to fix when you guess. Everything here is built around finding that layer first.

## Status

🚧 Under active development.
