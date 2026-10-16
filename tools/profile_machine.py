#!/usr/bin/env python3
"""profile_machine.py - Detect the host (or container) profile with the Python stdlib only.

Why: every later decision (chunk sizes, targets/DVC parallelism, number of
subagents/worktrees, full vs sampled downloads, DuckDB in-memory vs on-disk,
container CPU/RAM limits) is derived from this file instead of being hardcoded.

Usage:  python tools/profile_machine.py [--out machine-profile.json] [--quiet]
Output: machine-profile.json (gitignored) + an 8-line summary on stdout.
"""
from __future__ import annotations

import argparse
import ctypes
import json
import os
import platform
import re
import shutil
import socket
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

TIMEOUT = 20


def run(cmd: list[str], timeout: int = TIMEOUT) -> str | None:
    """Run a command and return stripped stdout+stderr, or None if unavailable."""
    exe = shutil.which(cmd[0])
    if exe is None:
        return None
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
                           errors="replace")
        out = (p.stdout or "") + (p.stderr or "")
        return out.strip() or None
    except (subprocess.TimeoutExpired, OSError):
        return None


def first_line(s: str | None) -> str | None:
    return s.splitlines()[0].strip() if s else None


# --------------------------------------------------------------------------- CPU / RAM
def cpu_info() -> dict:
    info = {"logical_cores": os.cpu_count(), "physical_cores": None, "model": None}
    sysname = platform.system()
    if sysname == "Windows":
        out = run(["powershell", "-NoProfile", "-Command",
                   "(Get-CimInstance Win32_Processor | Select-Object -First 1 | "
                   "ForEach-Object { \"$($_.Name)|$($_.NumberOfCores)\" })"])
        if out and "|" in out:
            name, cores = out.rsplit("|", 1)
            info["model"] = name.strip()
            info["physical_cores"] = int(cores) if cores.strip().isdigit() else None
    elif sysname == "Linux":
        try:
            txt = Path("/proc/cpuinfo").read_text(errors="replace")
            m = re.search(r"model name\s*:\s*(.+)", txt)
            info["model"] = m.group(1).strip() if m else None
            cores = set(re.findall(r"core id\s*:\s*(\d+)", txt))
            info["physical_cores"] = len(cores) or None
        except OSError:
            pass
    elif sysname == "Darwin":
        info["model"] = run(["sysctl", "-n", "machdep.cpu.brand_string"])
        pc = run(["sysctl", "-n", "hw.physicalcpu"])
        info["physical_cores"] = int(pc) if pc and pc.isdigit() else None
    return info


def ram_info() -> dict:
    sysname = platform.system()
    total = avail = None
    if sysname == "Windows":
        class MEMORYSTATUSEX(ctypes.Structure):
            _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong),
                        ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong),
                        ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong),
                        ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong),
                        ("ullAvailExtendedVirtual", ctypes.c_ulonglong)]
        st = MEMORYSTATUSEX()
        st.dwLength = ctypes.sizeof(MEMORYSTATUSEX)
        if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(st)):
            total, avail = st.ullTotalPhys, st.ullAvailPhys
    elif sysname == "Linux":
        try:
            mem = {}
            for line in Path("/proc/meminfo").read_text().splitlines():
                k, _, v = line.partition(":")
                mem[k.strip()] = int(v.strip().split()[0]) * 1024
            total, avail = mem.get("MemTotal"), mem.get("MemAvailable")
        except OSError:
            pass
        # cgroup v2 limit (inside a container)
        try:
            lim = Path("/sys/fs/cgroup/memory.max").read_text().strip()
            if lim.isdigit():
                total = min(total or int(lim), int(lim))
        except OSError:
            pass
    elif sysname == "Darwin":
        t = run(["sysctl", "-n", "hw.memsize"])
        total = int(t) if t and t.isdigit() else None
    gb = lambda b: round(b / 2**30, 1) if b else None
    return {"total_gb": gb(total), "available_gb": gb(avail)}


# --------------------------------------------------------------------------- Disk / GPU
def disk_info() -> list[dict]:
    disks = []
    if platform.system() == "Windows":
        import string
        roots = [f"{d}:\\" for d in string.ascii_uppercase if os.path.exists(f"{d}:\\")]
    else:
        roots = ["/"]
        for extra in ("/home", "/workspace", "/workspaces", "/data", "/mnt/c"):
            if os.path.ismount(extra):
                roots.append(extra)
    for r in roots:
        try:
            u = shutil.disk_usage(r)
            disks.append({"mount": r, "total_gb": round(u.total / 2**30), "free_gb": round(u.free / 2**30)})
        except OSError:
            continue
    return disks


def gpu_info() -> list[str]:
    out = run(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"])
    if out:
        return [l.strip() for l in out.splitlines() if l.strip()]
    if platform.system() == "Windows":
        out = run(["powershell", "-NoProfile", "-Command",
                   "(Get-CimInstance Win32_VideoController).Name -join '|'"])
        return [g for g in (out or "").split("|") if g.strip()]
    if platform.system() == "Linux":
        out = run(["lspci"])
        return [l for l in (out or "").splitlines() if re.search(r"VGA|3D|Display", l)]
    return []


# --------------------------------------------------------------------------- Software
VERSION_CMDS = {
    "python": [sys.executable, "--version"],
    "r": ["R", "--version"],
    "rscript": ["Rscript", "--version"],
    "git": ["git", "--version"],
    "gh": ["gh", "--version"],
    "duckdb_cli": ["duckdb", "--version"],
    "dvc": ["dvc", "--version"],
    "docker": ["docker", "--version"],
    "docker_compose": ["docker", "compose", "version"],
    "julia": ["julia", "--version"],
    "quarto": ["quarto", "--version"],
    "node": ["node", "--version"],
    "uv": ["uv", "--version"],
    "claude_code": ["claude", "--version"],
    "wsl": ["wsl", "--version"],
}


def software_versions() -> dict:
    v = {}
    for k, cmd in VERSION_CMDS.items():
        v[k] = first_line(run(cmd))
    # Windows: `claude` may be a .ps1 shim not resolvable by shutil.which
    if v["claude_code"] is None and platform.system() == "Windows":
        v["claude_code"] = first_line(run(["powershell", "-NoProfile", "-Command", "claude --version"]))
    # DuckDB python module version, if any
    try:
        import importlib.metadata as md
        v["duckdb_python"] = md.version("duckdb")
    except Exception:
        v["duckdb_python"] = None
    # Docker daemon reachable?
    v["docker_daemon_running"] = run(["docker", "info", "--format", "{{.ServerVersion}}"]) not in (None, "")
    return v


def shell_info() -> dict:
    return {
        "default_shell": os.environ.get("SHELL") or os.environ.get("ComSpec"),
        "git_bash_present": shutil.which("bash") is not None,
        "term_program": os.environ.get("TERM_PROGRAM"),
        "in_container": Path("/.dockerenv").exists() or os.environ.get("REMOTE_CONTAINERS") == "true",
        "wsl_interop": os.environ.get("WSL_DISTRO_NAME"),
    }


# --------------------------------------------------------------------------- Network
def network_info() -> dict:
    proxies = urllib.request.getproxies()
    reach = {}
    for name, url in {"github_api": "https://api.github.com",
                      "inei_portal": "https://proyectos.inei.gob.pe/microdatos/",
                      "zenodo_sandbox": "https://sandbox.zenodo.org/api/records?size=1"}.items():
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "profile_machine/1.0"})
            with urllib.request.urlopen(req, timeout=10) as r:
                reach[name] = r.status
        except Exception as e:  # noqa: BLE001
            reach[name] = f"error: {type(e).__name__}"
    return {"internet": any(isinstance(s, int) and s < 500 for s in reach.values()),
            "proxy": proxies or None, "reachability": reach, "hostname": socket.gethostname()}


# --------------------------------------------------------------------------- Claude Code / MCP
def claude_config_info() -> dict:
    home = Path.home()
    info = {"user_settings": None, "mcp_servers_user": [], "mcp_servers_project": [],
            "plugins_enabled": [], "permission_mode": None}
    try:
        s = json.loads((home / ".claude" / "settings.json").read_text(encoding="utf-8"))
        info["user_settings"] = str(home / ".claude" / "settings.json")
        info["plugins_enabled"] = sorted(k for k, on in s.get("enabledPlugins", {}).items() if on)
        info["permission_mode"] = s.get("permissions", {}).get("defaultMode")
    except Exception:
        pass
    try:
        c = json.loads((home / ".claude.json").read_text(encoding="utf-8"))
        info["mcp_servers_user"] = sorted(c.get("mcpServers", {}).keys())
        proj = c.get("projects", {}).get(str(Path.cwd()), {})
        info["mcp_servers_project"] = sorted(proj.get("mcpServers", {}).keys())
    except Exception:
        pass
    pm = Path.cwd() / ".mcp.json"
    if pm.exists():
        try:
            info["mcp_servers_project"] += sorted(json.loads(pm.read_text()).get("mcpServers", {}).keys())
        except Exception:
            pass
    return info


# --------------------------------------------------------------------------- Derived settings
def derive(profile: dict) -> dict:
    """Turn raw facts into the knobs the template reads. Rationale in each key."""
    cores = profile["cpu"]["logical_cores"] or 2
    phys = profile["cpu"]["physical_cores"] or max(1, cores // 2)
    ram = profile["ram"]["total_gb"] or 4
    free = min((d["free_gb"] for d in profile["disk"]), default=0)
    return {
        "container_cpus": max(1, cores - 1),                # logical cores - 1 (spec: nucleos - 1); host stays responsive
        "container_memory_gb": round(ram * 0.75, 1),        # ~75 % of RAM (spec: 75-80 %)
        "wsl_memory_gb": round(ram * 0.75),                 # mirrors container_memory_gb for %UserProfile%\.wslconfig
        "wsl_processors": max(1, cores - 1),
        "targets_workers": max(1, phys - 1),                # compute-bound stages: physical cores - 1
        "dvc_jobs": max(2, min(8, cores)),
        "max_subagents": 2 if ram < 16 else (4 if ram < 32 else 6),
        "max_worktrees": 2 if free < 50 else 4,
        "duckdb_mode": "memory" if ram >= 16 else "disk",
        "duckdb_memory_limit_gb": round(ram * 0.4, 1),
        "read_chunk_rows": 250_000 if ram >= 16 else 100_000,
        "download_mode": "full" if free > 100 else "sample",
        "gpu_available": bool(profile["gpu"]),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="machine-profile.json")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()

    profile = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "os": {"system": platform.system(), "release": platform.release(),
               "version": platform.version(), "arch": platform.machine()},
        "cpu": cpu_info(), "ram": ram_info(), "disk": disk_info(), "gpu": gpu_info(),
        "shell": shell_info(), "software": software_versions(), "network": network_info(),
        "claude": claude_config_info(),
    }
    profile["derived"] = derive(profile)
    Path(a.out).write_text(json.dumps(profile, indent=2, ensure_ascii=False), encoding="utf-8")

    if not a.quiet:
        d, sw = profile["derived"], profile["software"]
        disks = ", ".join(f"{x['mount']} {x['free_gb']}GB free" for x in profile["disk"])
        lines = [
            f"1. OS: {profile['os']['system']} {profile['os']['release']} ({profile['os']['arch']}); shell: {profile['shell']['default_shell']}; container={profile['shell']['in_container']}",
            f"2. CPU: {profile['cpu']['model']} | {profile['cpu']['physical_cores']} physical / {profile['cpu']['logical_cores']} logical",
            f"3. RAM: {profile['ram']['total_gb']} GB total, {profile['ram']['available_gb']} GB available | GPU: {', '.join(profile['gpu']) or 'none'}",
            f"4. Disk: {disks}",
            f"5. Python {sw['python']} | R {sw['rscript'] or 'absent'} | git {sw['git']} | DuckDB py={sw['duckdb_python'] or 'absent'} cli={sw['duckdb_cli'] or 'absent'} | DVC {sw['dvc'] or 'absent'}",
            f"6. Docker {sw['docker'] or 'absent'} daemon_running={sw['docker_daemon_running']} | Julia {sw['julia'] or 'absent'} | Quarto {sw['quarto'] or 'absent'} | uv {sw['uv'] or 'absent'}",
            f"7. Network: internet={profile['network']['internet']} proxy={profile['network']['proxy']} | Claude Code {sw['claude_code']} | plugins={len(profile['claude']['plugins_enabled'])} mcp_user={len(profile['claude']['mcp_servers_user'])}",
            f"8. Derived: container {d['container_cpus']} CPU / {d['container_memory_gb']} GB; targets_workers={d['targets_workers']}; subagents<={d['max_subagents']}; worktrees<={d['max_worktrees']}; duckdb={d['duckdb_mode']}; download={d['download_mode']}",
        ]
        print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
