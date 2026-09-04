# Linux Fundamentals

I ran all of this on Ubuntu 26.04 (WSL2). The outputs below are copied straight from my terminal.

---

## Task 1: Soft links vs hard links

The thing that finally made this click for me: a filename isn't the file. The actual data sits in an **inode**, and a filename is just a label pointing at it.

- A **hard link** is a second label on the *same* inode. Delete the first name and the data is still there.
- A **soft link** just stores a *path* as text. Delete what it points at and it breaks.

```bash
ln  original.txt hardlink.txt     # hard link, no flag
ln -s original.txt softlink.txt   # soft link, -s
ls -li                            # -i shows inode numbers
```

Here's the proof. Watch the first column (the inode) and what happens after `rm`:

```console
### 1. Create the original file
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

The important bits:

- `original.txt` and `hardlink.txt` both show inode **2378**. The soft link has its own, **14204**.
- The link count on the original is **2**, because two names point at that one inode.
- After deleting the original, the hard link **still prints the text**. The soft link dies with `No such file or directory`.
- `ln -s /etc` works, but `ln /etc` fails: `hard link not allowed for directory`.

**If asked in an interview:** a hard link is another name for the same inode, so the data survives until every name is gone and no link is more "real" than another. A soft link stores a path, so it dangles if that path disappears. Hard links can't cross filesystems (inode numbers are only unique within one) or point at directories (you'd create loops). Soft links can do both, which is why `/usr/bin` is full of them.

---

## Task 2: `adduser` vs `useradd`

Both make users, but they work at different levels. `adduser` is a **Perl script** that wraps `useradd`, which is the actual **compiled binary**.

On Ubuntu you want **`adduser`**. It reads the distro defaults and gives you a working account in one go: home directory, group, bash shell, password prompt. `useradd` does only exactly what you tell it, which is what you want in scripts where you don't want surprises.

```bash
sudo adduser testuser      # what you normally want on Ubuntu
sudo useradd testuser2     # bare bones
sudo userdel -r testuser   # -r removes the home dir too
```

I created a user with each to compare:

```console
### 1. Where does each command live?
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

`adduser` gave `testuser` a home directory with `.bashrc` and `.profile` copied from `/etc/skel`, its own group, and `/bin/bash`. Bare `useradd` made the passwd entry and **no home directory at all**, with `/bin/sh`.

---

## Task 3: `journalctl`

Instead of digging through text files in `/var/log`, systemd keeps one indexed binary log for everything: kernel messages, service output, syslog. `journalctl` is how you read it.

The ones I actually use:

```bash
journalctl -u docker.service     # one service's logs
journalctl -u docker -f          # follow it live, like tail -f
journalctl -p err                # errors only
journalctl --since "1 hour ago"  # time filter
journalctl -b                    # this boot only
journalctl -k                    # kernel messages (dmesg)
```

Checking a specific service is the one that matters day to day. Here's Docker's startup, which reads as a clean story from `Starting up` to `API listen on /run/docker.sock`:

```console
### 2. Disk space currently used by the journal
Archived and active journals take up 296.1M in the file system.

### 3. Oldest + newest entries the journal holds
IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
 -3 19333054c20c41b9b955851e9f5979f9 Mon 2026-08-17 11:47:07 UTC Mon 2026-08-17 12:31:21 UTC
 -2 41e059c5465c42e8aef37ad60dfd16c4 Mon 2026-08-17 14:39:19 UTC Mon 2026-08-17 14:55:15 UTC
 -1 adcc2ad2fa5d45a49585cca2511e7079 Mon 2026-08-17 17:02:30 UTC Mon 2026-08-17 17:03:07 UTC

### 5. Logs for a SPECIFIC SERVICE (docker) -- the interview-relevant use case
Sep 03 18:20:51 Vlair-Lavya systemd[1]: docker.service: Deactivated successfully.
Sep 03 18:20:51 Vlair-Lavya systemd[1]: Stopped docker.service - Docker Application Container Engine.
Sep 03 18:21:18 Vlair-Lavya systemd[1]: Starting docker.service - Docker Application Container Engine...
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.211518168Z" level=info msg="Starting up"
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.233954266Z" level=info msg="Loading containers: start."
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.234444794Z" level=info msg="Starting daemon with containerd snapshotter integration enabled"
Sep 03 18:21:18 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:18.237601950Z" level=info msg="Restoring containers: start."
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.220651947Z" level=info msg="Loading containers: done."
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.226838594Z" level=info msg="Docker daemon" commit=29.1.3-0ubuntu4.1 containerd-snapshotter=true storage-driver=overlayfs version=29.1.3
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.227152988Z" level=info msg="Initializing buildkit"
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.239832842Z" level=info msg="Completed buildkit initialization"
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.242564766Z" level=info msg="Daemon has completed initialization"
Sep 03 18:21:19 Vlair-Lavya dockerd[345]: time="2026-09-03T18:21:19.242651478Z" level=info msg="API listen on /run/docker.sock"
Sep 03 18:21:19 Vlair-Lavya systemd[1]: Started docker.service - Docker Application Container Engine.
```

When a service won't start, this is the first thing to run.

<details>
<summary>Full journalctl session (disk usage, boots, priority filters, JSON output)</summary>

```console
### 1. What is journalctl? -> the query tool for the systemd journal (centralised binary log)
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

</details>

---

## Task 4: Command cheat sheet

The commands I practised, grouped by what I'd reach for them for:

**Getting around:** `pwd`, `cd`, `ls -l` / `-a` / `-h`, `tree`

**Files:** `touch`, `mkdir -p`, `cp` / `cp -r`, `mv` (also renames), `rm` / `rm -r`, `cat`, `less`, `head`, `tail -f`, `wc -l`

**Finding things:** `grep -r` / `-i` / `-n` / `-v`, `find . -name`, `find . -size +10M`, `which`

**Permissions:** `chmod 755` (r=4, w=2, x=1), `chmod u+x`, `chown user:group`, `stat`

**Processes:** `ps aux`, `top`, `kill` / `kill -9`, `pgrep` / `pkill`, `jobs` / `fg` / `bg`

**System:** `df -h`, `du -sh`, `free -h`, `uname -a`, `uptime`, `whoami`, `id`

**Text:** `sort`, `uniq -c`, `cut -d: -f1`, `awk '{print $1}'`, `sed 's/a/b/g'`, and piping with `|`, `>`, `>>`, `2>&1`

**Archives:** `tar -czf` to make, `-xzf` to extract, `-tzf` to peek inside

A slice of me running them:

```console
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
```

<details>
<summary>Full cheat sheet run (all 30+ commands)</summary>

```console
=========== NAVIGATION ===========
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

</details>
