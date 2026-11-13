#!/usr/bin/env python3
"""runbook-tray.py: the helper behind the menu-bar runbook tray. Python's standard library only.

    runbook-tray.py render --config FILE --state DIR [--print]   run the status command; write DIR/menu.json for the tray
    runbook-tray.py act ID --config FILE --state DIR             do one entry of the config: run its command, or open its page
    runbook-tray.py doctor --config FILE                         check the config and say what the tray would run; runs nothing
    runbook-tray.py stamp  --source FILE KEY=VALUE ...           print the applet's source with its @@KEY@@ marks filled (build.sh)

The tray itself (tray.applescript, compiled by build.sh) only draws. What it shows is decided here, so it can be
tested without a screen: runbook-tray.selftest.sh.

The status command is yours. It prints one JSON object:

    {"when": "2026-01-31 08:30:00", "result": "all good", "ok": true,
     "rows": [{"name": "nightly-backup", "state": "good", "detail": "waiting for its time", "group": "Scheduled jobs"}]}

A row's state is good, look, bad, off or unknown. "off" means not running and not expected to be; "unknown" means the
check cannot tell from where it runs. Both are shown and never counted. A row with "counted": false is shown with its
state and never raises the mark in the menu bar. With "fold": ["A group's name"] beside the status command in the
config, that group's rows sit in a submenu of their own, under one row that carries their worst state and counts them.

With "machine": true in the config, the menu also carries a section on this Mac itself: memory, swap, processor and
disk as meters, the last hour of memory as a small line, and which apps hold the most memory. It reads sysctl,
vm_stat, top and ps, names apps only (never their arguments), and keeps its samples in DIR/history.json (six hours)
and one line a minute in DIR/days/<date>.csv, which nothing removes: a record of each working day.

What this never does: schedule, edit or stop a scheduled job; ask for a password; run anything the config does not
name. Commands are lists of words and never pass through a shell. A config that another account on the machine could
write is refused. A command that runs past its timeout is stopped.

Exit: 0 done and good · 1 done, and something needs a look · 2 usage or config error.
"""
import argparse
import datetime
import fcntl
import json
import os
import re
import signal
import stat
import subprocess
import sys
import time

STATES = ("good", "look", "bad", "off", "unknown")
# state -> (SF Symbol, tint, mark used where a symbol cannot be drawn). Shape and colour both carry the state.
LOOKS = {
    "good": ("checkmark.circle.fill", "green", "✓"),
    "look": ("exclamationmark.triangle.fill", "amber", "!"),
    "bad": ("xmark.octagon.fill", "red", "✕"),
    "off": ("minus.circle", "grey", "–"),
    "unknown": ("questionmark.circle", "grey", "?"),
}
BAR_SYMBOL = "checklist"
DEFAULT_PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
DEFAULT_OPENER = ["/usr/bin/open"]
ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,39}$")
URL_RE = re.compile(r"^[a-z][a-z0-9+.-]*://")
MARK_RE = re.compile(r"@@([A-Z_]+)@@")
RUNNER_RE = re.compile(r"^(sh|bash|zsh|dash|python[\d.]*|node|ruby|perl|osascript)$")
MAX_OUTPUT = 1_000_000
LOG_TAIL = 200_000
TOP_KEYS = {"name", "path", "status", "entries", "stale_after_seconds", "open_with", "machine", "comment"}
MACHINE_KEYS = {"processes", "processes_every_seconds", "disk", "comment"}
GIB = 1024 ** 3
PRESSURE = {1: "normal", 2: "warning", 4: "critical"}       # kern.memorystatus_vm_pressure_level
PRESSURE_TINT = {1: "blue", 2: "amber", 4: "red"}           # a meter's fill carries severity; blue is "no alarm"
TINT_RANK = {"none": 0, "amber": 1, "red": 2}
ALIASES = {"com.apple.WebKit.WebContent": "WebKit web content", "com.apple.WebKit.GPU": "WebKit graphics",
           "com.apple.WebKit.Networking": "WebKit networking"}
HISTORY_SECONDS = 6 * 3600
DAY_HEADER = ("time,memory_used_gb,memory_total_gb,pressure,available_percent,swap_gb,app_gb,wired_gb,compressed_gb,"
              "held_in_compressed_gb,cached_gb,free_gb,processor_busy_percent,load_1m")
# Memory's parts are told apart by hue, never by a state colour: amber, red and green stay with state. Each is
# (light menu, dark menu). The three hues pass the charting validator as neighbours in this order, in both modes;
# cached files and free memory are greys, because they are what is not committed.
PART_COLOURS = {"app": ("#2a78d6", "#3987e5"), "wired": ("#e87ba4", "#d55181"), "compressed": ("#6250d6", "#9085e9"),
                "cached": ("#9a9aa0", "#7d7d83"), "free": ("#d4d4d8", "#4a4a4e")}
STATUS_KEYS = {"command", "timeout_seconds", "fold", "comment"}
# how the row of a folded group counts what is under it, in this order
FOLD_WORDS = (("good", "good"), ("off", "off"), ("look", "to look at"), ("bad", "failing"), ("unknown", "not checked"))
ENTRY_KEYS = {"id", "title", "command", "open", "timeout_seconds", "summary", "ok_exit_codes", "separator", "comment"}


class ConfigError(Exception):
    """The config cannot be used; the message says why in words for the person who wrote it."""


# ---------- small helpers ----------

def one_line(text, limit):
    """Any value as one line of printable text, cut to limit characters."""
    flat = " ".join("".join(ch if ch.isprintable() else " " for ch in str(text)).split())
    return flat if len(flat) <= limit else flat[: limit - 1].rstrip() + "…"


def home(text):
    return os.path.expanduser(text) if text == "~" or text.startswith("~/") else text


def clock(epoch, now):
    """09:41 for today, Nov 12 23:10 for another day."""
    then, today = datetime.datetime.fromtimestamp(epoch), datetime.datetime.fromtimestamp(now)
    if then.date() == today.date():
        return f"{then:%H:%M}"
    return f"{then:%b} {then.day} {then:%H:%M}"


def write_json(path, data):
    """Whole file or nothing: written beside the target, then moved over it."""
    tmp = f"{path}.{os.getpid()}.tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    os.replace(tmp, path)


def read_json(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return None


def ensure_dir(path):
    """The tray's own folder, readable by its owner alone: it holds the output of the commands it ran."""
    os.makedirs(path, mode=0o700, exist_ok=True)
    try:
        os.chmod(path, 0o700)
    except OSError:
        pass
    return path


# ---------- the config ----------

def only_mine(path):
    st = os.stat(path)
    if st.st_uid not in (os.getuid(), 0):
        raise ConfigError(f"{path} belongs to another account; the tray runs only a config that is yours")
    if st.st_mode & (stat.S_IWGRP | stat.S_IWOTH):
        raise ConfigError(f"{path} can be written by other accounts on this machine; run chmod go-w on it, then try again")


def whole(value, low, high, default, where):
    if value is None:
        return default
    if isinstance(value, bool) or not isinstance(value, int) or not low <= value <= high:
        raise ConfigError(f"{where} must be a whole number from {low} to {high}")
    return value


def words(value, where):
    if not isinstance(value, list) or not value or not all(isinstance(a, str) and a for a in value):
        raise ConfigError(f'{where} must be a list of words, like ["/bin/sh", "/path/to/script.sh"]')
    argv = [home(a) for a in value]
    if not os.path.isabs(argv[0]):
        raise ConfigError(f"{where}: the first word must be a full path, and {value[0]!r} is not")
    return argv


def known(data, allowed, where):
    if not isinstance(data, dict):
        raise ConfigError(f"{where} must be a set of named values in braces")
    extra = sorted(set(data) - allowed)
    if extra:
        raise ConfigError(f"{where} has a name the tray does not know: {', '.join(extra)}")


def load_config(path):
    path = os.path.abspath(home(path))
    if not os.path.isfile(path):
        raise ConfigError(f"no config at {path}")
    only_mine(path)
    only_mine(os.path.dirname(path))
    try:
        with open(path, encoding="utf-8") as fh:
            raw = json.load(fh)
    except (OSError, ValueError) as exc:
        raise ConfigError(f"{path} is not readable JSON: {exc}")
    known(raw, TOP_KEYS, "the config")
    name = raw.get("name", "Runbook")
    if not isinstance(name, str) or not name.strip() or len(name) > 40:
        raise ConfigError("name must be 1 to 40 characters")
    search = raw.get("path", DEFAULT_PATH)
    if not isinstance(search, str) or not search:
        raise ConfigError("path must be a colon-separated list of folders")
    if "status" not in raw:
        raise ConfigError("the config needs a status command")
    known(raw["status"], STATUS_KEYS, "status")
    fold = raw["status"].get("fold", [])
    if not isinstance(fold, list) or not all(isinstance(g, str) and g.strip() and len(g) <= 60 for g in fold):
        raise ConfigError("status.fold must be a list of group names")
    cfg = {
        "file": path, "name": name.strip(), "path": search,
        "status": {"command": words(raw["status"].get("command"), "status.command"),
                   "timeout": whole(raw["status"].get("timeout_seconds"), 1, 600, 30, "status.timeout_seconds"),
                   "fold": [g.strip() for g in fold]},
        "stale_after": whole(raw.get("stale_after_seconds"), 60, 86400, 300, "stale_after_seconds"),
        "opener": words(raw.get("open_with", DEFAULT_OPENER), "open_with"),
        "machine": None,
        "entries": [],
    }
    machine = raw.get("machine", False)
    if machine is True:
        machine = {}
    if machine is not False:
        known(machine, MACHINE_KEYS, "machine")
        disk = machine.get("disk", "")
        if not isinstance(disk, str):
            raise ConfigError("machine.disk must be a folder on the disk to measure")
        cfg["machine"] = {
            "processes": whole(machine.get("processes"), 0, 20, 8, "machine.processes"),
            "processes_every": whole(machine.get("processes_every_seconds"), 60, 3600, 300,
                                     "machine.processes_every_seconds"),
            "disk": home(disk)}
    entries = raw.get("entries", [])
    if not isinstance(entries, list):
        raise ConfigError("entries must be a list")
    seen = set()
    for n, item in enumerate(entries, 1):
        where = f"entry {n}"
        known(item, ENTRY_KEYS, where)
        if item.get("separator") is True:
            cfg["entries"].append({"separator": True})
            continue
        ident, title = item.get("id"), item.get("title")
        if not isinstance(ident, str) or not ID_RE.match(ident):
            raise ConfigError(f"{where}: id must be lower-case letters, digits and hyphens, at most 40")
        if ident in seen:
            raise ConfigError(f"{where}: the id {ident!r} is used twice")
        seen.add(ident)
        where = f"entry {ident!r}"
        if not isinstance(title, str) or not title.strip() or len(title) > 80:
            raise ConfigError(f"{where}: title must be 1 to 80 characters")
        if ("command" in item) == ("open" in item):
            raise ConfigError(f"{where} needs exactly one of command or open")
        entry = {"id": ident, "title": title.strip()}
        if "open" in item:
            if not isinstance(item["open"], str) or not item["open"]:
                raise ConfigError(f"{where}: open must be a path or an address")
            entry.update(kind="open", open=item["open"])
        else:
            summary = item.get("summary", "last-line")
            if summary not in ("first-line", "last-line"):
                raise ConfigError(f"{where}: summary is first-line or last-line")
            codes = item.get("ok_exit_codes", [0])
            if not isinstance(codes, list) or not codes or not all(isinstance(c, int) and not isinstance(c, bool) for c in codes):
                raise ConfigError(f"{where}: ok_exit_codes must be a list of whole numbers")
            entry.update(kind="command", command=words(item["command"], f"{where}: command"), summary=summary, ok=codes,
                         timeout=whole(item.get("timeout_seconds"), 1, 3600, 300, f"{where}: timeout_seconds"))
        cfg["entries"].append(entry)
    return cfg


# ---------- running things ----------

def child_env(cfg):
    env = {"PATH": cfg["path"], "HOME": os.path.expanduser("~"), "LANG": "en_US.UTF-8", "LC_ALL": "en_US.UTF-8"}
    for key in ("USER", "LOGNAME", "TMPDIR", "SHELL"):
        if key in os.environ:
            env[key] = os.environ[key]
    return env


def run_words(argv, env, timeout, merge):
    """Run a command. Returns (exit code or None, stdout text, stderr text, note). Never raises, never uses a shell."""
    try:
        proc = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT if merge else subprocess.PIPE,
                                env=env, cwd=env["HOME"], start_new_session=True)
    except OSError as exc:
        return None, "", "", f"could not start: {exc.strerror or exc}"
    note = ""
    try:
        out, err = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        note = f"stopped after {timeout} s without finishing"
        for sig, wait in ((signal.SIGTERM, 5), (signal.SIGKILL, None)):
            try:
                os.killpg(proc.pid, sig)
            except OSError:
                pass
            try:
                out, err = proc.communicate(timeout=wait)
                break
            except subprocess.TimeoutExpired:
                continue
    text = lambda b: (b or b"")[:MAX_OUTPUT].decode("utf-8", "replace")
    return (None if note else proc.returncode), text(out), text(err), note


def read_status(cfg):
    """(status or None, why not). The status is checked and tidied, so the tray can trust its shape."""
    code, out, err, note = run_words(cfg["status"]["command"], child_env(cfg), cfg["status"]["timeout"], merge=False)
    if code is None:
        return None, f"the status command {note}"
    try:
        data = json.loads(out)
    except ValueError:
        said = one_line(err or out, 120)
        return None, f"the status command did not print JSON (exit {code})" + (f": {said}" if said else "")
    if not isinstance(data, dict) or not isinstance(data.get("rows"), list):
        return None, 'the status command printed JSON without a "rows" list'
    rows = []
    for row in data["rows"]:
        if not isinstance(row, dict) or not one_line(row.get("name", ""), 80):
            continue
        state, detail = row.get("state"), one_line(row.get("detail", ""), 300)
        if state not in STATES:
            detail, state = one_line(f"state {state!r} is not one the tray knows; {detail}", 300), "look"
        rows.append({"name": one_line(row["name"], 80), "state": state, "detail": detail,
                     "group": one_line(row.get("group", ""), 60), "counted": row.get("counted") is not False})
    need = [r for r in rows if r["counted"] and r["state"] in ("bad", "look")]
    if need:
        line = f"{len(need)} need{'s' if len(need) == 1 else ''} a look: " + ", ".join(r["name"] for r in need)
    else:
        line = "all good"
    return {"when": one_line(data.get("when", ""), 40), "result": one_line(line, 200), "rows": rows}, ""


# ---------- this Mac: memory, swap, processor, disk ----------

def tool_text(argv, timeout=10):
    """What one of macOS's own tools prints, or an empty string. Numbers are asked for in the C locale."""
    env = {"PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "HOME": os.path.expanduser("~"), "LANG": "C", "LC_ALL": "C"}
    code, out, _, _ = run_words(argv, env, timeout, merge=False)
    return out if code == 0 else ""


def parse_sysctl(text):
    facts = {}
    for line in text.splitlines():
        key, sep, value = line.partition(":")
        if sep:
            facts[key.strip()] = value.strip()
    return facts


def parse_vm_stat(text):
    """vm_stat's page counts as bytes, keyed by its own labels in lower case."""
    size = re.search(r"page size of (\d+) bytes", text)
    page = int(size.group(1)) if size else 4096
    counts = {}
    for line in text.splitlines():
        key, sep, value = line.partition(":")
        value = value.strip().rstrip(".")
        if sep and value.isdigit():
            counts[key.strip().strip('"').lower()] = int(value) * page
    return counts


def memory_facts(sysctl_text, vm_text):
    """Memory, swap, load and cores from `sysctl` and `vm_stat`. Used is app memory + wired + compressed."""
    facts, pages = parse_sysctl(sysctl_text), parse_vm_stat(vm_text)
    if not facts.get("hw.memsize", "").isdigit() or "pages wired down" not in pages:
        return None
    total = int(facts["hw.memsize"])
    wired, packed = pages["pages wired down"], pages.get("pages occupied by compressor", 0)
    if "anonymous pages" in pages:
        app = max(0, pages["anonymous pages"] - pages.get("pages purgeable", 0))
    else:
        app = pages.get("pages active", 0)
    swap = re.search(r"total = ([\d.]+)M\s+used = ([\d.]+)M", facts.get("vm.swapusage", ""))
    load = re.findall(r"\d+(?:\.\d+)?", facts.get("vm.loadavg", ""))
    level = facts.get("kern.memorystatus_vm_pressure_level", "")
    cores = facts.get("hw.logicalcpu", "")
    headroom = facts.get("kern.memorystatus_level", "")
    return {"total": total, "used": min(total, app + wired + packed), "app": app, "wired": wired, "compressed": packed,
            "cached": pages.get("file-backed pages", 0) + pages.get("pages purgeable", 0),
            "free": pages.get("pages free", 0) + pages.get("pages speculative", 0),
            "stored": pages.get("pages stored in compressor", 0),
            "headroom": int(headroom) if headroom.isdigit() and int(headroom) <= 100 else None,
            "swap_used": int(float(swap.group(2)) * 1024 * 1024) if swap else None,
            "pressure": int(level) if level.isdigit() and int(level) in PRESSURE else 0,
            "cores": int(cores) if cores.isdigit() else 0, "load": float(load[0]) if load else None}


def cpu_ticks():
    """The kernel's running count of processor ticks, [user, system, idle, nice], or None where it cannot be read."""
    if sys.platform != "darwin":
        return None
    try:
        import ctypes
        lib = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
        lib.mach_host_self.restype = ctypes.c_uint
        ticks, count = (ctypes.c_uint * 4)(), ctypes.c_uint(4)
        if lib.host_statistics(lib.mach_host_self(), 3, ctypes.byref(ticks), ctypes.byref(count)) != 0:   # 3: CPU load
            return None
        return list(ticks)
    except Exception:
        return None


def busy_between(before, after):
    """The share of processor time that was not idle between two tick counts (each wraps at 2**32), or None."""
    if not before or not after or len(before) != 4 or len(after) != 4:
        return None
    user, system, idle, nice = ((b - a) % (2 ** 32) for a, b in zip(before, after))
    spent = user + system + idle + nice
    return (user + system + nice) / spent if spent else None


def busy_since(samples, ticks, now):
    """The busy share since the newest earlier sample that is 5 s to 15 min old, or None."""
    recent = [s for s in samples[:-1] if s.get("cpu") and 5 <= now - s["t"] <= 900]
    return busy_between(recent[-1]["cpu"], ticks) if recent else None


def day_line(mem, busy, now):
    """One line of the day's record, in the order of DAY_HEADER: the time, then this Mac's memory in GB."""
    def gb(size):
        return "" if size is None else f"{size / GIB:.2f}"
    return ",".join([
        f"{datetime.datetime.fromtimestamp(now):%Y-%m-%d %H:%M:%S}", gb(mem["used"]), gb(mem["total"]),
        PRESSURE.get(mem["pressure"], ""), "" if mem.get("headroom") is None else str(mem["headroom"]),
        gb(mem["swap_used"]), gb(mem["app"]), gb(mem["wired"]), gb(mem["compressed"]), gb(mem.get("stored")),
        gb(mem.get("cached")), gb(mem.get("free")), "" if busy is None else f"{busy * 100:.0f}",
        "" if mem["load"] is None else f"{mem['load']:.2f}"])


def keep_day(state_dir, line, now):
    """Add the line to today's file, starting the file with its header. Nothing here removes a day."""
    path = os.path.join(ensure_dir(os.path.join(state_dir, "days")), f"{datetime.datetime.fromtimestamp(now):%Y-%m-%d}.csv")
    new = not os.path.exists(path)
    with open(path, "a", encoding="utf-8") as fh:
        if new:
            fh.write(DAY_HEADER + "\n")
        fh.write(line + "\n")


def disk_facts(df_text):
    """Used and free from the last line of `df -k <folder>`, so the figure is the one df and the Finder give."""
    lines = [ln.split() for ln in df_text.strip().splitlines()]
    if len(lines) < 2 or len(lines[-1]) < 5:
        return None
    try:
        used, free = int(lines[-1][2]) * 1024, int(lines[-1][3]) * 1024
        percent = int(lines[-1][4].rstrip("%"))
    except ValueError:
        return None
    if used + free <= 0:
        return None
    return {"used": used, "free": free, "fraction": used / (used + free), "percent": percent}


def parse_top(text):
    """{pid: bytes} from `top -l 1 -stats pid,mem`: top's MEM is the memory an app holds, compressed part included."""
    held, started = {}, False
    for line in text.splitlines():
        parts = line.split()
        if parts[:2] == ["PID", "MEM"]:
            started = True
        elif started and len(parts) == 2 and parts[0].isdigit():
            size = re.fullmatch(r"(\d+(?:\.\d+)?)([BKMG])[+-]?", parts[1])
            if size:
                held[int(parts[0])] = int(float(size.group(1)) * 1024 ** "BKMG".index(size.group(2)))
    return held


def parse_names(text):
    """{pid: name} from `ps -axo pid=,comm=`. A helper is counted with its app; arguments are never read."""
    names = {}
    for line in text.splitlines():
        pid, _, path = line.strip().partition(" ")
        path = path.strip()
        if not pid.isdigit() or not path:
            continue
        app = re.search(r"/([^/]+)\.app/", path)
        name = app.group(1) if app else os.path.basename(path)
        names[int(pid)] = one_line(ALIASES.get(name, name), 60)
    return names


def group_memory(held, names, limit):
    """[name, how many processes, bytes] for the apps holding the most memory, largest first."""
    totals = {}
    for pid, size in held.items():
        if pid in names:
            entry = totals.setdefault(names[pid], [0, 0])
            entry[0] += 1
            entry[1] += size
    rows = sorted(([name, count, size] for name, (count, size) in totals.items()), key=lambda r: (-r[2], r[0]))
    return rows[:limit]


def moved(now_bytes, then_bytes):
    change = (now_bytes - then_bytes) / GIB
    if abs(change) < 0.05:
        return "steady"
    return f"{'up' if change > 0 else 'down'} {abs(change):.1f} GB"


def earlier(samples, now):
    """(the sample to compare with, in words how long ago): about an hour back, or less while the record is short."""
    fit = [s for s in samples if 600 <= now - s["t"] <= 4500]
    if not fit:
        return None, ""
    then = min(fit, key=lambda s: abs(now - s["t"] - 3600))
    age = now - then["t"]
    return then, "in the last hour" if age >= 3000 else f"in the last {round(age / 60)} min"


def last_hour(samples, now):
    """Memory used, as a share of the whole, in one-minute steps over the last hour (steps with no sample left out)."""
    steps = {}
    for s in samples:
        if 0 <= now - s["t"] <= 3600 and s.get("total"):
            steps.setdefault(int((s["t"] - (now - 3600)) // 60), []).append(s["mem"] / s["total"])
    return [round(sum(v) / len(v), 4) for _, v in sorted(steps.items())]


def meter(title, subtitle, value, tint):
    return {"kind": "meter", "title": title, "subtitle": subtitle, "tint": tint,
            "value": round(max(0.0, min(1.0, value)), 4)}


def memory_parts(mem):
    """Memory part by part, as a submenu: one bar split into its parts, a line for each, and the kernel's own reading."""
    total = mem["total"]
    held = f"holding {mem['stored'] / GIB:.1f} GB of app data, squeezed" if mem.get("stored") else "squeezed to make room"
    lines = [("app", "App memory", "what apps hold and are using"),
             ("wired", "Wired", "what macOS must keep in memory; it cannot be squeezed or moved"),
             ("compressed", "Compressed", held),
             ("cached", "Cached files", "kept for speed, and given back the moment something needs it"),
             ("free", "Free", "not in use")]
    parts, rows = [], []
    for key, name, what in lines:
        size = mem.get(key, 0)
        light, dark = PART_COLOURS[key]
        parts.append({"name": name, "value": round(max(0.0, min(1.0, size / total)), 4), "light": light, "dark": dark})
        rows.append({"kind": "swatch", "title": name, "subtitle": f"{size / GIB:.1f} GB · {what}", "light": light, "dark": dark})
    items = [{"kind": "parts", "title": "", "subtitle": "", "parts": parts}] + rows
    word = PRESSURE.get(mem["pressure"], "")
    if word:
        state = {1: "good", 2: "look", 4: "bad"}[mem["pressure"]]
        note = "the kernel's own level, the one the memory bar's colour follows"
        if mem.get("headroom") is not None:
            note = f"the kernel counts {mem['headroom']}% of memory as available"
        items += [{"kind": "separator"}, info(f"Pressure: {word}", note, state)]
    short = " · ".join(f"{name.split()[0].lower()} {mem.get(key, 0) / GIB:.1f}" for key, name, _ in lines[:4]) + " GB"
    return {"kind": "group", "title": "Memory, part by part", "subtitle": short, "parts": parts, "items": items}


def machine_section(mem, disk, ticks, samples, groups, groups_at, now):
    """(menu items, what the menu bar shows). Pure: everything it needs is handed to it."""
    used, total = mem["used"], mem["total"]
    word = PRESSURE.get(mem["pressure"], "")
    items = [{"kind": "header", "title": "This Mac"}]
    note = f"{used / GIB:.1f} of {total / GIB:.0f} GB used" + (f" · pressure {word}" if word else "")
    items.append(meter("Memory", note, used / total, PRESSURE_TINT.get(mem["pressure"], "blue")))
    if "cached" in mem:
        items.append(memory_parts(mem))
    then, span = earlier(samples, now)
    if mem["swap_used"] is not None:
        note = f"{mem['swap_used'] / GIB:.1f} GB in use"
        if then and then.get("swap") is not None:
            note += f" · {moved(mem['swap_used'], then['swap'])} {span}"
        items.append(meter("Swap", note, mem["swap_used"] / total, "blue"))     # against the size of memory
    busy = busy_since(samples, ticks, now)
    load = f"load {mem['load']:.1f} on {mem['cores']} cores" if mem["load"] is not None and mem["cores"] else ""
    if busy is not None:
        items.append(meter("Processor", f"{busy:.0%} busy since the last check" + (f" · {load}" if load else ""), busy, "blue"))
    elif load:
        items.append(meter("Processor", load, mem["load"] / mem["cores"], "blue"))
    if disk:
        items.append(meter("Disk", f"{disk['percent']}% used · {disk['free'] / GIB:.0f} GiB free",
                           disk["fraction"], "blue"))
    line = last_hour(samples, now)
    if len(line) >= 3:
        note = f"between {min(line):.0%} and {max(line):.0%}"
        if then:
            note += f" · {moved(used, then['mem'])} {span}"
        minutes = round((now - min(s["t"] for s in samples if now - s["t"] <= 3600)) / 60)
        title = "Memory, last hour" if minutes >= 50 else f"Memory, last {minutes} min"
        items.append({"kind": "spark", "title": title, "subtitle": note, "values": line, "tint": "blue"})
    if groups:
        top = groups[0][2] or 1
        rows = [meter(name if count == 1 else f"{name} × {count}", f"{size / GIB:.1f} GB", size / top, "grey")
                for name, count, size in groups]
        items.append({"kind": "group", "title": "What is holding the most memory",
                      "subtitle": f"as of {clock(groups_at, now)}", "items": rows})
    bar = {"gauge": round(used / total, 4), "tint": {2: "amber", 4: "red"}.get(mem["pressure"], "none"),
           "tooltip": f"memory {used / total:.0%} used" + (f", pressure {word}" if word else "")}
    return items, bar


def read_machine(cfg, state_dir, now):
    """This Mac's section, read now. ([], None) where it is not asked for or cannot be read (another system)."""
    opts = cfg["machine"]
    if opts is None or sys.platform != "darwin":
        return [], None
    mem = memory_facts(tool_text(["/usr/sbin/sysctl", "hw.memsize", "hw.logicalcpu", "vm.loadavg", "vm.swapusage",
                                  "kern.memorystatus_vm_pressure_level", "kern.memorystatus_level"]),
                       tool_text(["/usr/bin/vm_stat"]))
    if mem is None:
        return [], None
    ticks = cpu_ticks()
    kept = read_json(os.path.join(state_dir, "history.json"))
    samples = [s for s in (kept.get("samples", []) if isinstance(kept, dict) else [])
               if isinstance(s, dict) and isinstance(s.get("t"), (int, float)) and isinstance(s.get("mem"), (int, float))
               and 0 <= now - s["t"] <= HISTORY_SECONDS]
    samples.append({"t": int(now), "mem": mem["used"], "total": mem["total"], "swap": mem["swap_used"], "cpu": ticks})
    samples = samples[-720:]
    write_json(os.path.join(state_dir, "history.json"), {"samples": samples})
    keep_day(state_dir, day_line(mem, busy_since(samples, ticks, now), now), now)
    groups, groups_at = [], now
    if opts["processes"]:
        cache_path = os.path.join(state_dir, "processes.json")
        cache = read_json(cache_path)
        if not (isinstance(cache, dict) and isinstance(cache.get("groups"), list)
                and 0 <= now - cache.get("t", 0) < opts["processes_every"]):
            held = parse_top(tool_text(["/usr/bin/top", "-l", "1", "-o", "mem", "-stats", "pid,mem"], timeout=30))
            names = parse_names(tool_text(["/bin/ps", "-axo", "pid=,comm="]))
            if held and names:
                cache = {"t": int(now), "groups": group_memory(held, names, 20)}
                write_json(cache_path, cache)
        if isinstance(cache, dict) and isinstance(cache.get("groups"), list):
            groups, groups_at = cache["groups"][:opts["processes"]], cache.get("t", now)
    disk_path = opts["disk"] or ("/System/Volumes/Data" if os.path.isdir("/System/Volumes/Data") else "/")
    disk = disk_facts(tool_text(["/bin/df", "-k", disk_path]))
    return machine_section(mem, disk, ticks, samples, groups, groups_at, now)


# ---------- what the tray draws ----------

def info(title, subtitle, state):
    symbol, tint, mark = LOOKS[state]
    return {"kind": "info", "title": title, "subtitle": subtitle, "state": state,
            "symbol": symbol, "tint": tint, "mark": mark}


def is_running(lock_path):
    """True while another process holds the entry's lock."""
    try:
        with open(lock_path, "a") as fh:
            try:
                fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError:
                return True
            fcntl.flock(fh, fcntl.LOCK_UN)
    except OSError:
        pass
    return False


def entry_note(rec, running, now):
    """(subtitle, can it be chosen) for one entry, from the record of its last run."""
    if not isinstance(rec, dict) or not isinstance(rec.get("started"), (int, float)):
        return ("running", False) if running else ("", True)
    if running:
        return f"running since {clock(rec['started'], now)}", False
    if rec.get("running"):
        return f"started {clock(rec['started'], now)} and did not finish", True
    when = clock(rec.get("finished") or rec["started"], now)
    if rec.get("kind") == "open":
        return (f"opened {when}" if rec.get("ok") else f"{when} · {one_line(rec.get('note', 'not opened'), 120)}"), True
    bits = [when]
    if rec.get("note"):
        bits.append(one_line(rec["note"], 120))
    else:
        if rec.get("summary"):
            summary = one_line(rec["summary"], 120)
            if summary.startswith(when):   # the command's own line already begins with the time
                bits = []
            bits.append(summary)
        if not rec.get("ok"):
            bits.append(f"exit {rec.get('exit')}")
    return " · ".join(bits), True


def fold_group(title, rows):
    """One row for a folded group: the worst state among its rows as its mark, and how many rows are in each state."""
    worst = next(s for s in ("bad", "look", "good", "off", "unknown") if any(r["state"] == s for r in rows))
    symbol, tint, mark = LOOKS[worst]
    counts = [(sum(1 for r in rows if r["state"] == state), word) for state, word in FOLD_WORDS]
    return {"kind": "group", "title": title, "subtitle": " · ".join(f"{n} {word}" for n, word in counts if n),
            "state": worst, "symbol": symbol, "tint": tint, "mark": mark,
            "items": [info(r["name"], r["detail"], r["state"]) for r in rows]}


def build_model(cfg, status, problem, state_dir, now, machine=None):
    """machine is (items, bar) from machine_section, or None to read this Mac now when the config asks for it."""
    items = []
    if status is None:
        bar = {"symbol": BAR_SYMBOL, "tint": "none", "text": "?", "tooltip": f"{cfg['name']}: {problem}"}
        items.append(info("The check did not run", one_line(problem, 300), "unknown"))
    else:
        counted = [r for r in status["rows"] if r.get("counted", True)]
        bad = sum(1 for r in counted if r["state"] == "bad")
        look = sum(1 for r in counted if r["state"] == "look")
        worst = "bad" if bad else "look" if look else "good"
        checked = f"checked {datetime.datetime.fromtimestamp(now):%H:%M:%S}"
        bar = {"symbol": BAR_SYMBOL, "tint": {"bad": "red", "look": "amber", "good": "none"}[worst],
               "text": str(bad + look) if bad + look else "",
               "tooltip": f"{cfg['name']}: {status['result']}, {checked}"}
        head = status["result"][:1].upper() + status["result"][1:]
        items.append(info(head, checked, worst))
        fold = (cfg.get("status") or {}).get("fold", [])
        previous = None
        for row in status["rows"]:
            if row["group"] in fold:
                continue
            if row["group"] != previous:
                items.append({"kind": "header", "title": row["group"]} if row["group"] else {"kind": "separator"})
                previous = row["group"]
            items.append(info(row["name"], row["detail"], row["state"]))
        folded = [(name, [r for r in status["rows"] if r["group"] == name]) for name in fold]
        if any(rows for _, rows in folded):
            items.append({"kind": "separator"})
        items += [fold_group(name, rows) for name, rows in folded if rows]
    more, gauge = machine if machine is not None else read_machine(cfg, state_dir, now)
    items += more
    if gauge:
        bar["gauge"] = gauge["gauge"]
        bar["tooltip"] += " · " + gauge["tooltip"]
        if TINT_RANK[gauge["tint"]] > TINT_RANK[bar["tint"]]:
            bar["tint"] = gauge["tint"]
    if cfg["entries"]:
        items.append({"kind": "separator"})
    for entry in cfg["entries"]:
        if entry.get("separator"):
            items.append({"kind": "separator"})
            continue
        base = os.path.join(state_dir, "actions", entry["id"])
        subtitle, free = entry_note(read_json(base + ".json"), is_running(base + ".lock"), now)
        symbol = "hourglass" if not free else "play.circle" if entry["kind"] == "command" else "arrow.up.right.square"
        items.append({"kind": "action", "id": entry["id"], "title": entry["title"], "subtitle": subtitle,
                      "enabled": free, "symbol": symbol})
    return {"version": 1, "name": cfg["name"], "epoch": int(now), "stale_after": cfg["stale_after"],
            "bar": bar, "items": items}


def problem_model(name, problem, now):
    return {"version": 1, "name": name, "epoch": int(now), "stale_after": 300,
            "bar": {"symbol": BAR_SYMBOL, "tint": "none", "text": "?", "tooltip": f"{name}: {problem}"},
            "items": [info("The tray's config has a problem", one_line(problem, 300), "unknown")]}


def as_text(model):
    """The menu as plain text, for --print and for people without the tray in front of them."""
    bar = model["bar"]
    out = [f"[{bar['symbol']}{' ' + bar['tint'] if bar['tint'] != 'none' else ''}] {bar['text']}".rstrip()
           + f"    {bar['tooltip']}"]
    if "gauge" in bar:
        out[0] += f"    [gauge {bar['gauge']:.0%}]"

    def line(item, indent):
        tail = f"  ·  {item['subtitle']}" if item.get("subtitle") else ""
        if item["kind"] == "separator":
            out.append(indent + "─" * 20)
        elif item["kind"] == "header":
            out.append(indent + item["title"].upper())
        elif item["kind"] == "meter":
            filled = round(item["value"] * 10)
            out.append(f"{indent}{'▰' * filled}{'▱' * (10 - filled)} {item['title']}{tail}")
        elif item["kind"] == "spark":
            low, high = min(item["values"]), max(item["values"])
            steps = "".join("▁▂▃▄▅▆▇█"[min(7, int((v - low) / ((high - low) or 1) * 8))] for v in item["values"])
            out.append(f"{indent}{steps} {item['title']}{tail}")
        elif item["kind"] == "parts":
            cells = "".join(mark * round(part["value"] * 30) for mark, part in zip("█▓▒░·", item["parts"]))
            out.append(f"{indent}{cells}")
        elif item["kind"] == "swatch":
            out.append(f"{indent}■ {item['title']}{tail}")
        elif item["kind"] == "group":
            out.append(f"{indent}▾ {item['mark'] + ' ' if item.get('mark') else ''}{item['title']}{tail}")
            for child in item["items"]:
                line(child, indent + "    ")
        else:
            lead = item["mark"] if item["kind"] == "info" else ("▸" if item.get("enabled", True) else "…")
            out.append(f"{indent}{lead} {item['title']}{tail}")

    for item in model["items"]:
        line(item, "  ")
    return "\n".join(out)


# ---------- the commands ----------

def cmd_render(args):
    now = time.time()
    state_dir = ensure_dir(os.path.abspath(home(args.state)))
    try:
        cfg = load_config(args.config)
    except ConfigError as exc:
        model = problem_model("Runbook", str(exc), now)
        write_json(os.path.join(state_dir, "menu.json"), model)
        print(f"runbook-tray: {exc}", file=sys.stderr)
        return 2
    status, problem = read_status(cfg)
    model = build_model(cfg, status, problem, state_dir, now)
    write_json(os.path.join(state_dir, "menu.json"), model)
    if status is not None:
        write_json(os.path.join(state_dir, "status.json"), status)
    if args.print:
        print(as_text(model))
    return 0 if status is not None and model["bar"]["text"] == "" else 1


def cmd_act(args):
    now = time.time()
    try:
        cfg = load_config(args.config)
    except ConfigError as exc:
        print(f"runbook-tray: {exc}", file=sys.stderr)
        return 2
    entry = next((e for e in cfg["entries"] if e.get("id") == args.id), None)
    if entry is None:
        print(f"runbook-tray: the config has no entry {args.id!r}", file=sys.stderr)
        return 2
    base = os.path.join(ensure_dir(os.path.join(os.path.abspath(home(args.state)), "actions")), entry["id"])
    env = child_env(cfg)
    if entry["kind"] == "open":
        target = home(entry["open"].replace("{date}", f"{datetime.datetime.fromtimestamp(now):%Y-%m-%d}"))
        rec = {"id": entry["id"], "kind": "open", "started": int(now), "finished": int(now), "target": target}
        if not URL_RE.match(target) and not os.path.exists(target):
            rec.update(ok=False, note="not there yet")
        else:
            code, out, _, note = run_words(cfg["opener"] + [target], env, 20, merge=True)
            rec.update(ok=code == 0, note="" if code == 0 else (note or one_line(out, 120) or f"exit {code}"))
        write_json(base + ".json", rec)
        print(f"{entry['id']}: {'opened ' + target if rec['ok'] else rec['note'] + ': ' + target}")
        return 0 if rec["ok"] else 1
    lock = open(base + ".lock", "a")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        print(f"{entry['id']}: already running")
        return 0
    rec = {"id": entry["id"], "kind": "command", "running": True, "pid": os.getpid(), "started": int(now)}
    write_json(base + ".json", rec)
    code, out, _, note = run_words(entry["command"], env, entry["timeout"], merge=True)
    done = time.time()
    with open(base + ".log", "w", encoding="utf-8") as fh:
        fh.write(f"{datetime.datetime.fromtimestamp(now):%Y-%m-%d %H:%M:%S}  {' '.join(entry['command'])}\n")
        fh.write(out[-LOG_TAIL:])
        fh.write(f"\n[{note or 'exit ' + str(code)}, {done - now:.1f} s]\n")
    lines = [ln.strip().lstrip("#").strip() for ln in out.splitlines()]
    lines = [ln for ln in lines if ln]
    summary = one_line(lines[0] if entry["summary"] == "first-line" else lines[-1], 100) if lines else ""
    rec.update(running=False, finished=int(done), exit=code, ok=code in entry["ok"], summary=summary, note=note)
    write_json(base + ".json", rec)
    print(f"{entry['id']}: {note or 'exit ' + str(code)}" + (f" · {summary}" if summary else ""))
    return 0 if rec["ok"] else 1


def cmd_doctor(args):
    try:
        cfg = load_config(args.config)
    except ConfigError as exc:
        print(f"runbook-tray: {exc}", file=sys.stderr)
        return 2
    trouble = 0

    def found(argv):
        nonlocal trouble
        if not (os.path.isfile(argv[0]) and os.access(argv[0], os.X_OK)):
            trouble += 1
            return "NOT FOUND or not runnable"
        if RUNNER_RE.match(os.path.basename(argv[0])):      # sh, python and the like: the script they are handed
            script = next((word for word in argv[1:] if not word.startswith("-")), None)
            if script and not os.path.isfile(script):
                trouble += 1
                return f"its script is NOT FOUND: {script}"
        return "found"

    print(f"config   {cfg['file']}   (only you can write it)")
    print(f"name     {cfg['name']}")
    print(f"PATH     {cfg['path']}   (what the commands below are given)")
    print(f"status   {' '.join(cfg['status']['command'])}   [{found(cfg['status']['command'])}; up to {cfg['status']['timeout']} s]")
    for entry in cfg["entries"]:
        if entry.get("separator"):
            continue
        if entry["kind"] == "open":
            target = home(entry["open"])
            there = "an address" if URL_RE.match(target) else ("a dated page" if "{date}" in target else
                                                               "there" if os.path.exists(target) else "not there yet")
            print(f"entry    {entry['id']}: \"{entry['title']}\" opens {target}   [{there}]")
        else:
            print(f"entry    {entry['id']}: \"{entry['title']}\" runs {' '.join(entry['command'])}   "
                  f"[{found(entry['command'])}; up to {entry['timeout']} s]")
    print("doctor: " + ("the config is usable" if not trouble else f"{trouble} command(s) cannot be run as written"))
    return 0 if not trouble else 2


def cmd_stamp(args):
    try:
        with open(args.source, encoding="utf-8") as fh:
            source = fh.read()
    except OSError as exc:
        print(f"runbook-tray: cannot read {args.source}: {exc.strerror}", file=sys.stderr)
        return 2
    values = {}
    for pair in args.pairs:
        key, sep, value = pair.partition("=")
        if not sep or not re.fullmatch(r"[A-Z_]+", key) or "\n" in value or "\r" in value:
            print(f"runbook-tray: stamp wants KEY=VALUE on one line, got {pair!r}", file=sys.stderr)
            return 2
        values[key] = value.replace("\\", "\\\\").replace('"', '\\"')   # as it must read inside an AppleScript string
    missing = sorted(set(MARK_RE.findall(source)) - set(values))
    if missing:
        print(f"runbook-tray: no value given for {', '.join(missing)}", file=sys.stderr)
        return 2
    sys.stdout.write(MARK_RE.sub(lambda m: values[m.group(1)], source))
    return 0


def main(argv):
    parser = argparse.ArgumentParser(prog="runbook-tray.py", description="The helper behind the menu-bar runbook tray.")
    sub = parser.add_subparsers(dest="what", required=True)
    for name in ("render", "act", "doctor"):
        p = sub.add_parser(name)
        if name == "act":
            p.add_argument("id")
        p.add_argument("--config", required=True)
        if name != "doctor":
            p.add_argument("--state", required=True)
        if name == "render":
            p.add_argument("--print", action="store_true")
    p = sub.add_parser("stamp")
    p.add_argument("--source", required=True)
    p.add_argument("pairs", nargs="*")
    args = parser.parse_args(argv)
    return {"render": cmd_render, "act": cmd_act, "doctor": cmd_doctor, "stamp": cmd_stamp}[args.what](args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
