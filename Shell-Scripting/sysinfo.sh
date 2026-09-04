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
