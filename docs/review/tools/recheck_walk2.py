#!/usr/bin/env python3
"""Follow-up recertify: remaining countries, article, Antarctica, me/parent."""
from __future__ import annotations

import importlib.util
import json
import re
import time
from pathlib import Path

# Reuse helpers from walk 1 by exec
ROOT = Path("/Users/penn/Projects/world_explorer/docs/review/recheck")
SHOTS = ROOT / "screenshots"
LOG = ROOT / "recheck2_log.jsonl"
SUMMARY = ROOT / "recheck2_results.json"

spec = importlib.util.spec_from_file_location(
    "w1", "/Users/penn/Projects/world_explorer/docs/review/tools/recheck_walk.py"
)
w1 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(w1)

# Relax CTA taps slightly — primary buttons often sit at y=1450-1510
w1.SOFT_Y_MAX = 1510

RESULTS = []


def log(event, **kw):
    w1.log(event, **kw)


def record(fid, status, detail):
    RESULTS.append({"id": fid, "status": status, "detail": detail})
    log("result", id=fid, status=status, detail=detail)


def leave_to_shell():
    for i in range(12):
        w1.ensure_app()
        _, nodes = w1.dump_ui()
        w1.dismiss_rest(quiet=True)
        if w1.has_label(nodes, "发现") and w1.has_label(nodes, "百科"):
            return nodes
        if w1.find(nodes, "返回百科", clickable=True) or w1.find(
            nodes, "返回百科", clickable=False
        ):
            w1.soft_tap(nodes, "返回百科")
            time.sleep(0.6)
            continue
        # Product mark on dedicated country overviews
        n = w1.has_label(nodes, "世界大百科")
        if n and n.get("click") == "true" and n.get("box") and n["box"][0] < 500:
            # tap the left side of the mark (logo)
            x = min(n["box"][0] + 80, n["box"][2] - 10)
            y = (n["box"][1] + n["box"][3]) // 2
            log("tap_logo", x=x, y=y)
            w1.tap_xy(x, y)
            time.sleep(0.8)
            continue
        w1.back()
        time.sleep(0.45)
    log("leave_shell_fail")
    return w1.capture("leave-fail", wait=0.3)


def ency_countries():
    leave_to_shell()
    w1.go_tab("百科")
    nodes = w1.capture("_ency", wait=0.7)
    if not w1.has_label(nodes, "中国"):
        w1.soft_tap(nodes, "国家", exact=True)
        nodes = w1.capture("_ency-countries", wait=0.7)
    return nodes


def reveal_and_tap(nodes, label, tag):
    for attempt in range(4):
        n = w1.has_label(nodes, label)
        if n and w1.soft_ok(n):
            return w1.soft_tap(nodes, label)
        # if present but too low, or missing, swipe up
        w1.swipe_up(1)
        nodes = w1.capture(f"_reveal-{tag}-{attempt}", wait=0.45)
    return w1.soft_tap(nodes, label)


def open_country(name, code):
    nodes = ency_countries()
    if not reveal_and_tap(nodes, name, code):
        log("open_country_fail", name=name)
        return None
    return w1.capture("hub-" + code, wait=1.1)


def map_entry(nodes):
    texts = w1.all_text(nodes)
    m = re.findall(r"打开.{0,10}地图", texts)
    icons = [
        w1.blob(n)
        for n in nodes
        if n.get("click") == "true" and "地图" in w1.blob(n)
    ]
    return m or icons


def main():
    if LOG.exists():
        LOG.write_text("", encoding="utf-8")
    w1.LOG = LOG
    w1.SHOTS = SHOTS
    log("start2")
    w1.ensure_app()
    w1.dismiss_rest()
    leave_to_shell()

    # ---- remaining country hubs ----
    plans = [
        ("japan", "日本", "打开日本"),
        ("kenya", "肯尼亚", "打开肯尼亚"),
        ("norway", "挪威", "打开挪威"),
        ("aus", "澳大利亚", "打开澳大利亚"),
        ("fra", "法国", "打开法国"),
        ("deu", "德国", "打开德国"),
        ("zaf", "南非", "打开南非"),
    ]
    map_ok = {"brazil": True}  # already confirmed in walk 1 + screenshot
    for code, name, key in plans:
        nodes = open_country(name, code)
        if not nodes:
            record(f"MP01-{code}", "未打开", f"未能进入{name}概览")
            if code == "norway":
                record("NO01", "未打开", "未能进入挪威概览")
            continue
        found = map_entry(nodes)
        # Japan may keep the CTA further down or in the directory
        if not found and code == "japan":
            w1.swipe_up(2)
            nodes = w1.capture("hub-japan-s2", wait=0.6)
            found = map_entry(nodes)
            if not found and w1.has_label(nodes, "探索目录"):
                w1.soft_tap(nodes, "探索目录")
                nodes = w1.capture("hub-japan-menu", wait=0.7)
                found = map_entry(nodes)
                w1.back()
                nodes = w1.capture("hub-japan-after-menu", wait=0.5)
        if found:
            record(f"MP01-{code}", "通过", f"{name}地图入口: " + "、".join(found))
            map_ok[code] = True
        else:
            record(
                f"MP01-{code}",
                "未通过",
                f"{name}概览未见打开地图: " + w1.all_text(nodes)[:400],
            )
            map_ok[code] = False
        if code == "norway":
            if w1.has_label(nodes, "北方的光与生命"):
                record("NO01", "通过", "挪威第三条路线显示「北方的光与生命」")
            elif w1.has_label(nodes, "北方光与生命"):
                record("NO01", "未通过", "仍显示「北方光与生命」，少了「的」")
            else:
                w1.swipe_up(1)
                nodes = w1.capture("hub-norway-s2", wait=0.6)
                if w1.has_label(nodes, "北方的光与生命"):
                    record("NO01", "通过", "下滑后可见「北方的光与生命」")
                elif w1.has_label(nodes, "北方光与生命"):
                    record("NO01", "未通过", "仍显示「北方光与生命」")
                else:
                    record("NO01", "待目视", "未找到该路线标题: " + w1.all_text(nodes)[:400])
        if code == "japan" and found:
            if w1.soft_tap(nodes, found[0]) or w1.soft_tap(nodes, "打开日本地图") or w1.soft_tap(
                nodes, "日本地图"
            ):
                w1.capture("14-japan-map", wait=1.6)
                log("japan_map_opened")
                leave_to_shell()

    seven = ["kenya", "norway", "aus", "fra", "deu", "zaf"]
    miss = [c for c in seven if not map_ok.get(c)]
    record(
        "MP01",
        "通过" if not miss else "部分通过",
        ("七国加巴西均有地图入口" if not miss else "缺失: " + "、".join(miss))
        + ("；日本亦有" if map_ok.get("japan") else "；日本未见地图入口"),
    )

    # ---- Antarctica ----
    leave_to_shell()
    nodes = ency_countries()
    w1.soft_tap(nodes, "专题", exact=True)
    nodes = w1.capture("40-topics", wait=0.8)
    if not w1.has_label(nodes, "南极"):
        if w1.has_label(nodes, "自然"):
            w1.soft_tap(nodes, "自然", exact=True)
            nodes = w1.capture("40-nature", wait=0.6)
    if w1.soft_tap(nodes, "南极") or w1.soft_tap(nodes, "南极洲"):
        nodes = w1.capture("41-antarctica", wait=1.3)
        rail = w1.has_label(nodes, "发现") and w1.has_label(nodes, "百科")
        if rail:
            record("A01", "通过", "南极洲宽屏出现与其他页一致的左侧栏")
        else:
            record("A01", "未通过", "未见左侧栏: " + w1.all_text(nodes)[:400])
        if w1.soft_tap(nodes, "开始探索"):
            w1.capture("42-antarctica-explore", wait=1.1)
            w1.swipe_up(2)
            w1.capture("42b-antarctica-explore-bottom", wait=0.7)
            record("A02", "待目视", "已打开「开始探索」并滑到底，对照截图")
            leave_to_shell()
        # tasks
        nodes = ency_countries()
        w1.soft_tap(nodes, "专题", exact=True)
        nodes = w1.capture("43-topics", wait=0.7)
        if not w1.has_label(nodes, "南极") and w1.has_label(nodes, "自然"):
            w1.soft_tap(nodes, "自然", exact=True)
            nodes = w1.capture("43-nature", wait=0.5)
        if w1.soft_tap(nodes, "南极") or w1.soft_tap(nodes, "南极洲"):
            nodes = w1.capture("44-ant-hub2", wait=1.0)
            if w1.soft_tap(nodes, "探索任务"):
                w1.capture("45-ant-tasks", wait=1.0)
                w1.swipe_up(2)
                nodes = w1.capture("45b-ant-tasks-bottom", wait=0.7)
                if w1.has_label(nodes, "开放观察"):
                    record("A03", "通过", "探索任务可滚动到列表底部，「开放观察」可见")
                else:
                    record("A03", "待目视", "已滑到任务页底部，对照截图")
    else:
        record("A01", "未打开", "未能进入南极洲")
        record("A02", "未打开", "未能进入南极洲")
        record("A03", "未打开", "未能进入南极洲")

    # ---- 我的 / settings / notes ----
    leave_to_shell()
    w1.go_tab("我的")
    nodes = w1.capture("50-me", wait=1.0)
    parent_btns = [n for n in nodes if "家长" in w1.blob(n) and n.get("box")]
    top_parent = next((n for n in parent_btns if n["box"][1] < 400), None)
    if top_parent:
        record("J02", "通过", f"我的页顶端有家长入口 bounds={top_parent['bounds']}")
    elif parent_btns:
        record("J02", "未通过", "有家长入口但不在顶端: " + str([n["bounds"] for n in parent_btns]))
    else:
        record("J02", "未通过", "我的页未见家长入口")
    w1.swipe_up(2)
    nodes = w1.capture("50b-me-scrolled", wait=0.7)
    record("J01", "待目视", "我的页已滚动，对照截图看收藏卡是否完整")
    w1.swipe_down(2)

    nodes = w1.capture("51-me-settings", wait=0.4)
    opened = w1.soft_tap(nodes, "阅读设置")
    if not opened:
        for n in nodes:
            if n["click"] == "true" and n.get("box") and n["box"][0] > 2200 and n["box"][1] < 220:
                w1.tap_xy(*w1.center(n["box"]))
                opened = True
                break
    if opened:
        nodes = w1.capture("52-reading-settings", wait=1.0)
        t = w1.all_text(nodes)
        if "0%, 100%" in t or re.search(r"0%,\s*100%", t):
            record("RS01", "未通过", "仍读出 0%, 100%")
        elif "字号" in t:
            record("RS01", "通过", "字号语义含「字号」，未见「0%, 100%」: " + t[:200])
        else:
            record("RS01", "待目视", t[:400])
        slower = w1.find(nodes, "较慢", clickable=True)
        if slower:
            record("RS02", "通过", "语速「较慢」标签可点击")
        elif w1.has_label(nodes, "语速"):
            if w1.soft_tap(nodes, "标准", exact=True):
                record("RS02", "通过", "已能点选语速标签")
            else:
                record("RS02", "待目视", t[:400])
        if w1.has_label(nodes, "清爽白"):
            w1.soft_tap(nodes, "清爽白")
        w1.back()
    else:
        record("RS01", "未打开", "未能进入阅读设置")
        record("RS02", "未打开", "未能进入阅读设置")

    leave_to_shell()
    w1.go_tab("我的")
    nodes = w1.capture("53-me-notes", wait=0.7)
    if not w1.soft_tap(nodes, "探索笔记") and not w1.soft_tap(nodes, "写一条笔记"):
        w1.swipe_up(1)
        nodes = w1.capture("53b", wait=0.5)
        w1.soft_tap(nodes, "探索笔记") or w1.soft_tap(nodes, "写一条笔记")
    nodes = w1.capture("54-notes-list", wait=0.8)
    if not w1.soft_tap(nodes, "新建笔记") and not w1.soft_tap(nodes, "写一条笔记"):
        for n in nodes:
            if n["click"] == "true" and n.get("box") and n["box"][0] > 2200 and n["box"][1] < 220:
                w1.tap_xy(*w1.center(n["box"]))
                break
    nodes = w1.capture("55-note-new", wait=1.0)
    save = w1.has_label(nodes, "保存笔记")
    if save and save.get("box") and len(save["box"]) == 4:
        x1, y1, x2, y2 = save["box"]
        h = y2 - y1
        if y2 <= 1588 and h >= 60:
            record("N01", "通过", f"「保存笔记」完整可见 bounds={save['bounds']} height={h}")
        else:
            record("N01", "未通过", f"按钮可能被裁切 bounds={save['bounds']} height={h}")
    else:
        record("N01", "未通过", "未见「保存笔记」: " + w1.all_text(nodes)[:400])
    w1.back()

    # ---- Search ----
    leave_to_shell()
    w1.go_tab("发现")
    nodes = w1.capture("60-discover-search", wait=0.7)
    if w1.soft_tap(nodes, "搜索国家、地点或问题") or w1.soft_tap(nodes, "搜索"):
        time.sleep(0.8)
        nodes = w1.capture("61-search", wait=0.8)
        kb = w1.keyboard_visible()
        if not kb:
            record("S01", "通过", "平板打开搜索后系统键盘未自动弹出")
        else:
            record("S01", "未通过", "平板仍自动弹出键盘")
        edit = next((n for n in nodes if "EditText" in (n.get("class") or "")), None)
        if edit and ("搜索" in (edit["desc"] or "") or "搜索" in (edit["text"] or "")):
            record("S02", "通过", f"搜索框有名称 desc={edit['desc']!r} text={edit['text']!r}")
        elif w1.has_label(nodes, "搜索"):
            record("S02", "通过", "页面存在「搜索」标签")
        else:
            record("S02", "未通过", "搜索框可能没有无障碍名称")
        w1.back()

    # ---- Parent / packs / credits ----
    leave_to_shell()
    w1.go_tab("我的")
    nodes = w1.capture("70-me-parent", wait=0.8)
    entered = False
    if w1.soft_tap(nodes, "家长入口") or w1.soft_tap(nodes, "家长"):
        nodes = w1.capture("71-parent-gate", wait=1.0)
        gate = (
            w1.find(nodes, "长按 2 秒进入", clickable=True)
            or w1.find(nodes, "长按 2 秒进入", clickable=False)
            or w1.find(nodes, "长按两秒", clickable=False)
            or w1.find(nodes, "家长入口，长按两秒进入", clickable=False)
        )
        if gate:
            w1.long_press_node(gate, ms=2500)
            nodes = w1.capture("72-parent-center", wait=1.2)
            if not (
                w1.has_label(nodes, "让探索更适合孩子")
                or w1.has_label(nodes, "内容包")
                or w1.has_label(nodes, "休息提醒")
            ):
                w1.long_press_node(gate, ms=2800)
                nodes = w1.capture("72b-parent-center", wait=1.2)
            entered = bool(
                w1.has_label(nodes, "让探索更适合孩子")
                or w1.has_label(nodes, "休息提醒")
                or w1.has_label(nodes, "内容包")
            )
    if not entered:
        record("P01", "未打开", "未能进入家长中心")
        record("PK01", "未打开", "未能进入内容包")
        record("PK02", "未打开", "未能进入内容包")
        record("CR01", "未打开", "未能进入来源页")
        record("CR02", "未打开", "未能进入来源页")
    else:
        nodes = w1.capture("73-parent-center", wait=0.3)
        if w1.has_label(nodes, "内容包"):
            record("P01", "通过", "家长中心可见「内容包」入口")
        else:
            w1.swipe_up(1)
            nodes = w1.capture("73b-parent", wait=0.5)
            if w1.has_label(nodes, "离线内容包") or w1.has_label(nodes, "内容包"):
                record("P01", "通过", "下滑后可见内容包入口")
            else:
                record("P01", "未通过", "未见内容包入口: " + w1.all_text(nodes)[:400])
        if w1.soft_tap(nodes, "内容包") or w1.soft_tap(nodes, "离线内容包"):
            nodes = w1.capture("74-packs", wait=1.2)
            if w1.soft_tap(nodes, "中国内容包") or w1.soft_tap(nodes, "中国"):
                nodes = w1.capture("75-pack-china", wait=1.2)
                header_view = any(
                    (n["text"] == "查看" or n["desc"] == "查看")
                    and n.get("box")
                    and n["box"][1] < 700
                    for n in nodes
                )
                record(
                    "PK01",
                    "未通过" if header_view else "通过",
                    "详情页顶部仍有「查看」" if header_view else "详情页顶部未见多余的「查看」",
                )
                if w1.has_label(nodes, "开始探索"):
                    record("PK02", "通过", "首屏可见「开始探索」")
                else:
                    record("PK02", "未通过", "详情首屏未见「开始探索」: " + w1.all_text(nodes)[:400])
                w1.back()
        _, nodes = w1.dump_ui()
        if not w1.has_label(nodes, "内容来源") and not w1.has_label(nodes, "来源与许可"):
            w1.back()
            nodes = w1.capture("76-back-parent", wait=0.7)
            if not w1.has_label(nodes, "内容来源"):
                w1.swipe_up(1)
                nodes = w1.capture("76b-parent", wait=0.5)
        if (
            w1.has_label(nodes, "内容来源与许可")
            or w1.has_label(nodes, "来源与许可")
            or w1.has_label(nodes, "内容来源")
        ):
            t0 = time.time()
            w1.soft_tap(nodes, "内容来源") or w1.soft_tap(nodes, "来源与许可")
            appeared = None
            for _ in range(20):
                time.sleep(0.4)
                _, nodes = w1.dump_ui()
                if (
                    w1.has_label(nodes, "每一个发现")
                    or w1.has_label(nodes, "文字资料")
                    or w1.has_label(nodes, "来源与许可")
                ):
                    appeared = time.time() - t0
                    break
            elapsed = appeared if appeared is not None else time.time() - t0
            nodes = w1.capture("77-credits", wait=0.3)
            if appeared is not None and appeared <= 5.0:
                record("CR01", "通过", f"来源页约 {elapsed:.2f} 秒出现内容")
            elif appeared is not None:
                record("CR01", "未通过", f"来源页 {elapsed:.2f} 秒才出现内容")
            else:
                record("CR01", "未通过", f"等待 {elapsed:.2f} 秒仍未见到来源页内容")
            if not w1.has_label(nodes, "开源软件许可"):
                for i in range(8):
                    w1.swipe_up(1)
                    nodes = w1.capture(f"77b-credits-s{i}", wait=0.4)
                    if w1.has_label(nodes, "开源软件许可"):
                        break
            if w1.soft_tap(nodes, "开源软件许可"):
                time.sleep(1.0)
                nodes = w1.capture("78-licenses", wait=1.2)
            t = w1.all_text(nodes)
            if "0.8.0" in t:
                record("CR02", "通过", "许可页版本为 0.8.0")
            elif "0.6.0" in t:
                record("CR02", "未通过", "许可页仍显示 0.6.0")
            else:
                record("CR02", "待目视", "未见版本号: " + t[:400])

    # ---- Article R01 / R02 / Egypt map M02 ----
    leave_to_shell()
    w1.go_tab("发现")
    nodes = w1.capture("80-discover-for-article", wait=0.8)
    if not w1.soft_tap(nodes, "开始探索"):
        # go egypt via encyclopedia
        nodes = ency_countries()
        reveal_and_tap(nodes, "埃及", "egypt2")
        nodes = w1.capture("80-egypt-hub", wait=1.0)
    else:
        nodes = w1.capture("80-egypt-hub", wait=1.1)
    if w1.soft_tap(nodes, "沿着尼罗河"):
        nodes = w1.capture("81-nile-journey", wait=1.1)
        # if CTA is low, swipe slightly up first
        n = w1.find(nodes, "继续这条路线", clickable=True)
        if n and n.get("box") and n["box"][1] > 1300:
            w1.swipe(1280, 1100, 1280, 900, 250)
            time.sleep(0.4)
            nodes = w1.capture("81b-nile-raised", wait=0.5)
        if w1.soft_tap(nodes, "继续这条路线"):
            nodes = w1.capture("82-egypt-article", wait=1.4)
            t = w1.all_text(nodes)
            title_ok = w1.has_label(nodes, "尼罗河流向哪里") or w1.has_label(
                nodes, "尼罗河为什么重要"
            )
            if title_ok:
                record("R01", "通过", "阅读页可见文章标题")
            else:
                record("R01", "未通过", "未见文章标题: " + t[:500])
            if w1.has_label(nodes, "打开埃及地图") or w1.has_label(nodes, "找北箭头"):
                record("R02", "通过", "正文动作改为明确的打开地图说明")
            elif w1.has_label(nodes, "在地图上看看"):
                record("R02", "未通过", "仍是旧文案「在地图上看看」")
            else:
                record("R02", "待目视", "对照截图看示意图与地图入口: " + t[:400])
            if w1.soft_tap(nodes, "打开埃及地图") or w1.soft_tap(nodes, "找北箭头") or w1.soft_tap(
                nodes, "在地图上看看"
            ):
                nodes = w1.capture("83-egypt-map", wait=1.6)
                record("M02", "待目视", "已打开埃及地图，对照截图看右栏是否可滚动")
                w1.swipe_up(1)
                w1.capture("83b-egypt-map-scrolled", wait=0.7)

    leave_to_shell()
    w1.go_tab("发现")
    w1.capture("99-back-discover", wait=0.7)
    SUMMARY.write_text(json.dumps(RESULTS, ensure_ascii=False, indent=2), encoding="utf-8")
    print("\n======= RECHECK2 RESULTS =======")
    for r in RESULTS:
        print(f"{r['id']:12} {r['status']:8} {r['detail']}")
    print("RECHECK_WALK2_DONE")


if __name__ == "__main__":
    main()
