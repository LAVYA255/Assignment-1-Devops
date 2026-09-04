# Linux Fundamentals

All commands below were executed on **Ubuntu 26.04 LTS** (WSL2, kernel 6.18.33.2). Every output block is real terminal output captured while running the task.

---

## Task 1 - Soft Link vs Hard Link

### The concept

A file's actual data lives in an **inode**. A filename is just a directory entry pointing at an inode.

| | Hard link | Soft link (symbolic link) |
|---|---|---|
| What it points to | The **inode** directly | The **pathname** of another file |
| Inode number | **Same** as the original | **Its own**, different inode |
| Survives deleting the original? | **Yes** - data lives until the last link goes | **No** - becomes a dangling link |
| Can cross filesystems? | No | Yes |
| Can link a directory? | No | Yes |
| Size | Same as the file | Just the length of the stored path |

### Commands

```bash
ln original.txt hardlink.txt       # hard link - no flag
ln -s original.txt softlink.txt    # soft link - the -s flag
ls -li                             # -i shows the inode number
rm softlink.txt                    # deleting a link never touches the original file
```

### Practical demonstration and output

```console
﻿### 1. Create the original file
Hello from the original file

### 2. Create a HARD link

### 3. Create a SOFT link (symbolic link)

### 4. Inspect all three with ls -li (note the inode numbers in column 1)
total 8
 2378 -rw-r--r-- 2 lavya lavya 29 Sep  3 18:20 hardlink.txt
 2378 -rw-r--r-- 2 lavya lavya 29 Sep  3 18:20 original.txt
14204 lrwxrwxrwx 1 lavya lavya 12 Sep  3 18:20 softlink.txt -> original.txt

### 5. Inode comparison
original.txt inode : 2378
hardlink.txt inode : 2378   <-- SAME as original
softlink.txt inode : 14204   <-- DIFFERENT (own inode)
link count on original.txt: 2  (2 = two names point to this inode)

### 6. Both links read the same content
cat hardlink.txt -> Hello from the original file
cat softlink.txt -> Hello from the original file

### 7. THE KEY TEST: delete the original file
total 4
 2378 -rw-r--r-- 1 lavya lavya 29 Sep  3 18:20 hardlink.txt
14204 lrwxrwxrwx 1 lavya lavya 12 Sep  3 18:20 softlink.txt -> original.txt

### 8. Read the links after deleting the original
--- hard link still works: ---
Hello from the original file
--- soft link is now BROKEN (dangling): ---
cat: softlink.txt: No such file or directory

### 9. Soft link can cross filesystems / point to directories; hard links cannot
soft link to a DIRECTORY /etc created OK:
lrwxrwxrwx 1 lavya lavya 4 Sep  3 18:20 etc-shortcut -> /etc
attempt a HARD link to a directory:
ln: /etc: hard link not allowed for directory
```

### What the output proves

1. `hardlink.txt` and `original.txt` share inode **2378**; `softlink.txt` has its own inode **14204**.
2. The link count on the original is **2** - two names point at one inode.
3. After `rm original.txt`, the **hard link still prints the content** (the inode still has a name referring to it, so the data was never freed), while the **soft link breaks** with `No such file or directory` because the path it stored no longer exists.
4. `ln -s /etc etc-shortcut` succeeds, but `ln /etc etc-hard` fails with `hard link not allowed for directory`.

### Interview answer

> A hard link is a second name for the same inode, so the file's data survives until every hard link is deleted, and all links are equal - there is no "original". A soft link is a small separate file that stores a *path*; if that path disappears the link dangles. Hard links cannot cross filesystem boundaries or point at directories, because inode numbers are only unique within a single filesystem and directory hard links would allow loops in the tree. Soft links can do both, which is why symlinks are what you normally see in `/usr/bin` and in versioned shared libraries.

---

## Task 2 - `adduser` vs `useradd`

### The difference

| | `adduser` | `useradd` |
|---|---|---|
| Type | High-level **Perl script** | Low-level **compiled binary** |
| Origin | Debian/Ubuntu convenience wrapper | Part of the `shadow` package, on every Linux |
| Behaviour | Interactive, applies sane defaults | Does exactly what you tell it, nothing more |
| Home directory | Created and populated from `/etc/skel` automatically | Only with `-m` |
| Password | Prompts for one | Not set (account stays locked) |
| Group | Creates a matching user group | Only with the right options |
| Shell | `/bin/bash` | `/bin/sh` or `nologin` |

**Preferred on Ubuntu: `adduser`** - it is the officially recommended, policy-compliant front-end. It applies the distribution's defaults from `/etc/adduser.conf`, so one step produces a usable account (home directory, group, shell, password) instead of a string of flags you have to remember. `useradd` is the right choice in **scripts and automation**, where predictable non-interactive behaviour matters more than convenience.

### Commands

```bash
sudo adduser testuser                 # recommended on Ubuntu
sudo useradd testuser2                # low-level, minimal
sudo userdel -r testuser              # -r also removes the home directory
```

### Practical demonstration and output

```console
﻿### 1. Where does each command live?
/usr/sbin/adduser
/usr/sbin/useradd

### 2. What TYPE of program is each?
Perl script text executable
ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=a20d46768ac3abdb6f7621ab4d8891509d5c181a, for GNU/Linux 3.2.0, stripped

=> adduser is a high-level Perl SCRIPT (a friendly wrapper)
=> useradd is a low-level compiled BINARY (the raw utility)

### 3. Create a test user with the RECOMMENDED command on Ubuntu (adduser)
usermod: no changes

### 4. Verify the account entry in /etc/passwd
testuser:x:1001:1001::/home/testuser:/bin/bash

### 5. adduser did all of this automatically:
-- home directory was created and populated from /etc/skel:
total 20
drwxr-x--- 2 testuser testuser 4096 Sep  3 18:21 .
drwxr-xr-x 4 root     root     4096 Sep  3 18:21 ..
-rw-r--r-- 1 testuser testuser  220 Sep  3 18:21 .bash_logout
-rw-r--r-- 1 testuser testuser 3771 Sep  3 18:21 .bashrc
-rw-r--r-- 1 testuser testuser  807 Sep  3 18:21 .profile
-- a matching GROUP was created:
testuser:x:1001:
-- login shell assigned:
/bin/bash

### 6. CONTRAST: what useradd does with no options
testuser2:x:1002:1002::/home/testuser2:/bin/sh
-- does testuser2 have a home directory?
ls: cannot access '/home/testuser2': No such file or directory
   >>> NO home directory was created by bare 'useradd'
-- default shell for testuser2:
/bin/sh
   >>> note /bin/sh (or /usr/sbin/nologin), NOT an interactive bash login

### 7. Clean up the contrast user
testuser2 removed; testuser kept as the deliverable

### 8. Final proof the recommended user exists
uid=1001(testuser) gid=1001(testuser) groups=1001(testuser),100(users)
```

### What the output proves

- `file` shows `adduser` is a **Perl script** and `useradd` is an **ELF binary** - the wrapper/underlying-tool relationship in a single command.
- `adduser` produced a complete account: a home directory populated from `/etc/skel` (`.bashrc`, `.profile`, `.bash_logout`), a matching `testuser` group, and `/bin/bash` as the login shell.
- Bare `useradd` created the `/etc/passwd` entry but **no home directory at all**, and gave the user `/bin/sh`.

---

## Task 3 - `journalctl`

### What it is

`journalctl` is the query tool for the **systemd journal**. Instead of plain-text files scattered through `/var/log`, systemd writes a single structured, indexed **binary** log capturing kernel messages, service stdout/stderr and syslog in one place - so it can be filtered by service, priority, time or boot without any `grep` gymnastics.

### Key commands

| Command | Purpose |
|---|---|
| `journalctl` | Everything, oldest first |
| `journalctl -n 20` | Last 20 lines |
| `journalctl -f` | **Follow** live, like `tail -f` |
| `journalctl -u docker.service` | Logs for **one specific service** |
| `journalctl -u docker -f` | Follow one service live |
| `journalctl -p err` | Priority `err` and worse |
| `journalctl --since "1 hour ago"` | Time filter |
| `journalctl --since today --until "10:00"` | Time range |
| `journalctl -b` / `journalctl -b -1` | This boot / previous boot |
| `journalctl -k` | Kernel messages only (like `dmesg`) |
| `journalctl --disk-usage` | Space used by the journal |
| `journalctl --vacuum-time=7d` | Delete entries older than 7 days |
| `journalctl -o json-pretty` | Structured output for scripting |

Priority levels: `0 emerg`, `1 alert`, `2 crit`, `3 err`, `4 warning`, `5 notice`, `6 info`, `7 debug`.

### Practical demonstration and output

```console
﻿### 1. What is journalctl? -> the query tool for the systemd journal (centralised binary log)
systemd 259 (259.5-0ubuntu3)
+PAM +AUDIT +SELINUX +APPARMOR +IMA +IPE +SMACK +SECCOMP +GCRYPT -GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN +KMOD +LIBCRYPTSETUP +LIBCRYPTSETUP_PLUGINS +LIBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +BTF -XKBCOMMON -UTMP +SYSVINIT +LIBARCHIVE

### 2. Disk space currently used by the journal
Archived and active journals take up 296.1M in the file system.

### 3. Oldest + newest entries the journal holds
IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
 -3 19333054c20c41b9b955851e9f5979f9 Mon 2026-08-17 11:47:07 UTC Mon 2026-08-17 12:31:21 UTC
 -2 41e059c5465c42e8aef37ad60dfd16c4 Mon 2026-08-17 14:39:19 UTC Mon 2026-08-17 14:55:15 UTC
 -1 adcc2ad2fa5d45a49585cca2511e7079 Mon 2026-08-17 17:02:30 UTC Mon 2026-08-17 17:03:07 UTC
  0 16507d2951ac40858fd72a26ccee3df6 Thu 2026-09-03 18:19:12 UTC Thu 2026-09-03 18:21:27 UTC

### 4. Last 15 lines of the WHOLE system log
Sep 03 18:21:20 Vlair-Lavya userdel[735]: removed group 'testuser2' owned by 'testuser2'
Sep 03 18:21:20 Vlair-Lavya userdel[735]: removed shadow group 'testuser2' owned by 'testuser2'
Sep 03 18:21:21 Vlair-Lavya snapd[192]: snapmgr.go:1659: performing periodic snap downloads cache cleanup
Sep 03 18:21:21 Vlair-Lavya snapd[192]: snapmgr.go:1669: cannot clean store downloads cache: open /var/lib/snapd/cache: no such file or directory
Sep 03 18:21:21 Vlair-Lavya wsl-pro-service[201]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/Lavya/.ubuntupro/.address": open /mnt/c/Users/Lavya/.ubuntupro/.address: no such file or directory
Sep 03 18:21:22 Vlair-Lavya snapd[192]: standby.go:101: standby conditions met, initiating standby...
Sep 03 18:21:22 Vlair-Lavya snapd[192]: daemon.go:556: gracefully waiting for running hooks
Sep 03 18:21:22 Vlair-Lavya snapd[192]: daemon.go:558: done waiting for running hooks
Sep 03 18:21:25 Vlair-Lavya wsl-pro-service[201]: WARNING Daemon: could not connect to Windows Agent: could not get address: could not read agent port file "/mnt/c/Users/Lavya/.ubuntupro/.address": open /mnt/c/Users/Lavya/.ubuntupro/.address: no such file or directory
Sep 03 18:21:26 Vlair-Lavya snapd[192]: standby.go:121: standby monitoring stop requested
Sep 03 18:21:26 Vlair-Lavya snapd[192]: overlord.go:543: Released state lock file
Sep 03 18:21:26 Vlair-Lavya snapd[192]: daemon stop requested to wait for socket activation
Sep 03 18:21:26 Vlair-Lavya systemd[1]: snapd.service: Deactivated successfully.
Sep 03 18:21:26 Vlair-Lavya chronyd[259]: Selected source 91.189.91.112 (3.ntp.ubuntu.com)
Sep 03 18:21:27 Vlair-Lavya chronyd[259]: Selected source 185.125.190.123 (2.ntp.ubuntu.com)

### 5. Logs for a SPECIFIC SERVICE (docker) -- the interview-relevant use case
Sep 03 18:20:51 Vlair-Lavya systemd[1]: docker.service: Deactivated successfully.
Sep 03 18:20:51 Vlair-Lavya systemd[1]: Stopped docker.service - Docker Application Container Engine.
Sep 03 18:21:18 Vlair-Lavya systemd[1]: Starting docker.service - Docker Application Container Engine...
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.211518168Z" level=info msg="Starting up"
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.212387430Z" level=info msg="OTEL tracing is not configured, using no-op tracer provider"
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.212498038Z" level=info msg="CDI directory does not exist, skipping: failed to monitor for changes: no such file or directory" dir=/etc/cdi
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.212515793Z" level=info msg="CDI directory does not exist, skipping: failed to monitor for changes: no such file or directory" dir=/var/run/cdi
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.224165897Z" level=info msg="Creating a containerd client" address=/run/containerd/containerd.sock timeout=1m0s
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.233954266Z" level=info msg="Loading containers: start."
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.234444794Z" level=info msg="Starting daemon with containerd snapshotter integration enabled"
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.237601950Z" level=info msg="Restoring containers: start."
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.283330346Z" level=info msg="Deleting nftables IPv4 rules" error="exit status 1"
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.327261681Z" level=info msg="Deleting nftables IPv6 rules" error="exit status 1"
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.220651947Z" level=info msg="Loading containers: done."
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.226838594Z" level=info msg="Docker daemon" commit=29.1.3-0ubuntu4.1 containerd-snapshotter=true storage-driver=overlayfs version=29.1.3
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.227152988Z" level=info msg="Initializing buildkit"
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.239832842Z" level=info msg="Completed buildkit initialization"
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.242564766Z" level=info msg="Daemon has completed initialization"
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.242651478Z" level=info msg="API listen on /run/docker.sock"
Sep 03 18:21:19 Vlair-Lavya systemd[1]: Started docker.service - Docker Application Container Engine.

### 6. Only errors and worse (priority 3 = err)
Sep 03 18:21:17 Vlair-Lavya unknown: WSL (232) ERROR: CheckConnection: getaddrinfo() failed: -3
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_is_feature_enabled: Ioctl failed: -22
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -22
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -22
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -22
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -2
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -22
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -22
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -22
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -2

### 7. Time-filtered query
Sep 03 18:21:26 Vlair-Lavya snapd[192]: overlord.go:543: Released state lock file
Sep 03 18:21:26 Vlair-Lavya snapd[192]: daemon stop requested to wait for socket activation
Sep 03 18:21:26 Vlair-Lavya systemd[1]: snapd.service: Deactivated successfully.
Sep 03 18:21:26 Vlair-Lavya chronyd[259]: Selected source 91.189.91.112 (3.ntp.ubuntu.com)
Sep 03 18:21:27 Vlair-Lavya chronyd[259]: Selected source 185.125.190.123 (2.ntp.ubuntu.com)

### 8. Kernel messages only (equivalent to dmesg)
Sep 03 18:21:17 Vlair-Lavya kernel: misc dxg: dxgk: dxgkio_query_adapter_info: Ioctl failed: -2
Sep 03 18:21:17 Vlair-Lavya unknown: WSL (2 - init-systemd(Ubuntu)) WARNING: /usr/share/zoneinfo/Asia/Calcutta not found. Is the tzdata package installed?
Sep 03 18:21:17 Vlair-Lavya systemd-journald[45]: Collecting audit messages is disabled.
Sep 03 18:21:17 Vlair-Lavya systemd-journald[45]: Received client request to flush runtime journal.
Sep 03 18:21:17 Vlair-Lavya systemd-journald[45]: File /var/log/journal/9a82298f20264177b204f9b715b45138/system.journal corrupted or uncleanly shut down, renaming and replacing.

### 9. Structured output (useful for scripting / log shipping)
{
	"__SEQNUM" : "20507",
	"MESSAGE_ID" : "39f53479d3a045ac8e11786248231fbf",
	"SYSLOG_FACILITY" : "3",
	"__CURSOR" : "s=8b1d308a039e4e31bdb46ed32613f903;i=501b;b=16507d2951ac40858fd72a26ccee3df6;m=7d204aa;t=65a9837e05a2c;x=1ac9ab7a9f39499c",
	"CODE_FILE" : "src/core/job.c",
	"JOB_RESULT" : "done",
	"JOB_ID" : "126",
	"PRIORITY" : "6",
	"_TRANSPORT" : "journal",
	"_SYSTEMD_UNIT" : "init.scope",
	"CODE_FUNC" : "job_emit_done_message",
	"_COMM" : "systemd",
	"__MONOTONIC_TIMESTAMP" : "131204266",
	"__SEQNUM_ID" : "8b1d308a039e4e31bdb46ed32613f903",
	"SYSLOG_IDENTIFIER" : "systemd",
	"MESSAGE" : "Started docker.service - Docker Application Container Engine.",
	"_BOOT_ID" : "16507d2951ac40858fd72a26ccee3df6",
	"CODE_LINE" : "815",
	"TID" : "1",
```

### Checking logs for a specific service

`journalctl -u docker.service` is the most useful form in practice. The output above traces the entire Docker daemon startup: `Starting up` → `Loading containers: start.` → `Loading containers: done.` → `Daemon has completed initialization` → `API listen on /run/docker.sock`. When a service fails to start, this is the first command to reach for.

---

## Task 4 - Linux Command Cheat Sheet

### Reference

**Navigation**

| Command | Purpose |
|---|---|
| `pwd` | Print working directory |
| `cd /path`, `cd ..`, `cd ~` | Change directory, up one, home |
| `ls -l`, `-a`, `-h`, `-R` | Long, hidden, human sizes, recursive |
| `tree` | Directory tree |

**Files and directories**

| Command | Purpose |
|---|---|
| `touch f` | Create an empty file / update its timestamp |
| `mkdir -p a/b/c` | Create nested directories |
| `cp f1 f2`, `cp -r d1 d2` | Copy file, copy directory |
| `mv a b` | Move **or** rename |
| `rm f`, `rm -r d`, `rm -rf d` | Remove file, directory, force |
| `cat`, `less`, `head -n`, `tail -n`, `tail -f` | View contents |
| `wc -l`, `-w`, `-c` | Count lines, words, bytes |

**Search**

| Command | Purpose |
|---|---|
| `grep 'text' file` | Search inside a file |
| `grep -r`, `-i`, `-n`, `-v` | Recursive, ignore case, line numbers, invert |
| `find . -name '*.txt'` | Find by name |
| `find . -type f -size +10M` | Find by type and size |
| `which cmd`, `whereis cmd` | Locate an executable |

**Permissions and ownership**

| Command | Purpose |
|---|---|
| `chmod 755 f` | Set permissions numerically (`r=4 w=2 x=1`) |
| `chmod u+x f` | Symbolic form |
| `chown user:group f` | Change owner |
| `stat f` | Full file metadata |
| `umask` | Default permission mask |

**Processes**

| Command | Purpose |
|---|---|
| `ps aux` | All running processes |
| `top`, `htop` | Live process view |
| `kill PID`, `kill -9 PID` | Terminate, force kill |
| `pkill name`, `pgrep name` | Kill by name, find by name |
| `jobs`, `fg`, `bg`, `&` | Job control |
| `nohup cmd &` | Keep running after logout |

**System and disk**

| Command | Purpose |
|---|---|
| `df -h` | Disk free per filesystem |
| `du -sh dir` | Size of a directory |
| `free -h` | Memory usage |
| `uname -a` | Kernel and architecture |
| `uptime` | Load average |
| `whoami`, `id` | Current user; UID, GID and groups |
| `history` | Command history |

**Text processing**

| Command | Purpose |
|---|---|
| `sort`, `sort -r`, `sort -n` | Sort, reverse, numeric |
| `uniq -c` | Deduplicate and count |
| `cut -d: -f1` | Extract a field |
| `awk '{print $1}'` | Field-based processing |
| `sed 's/a/b/g'` | Stream find-and-replace |
| Pipe and redirection | `\|`, `>`, `>>`, `2>&1` |

**Archive**

| Command | Purpose |
|---|---|
| `tar -czf a.tar.gz dir` | Create a gzip archive |
| `tar -xzf a.tar.gz` | Extract |
| `tar -tzf a.tar.gz` | List contents without extracting |

### Practical demonstration and output

```console
﻿=========== NAVIGATION ===========
$ pwd
/home/lavya/linux-hw/cheatsheet

$ mkdir -p demo/sub && ls -R demo
demo:
sub

demo/sub:

$ cd demo && pwd && cd ..
/home/lavya/linux-hw/cheatsheet/demo

=========== FILE CREATION / VIEWING ===========
$ touch notes.txt && ls -l notes.txt
-rw-r--r-- 1 lavya lavya 0 Sep  3 18:22 notes.txt

$ printf 'alpha\nbravo\ncharlie\ndelta\necho\n' > words.txt && cat words.txt
alpha
bravo
charlie
delta
echo

$ head -2 words.txt
alpha
bravo

$ tail -2 words.txt
delta
echo

$ wc -l words.txt
5 words.txt

=========== COPY / MOVE / DELETE ===========
$ cp words.txt words-copy.txt && ls
demo
notes.txt
words-copy.txt
words.txt

$ mv words-copy.txt renamed.txt && ls
demo
notes.txt
renamed.txt
words.txt

$ rm renamed.txt && ls
demo
notes.txt
words.txt

=========== SEARCHING ===========
$ grep 'char' words.txt
charlie

$ grep -n 'a' words.txt
1:alpha
2:bravo
3:charlie
4:delta

$ find . -name '*.txt'
./words.txt
./notes.txt

=========== PERMISSIONS / OWNERSHIP ===========
$ chmod 755 notes.txt && ls -l notes.txt
-rwxr-xr-x 1 lavya lavya 0 Sep  3 18:22 notes.txt

$ chmod u-x,go-rx notes.txt && ls -l notes.txt
-rw------- 1 lavya lavya 0 Sep  3 18:22 notes.txt

$ stat -c '%A %U:%G %n' notes.txt
-rw------- lavya:lavya notes.txt

=========== PROCESSES ===========
$ ps -eo pid,comm --sort=-pid | head -6
    PID COMMAND
    743 tail
    742 head
    741 bash
    740 bash
    739 bash

$ echo $$
598

=========== DISK / MEMORY / SYSTEM ===========
$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G  3.8G  952G   1% /

$ du -sh .
16K	.

$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.6Gi       843Mi       5.9Gi       3.6Mi       1.0Gi       6.8Gi
Swap:          2.0Gi          0B       2.0Gi

$ uname -a
Linux Vlair-Lavya 6.18.33.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026 x86_64 GNU/Linux

$ uptime
 18:22:16 up 3 min,  1 user,  load average: 0.84, 0.37, 0.14

$ whoami && id -u
lavya
1000

=========== TEXT PROCESSING / PIPES ===========
$ sort -r words.txt
echo
delta
charlie
bravo
alpha

$ cat words.txt | wc -w
5

$ awk '{print NR": "$1}' words.txt
1: alpha
2: bravo
3: charlie
4: delta
5: echo

$ sed 's/alpha/ALPHA/' words.txt | head -2
ALPHA
bravo

=========== ARCHIVE ===========
$ tar -czf words.tar.gz words.txt && ls -lh words.tar.gz
-rw-r--r-- 1 lavya lavya 150 Sep  3 18:22 words.tar.gz

$ tar -tzf words.tar.gz
words.txt
```
