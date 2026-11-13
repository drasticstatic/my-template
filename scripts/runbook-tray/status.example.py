#!/usr/bin/env python3
"""status.example.py: a status command to start from. One row per scheduled job, read from `launchctl list`.

    status.example.py LABEL[=NAME] ...        e.g.  status.example.py local.example.nightly="Nightly backup"

It prints the one JSON object the runbook tray reads (see runbook-tray.py). It reads launchd's list and changes
nothing. A job counts as good when its last exit status is 0; a job launchd does not list is bad.

Copy it, then add your own rows: a file's age, a port, a disk. Keep it quick (the tray asks every minute) and keep it
away from folders macOS guards (Desktop, Documents, Downloads, iCloud Drive), or the tray will raise a prompt.
"""
import json
import subprocess
import sys
import time


def loaded_jobs():
    """{label: (pid or "-", last exit status)} from `launchctl list`, or None when it did not run."""
    try:
        done = subprocess.run(["/bin/launchctl", "list"], capture_output=True, text=True, timeout=20)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if done.returncode != 0:
        return None
    jobs = {}
    for line in done.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) == 3:
            jobs[parts[2]] = (parts[0], parts[1])
    return jobs


def main(argv):
    wanted = [(arg.partition("=")[0], arg.partition("=")[2] or arg.partition("=")[0]) for arg in argv]
    jobs = loaded_jobs()
    rows = []
    for label, name in wanted:
        if jobs is None:
            row = {"state": "look", "detail": "launchctl did not run, so the job could not be read"}
        elif label not in jobs:
            row = {"state": "bad", "detail": "not loaded"}
        else:
            pid, status = jobs[label]
            detail = f"running, pid {pid}" if pid.isdigit() else "waiting for its time"
            row = {"state": "good", "detail": detail} if status == "0" else \
                  {"state": "bad", "detail": f"{detail}, last exit status {status}"}
        rows.append({"name": name, "group": "Scheduled jobs", **row})
    print(json.dumps({"when": time.strftime("%Y-%m-%d %H:%M:%S"), "rows": rows}, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
