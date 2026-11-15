#!/usr/bin/env python3
"""ADB UI walker for World Explorer review testing."""
from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path

ADB = "/Users/penn/Library/Android/sdk/platform-tools/adb"
SERIAL = "emulator-5554"
REVIEW = Path("/Users/penn/Projects/world_explorer/docs/review")
SHOTS = REVIEW / "screenshots"
DUMPS = REVIEW / "dumps"
LOG = REVIEW / "coverage.json"


def adb(*args, check=True, timeout=30):
    cmd = [ADB, "-s", SERIAL, *args]
    return subprocess.run(cmd, check=check, capture_output=True, timeout=timeout)


def sleep(seconds):
    time.sleep(seconds)


def capture(name, wait=1.6):
    SHOTS.mkdir(parents=True, exist_ok=True)
    DUMPS.mkdir(parents=True, exist_ok=True)
    sleep(wait)
    png = SHOTS / f"{name}.png"
    xml = DUMPS / f"{name}.xml"
    shot = adb("exec-out", "screencap", "-p")
    png.write_bytes(shot.stdout)
    adb("shell", "uiautomator", "dump", "/sdcard/window_dump.xml")
    adb("pull", "/sdcard/window_dump.xml", str(xml))
    nodes = parse(xml)
    print(f"===== {name}  nodes={len(nodes)}  bytes={png.stat().st_size} =====")
    for n in nodes:
        if n["text"] or n["desc"]:
            print(
                "text=%r desc=%r click=%s bounds=%s"
                % (n["text"], n["desc"], n["click"], n["bounds"])
            )
    return nodes


def parse(xml_path):
    t = Path(xml_path).read_text(encoding="utf-8", errors="replace")
    nodes = []
    for m in re.finditer(r"<node[^>]*>", t):
        s = m.group(0)
        def g(k):
            m2 = re.search(rf'{k}="([^"]*)"', s)
            return m2.group(1) if m2 else ""
        b = g("bounds")
        nums = list(map(int, re.findall(r"\d+", b))) if b else []
        nodes.append(
            {
                "text": g("text"),
                "desc": g("content-desc").replace("&#10;", "\n"),
                "click": g("clickable"),
                "class": g("class"),
                "bounds": b,
                "box": nums,
                "focused": g("focused"),
            }
        )
    return nodes


def center(box):
    x1, y1, x2, y2 = box
    return (x1 + x2) // 2, (y1 + y2) // 2


def find_nodes(nodes, pred):
    return [n for n in nodes if pred(n)]


def find(nodes, label, clickable=True):
    label = label.strip()
    for n in nodes:
        if clickable and n["click"] != "true":
            continue
        blob = (n["desc"] or "") + "\n" + (n["text"] or "")
        if label == n["desc"] or label == n["text"] or label in blob.split("\n") or blob.startswith(label + "\n") or label in blob:
            return n
    return None


def tap_xy(x, y):
    adb("shell", "input", "tap", str(int(x)), str(int(y)))


def tap(nodes, label, clickable=True):
    n = find(nodes, label, clickable=clickable)
    if not n or len(n["box"]) != 4:
        raise SystemExit(f"cannot find tappable {label!r}")
    x, y = center(n["box"])
    print(f"TAP {label!r} -> {x},{y}  bounds={n['bounds']}")
    tap_xy(x, y)
    return n


def long_press(nodes, label, ms=2200):
    n = find(nodes, label, clickable=True) or find(nodes, label, clickable=False)
    if not n or len(n["box"]) != 4:
        raise SystemExit(f"cannot find long-press {label!r}")
    x, y = center(n["box"])
    print(f"LONG PRESS {label!r} {ms}ms -> {x},{y}")
    adb("shell", "input", "swipe", str(x), str(y), str(x), str(y), str(ms))
    return n


def back():
    adb("shell", "input", "keyevent", "4")


def swipe(x1, y1, x2, y2, ms=400):
    adb("shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(ms))


def swipe_up(times=1):
    # Start well above the system gesture bar (y=1600). A swipe from near
    # the bottom is treated as Home on this tablet emulator.
    for _ in range(times):
        swipe(1280, 1100, 1280, 520, 350)
        sleep(0.4)


def current_app_ok():
    out = adb("shell", "dumpsys", "activity", "activities").stdout.decode("utf-8", "replace")
    return "com.example.world_explorer/.MainActivity" in out


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "capture"
    if cmd == "capture":
        capture(sys.argv[2] if len(sys.argv) > 2 else "current")
    elif cmd == "tap":
        nodes = capture("_tmp", wait=0.2)
        tap(nodes, sys.argv[2])
    else:
        raise SystemExit("unknown")
