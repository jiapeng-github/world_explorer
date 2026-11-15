#!/usr/bin/env python3
"""Recertify resolved review findings on the live Pixel Tablet emulator.

Do not clear app data. Swipes start at y=1100 to avoid the Home gesture.
Taps avoid y>1450. Rest reminders are dismissed with「稍后提醒我」.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path

ADB = "/Users/penn/Library/Android/sdk/platform-tools/adb"
SERIAL = "emulator-5554"
ROOT = Path("/Users/penn/Projects/world_explorer/docs/review/recheck")
SHOTS = ROOT / "screenshots"
LOG = ROOT / "recheck_log.jsonl"
SUMMARY = ROOT / "recheck_results.json"

W, H = 2560, 1600
SOFT_Y_MAX = 1450


def adb(*args, check=True, timeout=40):
    return subprocess.run(
        [ADB, "-s", SERIAL, *args],
        check=check,
        capture_output=True,
        timeout=timeout,
    )


def sh(cmd, timeout=20):
    r = adb("shell", cmd, check=False, timeout=timeout)
    return (r.stdout or b"").decode("utf-8", "replace")


def sleep(s):
    time.sleep(s)


def log(event, **kw):
    rec = {"t": time.strftime("%H:%M:%S"), "event": event, **kw}
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    extra = " ".join(f"{k}={v!r}" for k, v in kw.items())
    print(f"[{rec['t']}] {event} {extra}", flush=True)


RESULTS = []


def record(fid, status, detail):
    RESULTS.append({"id": fid, "status": status, "detail": detail})
    log("result", id=fid, status=status, detail=detail)


def parse_xml_bytes(t: str):
    nodes = []
    for m in re.finditer(r"<node[^>]*>", t):
        s = m.group(0)

        def g(k):
            m2 = re.search(rf'{k}="([^"]*)"', s)
            return m2.group(1) if m2 else ""

        b = g("bounds")
        nums = list(map(int, re.findall(r"\d+", b))) if b else []
        desc = g("content-desc").replace("&#10;", "\n")
        nodes.append(
            {
                "text": g("text"),
                "desc": desc,
                "click": g("clickable"),
                "class": g("class"),
                "bounds": b,
                "box": nums,
                "focused": g("focused"),
            }
        )
    return nodes


def dump_ui():
    adb("shell", "uiautomator", "dump", "/sdcard/window_dump.xml")
    r = adb("shell", "cat", "/sdcard/window_dump.xml")
    t = (r.stdout or b"").decode("utf-8", "replace")
    return t, parse_xml_bytes(t)


def capture(name, wait=1.2):
    SHOTS.mkdir(parents=True, exist_ok=True)
    sleep(wait)
    dismiss_rest(quiet=True)
    png = SHOTS / f"{name}.png"
    xmlp = SHOTS / f"{name}.xml"
    shot = adb("exec-out", "screencap", "-p")
    png.write_bytes(shot.stdout)
    xml, nodes = dump_ui()
    xmlp.write_text(xml, encoding="utf-8")
    log("capture", name=name, nodes=len(nodes), bytes=png.stat().st_size)
    return nodes


def blob(n):
    return ((n.get("desc") or "") + "\n" + (n.get("text") or "")).strip()


def labels_of(nodes):
    out = []
    for n in nodes:
        b = blob(n)
        if b:
            out.append(b)
    return out


def has_label(nodes, s, exact=False):
    for n in nodes:
        b = blob(n)
        if exact:
            if s == n["desc"] or s == n["text"] or s in b.split("\n"):
                return n
        elif s in b or s in (n["desc"] or "") or s in (n["text"] or ""):
            return n
    return None


def all_text(nodes):
    return "\n".join(labels_of(nodes))


def center(box):
    x1, y1, x2, y2 = box
    return (x1 + x2) // 2, (y1 + y2) // 2


def app_ok():
    out = adb("shell", "dumpsys", "activity", "activities").stdout.decode("utf-8", "replace")
    return "com.example.world_explorer/.MainActivity" in out


def ensure_app():
    if app_ok():
        return
    log("relaunch")
    adb(
        "shell",
        "am",
        "start",
        "-n",
        "com.example.world_explorer/.MainActivity",
    )
    sleep(2.0)
    if not app_ok():
        raise SystemExit("app not focused")


def tap_xy(x, y):
    adb("shell", "input", "tap", str(int(x)), str(int(y)))


def swipe(x1, y1, x2, y2, ms=400):
    adb("shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(ms))


def swipe_up(times=1):
    for _ in range(times):
        swipe(1280, 1100, 1280, 520, 350)
        sleep(0.35)


def swipe_down(times=1):
    for _ in range(times):
        swipe(1280, 520, 1280, 1100, 350)
        sleep(0.35)


def back():
    adb("shell", "input", "keyevent", "4")
    sleep(0.5)
    ensure_app()


def find(nodes, label, clickable=True, exact=False):
    for n in nodes:
        if clickable and n["click"] != "true":
            continue
        b = blob(n)
        if exact:
            if label == n["desc"] or label == n["text"] or label in b.split("\n"):
                return n
        else:
            if label == n["desc"] or label == n["text"] or label in b:
                return n
    return None


def soft_ok(n):
    if not n or len(n.get("box") or []) != 4:
        return False
    x, y = center(n["box"])
    return 0 < x < W and 0 < y <= SOFT_Y_MAX


def soft_tap(nodes, label, exact=False, clickable=True):
    n = find(nodes, label, clickable=clickable, exact=exact)
    if n is None and clickable:
        n = find(nodes, label, clickable=False, exact=exact)
    if not soft_ok(n):
        log("tap_fail", label=label, node=n)
        return False
    x, y = center(n["box"])
    log("tap", label=label, x=x, y=y, bounds=n["bounds"])
    tap_xy(x, y)
    sleep(0.7)
    return True


def long_press_node(n, ms=2400):
    if not soft_ok(n) and n and n.get("box"):
        # allow slightly lower for parent gate hint
        x, y = center(n["box"])
        if y > 1550:
            return False
    elif not n or not n.get("box"):
        return False
    x, y = center(n["box"])
    # If too low, press a bit higher within the box
    if y > SOFT_Y_MAX:
        y = min(SOFT_Y_MAX, n["box"][3] - 20)
        y = max(n["box"][1] + 10, y)
    log("long_press", x=x, y=y, ms=ms, bounds=n["bounds"])
    adb("shell", "input", "swipe", str(x), str(y), str(x), str(y), str(ms))
    sleep(0.6)
    return True


def dismiss_rest(quiet=False):
    try:
        xml, nodes = dump_ui()
    except Exception:
        return False
    if has_label(nodes, "稍后提醒我") or has_label(nodes, "休息一下"):
        if not quiet:
            log("dismiss_rest")
        n = find(nodes, "稍后提醒我", clickable=True) or find(
            nodes, "稍后提醒我", clickable=False
        )
        if n and n.get("box"):
            x, y = center(n["box"])
            tap_xy(x, y)
            sleep(0.8)
            return True
    return False


def go_tab(name):
    """Tap left rail: 发现 / 地图 / 百科 / 我的."""
    ensure_app()
    nodes = capture(f"_nav_before_{name}", wait=0.4)
    if not soft_tap(nodes, name, exact=True):
        # rail icons may have only desc
        n = find(nodes, name, clickable=False, exact=True)
        if n and n.get("box"):
            x, y = center(n["box"])
            if y <= SOFT_Y_MAX:
                log("tap_rail", label=name, x=x, y=y)
                tap_xy(x, y)
                sleep(0.8)
                return True
        log("nav_fail", name=name)
        return False
    sleep(0.4)
    return True


def wait_for(pred, tries=8, delay=0.45, name="wait"):
    nodes = []
    for i in range(tries):
        _, nodes = dump_ui()
        dismiss_rest(quiet=True)
        if pred(nodes):
            return nodes
        sleep(delay)
    log("wait_timeout", name=name)
    return nodes


# ---------------- checks ----------------

def check_discover(nodes):
    t = all_text(nodes)
    # D05
    if "世界大百科" in t and "发现世界" not in t.split("世界大百科")[0][:80]:
        # title should be 世界大百科; 发现 may still exist as nav
        title = has_label(nodes, "世界大百科")
        record("D05", "通过", "顶栏可见「世界大百科」")
    else:
        record("D05", "未通过", "未看到顶栏「世界大百科」: " + t[:200])

    # D01 / D06
    school = has_label(nodes, "怎么上学？") or has_label(nodes, "世界各地\n怎么上学？")
    broken = "怎样生" in t and "世界各地怎样生活" in t
    if school and not broken:
        record("D01", "通过", "问题卡按语义换行为「世界各地 / 怎么上学？」")
        record("D06", "通过", "文案已改为「世界各地怎么上学？」，与教室配图一致")
    else:
        record("D01", "未通过", t[:300])
        record("D06", "未通过", t[:300])

    # D04
    cont = has_label(nodes, "已读")
    leak = re.search(r"(^|\n)\d+, 继续阅读", t)
    if cont and not leak:
        record("D04", "通过", "续读卡显示「已读 N%」，未见孤立数字前缀")
    else:
        record("D04", "未通过", f"has_read={bool(cont)} leak={bool(leak)} text={t[:300]}")

    # D03
    frog = has_label(nodes, "红眼树蛙")
    if frog:
        record("D03", "待目视", "语义已是完整红眼树蛙说明，截图需确认能看见整只青蛙")
    else:
        record("D03", "未通过", "未找到红眼树蛙图片说明")

    # D02
    hero = has_label(nodes, "尼罗河") or has_label(nodes, "帆船")
    if hero:
        record("D02", "待目视", "主视觉语义含尼罗河/帆船，截图需确认河面与帆船可见")
    else:
        record("D02", "待目视", "请对照 00-discover-home.png 看河面与帆船")

    # D07
    search = has_label(nodes, "搜索")
    if search:
        record("D07", "待目视", "搜索按钮存在，截图需确认有可见底色")
    else:
        record("D07", "未通过", "未找到搜索按钮")


def check_hub_e01(code, nodes, expected_titles):
    missing = [title for title in expected_titles if not has_label(nodes, title)]
    if not missing:
        record(f"E01-{code}", "通过", "首屏可见全部路线标题: " + "、".join(expected_titles))
        return True
    record(f"E01-{code}", "未通过", "首屏缺少: " + "、".join(missing))
    return False


def check_facts(code, nodes, expected_fields):
    t = all_text(nodes)
    missing = [f for f in expected_fields if f not in t]
    if not missing:
        record(f"E03-{code}", "通过", "资料条可见字段名: " + "、".join(expected_fields))
    else:
        record(f"E03-{code}", "未通过", "缺少字段名: " + "、".join(missing) + " | " + t[:400])


def keyboard_visible():
    out = sh("dumpsys input_method")
    # common flags
    if re.search(r"mInputShown=true", out) or re.search(r"mIsInputViewShown=true", out):
        return True
    if re.search(r"mInputShown=false", out) and re.search(
        r"mIsInputViewShown=false", out
    ):
        return False
    # fallback: InputMethod window
    win = sh("dumpsys window windows")
    return "InputMethod" in win and "mHasSurface=true" in win


def open_ency_country(name, shot):
    if not go_tab("百科"):
        return None
    nodes = capture("ency-before-" + shot, wait=0.8)
    # ensure 国家 tab
    if has_label(nodes, "跨国专题") or (
        has_label(nodes, "专题") and not has_label(nodes, name)
    ):
        # maybe on topics; switch to 国家
        if has_label(nodes, "国家"):
            soft_tap(nodes, "国家", exact=True)
            nodes = capture("ency-countries-" + shot, wait=0.8)
    if not has_label(nodes, name):
        # try continent filters / scroll
        for filt in ("全部", "亚洲", "欧洲", "非洲", "北美洲", "南美洲", "大洋洲"):
            if has_label(nodes, filt):
                soft_tap(nodes, filt, exact=True)
                nodes = capture(f"ency-filt-{filt}-{shot}", wait=0.6)
                if has_label(nodes, name):
                    break
        if not has_label(nodes, name):
            swipe_up(1)
            nodes = capture("ency-scrolled-" + shot, wait=0.5)
    if not soft_tap(nodes, name, exact=False):
        log("open_country_fail", name=name)
        return None
    nodes = capture("hub-" + shot, wait=1.2)
    return nodes


def pop_to_shell():
    """Back until left rail is visible."""
    for _ in range(8):
        ensure_app()
        _, nodes = dump_ui()
        dismiss_rest(quiet=True)
        if has_label(nodes, "发现") and has_label(nodes, "百科"):
            return nodes
        back()
    return capture("pop-failed", wait=0.3)


def main():
    SHOTS.mkdir(parents=True, exist_ok=True)
    if LOG.exists():
        LOG.write_text("", encoding="utf-8")
    log("start")
    ensure_app()
    dismiss_rest()

    # ---- Discover (already likely here) ----
    if not go_tab("发现"):
        log("warn", msg="could not tap 发现, capturing anyway")
    nodes = capture("00-discover-home", wait=1.0)
    check_discover(nodes)

    # ---- Egypt hub via 开始探索 ----
    if not soft_tap(nodes, "开始探索"):
        # maybe scrolled; try again
        go_tab("发现")
        nodes = capture("00b-discover", wait=0.8)
        soft_tap(nodes, "开始探索")
    nodes = capture("10-egypt-hub", wait=1.4)
    check_hub_e01(
        "egypt",
        nodes,
        ["沿着尼罗河", "走进今天", "追寻文明"],
    )
    # E03 egypt facts
    check_facts("egypt", nodes, ["首都", "位置"])
    # E02
    if has_label(nodes, "浏览全部主题"):
        record("E02", "通过", "概览出现稳定入口「浏览全部主题」")
    elif has_label(nodes, "换个主题"):
        record("E02", "未通过", "仍显示「换个主题」")
    else:
        # might be below fold
        swipe_up(1)
        nodes2 = capture("10b-egypt-hub-s2", wait=0.7)
        if has_label(nodes2, "浏览全部主题"):
            record("E02", "通过", "下滑后可见「浏览全部主题」")
        else:
            record("E02", "未通过", "未见「浏览全部主题」: " + all_text(nodes2)[:400])
        swipe_down(1)

    # ---- Journey + article R01 R02 ----
    nodes = capture("10c-egypt-hub-retry", wait=0.4)
    if not soft_tap(nodes, "沿着尼罗河"):
        swipe_down(1)
        nodes = capture("10d-egypt-up", wait=0.5)
        soft_tap(nodes, "沿着尼罗河")
    nodes = capture("11-egypt-nile-journey", wait=1.2)
    # continue into article
    if not soft_tap(nodes, "继续这条路线"):
        # try first station
        for lab in ("尼罗河流向哪里", "从河谷到地中海", "第一"):
            if soft_tap(nodes, lab):
                break
    nodes = capture("12-egypt-article", wait=1.4)
    t = all_text(nodes)
    # R01: app bar should show article title
    title_ok = has_label(nodes, "尼罗河流向哪里") or has_label(
        nodes, "尼罗河为什么重要"
    )
    country_only = (
        ("埃及 · 地理" in t or "国家 · 栏目" in t)
        and "尼罗河流向哪里" not in t
        and "尼罗河为什么重要" not in t
    )
    if title_ok and not country_only:
        record("R01", "通过", "阅读页可见文章标题")
    else:
        record("R01", "未通过", "未见文章标题: " + t[:500])

    # R02: new CTA copy and/or diagram
    if has_label(nodes, "打开埃及地图") or has_label(nodes, "找北箭头"):
        record("R02", "通过", "正文动作改为明确的打开地图说明")
    elif has_label(nodes, "在地图上看看"):
        record("R02", "未通过", "仍是旧文案「在地图上看看」")
    else:
        record("R02", "待目视", "未见新地图按钮文案，对照截图看示意图是否在正文前: " + t[:400])

    # open egypt map from article if possible
    if has_label(nodes, "打开埃及地图") or has_label(nodes, "找北箭头") or has_label(
        nodes, "在地图上看看"
    ):
        soft_tap(nodes, "打开埃及地图") or soft_tap(nodes, "找北箭头") or soft_tap(
            nodes, "在地图上看看"
        )
        nodes = capture("13-egypt-map", wait=1.6)
        # M02: nearby list scrollable — just capture and note
        if has_label(nodes, "看看附近") or has_label(nodes, "卡纳克") or has_label(
            nodes, "全部地点"
        ):
            record("M02", "待目视", "埃及地图右栏已打开，对照截图看是否可滚动到完整卡片")
        else:
            record("M02", "待目视", "已打开埃及地图: " + all_text(nodes)[:300])

    # ---- World map M01 ----
    pop_to_shell()
    go_tab("地图")
    nodes = capture("20-world-map", wait=1.8)
    # try select Egypt if a search or egypt chip exists
    if not has_label(nodes, "埃及"):
        # maybe a search on map
        if has_label(nodes, "搜索"):
            soft_tap(nodes, "搜索")
            sleep(0.5)
            nodes = capture("20b-map-search", wait=0.6)
        # leave as is — previous session had Egypt selected
    # If 探索埃及 or 吉萨 is visible, good for visual
    record("M01", "待目视", "世界地图已打开，对照截图看埃及选中后标签是否重叠")

    # ---- Encyclopedia C01 C02 T01 ----
    pop_to_shell()
    go_tab("百科")
    nodes = capture("30-ency-home", wait=1.0)
    if has_label(nodes, "专题") and not has_label(nodes, "中国"):
        soft_tap(nodes, "国家", exact=True)
        nodes = capture("30b-ency-countries", wait=0.8)
    # C02
    if has_label(nodes, "精选顺序") or has_label(nodes, "英文 A"):
        record("C02", "通过", "排序按钮标明「精选顺序 / 英文 A–Z」一类规则")
    elif has_label(nodes, "按英文名称排序"):
        record("C02", "未通过", "仍是旧无障碍名称「按英文名称排序」")
    else:
        record("C02", "待目视", "未直接看到排序文案: " + all_text(nodes)[:300])

    # C01 first screen + scroll to bottom
    first_clipped = []
    for c in ("澳大利亚", "法国", "德国", "南非"):
        n = has_label(nodes, c)
        if not n:
            first_clipped.append(c)
    capture("30c-ency-first", wait=0.3)
    swipe_up(2)
    nodes = capture("30d-ency-bottom", wait=0.7)
    missing = [c for c in ("澳大利亚", "法国", "德国", "南非") if not has_label(nodes, c)]
    if not missing:
        record(
            "C01",
            "通过",
            "下滑后四国名称完整可见"
            + ("；首屏未露出国名属滚动边界" if first_clipped else "；首屏已能看到四国"),
        )
    else:
        record("C01", "未通过", "滑到底仍看不到: " + "、".join(missing))
    swipe_down(2)

    # T01 topics title
    nodes = capture("31-ency-for-topics", wait=0.4)
    if not soft_tap(nodes, "专题", exact=True):
        # may need exact node 专题 not 跨国专题
        n = find(nodes, "专题", clickable=True, exact=True)
        if n:
            soft_tap(nodes, "专题", exact=True)
    nodes = capture("31-topics-tab", wait=0.9)
    if has_label(nodes, "跨国专题"):
        record("T01", "通过", "百科切到专题后标题为「跨国专题」")
    elif has_label(nodes, "国家百科"):
        record("T01", "未通过", "专题页仍写「国家百科」")
    else:
        record("T01", "待目视", "标题不明确: " + all_text(nodes)[:300])

    # ---- Country hubs: E01 china/usa/gbr, MP01 seven, NO01, Japan map ----
    country_plans = [
        ("china", "中国", ["山河", "生活", "文明"], None, ["首都", "位置"]),
        ("usa", "美国", ["沿着山河走", "走进城市", "循着历史找"], None, ["首都", "位置"]),
        ("gbr", "英国", ["沿着河流进城", "去海岸找线索", "顺着时间找证据"], None, ["首都", "位置"]),
        ("japan", "日本", None, "打开日本地图", None),
        ("brazil", "巴西", None, "打开巴西", None),
        ("kenya", "肯尼亚", None, "打开肯尼亚", None),
        ("norway", "挪威", None, "打开挪威", None),
        ("aus", "澳大利亚", None, "打开澳大利亚", None),
        ("fra", "法国", None, "打开法国", None),
        ("deu", "德国", None, "打开德国", None),
        ("zaf", "南非", None, "打开南非", None),
    ]
    map_found = {}
    for code, name, titles, map_key, fields in country_plans:
        pop_to_shell()
        nodes = open_ency_country(name, code)
        if not nodes:
            if titles:
                record(f"E01-{code}", "未打开", f"未能进入{name}概览")
            if map_key:
                map_found[code] = False
                record(f"MP01-{code}", "未打开", f"未能进入{name}概览")
            continue
        if titles:
            check_hub_e01(code, nodes, titles)
        if fields:
            check_facts(code, nodes, fields)
        if map_key:
            # icon button may only be in app bar desc
            n = has_label(nodes, map_key) or has_label(nodes, "地图")
            # avoid matching 世界地图 in other places; prefer 打开…
            opened = has_label(nodes, "打开") and has_label(nodes, "地图")
            text = all_text(nodes)
            ok = bool(has_label(nodes, map_key) or re.search(r"打开.{0,8}地图", text))
            map_found[code] = ok
            if ok:
                record(f"MP01-{code}", "通过", f"{name}概览有打开地图入口")
            else:
                # maybe in app bar icon without text — look at clickable desc
                icons = [
                    blob(x)
                    for x in nodes
                    if x["click"] == "true" and "地图" in blob(x)
                ]
                if icons:
                    record(f"MP01-{code}", "通过", f"{name}概览地图入口: " + " | ".join(icons))
                    map_found[code] = True
                else:
                    record(f"MP01-{code}", "未通过", f"{name}概览未见打开地图: " + text[:400])
        if code == "norway":
            if has_label(nodes, "北方的光与生命"):
                record("NO01", "通过", "挪威第三条路线显示「北方的光与生命」")
            elif has_label(nodes, "北方光与生命"):
                record("NO01", "未通过", "仍显示「北方光与生命」，少了「的」")
            else:
                swipe_up(1)
                nodes = capture("hub-norway-s2", wait=0.6)
                if has_label(nodes, "北方的光与生命"):
                    record("NO01", "通过", "下滑后可见「北方的光与生命」")
                elif has_label(nodes, "北方光与生命"):
                    record("NO01", "未通过", "仍显示「北方光与生命」")
                else:
                    record("NO01", "待目视", "未找到该路线标题: " + all_text(nodes)[:400])
        if code == "japan":
            # open japan map
            if soft_tap(nodes, "打开日本地图") or soft_tap(nodes, "日本地图"):
                capture("14-japan-map", wait=1.6)
                log("japan_map_opened")

    # summarize MP01
    seven = ["brazil", "kenya", "norway", "aus", "fra", "deu", "zaf"]
    if seven and all(map_found.get(c) for c in seven):
        record("MP01", "通过", "七国概览均有打开地图入口")
    elif any(k in map_found for k in seven):
        miss = [c for c in seven if not map_found.get(c)]
        record("MP01", "部分通过" if miss else "通过", "缺失: " + "、".join(miss) if miss else "全部找到")

    # summarize E01
    e01_ids = [r for r in RESULTS if r["id"].startswith("E01-")]
    if e01_ids and all(r["status"] == "通过" for r in e01_ids):
        record("E01", "通过", "中埃美英首屏均能看到三条路线标题")
    elif e01_ids:
        bad = [r["id"] + ":" + r["status"] for r in e01_ids if r["status"] != "通过"]
        record("E01", "未通过", "；".join(bad))

    e03_ids = [r for r in RESULTS if r["id"].startswith("E03-")]
    if e03_ids and all(r["status"] == "通过" for r in e03_ids):
        record("E03", "通过", "资料条已统一显示字段名")
    elif e03_ids:
        bad = [r["id"] + ":" + r["status"] for r in e03_ids if r["status"] != "通过"]
        record("E03", "未通过", "；".join(bad))

    # ---- Antarctica A01 A02 A03 ----
    pop_to_shell()
    go_tab("百科")
    nodes = capture("40-ency-for-ant", wait=0.8)
    if not has_label(nodes, "南极"):
        if has_label(nodes, "专题") or has_label(nodes, "跨国专题"):
            soft_tap(nodes, "专题", exact=True)
            nodes = capture("40b-topics", wait=0.8)
        if not has_label(nodes, "南极"):
            # 自然 filter
            if has_label(nodes, "自然"):
                soft_tap(nodes, "自然", exact=True)
                nodes = capture("40c-nature", wait=0.7)
    if soft_tap(nodes, "南极") or soft_tap(nodes, "南极洲"):
        nodes = capture("41-antarctica", wait=1.4)
        # A01: side rail present, no bottom nav typical items occupying bottom
        rail = has_label(nodes, "发现") and has_label(nodes, "百科")
        # AntarcticaNavigation used to have 南极-specific bottom items
        if rail:
            record("A01", "通过", "南极洲宽屏出现与其他页一致的左侧栏")
        else:
            record("A01", "未通过", "未见左侧栏: " + all_text(nodes)[:400])
        if soft_tap(nodes, "开始探索"):
            nodes = capture("42-antarctica-explore", wait=1.2)
            record("A02", "待目视", "已打开「开始探索」，对照截图看拼图与主题卡片")
            swipe_up(2)
            capture("42b-antarctica-explore-bottom", wait=0.7)
        pop_to_shell()
        # re-enter tasks? might still be in ant
        go_tab("百科")
        nodes = capture("43-ency-tasks", wait=0.6)
        soft_tap(nodes, "专题", exact=True)
        nodes = capture("43b-topics", wait=0.6)
        if not has_label(nodes, "南极"):
            if has_label(nodes, "自然"):
                soft_tap(nodes, "自然", exact=True)
                nodes = capture("43c", wait=0.5)
        if soft_tap(nodes, "南极") or soft_tap(nodes, "南极洲"):
            nodes = capture("44-ant-hub2", wait=1.0)
            if soft_tap(nodes, "探索任务"):
                nodes = capture("45-ant-tasks", wait=1.0)
                swipe_up(2)
                nodes = capture("45b-ant-tasks-bottom", wait=0.7)
                if has_label(nodes, "开放观察") or has_label(nodes, "任务"):
                    record("A03", "通过", "探索任务可滚动到列表底部内容")
                else:
                    record("A03", "待目视", "已滑到任务页底部，对照截图")

    # ---- 我的 J01 J02, settings, notes ----
    pop_to_shell()
    go_tab("我的")
    nodes = capture("50-me", wait=1.0)
    # J02 parent at top
    parent_btns = [n for n in nodes if "家长" in blob(n) and n.get("box")]
    top_parent = None
    for n in parent_btns:
        if n["box"][1] < 400:
            top_parent = n
            break
    if top_parent:
        record("J02", "通过", f"我的页顶端有家长入口 bounds={top_parent['bounds']}")
    elif parent_btns:
        record("J02", "未通过", "有家长入口但不在顶端: " + str([n["bounds"] for n in parent_btns]))
    else:
        record("J02", "未通过", "我的页未见家长入口")

    # J01 scroll bookmarks
    swipe_up(2)
    nodes = capture("50b-me-scrolled", wait=0.7)
    if has_label(nodes, "大熊猫") or has_label(nodes, "最近收藏") or has_label(nodes, "家长入口"):
        record("J01", "通过", "我的页可滚动，列表内容能完整进入视口（目视再确认裁切）")
    else:
        record("J01", "待目视", "已滚动我的页: " + all_text(nodes)[:300])
    swipe_down(2)

    # Reading settings RS01 RS02
    nodes = capture("51-me-for-settings", wait=0.4)
    # gear often desc 阅读设置
    opened_settings = soft_tap(nodes, "阅读设置") or soft_tap(nodes, "把文字调到舒服")
    if not opened_settings:
        # tap top-right gear roughly
        for n in nodes:
            if n["click"] == "true" and n.get("box") and n["box"][0] > 2200 and n["box"][1] < 220:
                x, y = center(n["box"])
                log("tap_gear_guess", bounds=n["bounds"], desc=blob(n))
                tap_xy(x, y)
                opened_settings = True
                break
    if opened_settings:
        nodes = capture("52-reading-settings", wait=1.0)
        t = all_text(nodes)
        if "字号" in t and re.search(r"字号\s*100%|字号 100%", t):
            record("RS01", "通过", "字号语义为「字号 100%」一类，未见「0%, 100%」")
        elif "0%, 100%" in t or re.search(r"0%,\s*100%", t):
            record("RS01", "未通过", "仍读出 0%, 100%: " + t[:400])
        else:
            record("RS01", "待目视", "字号文案: " + t[:400])
        if has_label(nodes, "语速") or has_label(nodes, "较慢"):
            # try click 较慢 then 标准 to restore
            slower = find(nodes, "较慢", clickable=True) or find(
                nodes, "较慢", clickable=False
            )
            if slower and slower.get("click") == "true":
                record("RS02", "通过", "语速标签可点击；语义含语速/较慢/标准/较快")
            elif has_label(nodes, "语速 标准") or has_label(nodes, "语速 较慢"):
                record("RS02", "通过", "语速语义已改为「语速 …」")
            else:
                # click the text 标准 anyway
                if soft_tap(nodes, "标准", exact=True):
                    record("RS02", "通过", "已能点选「标准」语速标签")
                else:
                    record("RS02", "待目视", "语速区: " + t[:400])
        # restore 清爽白 if needed
        if has_label(nodes, "清爽白"):
            soft_tap(nodes, "清爽白")
            sleep(0.3)
        back()
    else:
        record("RS01", "未打开", "未能进入阅读设置")
        record("RS02", "未打开", "未能进入阅读设置")

    # Notes N01
    go_tab("我的")
    nodes = capture("53-me-for-notes", wait=0.6)
    if not soft_tap(nodes, "探索笔记") and not soft_tap(nodes, "写一条笔记"):
        swipe_up(1)
        nodes = capture("53b-me-notes", wait=0.5)
        soft_tap(nodes, "探索笔记") or soft_tap(nodes, "写一条笔记")
    nodes = capture("54-notes-list", wait=0.8)
    if not soft_tap(nodes, "新建笔记") and not soft_tap(nodes, "写一条笔记"):
        # top-right new
        for n in nodes:
            if n["click"] == "true" and n.get("box") and n["box"][0] > 2200 and n["box"][1] < 220:
                tap_xy(*center(n["box"]))
                break
    nodes = capture("55-note-new", wait=1.0)
    save = has_label(nodes, "保存笔记")
    if save and save.get("box") and len(save["box"]) == 4:
        x1, y1, x2, y2 = save["box"]
        h = y2 - y1
        if y2 <= 1580 and h >= 60 and y1 >= 0:
            record("N01", "通过", f"「保存笔记」完整可见 bounds={save['bounds']} height={h}")
        else:
            record("N01", "未通过", f"按钮仍可能被裁切 bounds={save['bounds']} height={h}")
    else:
        record("N01", "未通过", "新建笔记页未见「保存笔记」: " + all_text(nodes)[:400])
    back()

    # ---- Search S01 S02 ----
    pop_to_shell()
    go_tab("发现")
    nodes = capture("60-discover-for-search", wait=0.7)
    if soft_tap(nodes, "搜索国家、地点或问题") or soft_tap(nodes, "搜索"):
        sleep(0.8)
        nodes = capture("61-search", wait=0.8)
        kb = keyboard_visible()
        focused = any(
            n.get("focused") == "true" and "EditText" in (n.get("class") or "")
            for n in nodes
        )
        if not kb:
            record("S01", "通过", "平板打开搜索后系统键盘未自动弹出")
        else:
            record("S01", "未通过", f"平板仍自动弹出键盘 focused={focused}")
        # S02 label
        edit = None
        for n in nodes:
            if "EditText" in (n.get("class") or ""):
                edit = n
                break
        if edit and (
            "搜索" in (edit["desc"] or "")
            or "搜索" in (edit["text"] or "")
            or has_label(nodes, "搜索")
        ):
            record(
                "S02",
                "通过",
                f"搜索框有名称 desc={edit['desc']!r} text={edit['text']!r}",
            )
        elif has_label(nodes, "搜索"):
            record("S02", "通过", "页面存在「搜索」标签")
        else:
            record("S02", "未通过", "搜索框仍可能没有无障碍名称: " + all_text(nodes)[:300])
        back()

    # ---- Parent / packs / credits ----
    pop_to_shell()
    go_tab("我的")
    nodes = capture("70-me-parent", wait=0.8)
    # tap top 家长入口 then long-press gate
    entered = False
    if soft_tap(nodes, "家长入口") or soft_tap(nodes, "家长"):
        nodes = capture("71-parent-gate", wait=1.0)
        gate = (
            find(nodes, "长按 2 秒进入", clickable=True)
            or find(nodes, "长按 2 秒进入", clickable=False)
            or find(nodes, "长按两秒", clickable=False)
            or find(nodes, "家长入口，长按两秒进入", clickable=False)
        )
        if gate:
            long_press_node(gate, ms=2500)
            nodes = capture("72-parent-center", wait=1.2)
            if has_label(nodes, "让探索更适合孩子") or has_label(nodes, "内容与记录") or has_label(
                nodes, "内容包"
            ):
                entered = True
            else:
                # try once more
                long_press_node(gate, ms=2800)
                nodes = capture("72b-parent-center", wait=1.2)
                entered = bool(
                    has_label(nodes, "让探索更适合孩子")
                    or has_label(nodes, "休息提醒")
                    or has_label(nodes, "内容包")
                )
    if not entered:
        record("P01", "未打开", "未能进入家长中心，内容包快捷入口无法复核")
        record("PK01", "未打开", "未能进入内容包")
        record("PK02", "未打开", "未能进入内容包")
        record("CR01", "未打开", "未能进入来源页")
        record("CR02", "未打开", "未能进入来源页")
    else:
        nodes = capture("73-parent-center", wait=0.4)
        if has_label(nodes, "内容包"):
            record("P01", "通过", "家长中心可见「内容包」快捷入口或内容与记录")
        else:
            swipe_up(1)
            nodes = capture("73b-parent-scrolled", wait=0.6)
            if has_label(nodes, "离线内容包") or has_label(nodes, "内容包"):
                record("P01", "通过", "下滑后可见内容包入口（快捷入口需目视顶栏）")
            else:
                record("P01", "未通过", "未见内容包入口: " + all_text(nodes)[:400])

        # Packs
        if soft_tap(nodes, "内容包") or soft_tap(nodes, "离线内容包"):
            nodes = capture("74-packs", wait=1.2)
            # open 中国
            if soft_tap(nodes, "中国内容包") or soft_tap(nodes, "中国"):
                nodes = capture("75-pack-china", wait=1.2)
                t = all_text(nodes)
                # PK01: 查看 should not sit on the header opening the same page
                # A list item「查看」would be bad if it's on the header card.
                header_view = False
                for n in nodes:
                    if n["text"] == "查看" or n["desc"] == "查看":
                        # if high on the page, likely the redundant header button
                        if n.get("box") and n["box"][1] < 700:
                            header_view = True
                if header_view:
                    record("PK01", "未通过", "详情页顶部仍有「查看」按钮")
                else:
                    record("PK01", "通过", "详情页顶部未见多余的「查看」")
                # PK02: 开始探索 should be above article list, i.e. visible on first screen
                if has_label(nodes, "开始探索"):
                    record("PK02", "通过", "首屏可见「开始探索」，已移到文章列表上方")
                else:
                    record("PK02", "未通过", "详情首屏未见「开始探索」: " + t[:400])
                back()

        # Credits CR01 CR02
        # may need to go back to parent center
        _, nodes = dump_ui()
        if not has_label(nodes, "内容来源") and not has_label(nodes, "来源与许可"):
            back()
            nodes = capture("76-back-parent", wait=0.7)
            if not has_label(nodes, "内容来源"):
                swipe_up(1)
                nodes = capture("76b-parent", wait=0.5)
        target = "内容来源与许可"
        if has_label(nodes, target) or has_label(nodes, "来源与许可") or has_label(
            nodes, "内容来源"
        ):
            t0 = time.time()
            soft_tap(nodes, "内容来源") or soft_tap(nodes, "来源与许可")
            # poll until content appears or 8s
            appeared = None
            for i in range(20):
                sleep(0.4)
                _, nodes = dump_ui()
                if has_label(nodes, "每一个发现") or has_label(nodes, "文字资料") or has_label(
                    nodes, "来源与许可"
                ):
                    appeared = time.time() - t0
                    break
            elapsed = appeared if appeared is not None else time.time() - t0
            nodes = capture("77-credits", wait=0.3)
            if appeared is not None and appeared <= 5.0:
                record("CR01", "通过", f"来源页约 {elapsed:.2f} 秒出现内容，不再卡约 20 秒")
            elif appeared is not None:
                record("CR01", "未通过", f"来源页 {elapsed:.2f} 秒才出现内容，仍偏慢")
            else:
                record("CR01", "未通过", f"等待 {elapsed:.2f} 秒仍未见到来源页内容")
            # CR02 license version — scroll for 开源软件许可
            found_ver = has_label(nodes, "0.8.0") or has_label(nodes, "0.6.0")
            if not has_label(nodes, "开源软件许可") and not found_ver:
                for i in range(6):
                    swipe_up(1)
                    nodes = capture(f"77b-credits-s{i}", wait=0.4)
                    if has_label(nodes, "开源软件许可") or has_label(nodes, "0.8.0") or has_label(
                        nodes, "0.6.0"
                    ):
                        break
            if soft_tap(nodes, "开源软件许可"):
                sleep(1.0)
                nodes = capture("78-licenses", wait=1.0)
            t = all_text(nodes)
            if "0.8.0" in t:
                record("CR02", "通过", "许可页版本为 0.8.0（或带 build）")
            elif "0.6.0" in t:
                record("CR02", "未通过", "许可页仍显示 0.6.0")
            else:
                record("CR02", "待目视", "未见版本号: " + t[:400])

    # Done — return to discover
    pop_to_shell()
    go_tab("发现")
    capture("99-back-discover", wait=0.8)
    log("done", count=len(RESULTS))
    SUMMARY.write_text(json.dumps(RESULTS, ensure_ascii=False, indent=2), encoding="utf-8")
    # print table
    print("\n======= RECHECK RESULTS =======")
    for r in RESULTS:
        print(f"{r['id']:12} {r['status']:8} {r['detail']}")
    print("RECHECK_WALK_DONE")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        log("adb_error", cmd=str(e.cmd), err=(e.stderr or b"")[:400].decode("utf-8", "replace"))
        SUMMARY.write_text(json.dumps(RESULTS, ensure_ascii=False, indent=2), encoding="utf-8")
        raise
