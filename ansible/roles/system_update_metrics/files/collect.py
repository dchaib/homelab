#!/usr/bin/python3
"""Collect pending APT updates and kernel reboot status."""

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time


def command(*args, limit="10m"):
    # GNU timeout bounds the command and its children; no process manager in Python.
    return subprocess.check_output(
        ["/usr/bin/timeout", "--kill-after=10s", limit, *args],
        text=True, env={**os.environ, "LC_ALL": "C", "DEBIAN_FRONTEND": "noninteractive"},
    )


def count_updates(cache, compare):
    counts = dict.fromkeys(("updates", "security_updates", "kernel_updates", "proxmox_updates"), 0)
    for package in cache:
        if not package.is_installed or not package.candidate:
            continue
        installed, candidate = package.installed.version, package.candidate
        if compare(candidate.version, installed) <= 0:
            continue
        counts["updates"] += 1
        counts["kernel_updates"] += int(package.name.startswith(("linux-image-", "proxmox-kernel-", "pve-kernel-")))
        counts["proxmox_updates"] += int(any(o.origin == "Proxmox" for o in candidate.origins))
        # A regular candidate can supersede a security version still in the indexes.
        counts["security_updates"] += int(any(
            compare(v.version, installed) > 0 and compare(v.version, candidate.version) <= 0
            and any(o.origin == "Debian" and (o.label == "Debian-Security" or o.archive.endswith("-security")) for o in v.origins)
            for v in package.versions
        ))
    return {f"homelab_apt_{name}_pending": count for name, count in counts.items()}


def collect_apt():
    command("/usr/bin/apt-get", "--error-on=any", "-o", "Acquire::Timeout=20", "-o", "Acquire::Retries=1", "update")
    import apt
    import apt_pkg

    with apt.Cache() as cache:
        return count_updates(cache, apt_pkg.version_compare)


def collect_reboot():
    if Path("/run/reboot-required").exists():
        return {"homelab_reboot_required": 1}
    output = command("/usr/sbin/needrestart", "-b", "-k", limit="1m")
    status = re.search(r"^NEEDRESTART-KSTA:\s*([1-3])\s*$", output, re.MULTILINE)
    if status is None:
        raise ValueError("needrestart kernel status is unknown")
    # 1=current, 2=ABI-compatible upgrade, 3=version upgrade; 0 is unknown.
    return {"homelab_reboot_required": int(status[1] != "1")}


def read_previous(path):
    if not path.exists():
        return {}
    values = {}
    for line in path.read_text().splitlines():
        fields = line.split()
        if len(fields) == 2 and fields[0].startswith("homelab_") and fields[1].isdigit():
            values[fields[0]] = int(fields[1])
    return values


def write_metrics(path, values):
    # Rename within the shared directory so Alloy never reads a partial file.
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, suffix=".tmp", delete=False) as stream:
        temporary = Path(stream.name)
        try:
            for name in sorted({key.split("{")[0] for key in values}):
                stream.write(f"# TYPE {name} gauge\n")
            for name, value in sorted(values.items()):
                stream.write(f"{name} {value}\n")
            stream.flush()
            os.fchmod(stream.fileno(), 0o644)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def collect(path):
    values = read_previous(path)
    failed = False
    for check, reader in (("apt", collect_apt), ("reboot", collect_reboot)):
        success = f'homelab_system_update_collect_success{{check="{check}"}}'
        last_success = f'homelab_system_update_last_success_timestamp_seconds{{check="{check}"}}'
        values.setdefault(last_success, 0)
        try:
            values.update(reader())
        except Exception as error:
            print(f"{check}: {error}", file=sys.stderr)
            values[success] = 0
            failed = True
        else:
            values[success] = 1
            values[last_success] = int(time.time())
    write_metrics(path, values)
    return int(failed)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    raise SystemExit(collect(parser.parse_args().output))
