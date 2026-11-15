#!/usr/bin/env python3
"""Full walk of 12 editorial countries, remaining topics, Antarctica, packs, reader."""
from __future__ import annotations

import json
import sys
import traceback
from datetime import datetime
from pathlib import Path

sys.path.insert(0, "/Users/penn/Projects/world_explorer/docs/review/tools")
from walk import (
    ADB,
    REVIEW,
    adb,
    back,
    capture,
    current_app_ok,
    find,
    long_press,
    sleep,
    swipe,
    tap_xy,
)

LOG = REVIEW / "country_walk_log.jsonl"

EDITORIAL = [
    ("china", "中国", ["山河", "生活", "文明"]),
    ("egypt", "埃及", ["沿着尼罗河", "走进今天", "追寻文明"]),
    ("usa", "美国", ["沿着山河走", "走进城市", "循着历史找"]),
    ("gbr", "英国", ["沿着河流进城", "去海岸找线索", "顺着时间找证据"]),
    ("brazil", "巴西", ["河流与雨林", "城市与生活", "自然的节奏"]),
    ("japan", "日本", ["岛屿与山海", "城市的一天", "物件里的时间"]),
    ("kenya", "肯尼亚", ["高山与水", "城市与海岸", "生命的空间"]),
    ("norway", "挪威", ["峡湾与木城", "城市里的日常", "北方的光与生命"]),
    ("aus", "澳大利亚", ["海岸与城市", "红土与水", "动物的家"]),
    ("fra", "法国", ["河岸里的城市", "山海的变化", "物件里的时间"]),
    ("deu", "德国", ["河流与城市", "森林与海岸", "物件里的时间"]),
    ("zaf", "南非", ["海岸与生命", "山地与草原", "城市里的生活"]),
]

TOPICS = ["学做世界观察员", "一起守护世界"]

MAP_LABELS = [
    "在地图上看看",
    "在地图上找到它",
    "在地图上认识",
    "打开南极地图",
    "从世界地图",
    "打开地图",
]


def log(event, **kw):
    rec = {"ts": datetime.now().isoformat(timespec="seconds"), "event": event, **kw}
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    slim = {k: v for k, v in kw.items() if k not in {"labels", "trace"}}
    print("LOG", event, slim, flush=True)


def labels(nodes):
    return [n["desc"] or n["text"] for n in nodes if n["desc"] or n["text"]]


def blob_of(n):
    return (n["desc"] or "") + "\n" + (n["text"] or "")


def find_exact(nodes, label, clickable=None):
    for n in nodes:
        if clickable is True and n["click"] != "true":
            continue
        if n["desc"] == label or n["text"] == label:
            return n
    return None


def find_line(nodes, label, clickable=None):
    """Match a whole line, avoiding substring false positives."""
    for n in nodes:
        if clickable is True and n["click"] != "true":
            continue
        lines = [ln.strip() for ln in blob_of(n).split("\n") if ln.strip()]
        if label in lines or (n["desc"] or "").startswith(label + "\n"):
            return n
    return None


def find_startswith(nodes, prefix, clickable=None):
    for n in nodes:
        if clickable is True and n["click"] != "true":
            continue
        if (n["desc"] or "").startswith(prefix) or (n["text"] or "").startswith(prefix):
            return n
    return None


def soft_tap_node(n, label=""):
    if not n or len(n["box"]) != 4:
        return False
    x, y = (n["box"][0] + n["box"][2]) // 2, (n["box"][1] + n["box"][3]) // 2
    if y > 1450:
        # too close to the system gesture bar — do not tap
        print(f"SKIP TAP {label!r} y={y} too low bounds={n['bounds']}", flush=True)
        return False
    if y < 40:
        print(f"SKIP TAP {label!r} y={y} too high bounds={n['bounds']}", flush=True)
        return False
    print(f"SOFT TAP {label!r} -> {x},{y} bounds={n['bounds']}", flush=True)
    tap_xy(x, y)
    return True


def soft_tap(nodes, label, exact=False, line=False):
    if exact:
        n = find_exact(nodes, label, clickable=True) or find_exact(nodes, label)
    elif line:
        n = find_line(nodes, label, clickable=True) or find_line(nodes, label)
    else:
        n = find(nodes, label, clickable=True) or find(nodes, label, clickable=False)
    return soft_tap_node(n, label)


def safe_swipe(direction="up"):
    if direction == "up":
        swipe(1280, 1080, 1280, 520, 380)
    else:
        swipe(1280, 520, 1280, 1080, 380)
    sleep(0.45)


def relaunch():
    adb("shell", "am", "start", "-n", "com.example.world_explorer/.MainActivity")
    sleep(2.2)
    log("relaunched", app_ok=current_app_ok())
    return capture("relaunch", wait=1.0)


def ensure_app(nodes=None):
    if not current_app_ok():
        log("left_app_relaunching")
        return relaunch()
    return nodes if nodes is not None else capture("_cur", wait=0.3)


def dismiss_rest(nodes=None):
    nodes = ensure_app(nodes)
    if find_exact(nodes, "休息一下") or find(nodes, "让眼睛也去旅行", clickable=False):
        log("rest_shown")
        if soft_tap(nodes, "稍后提醒我", exact=True) or soft_tap(nodes, "休息好了，继续探索", exact=True):
            sleep(1.2)
            return capture("_after_rest", wait=0.4)
    return nodes


def has_tabs(nodes):
    return bool(find_exact(nodes, "发现") and find_exact(nodes, "百科"))


def on_countries_tab(nodes):
    return bool(find_exact(nodes, "国家") and (find_exact(nodes, "全部") or find_exact(nodes, "亚洲")))


def on_topics_tab(nodes):
    return bool(
        find(nodes, "沿着好奇心看世界", clickable=False)
        or find(nodes, "一个问题，连接不同的地方", clickable=False)
    )


def back_to_shell(max_backs=8):
    nodes = dismiss_rest()
    for _ in range(max_backs):
        nodes = dismiss_rest(nodes)
        if not current_app_ok():
            return relaunch()
        if has_tabs(nodes):
            return nodes
        back()
        sleep(0.7)
        nodes = capture("_nav", wait=0.3)
    log("back_to_shell_failed", labels=labels(nodes)[:15])
    return nodes


def tap_tab(nodes, name):
    nodes = dismiss_rest(nodes)
    if not soft_tap(nodes, name, exact=True):
        log("tab_missing", name=name)
        return nodes
    sleep(1.1)
    return dismiss_rest(capture(f"tab-{name}", wait=0.5))


def scroll_to_top(times=4):
    for _ in range(times):
        safe_swipe("down")


def scroll_until(pred, shot_prefix, max_swipes=8, downward_first=True):
    nodes = dismiss_rest()
    if downward_first:
        scroll_to_top(2)
        nodes = dismiss_rest(capture(f"{shot_prefix}-top", wait=0.3))
        if pred(nodes):
            # if the match is clipped at the bottom, swipe up once
            return reveal_if_clipped(nodes, pred, shot_prefix)
    for i in range(max_swipes + 1):
        nodes = dismiss_rest(ensure_app(nodes))
        if pred(nodes):
            return reveal_if_clipped(nodes, pred, shot_prefix)
        safe_swipe("up")
        nodes = capture(f"{shot_prefix}-{i}", wait=0.35)
    return nodes


def node_clipped(n):
    if not n or len(n["box"]) != 4:
        return True
    y1, y2 = n["box"][1], n["box"][3]
    return y2 > 1520 or y1 < 80 or (y2 - y1) < 80


def reveal_if_clipped(nodes, pred, shot_prefix):
    # Try to identify the matching node and scroll it into a safe tap zone.
    # pred is a lambda on nodes, so re-run after a cautious swipe.
    # We look for a recently targeted card by calling pred after small swipes.
    for i in range(3):
        # If some clickable match exists and is not clipped, stop
        # (pred itself doesn't return the node; caller will re-find.)
        nodes = dismiss_rest(nodes)
        # Heuristic: if any clickable node in the bottom 80px exists and pred is true,
        # swipe up a little to reveal it.
        bottomish = [
            n
            for n in nodes
            if n["click"] == "true" and n["box"] and n["box"][3] > 1520 and n["box"][1] > 1400
        ]
        if not bottomish:
            return nodes
        # only nudge if pred still holds after we might need more of the card
        swipe(1280, 1100, 1280, 820, 320)
        sleep(0.4)
        nodes = capture(f"{shot_prefix}-reveal-{i}", wait=0.3)
        if not pred(nodes):
            # went too far; try a little back
            swipe(1280, 820, 1280, 1000, 280)
            sleep(0.35)
            nodes = capture(f"{shot_prefix}-reveal-back", wait=0.3)
            return nodes
    return nodes


def go_ency_countries():
    nodes = back_to_shell()
    nodes = tap_tab(nodes, "百科")
    scroll_to_top(3)
    nodes = dismiss_rest(capture("110-ency-top", wait=0.6))
    if on_topics_tab(nodes) and not on_countries_tab(nodes):
        if not soft_tap(nodes, "国家", exact=True):
            log("country_segment_missing", labels=labels(nodes)[:20])
        else:
            sleep(1.0)
            nodes = dismiss_rest(capture("110-ency-countries", wait=0.6))
    if not on_countries_tab(nodes):
        # maybe header scrolled off
        scroll_to_top(4)
        nodes = dismiss_rest(capture("110-ency-top2", wait=0.5))
        if soft_tap(nodes, "国家", exact=True):
            sleep(1.0)
            nodes = dismiss_rest(capture("110-ency-countries2", wait=0.6))
    log("encyclopedia_countries", ok=on_countries_tab(nodes), labels=labels(nodes)[:30])
    return nodes


def go_ency_topics():
    nodes = back_to_shell()
    nodes = tap_tab(nodes, "百科")
    scroll_to_top(3)
    nodes = dismiss_rest(capture("111-ency-top", wait=0.6))
    if find_exact(nodes, "专题"):
        soft_tap(nodes, "专题", exact=True)
        sleep(1.0)
        nodes = dismiss_rest(capture("111-topics", wait=0.7))
    log("encyclopedia_topics", labels=labels(nodes)[:20])
    return nodes


def walk_continent_filters(nodes):
    filters = ["亚洲", "欧洲", "非洲", "北美洲", "南美洲", "大洋洲", "全部"]
    results = {}
    for f in filters:
        scroll_to_top(2)
        nodes = dismiss_rest(capture(f"112-filter-before-{f}", wait=0.3))
        if not soft_tap(nodes, f, exact=True):
            log("filter_missing", name=f)
            results[f] = "missing"
            continue
        sleep(0.9)
        nodes = dismiss_rest(capture(f"112-filter-{f}", wait=0.5))
        names = []
        for n in nodes:
            if n["click"] == "true" and "\n" in (n["desc"] or "") and n["box"] and n["box"][0] > 200:
                names.append((n["desc"] or "").split("\n")[0])
        empty = bool(find(nodes, "这里的国家内容即将上线", clickable=False))
        results[f] = {"countries": names, "empty": empty}
        log("continent_filter", name=f, countries=names, empty=empty)
    return nodes


def country_card(nodes, name):
    return find_startswith(nodes, name + "\n", clickable=True) or find_line(nodes, name, clickable=True)


def walk_country(cid, name, journeys):
    nodes = go_ency_countries()
    nodes = scroll_until(lambda n, nm=name: country_card(n, nm) is not None, f"120-find-{cid}", 8)
    card = country_card(nodes, name)
    if not card:
        log("country_missing", id=cid, name=name, labels=labels(nodes)[:25])
        return
    if not soft_tap_node(card, name):
        # clipped; try one more reveal
        safe_swipe("up")
        nodes = dismiss_rest(capture(f"120-find-{cid}-nudge", wait=0.4))
        card = country_card(nodes, name)
        if not card or not soft_tap_node(card, name):
            log("country_untappable", id=cid, name=name, bounds=card["bounds"] if card else None)
            return

    nodes = dismiss_rest(capture(f"121-{cid}-hub", wait=1.8))
    log("country_hub", id=cid, name=name, labels=labels(nodes))
    # full scroll of hub
    for i in range(1, 5):
        safe_swipe("up")
        nodes = dismiss_rest(capture(f"121-{cid}-hub-s{i}", wait=0.55))
        log(f"country_hub_scroll", id=cid, i=i, labels=labels(nodes))
        # stop early if we hit the end-ish
        if find(nodes, "资料来源与图片许可") or find(nodes, "查看全部 10 个栏目"):
            break

    present = []
    for j in journeys:
        scroll_to_top(3)
        nodes = scroll_until(lambda n, jj=j: find_line(n, jj) is not None, f"122-{cid}-find-{j}", 6)
        target = find_line(nodes, j, clickable=True) or find_line(nodes, j)
        if target and soft_tap_node(target, j):
            present.append(j)
            nodes = dismiss_rest(capture(f"123-{cid}-journey-{j}", wait=1.6))
            log("journey", id=cid, journey=j, labels=labels(nodes))
            safe_swipe("up")
            nodes = dismiss_rest(capture(f"123b-{cid}-journey-{j}-s", wait=0.6))
            # open first article / first stop if present
            opened = open_first_article(nodes, f"124-{cid}-{j}")
            if opened:
                back()
                sleep(1.0)
            back()
            sleep(1.0)
            nodes = dismiss_rest()
        else:
            log("journey_missing", id=cid, journey=j, labels=labels(nodes)[:20])
    log("journeys_present", id=cid, present=present, expected=journeys)

    # map
    scroll_to_top(3)
    nodes = scroll_until(lambda n: any(find(n, lab) for lab in MAP_LABELS) or find(n, "打开" + name + "探索地图"), f"125-{cid}-find-map", 7)
    map_label = None
    map_node = find(nodes, "打开" + name + "探索地图")
    if map_node:
        map_label = "打开" + name + "探索地图"
    else:
        for cand in MAP_LABELS:
            if find(nodes, cand):
                map_label = cand
                map_node = find(nodes, cand, clickable=True) or find(nodes, cand)
                break
    if map_label and soft_tap_node(map_node, map_label):
        nodes = dismiss_rest(capture(f"126-{cid}-map", wait=2.0))
        log("country_map", id=cid, via=map_label, labels=labels(nodes)[:25])
        back()
        sleep(1.0)
    else:
        log("country_map_missing", id=cid, labels=labels(nodes)[:20])

    # return
    nodes = back_to_shell()
    log("country_done", id=cid, app_ok=current_app_ok())


def open_first_article(nodes, prefix):
    # Prefer numbered stops or obvious article rows, never "换个主题" / map / 返回
    skip = ("返回", "收藏", "在地图", "换个主题", "图片来源", "完整目录", "阅读选项")
    candidates = []
    for n in nodes:
        if n["click"] != "true" or len(n["box"]) != 4:
            continue
        b = (n["desc"] or n["text"] or "").strip()
        if not b or any(s in b for s in skip):
            continue
        if b.startswith("01") or "阅读 ·" in b or b.startswith("第") or "可以离线阅读" in b:
            candidates.append((0, n, b))
        elif n["box"][1] > 400 and n["box"][2] - n["box"][0] > 400:
            candidates.append((1, n, b))
    candidates.sort(key=lambda x: (x[0], x[1]["box"][1]))
    for _, n, b in candidates[:4]:
        if soft_tap_node(n, b[:40]):
            art = dismiss_rest(capture(f"{prefix}-article", wait=1.6))
            # confirm it looks like a reader
            if find(art, "听讲解") or find(art, "这篇文章") or find(art, "阅读 ·") or find(art, "认识一个词"):
                log("article_opened", item=b, labels=labels(art)[:20])
                return True
            log("article_open_maybe", item=b, labels=labels(art)[:20])
            back()
            sleep(0.8)
            nodes = dismiss_rest()
    log("article_not_opened", prefix=prefix)
    return False


def walk_topics():
    nodes = go_ency_topics()
    for title in TOPICS:
        scroll_to_top(3)
        nodes = scroll_until(lambda n, t=title: find_line(n, t) is not None, f"130-find-{title}", 6)
        target = find_line(nodes, title, clickable=True) or find_line(nodes, title)
        if not target:
            log("topic_missing", title=title)
            continue
        if not soft_tap_node(target, title):
            log("topic_untappable", title=title)
            continue
        slug = title.replace("？", "")
        nodes = dismiss_rest(capture(f"131-topic-{slug}", wait=1.6))
        # verify heading
        ok = bool(find_line(nodes, title) or find_exact(nodes, title))
        # mismatch if another known topic heading is present and this title is not a heading
        log("topic_hub", title=title, verified=ok, labels=labels(nodes))
        if not ok:
            log("topic_mismatch", title=title, labels=labels(nodes)[:15])
        safe_swipe("up")
        nodes = dismiss_rest(capture(f"131b-topic-{slug}-s", wait=0.6))
        opened = False
        for n in nodes:
            b = n["desc"] or n["text"]
            if n["click"] == "true" and b.startswith("01"):
                if soft_tap_node(n, b[:40]):
                    art = dismiss_rest(capture(f"131c-topic-{slug}-art", wait=1.6))
                    log("topic_item", title=title, item=b, labels=labels(art)[:20])
                    back()
                    sleep(1.0)
                    opened = True
                    break
        if not opened:
            log("topic_no_article", title=title)
        nodes = back_to_shell()
        # make sure we are back on topics for the next one
        nodes = go_ency_topics()
        log("topic_done", title=title, verified=ok)


def walk_antarctica():
    nodes = go_ency_topics()
    scroll_to_top(2)
    nodes = scroll_until(lambda n: find(n, "南极洲"), "140-find-ant", 5)
    target = find_line(nodes, "南极洲", clickable=True) or find(nodes, "南极洲", clickable=True)
    if not target or not soft_tap_node(target, "南极洲"):
        log("antarctica_missing", labels=labels(nodes)[:20])
        return
    nodes = dismiss_rest(capture("141-ant-hub", wait=1.8))
    log("antarctica_hub", labels=labels(nodes))
    for i in range(1, 4):
        safe_swipe("up")
        nodes = dismiss_rest(capture(f"141-ant-hub-s{i}", wait=0.55))
        log("antarctica_hub_scroll", i=i, labels=labels(nodes))

    actions = [
        ("开始探索", "142-ant-explore"),
        ("打开南极地图", "143-ant-map"),
        ("探索任务", "144-ant-tasks"),
        ("认识南极的时间线", "145-ant-timeline"),
        ("我的发现", "146-ant-discoveries"),
        ("摄影与资料来源", "147-ant-credits"),
    ]
    for label, shot in actions:
        scroll_to_top(3)
        nodes = scroll_until(lambda n, lb=label: find(n, lb) is not None, f"{shot}-find", 5)
        if soft_tap(nodes, label):
            nodes = dismiss_rest(capture(shot, wait=1.8))
            log("antarctica_page", via=label, labels=labels(nodes)[:25])
            if label == "开始探索":
                safe_swipe("up")
                capture(shot + "-s", wait=0.6)
            back()
            sleep(1.0)
            # if we left the hub, try to return
            nodes = dismiss_rest()
            if not (find(nodes, "打开南极地图") or find(nodes, "南极洲")):
                nodes = back_to_shell()
                walk_antarctica_reenter = True
                nodes = go_ency_topics()
                nodes = scroll_until(lambda n: find(n, "南极洲"), "140-reenter-ant", 4)
                t2 = find(nodes, "南极洲", clickable=True)
                if t2:
                    soft_tap_node(t2, "南极洲")
                    sleep(1.4)
        else:
            log("antarctica_action_missing", via=label)
    log("antarctica_done", app_ok=current_app_ok())


def walk_packs():
    nodes = back_to_shell()
    nodes = tap_tab(nodes, "我的")
    scroll_to_top(3)
    nodes = scroll_until(lambda n: find(n, "家长入口"), "150-me-parent", 6)
    target = find_line(nodes, "家长入口", clickable=True) or find(nodes, "家长入口")
    if not target:
        log("parent_entry_missing")
        return
    # reveal full card if clipped
    if target["box"][3] > 1500:
        swipe(1280, 1100, 1280, 800, 320)
        sleep(0.4)
        nodes = dismiss_rest(capture("150-me-parent-revealed", wait=0.4))
        target = find(nodes, "家长入口") or target
    try:
        # Prefer the explicit long-press target if visible
        if find(nodes, "长按 2 秒进入") or find(nodes, "家长入口，长按两秒进入"):
            long_press(nodes, "长按 2 秒进入" if find(nodes, "长按 2 秒进入") else "家长入口，长按两秒进入", 2400)
        else:
            long_press(nodes, "家长入口", 2400)
    except SystemExit as e:
        log("parent_longpress_failed", error=str(e))
        return
    nodes = dismiss_rest(capture("151-parent", wait=1.6))
    log("parent_opened", labels=labels(nodes))
    nodes = scroll_until(lambda n: find(n, "离线内容包"), "151-parent-packs", 5)
    if not soft_tap(nodes, "离线内容包", exact=True) and not soft_tap(nodes, "离线内容包"):
        log("packs_entry_missing", labels=labels(nodes)[:20])
        return
    for i in range(12):
        nodes = dismiss_rest(capture(f"152-packs-s{i}", wait=0.55))
        log("packs_scroll", i=i, labels=labels(nodes))
        names = [lb for lb in labels(nodes) if any(x in lb for x in [c[1] for c in EDITORIAL])]
        if i >= 11:
            break
        safe_swipe("up")
    log("packs_done")
    back()
    sleep(0.8)
    if not has_tabs(dismiss_rest()):
        back()
        sleep(0.8)


def restore_white():
    try:
        nodes = back_to_shell()
        nodes = tap_tab(nodes, "我的")
        scroll_to_top(3)
        nodes = dismiss_rest(capture("160-me-top", wait=0.6))
        if not soft_tap(nodes, "阅读设置", exact=True):
            log("reading_settings_missing")
            return
        nodes = dismiss_rest(capture("160-reading", wait=1.2))
        log("reading_settings", labels=labels(nodes))
        if soft_tap(nodes, "清爽白"):
            sleep(0.6)
            capture("160-reading-white", wait=0.5)
            log("restored_white")
        else:
            log("white_bg_untappable", labels=labels(nodes)[:20])
        back()
        sleep(0.8)
    except Exception as e:
        log("restore_white_error", error=str(e))


def walk_reader_features():
    """Open a known article and exercise TTS, glossary, and related place if present."""
    try:
        nodes = go_ency_countries()
        nodes = scroll_until(lambda n: country_card(n, "中国") is not None, "170-find-china", 6)
        card = country_card(nodes, "中国")
        if not card or not soft_tap_node(card, "中国"):
            log("reader_no_china")
            return
        nodes = dismiss_rest(capture("170-china-hub", wait=1.6))
        # Try a question link or first obvious article
        opened = False
        for cand in ["大熊猫为什么需要竹林？", "中国的地势有什么不同？", "你想先发现什么？"]:
            scroll_to_top(2)
            nodes = scroll_until(lambda n, c=cand: find(n, c) is not None, f"170-find-{cand}", 5)
            if cand != "你想先发现什么？" and soft_tap(nodes, cand):
                art = dismiss_rest(capture("171-reader", wait=1.6))
                opened = True
                break
        if not opened:
            opened = open_first_article(dismiss_rest(), "171-reader")
            art = dismiss_rest()
        if not opened and not (find(art, "听讲解") or find(art, "这篇文章")):
            log("reader_article_missing", labels=labels(art)[:20] if art else [])
            return
        log("reader_open", labels=labels(art)[:25])
        if find(art, "听讲解") and soft_tap(art, "听讲解", exact=True):
            sleep(1.4)
            art = dismiss_rest(capture("172-tts", wait=0.8))
            log("reader_tts", labels=labels(art)[:20])
            # stop if a stop control appeared
            if find(art, "停止") or find(art, "暂停"):
                soft_tap(art, "停止") or soft_tap(art, "暂停")
                sleep(0.4)
        # glossary
        art = dismiss_rest()
        g = None
        for n in art:
            b = n["desc"] or n["text"]
            if n["click"] == "true" and b.startswith("认识一个词"):
                g = n
                break
        if g and soft_tap_node(g, (g["desc"] or "")[:20]):
            art = dismiss_rest(capture("173-glossary", wait=1.0))
            log("reader_glossary", labels=labels(art)[:20])
            if find(art, "关闭词语解释"):
                soft_tap(art, "关闭词语解释", exact=True)
                sleep(0.5)
        # try 在地图上看看 from reader
        if find(art, "在地图上看看") and soft_tap(art, "在地图上看看"):
            m = dismiss_rest(capture("174-reader-map", wait=1.8))
            log("reader_map", labels=labels(m)[:20])
            back()
            sleep(0.9)
            art = dismiss_rest()
        log("reader_features_done")
        back_to_shell()
    except Exception as e:
        log("reader_features_error", error=str(e), trace=traceback.format_exc()[-600:])


def main():
    log("country_walk_start", app_ok=current_app_ok())
    if not current_app_ok():
        relaunch()
    restore_white()
    nodes = go_ency_countries()
    walk_continent_filters(nodes)
    for cid, name, journeys in EDITORIAL:
        try:
            walk_country(cid, name, journeys)
        except Exception as e:
            log("country_error", id=cid, error=str(e), trace=traceback.format_exc()[-800:])
            if not current_app_ok():
                relaunch()
            back_to_shell()
    try:
        walk_topics()
    except Exception as e:
        log("topics_error", error=str(e), trace=traceback.format_exc()[-600:])
        if not current_app_ok():
            relaunch()
    try:
        walk_antarctica()
    except Exception as e:
        log("antarctica_error", error=str(e), trace=traceback.format_exc()[-600:])
        if not current_app_ok():
            relaunch()
    try:
        walk_packs()
    except Exception as e:
        log("packs_error", error=str(e), trace=traceback.format_exc()[-600:])
        if not current_app_ok():
            relaunch()
    try:
        walk_reader_features()
    except Exception as e:
        log("reader_error", error=str(e), trace=traceback.format_exc()[-600:])
    log("country_walk_done", app_ok=current_app_ok())
    print("COUNTRY_WALK_DONE", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        log("country_walk_fatal", trace=traceback.format_exc())
        print("COUNTRY_WALK_FAILED", flush=True)
        raise
