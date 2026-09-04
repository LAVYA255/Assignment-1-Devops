# Shell Scripting — System Information Script

The script [`sysinfo.sh`](sysinfo.sh) prints system information, takes input from the user, creates a directory and a file, and saves the running-process list into that file using output redirection.

---

## Requirements checklist

| Requirement | How the script does it | Line reference |
|---|---|---|
| Prints the current date | `CURRENT_DATE=$(date)` then `echo "$CURRENT_DATE"` | Variables + section 1 |
| Prints the hostname | `HOST_NAME=$(hostname)` | Variables + section 1 |
| Prints the username | `USER_NAME=$(whoami)` | Variables + section 1 |
| Prints the disk usage | `df -h` | Section 1 |
| Prints the running processes | `ps aux \| head -10` | Section 1 |
| Uses variables to store and use data | `CURRENT_DATE`, `HOST_NAME`, `USER_NAME`, `SEPARATOR`, `DIR_NAME`, `FILE_NAME` | Throughout |
| Takes user input using `read -p` | `read -p "Enter a name for the report directory: " DIR_NAME` | Section 2 |
| Creates a directory using `mkdir` | `mkdir -p "$DIR_NAME"` | Section 3 |
| Creates a file using `touch` | `touch "$DIR_NAME/$FILE_NAME"` | Section 3 |
| Stores processes in the file using `>` | `ps aux > "$DIR_NAME/$FILE_NAME"` | Section 4 |

All ten required commands are used: `mkdir`, `touch`, `echo`, `df`, `ps`, `read -p`, variables and `>` redirection.

---

## The script

```bash
#!/bin/bash
#
# sysinfo.sh - System Information Script
#
# DevOps Homework - Shell Scripting Task
#
# Prints the date, hostname, username, disk usage and running processes,
# then asks the user for a directory name, creates that directory and a
# file inside it, and saves the running-process list into the file using
# output redirection.
#

# ----- Variables: store the data first, then use it -------------------------
CURRENT_DATE=$(date)
HOST_NAME=$(hostname)
USER_NAME=$(whoami)
SEPARATOR="========================================================"

# ----- 1. Print the system information --------------------------------------
echo "$SEPARATOR"
echo "                 SYSTEM INFORMATION REPORT"
echo "$SEPARATOR"

echo
echo "--- Current Date ---"
echo "$CURRENT_DATE"

echo
echo "--- Hostname ---"
echo "$HOST_NAME"

echo
echo "--- Username ---"
echo "$USER_NAME"

echo
echo "--- Disk Usage ---"
df -h

echo
echo "--- Running Processes (top 10) ---"
ps aux | head -10

# ----- 2. Take input from the user ------------------------------------------
echo
echo "$SEPARATOR"
read -p "Enter a name for the report directory: " DIR_NAME
read -p "Enter a name for the report file: " FILE_NAME

# Fall back to defaults if the user just pressed Enter
DIR_NAME=${DIR_NAME:-sysinfo_reports}
FILE_NAME=${FILE_NAME:-processes.txt}

# ----- 3. Create the directory and the file ---------------------------------
mkdir -p "$DIR_NAME"
echo "Directory created: $DIR_NAME"

touch "$DIR_NAME/$FILE_NAME"
echo "File created: $DIR_NAME/$FILE_NAME"

# ----- 4. Store the running processes in the file using > redirection -------
ps aux > "$DIR_NAME/$FILE_NAME"
echo "Running processes saved to: $DIR_NAME/$FILE_NAME"

# ----- 5. Confirm what was written ------------------------------------------
echo
echo "--- Proof the file was written (first 5 lines) ---"
head -5 "$DIR_NAME/$FILE_NAME"

echo
echo "--- Line count of the saved report ---"
wc -l < "$DIR_NAME/$FILE_NAME"

echo
echo "$SEPARATOR"
echo "Report complete."
echo "$SEPARATOR"
```

---

## How to run it

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

The script pauses at two `read -p` prompts. In the captured run below the answers `system_reports` and `running_processes.txt` were supplied on standard input, which is why the prompt text itself does not appear in the transcript — Bash only renders a `read -p` prompt when standard input is an interactive terminal.

---

## Output

```console
﻿========================================================
                 SYSTEM INFORMATION REPORT
========================================================

--- Current Date ---
Thu Sep  3 18:23:52 UTC 2026

--- Hostname ---
Vlair-Lavya

--- Username ---
lavya

--- Disk Usage ---
Filesystem      Size  Used Avail Use% Mounted on
none            3.9G     0  3.9G   0% /usr/lib/modules/6.18.33.2-microsoft-standard-WSL2
none            3.9G  4.0K  3.9G   1% /mnt/wsl
drivers         659G  536G  124G  82% /usr/lib/wsl/drivers
/dev/sdd       1007G  4.0G  952G   1% /
none            3.9G   32K  3.9G   1% /mnt/wslg
none            3.9G     0  3.9G   0% /usr/lib/wsl/lib
rootfs          3.8G  2.8M  3.8G   1% /init
none            3.9G  636K  3.9G   1% /run
none            3.9G     0  3.9G   0% /run/lock
none            3.9G     0  3.9G   0% /run/shm
none            3.9G   80K  3.9G   1% /mnt/wslg/versions.txt
none            3.9G   80K  3.9G   1% /mnt/wslg/doc
C:\             659G  536G  124G  82% /mnt/c
L:\             147G   85G   62G  58% /mnt/l
V:\             147G  107G   40G  73% /mnt/v
tmpfs           3.9G     0  3.9G   0% /tmp
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
tmpfs           779M   12K  779M   1% /run/user/0
tmpfs           779M   12K  779M   1% /run/user/1000

--- Running Processes (top 10) ---
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  2.1  0.1  24548 15484 ?        Ss   18:23   0:00 /sbin/init
root           2  0.0  0.0   3180  2204 hvc0     Sl+  18:23   0:00 /init
root           8  0.0  0.0   3180  2040 hvc0     Sl+  18:23   0:00 plan9 --control-socket 7 --log-level 4 --server-fd 8 --pipe-fd 10 --log-truncate
root          45  0.4  0.2  42200 16744 ?        S<s  18:23   0:00 /usr/lib/systemd/systemd-journald
systemd+      80  0.2  0.1  22540 14672 ?        Ss   18:23   0:00 /usr/lib/systemd/systemd-resolved
root          87  0.7  0.1  35600 12484 ?        Ss   18:23   0:00 /usr/lib/systemd/systemd-udevd
root         173  0.1  0.0   2888  1940 ?        Ss   18:23   0:00 /bin/sh /usr/lib/systemd/scripts/chronyd-starter.sh -n -F 1
root         174  0.0  0.0   4472  3056 ?        Ss   18:23   0:00 /usr/sbin/cron -f -P
message+     175  0.2  0.0   8800  5392 ?        Ss   18:23   0:00 @dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only

========================================================
Directory created: system_reports
File created: system_reports/running_processes.txt
Running processes saved to: system_reports/running_processes.txt

--- Proof the file was written (first 5 lines) ---
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  2.1  0.1  24548 15484 ?        Ss   18:23   0:00 /sbin/init
root           2  0.0  0.0   3180  2204 hvc0     Sl+  18:23   0:00 /init
root           8  0.0  0.0   3180  2040 hvc0     Sl+  18:23   0:00 plan9 --control-socket 7 --log-level 4 --server-fd 8 --pipe-fd 10 --log-truncate
root          45  0.4  0.2  42200 16744 ?        S<s  18:23   0:00 /usr/lib/systemd/systemd-journald

--- Line count of the saved report ---
43

========================================================
Report complete.
========================================================

=== VERIFY: directory and file created ===
/home/lavya/shell-hw:
total 8
-rwxr-xr-x 1 lavya lavya 2024 Sep  3 18:23 sysinfo.sh
drwxr-xr-x 2 lavya lavya 4096 Sep  3 18:23 system_reports

/home/lavya/shell-hw/system_reports:
total 8
-rw-r--r-- 1 lavya lavya 4589 Sep  3 18:23 running_processes.txt
```

---

## What the output demonstrates

- **Date, hostname and username** are read into variables and printed back.
- **`df -h`** lists every mounted filesystem with human-readable sizes.
- **`ps aux | head -10`** shows the running processes.
- The two **`read -p`** prompts captured `system_reports` and `running_processes.txt`.
- **`mkdir -p`** created the directory and **`touch`** created the file — both confirmed by the final `ls -lR`, which shows `system_reports/running_processes.txt` at 4589 bytes.
- **`ps aux > "$DIR_NAME/$FILE_NAME"`** redirected the full process table into the file; `wc -l` counts **43 lines**, and `head -5` prints the saved content back to prove the redirection worked.

Note that `head -10` in the on-screen listing shows 10 lines, while the saved file holds all 43 processes — the redirection captured the complete `ps aux` output, not the truncated view.
