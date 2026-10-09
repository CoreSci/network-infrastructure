# Disk management with `diskpart`: taking a disk offline, removing stuck partitions

Two jobs Windows' graphical *Disk Management* often can't do: taking a disk offline (so Windows stops using it without unplugging it), and deleting partitions that the graphical tool refuses to touch (recovery, OEM or EFI partitions left on a disk being reused).

> ⚠️ **These commands can destroy data, instantly and without an undo.** `diskpart` doesn't ask "are you sure?". Whatever disk or partition is selected is what gets changed. Before any `delete` or `clean`:
>
> - **Back up anything you might need** from that disk.
> - **Identify the disk by size and model, not by number.** Disk numbers can change between restarts and when drives are added. Check with `list disk` and `detail disk` every time, just before acting.
> - **Never run this on the disk Windows is installed on** unless you intend to wipe the system. `detail disk` lists its volumes; `C:` on a disk means it's the system disk.
> - Disconnect other external drives you don't need, so there's less to confuse.

## Starting `diskpart`

Open **Command Prompt as administrator**, then:

```
C:\> diskpart
DISKPART> list disk
```

```
  Disk ###  Status         Size     Free     Dyn  Gpt
  --------  -------------  -------  -------  ---  ---
  Disk 0    Online          931 GB      0 B        *
  Disk 1    Online          465 GB  1024 KB        *
  Disk 2    Online          238 GB      0 B        *
```

*(Example output: sizes and numbering vary.)* An asterisk under `Gpt` means the disk uses GPT partitioning. Most `diskpart` commands act on the **selected** disk, partition or volume, so every task starts with `select`, and then a check that the selection is right:

```
DISKPART> select disk 2
Disk 2 is now the selected disk.

DISKPART> detail disk          (model, type, and the volumes/letters on this disk)
DISKPART> list disk            (the selected disk is marked with *)
```

Type `exit` to leave `diskpart`.

## Task 1: take a disk offline, and bring it back

Useful for a second internal drive you want Windows to leave alone: no drive letter, no indexing, no accidental writes, without opening the case. Nothing on the disk is changed.

```
DISKPART> list disk
DISKPART> select disk 2
DISKPART> detail disk          check: is this really the disk you mean?
DISKPART> offline disk
DiskPart successfully offlined the selected disk.
```

`list disk` now shows it as `Offline`, and its drive letters disappear from File Explorer. To use it again:

```
DISKPART> select disk 2
DISKPART> online disk
```

If the disk comes back **read-only**, clear the flag with `attributes disk clear readonly`.

## Task 2: delete a partition that won't delete

Disk Management greys out *Delete Volume* for protected partitions (EFI system, recovery, OEM). `diskpart` can remove them with `override`. **Everything on the deleted partition is lost.**

```
DISKPART> list disk
DISKPART> select disk 1
DISKPART> detail disk          check the model, size and volumes
DISKPART> list partition
```

```
  Partition ###  Type              Size     Offset
  -------------  ----------------  -------  -------
  Partition 1    System             100 MB  1024 KB
  Partition 2    Reserved            16 MB   101 MB
  Partition 3    Primary            464 GB   117 MB
  Partition 4    Recovery           650 MB   464 GB
```

*(Example output.)* Then, for each partition to remove:

```
DISKPART> select partition 4
DISKPART> detail partition     check the type and size once more
DISKPART> delete partition override
DiskPart successfully deleted the selected partition.
```

Repeat `select partition` / `detail partition` / `delete partition override` for the others, and run `list partition` after each one. **Partition numbers can shift after a deletion.**

### Wiping the whole disk instead

If the goal is to empty the entire disk, `clean` removes **all** partitions and the partition table in one step, and is simpler than deleting partitions one by one:

```
DISKPART> select disk 1
DISKPART> detail disk          last check
DISKPART> clean
```

Afterwards, create a new partition in Disk Management, or with `create partition primary`, `format fs=ntfs quick` and `assign`.

## When a command fails

| Message | Usually means |
|---|---|
| `Virtual Disk Service error: The operation is not supported on a non-empty removable disk` | Some USB sticks report themselves as removable, so `diskpart` limits what it will do. `clean` usually still works |
| `The disk is write protected` / media is read-only | Try `attributes disk clear readonly`. A physical write-protect switch or a failing drive can also cause it |
| `Access is denied` | The prompt isn't elevated. Run Command Prompt as administrator |
| `Cannot delete a protected partition without the force protected parameter set` | Add `override`: `delete partition override` |

## Why this matters

Reusing a drive from another computer, clearing a manufacturer's recovery partition, or keeping a data disk out of Windows' way are routine jobs, and `diskpart` handles them without extra software. The discipline is what matters: **select, verify, then act**, every time, because the tool trusts the selection completely.
