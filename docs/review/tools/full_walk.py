#!/usr/bin/env python3
"""Full coverage walk: topics, Antarctica, 12 editorial country hubs/journeys/maps."""
from __future__ import annotations

import json
import sys
import time
import traceback
from datetime import datetime
from pathlib import Path

sys.path.insert(0, "/Users/penn/Projects/world_explorer/docs/review/tools")
from walk import (
    REVIEW,
    SHOTS,
    back,
    capture,
    current_app_ok,
    find,
    sleep,
    swipe,
    tap,
    tap_xy,
)

LOG = REVIEW / "full_walk_log.jsonl"
SUMMARY = REVIEW / "full_walk_summary.md"

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

TOPICS = [
    "江河与文明",
    "雨林与生命",
    "世界上的不同生活",
    "石头会讲故事吗？",
    "双手里的文化",
    "水从哪里来？",
    "学做世界观察员",
    "一起守护世界",
]


def log(event, **kw):
    rec = {"ts": datetime.now().isoformat(timespec="seconds"), "event": event, **kw}
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    print("LOG", event, kw, flush=True)


def labels(nodes):
    return [n["desc"] or n["text"] for n in nodes if n["desc"] or n["text"]]


def find_exact(nodes, label, clickable=None):
    for n in nodes:
        if clickable is True and n["click"] != "true":
            continue
        if clickable is False and n["click"] == "true":
            continue
        if n["desc"] == label or n["text"] == label:
            return n
    return None


def soft_tap(nodes, label, exact=False):
    n = find_exact(nodes, label, clickable=True) if exact else find(nodes, label, clickable=True)
    if not n or len(n["box"]) != 4:
        return False
    x, y = (n["box"][0] + n["box"][2]) // 2, (n["box"][1] + n["box"][3]) // 2
    print(f"SOFT TAP {label!r} -> {x},{y}  bounds={n['bounds']}", flush=True)
    tap_xy(x, y)
    return True


def dismiss_rest(nodes=None):
    if nodes is None:
        nodes = capture("_restcheck", wait=0.25)
    if find_exact(nodes, "休息一下") or find(nodes, "让眼睛也去旅行", clickable=False):
        log("rest_shown")
        if soft_tap(nodes, "稍后提醒我", exact=True) or soft_tap(nodes, "休息好了，继续探索", exact=True):
            sleep(1.2)
            return capture("_after_rest", wait=0.4)
    return nodes


def has_tabs(nodes):
    return bool(find_exact(nodes, "发现") and find_exact(nodes, "百科"))


def back_to_shell(max_backs=12):
    nodes = dismiss_rest()
    for _ in range(max_backs):
        nodes = dismiss_rest(nodes)
        if has_tabs(nodes):
            return nodes
        back()
        sleep(0.7)
        nodes = capture("_nav", wait=0.35)
    log("back_to_shell_failed", labels=labels(nodes)[:15])
    return nodes


def tap_tab(nodes, name):
    nodes = dismiss_rest(nodes)
    if not soft_tap(nodes, name, exact=True):
        log("tab_missing", name=name, labels=labels(nodes)[:20])
        return nodes
    sleep(1.2)
    return dismiss_rest(capture(f"tab-{name}", wait=0.5))


def scroll_until(pred, shot_prefix, max_swipes=6):
    nodes = dismiss_rest()
    for i in range(max_swipes + 1):
        nodes = dismiss_rest(nodes)
        if pred(nodes):
            return nodes
        swipe(1280, 1350, 1280, 550, 400)
        sleep(0.45)
        nodes = capture(f"{shot_prefix}-{i}", wait=0.35)
    return nodes


def restore_white_bg(nodes):
    try:
        nodes = tap_tab(nodes, "我的")
        nodes = dismiss_rest(capture("restore-settings-entry", wait=0.8))
        if not find(nodes, "清爽白", clickable=False) and not find(nodes, "柔和米色", clickable=False):
            if soft_tap(nodes, "阅读设置"):
                nodes = dismiss_rest(capture("restore-settings", wait=1.0))
        if find(nodes, "清爽白"):
            soft_tap(nodes, "清爽白")
            sleep(0.6)
            capture("restore-white", wait=0.4)
            log("restored_white_bg")
            back()
            sleep(0.8)
            return dismiss_rest()
        log("restore_white_skipped", labels=labels(nodes)[:20])
    except Exception as e:
        log("restore_white_error", error=str(e))
    return back_to_shell()


def walk_topics():
    nodes = back_to_shell()
    nodes = tap_tab(nodes, "发现")
    nodes = scroll_until(lambda n: find(n, "换个主题"), "40-discover-to-topics", 4)
    if not soft_tap(nodes, "换个主题", exact=True):
        # encyclopedia 专题
        nodes = tap_tab(nodes, "百科")
        if soft_tap(nodes, "专题", exact=True):
            sleep(1.0)
            nodes = dismiss_rest(capture("40-s09-topics-via-ency", wait=0.8))
        else:
            log("topics_entry_missing")
            return
    else:
        nodes = dismiss_rest(capture("40-s09-topics", wait=1.4))

    log("topics_list", labels=labels(nodes))

    # Antarctica first if visible
    nodes = scroll_until(
        lambda n: find(n, "南极洲"),
        "40-topics-scroll-anta",
        3,
    )
    if find(nodes, "南极洲"):
        soft_tap(nodes, "南极洲 · 自然地理专题") or soft_tap(nodes, "南极洲")
        nodes = dismiss_rest(capture("41-antarctica-hub", wait=2.0))
        log("antarctica_hub", labels=labels(nodes))
        # explore a couple of visible actions
        for action in ["开始探索", "继续阅读", "认识南极洲", "打开专题", "去看看"]:
            if find_exact(nodes, action):
                soft_tap(nodes, action, exact=True)
                nodes = dismiss_rest(capture("41b-antarctica-open", wait=1.6))
                log("antarctica_open", action=action, labels=labels(nodes))
                back()
                sleep(1.0)
                nodes = dismiss_rest(capture("41c-antarctica-back", wait=0.6))
                break
        # swipe hub
        swipe(1280, 1350, 1280, 550, 400)
        nodes = dismiss_rest(capture("41d-antarctica-scrolled", wait=0.8))
        back()
        sleep(1.2)
        nodes = dismiss_rest(capture("40-topics-after-anta", wait=0.8))

    # filters
    for filt in ["自然", "人文", "生活", "全部"]:
        if soft_tap(nodes, filt, exact=True):
            sleep(0.7)
            nodes = dismiss_rest(capture(f"42-topics-filter-{filt}", wait=0.5))
            log("topics_filter", filter=filt, labels=labels(nodes))

    # each topic
    seen = set()
    for title in TOPICS:
        nodes = dismiss_rest(capture("_topics-list", wait=0.3))
        # may need to scroll from top: swipe down first
        swipe(1280, 500, 1280, 1300, 400)
        sleep(0.4)
        nodes = scroll_until(lambda n, t=title: find(n, t), f"43-topics-find-{title}", 5)
        if not find(nodes, title):
            log("topic_missing", title=title)
            continue
        if not soft_tap(nodes, title):
            log("topic_untappable", title=title)
            continue
        slug = title.replace("？", "").replace("?", "")
        nodes = dismiss_rest(capture(f"44-topic-{slug}", wait=1.6))
        log("topic_hub", title=title, labels=labels(nodes))
        swipe(1280, 1350, 1280, 550, 400)
        nodes = dismiss_rest(capture(f"44b-topic-{slug}-scrolled", wait=0.8))
        # open first article-like row if any
        opened = False
        for n in nodes:
            blob = n["desc"] or n["text"]
            if n["click"] == "true" and blob and blob not in (
                "返回", "分享", "收藏", "全部", "自然", "人文", "生活", title
            ) and "专题" not in blob and len(blob) >= 4:
                # skip nav tabs
                if blob in ("发现", "地图", "百科", "我的"):
                    continue
                soft_tap(nodes, blob)
                nodes = dismiss_rest(capture(f"44c-topic-{slug}-item", wait=1.6))
                log("topic_item", title=title, item=blob, labels=labels(nodes)[:25])
                back()
                sleep(1.0)
                opened = True
                break
        if not opened:
            log("topic_no_item", title=title)
        back()
        sleep(1.1)
        seen.add(title)
    log("topics_done", seen=sorted(seen))


def on_country_hub(nodes, name):
    labs = labels(nodes)
    return any(name == (n["desc"] or n["text"]) for n in nodes) and (
        find(nodes, "换个主题") or find(nodes, "从") or any("开始" in x for x in labs)
    )


def walk_country(cid, name, journeys):
    nodes = dismiss_rest()
    # ensure encyclopedia countries tab
    if not find(nodes, name):
        # scroll list; also swipe down to top
        swipe(1280, 500, 1280, 1300, 400)
        sleep(0.4)
        nodes = scroll_until(lambda n, nm=name: find(n, nm), f"50-ency-find-{cid}", 6)
    if not find(nodes, name):
        log("country_missing_in_ency", id=cid, name=name)
        return
    if not soft_tap(nodes, name):
        log("country_untappable", id=cid, name=name)
        return
    nodes = dismiss_rest(capture(f"51-{cid}-hub", wait=1.8))
    log("country_hub", id=cid, name=name, labels=labels(nodes))

    # scroll hub twice to see journeys / sections
    swipe(1280, 1350, 1280, 550, 400)
    nodes = dismiss_rest(capture(f"51b-{cid}-hub-scroll1", wait=0.8))
    log("country_hub_scroll1", id=cid, labels=labels(nodes))
    swipe(1280, 1350, 1280, 550, 400)
    nodes = dismiss_rest(capture(f"51c-{cid}-hub-scroll2", wait=0.8))
    log("country_hub_scroll2", id=cid, labels=labels(nodes))

    present = [j for j in journeys if any(j in x for x in labels(nodes)) or find(nodes, j, clickable=False)]
    # re-scan from top for journey names
    swipe(1280, 500, 1280, 1400, 350)
    sleep(0.35)
    swipe(1280, 500, 1280, 1400, 350)
    sleep(0.4)
    nodes = dismiss_rest(capture(f"51d-{cid}-hub-top", wait=0.5))
    present = []
    for j in journeys:
        nodes = scroll_until(lambda n, jj=j: find(n, jj, clickable=False), f"52-{cid}-find-{j}", 5)
        if find(nodes, j, clickable=False):
            present.append(j)
            if soft_tap(nodes, j) or soft_tap(nodes, j, exact=True):
                nodes = dismiss_rest(capture(f"53-{cid}-journey-{j}", wait=1.6))
                log("journey", id=cid, journey=j, labels=labels(nodes))
                swipe(1280, 1350, 1280, 550, 400)
                nodes = dismiss_rest(capture(f"53b-{cid}-journey-{j}-scroll", wait=0.7))
                back()
                sleep(1.1)
                nodes = dismiss_rest(capture(f"51e-{cid}-hub-after-{j}", wait=0.5))
            else:
                log("journey_untappable", id=cid, journey=j)
        else:
            log("journey_missing", id=cid, journey=j)
    log("journeys_present", id=cid, present=present, expected=journeys)

    # map
    swipe(1280, 500, 1280, 1400, 350)
    sleep(0.3)
    nodes = scroll_until(
        lambda n: find(n, "在地图上看看") or find(n, "打开地图") or find_exact(n, "地图") or find(n, "从世界地图"),
        f"54-{cid}-find-map",
        6,
    )
    map_label = None
    for cand in ["在地图上看看", "从世界地图找到" + name, "从世界地图找到" + name.replace("澳大利亚", "澳洲"), "打开地图"]:
        if find(nodes, cand):
            map_label = cand
            break
    if map_label is None:
        if find(nodes, "从世界地图"):
            map_label = "从世界地图"
        elif find(nodes, "看看附近"):
            map_label = "看看附近"
    if map_label and soft_tap(nodes, map_label):
        nodes = dismiss_rest(capture(f"55-{cid}-map", wait=2.0))
        log("country_map", id=cid, via=map_label, labels=labels(nodes)[:30])
        back()
        sleep(1.1)
        nodes = dismiss_rest()
    else:
        log("country_map_missing", id=cid, labels=labels(nodes)[:25])

    # back to encyclopedia
    # may need more than one back if still on hub
    for _ in range(4):
        nodes = dismiss_rest()
        if find_exact(nodes, "国家百科") or (
            find_exact(nodes, "国家") and find_exact(nodes, "专题") and find(nodes, "百科", clickable=False)
        ):
            break
        if find_exact(nodes, name) and has_tabs(nodes) and not find(nodes, "换个主题"):
            # maybe still not encyclopedia
            pass
        back()
        sleep(0.9)
        nodes = capture(f"56-{cid}-back", wait=0.4)
        if find_exact(nodes, "国家百科") or (find_exact(nodes, "国家") and find_exact(nodes, "专题")):
            break
    log("country_done", id=cid, app_ok=current_app_ok())


def walk_countries():
    nodes = back_to_shell()
    nodes = tap_tab(nodes, "百科")
    # ensure 国家 segment
    if find_exact(nodes, "国家"):
        # if topics visible prominently, tap 国家
        if find(nodes, "沿着好奇心看世界") or find(nodes, "跨国专题"):
            soft_tap(nodes, "国家", exact=True)
            sleep(0.8)
            nodes = dismiss_rest(capture("50-ency-countries", wait=0.6))
    else:
        nodes = dismiss_rest(capture("50-ency", wait=0.6))
    log("encyclopedia", labels=labels(nodes))
    for cid, name, journeys in EDITORIAL:
        try:
            # return to encyclopedia between countries
            nodes = dismiss_rest()
            if not (find_exact(nodes, "国家百科") or (find_exact(nodes, "国家") and find_exact(nodes, "专题"))):
                nodes = back_to_shell()
                nodes = tap_tab(nodes, "百科")
                if find(nodes, "沿着好奇心看世界"):
                    soft_tap(nodes, "国家", exact=True)
                    sleep(0.8)
            walk_country(cid, name, journeys)
        except Exception as e:
            log("country_error", id=cid, error=str(e), trace=traceback.format_exc()[-800:])
            try:
                back_to_shell()
                tap_tab(dismiss_rest(), "百科")
            except Exception:
                pass


def walk_packs_remainder():
    """Scroll remaining pack cards if we can reach parent quickly; optional."""
    try:
        nodes = back_to_shell()
        nodes = tap_tab(nodes, "我的")
        nodes = scroll_until(lambda n: find(n, "家长入口"), "60-me-parent", 5)
        if not find(nodes, "长按 2 秒进入"):
            log("packs_skip_no_parent")
            return
        from walk import long_press
        long_press(nodes, "长按 2 秒进入", 2400)
        nodes = dismiss_rest(capture("60-parent", wait=1.6))
        nodes = scroll_until(lambda n: find(n, "离线内容包"), "60-parent-packs", 4)
        if not soft_tap(nodes, "离线内容包", exact=True):
            return
        # scroll through all pack cards
        for i in range(10):
            nodes = dismiss_rest(capture(f"61-packs-scroll-{i}", wait=0.6))
            log("packs_scroll", i=i, labels=labels(nodes))
            # stop if we see the footer
            if find(nodes, "移除下载内容会保留收藏与笔记") or find(nodes, "内置内容随应用提供"):
                break
            swipe(1280, 1400, 1280, 500, 400)
            sleep(0.4)
        back()
        sleep(0.8)
        back()
        sleep(0.8)
    except Exception as e:
        log("packs_remainder_error", error=str(e))


def main():
    LOG.write_text("", encoding="utf-8")
    log("start", app_ok=current_app_ok())
    if not current_app_ok():
        log("app_not_foreground")
        raise SystemExit("app not in foreground")
    nodes = back_to_shell()
    nodes = restore_white_bg(nodes)
    walk_topics()
    walk_countries()
    walk_packs_remainder()
    log("done", app_ok=current_app_ok())
    print("FULL_WALK_DONE", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        log("fatal", trace=traceback.format_exc())
        print("FULL_WALK_FAILED", flush=True)
        raise
