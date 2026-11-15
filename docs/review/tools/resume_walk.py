#!/usr/bin/env python3
"""Resume full walk after accidental Home gesture. Never swipe near the bottom."""
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
    SERIAL,
    adb,
    back,
    capture,
    current_app_ok,
    find,
    sleep,
    swipe,
    tap_xy,
)

LOG = REVIEW / "full_walk_log.jsonl"

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

REMAINING_TOPICS = [
    "双手里的文化",
    "水从哪里来？",
    "学做世界观察员",
    "一起守护世界",
]


def log(event, **kw):
    rec = {"ts": datetime.now().isoformat(timespec="seconds"), "event": event, **kw}
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    print("LOG", event, {k: v for k, v in kw.items() if k != "labels"}, flush=True)


def labels(nodes):
    return [n["desc"] or n["text"] for n in nodes if n["desc"] or n["text"]]


def find_exact(nodes, label, clickable=None):
    for n in nodes:
        if clickable is True and n["click"] != "true":
            continue
        if n["desc"] == label or n["text"] == label:
            return n
    return None


def soft_tap(nodes, label, exact=False):
    n = find_exact(nodes, label, clickable=True) if exact else find(nodes, label, clickable=True)
    if not n or len(n["box"]) != 4:
        return False
    x, y = (n["box"][0] + n["box"][2]) // 2, (n["box"][1] + n["box"][3]) // 2
    # avoid tapping too close to the bottom gesture bar
    if y > 1480:
        y = 1480
    print(f"SOFT TAP {label!r} -> {x},{y}", flush=True)
    tap_xy(x, y)
    return True


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


def scroll_until(pred, shot_prefix, max_swipes=7):
    nodes = dismiss_rest()
    for i in range(max_swipes + 1):
        nodes = dismiss_rest(ensure_app(nodes))
        if pred(nodes):
            return nodes
        safe_swipe("up")
        nodes = capture(f"{shot_prefix}-{i}", wait=0.35)
    return nodes


def go_topics():
    nodes = back_to_shell()
    nodes = tap_tab(nodes, "百科")
    if find_exact(nodes, "专题"):
        soft_tap(nodes, "专题", exact=True)
        sleep(1.0)
        nodes = dismiss_rest(capture("80-topics", wait=0.8))
    return nodes


def walk_remaining_topics():
    nodes = go_topics()
    log("topics_resume", labels=labels(nodes)[:20])
    for title in REMAINING_TOPICS:
        nodes = dismiss_rest(ensure_app())
        if not (find(nodes, "沿着好奇心看世界") or find(nodes, "专题")):
            nodes = go_topics()
        # go to top
        for _ in range(2):
            safe_swipe("down")
        nodes = scroll_until(lambda n, t=title: find(n, t), f"81-find-{title}", 6)
        if not find(nodes, title):
            log("topic_missing", title=title)
            continue
        if not soft_tap(nodes, title):
            log("topic_untappable", title=title)
            continue
        slug = title.replace("？", "")
        nodes = dismiss_rest(capture(f"82-topic-{slug}", wait=1.6))
        log("topic_hub", title=title, labels=labels(nodes))
        safe_swipe("up")
        nodes = dismiss_rest(capture(f"82b-topic-{slug}-scroll", wait=0.7))
        # open first article numbered 01 if possible
        opened = False
        for n in nodes:
            blob = n["desc"] or n["text"]
            if n["click"] == "true" and blob.startswith("01"):
                soft_tap(nodes, blob)
                nodes = dismiss_rest(capture(f"82c-topic-{slug}-article", wait=1.6))
                log("topic_item", title=title, item=blob, labels=labels(nodes)[:20])
                back()
                sleep(1.0)
                opened = True
                break
        if not opened:
            log("topic_no_article", title=title)
        # back to topics list only if we still have a back button and are not on the list
        nodes = dismiss_rest()
        if find(nodes, title) and not find(nodes, "沿着好奇心看世界"):
            back()
            sleep(1.0)
            nodes = dismiss_rest(capture(f"82d-after-{slug}", wait=0.5))
        log("topic_done", title=title)
    log("topics_resume_done")


def walk_country(cid, name, journeys):
    nodes = dismiss_rest()
    for _ in range(2):
        safe_swipe("down")
    nodes = scroll_until(lambda n, nm=name: find(n, nm), f"90-ency-find-{cid}", 6)
    if not find(nodes, name):
        log("country_missing_in_ency", id=cid, name=name)
        return
    if not soft_tap(nodes, name):
        log("country_untappable", id=cid, name=name)
        return
    nodes = dismiss_rest(capture(f"91-{cid}-hub", wait=1.8))
    log("country_hub", id=cid, name=name, labels=labels(nodes))
    safe_swipe("up")
    nodes = dismiss_rest(capture(f"91b-{cid}-hub-scroll1", wait=0.7))
    log("country_hub_scroll1", id=cid, labels=labels(nodes))
    safe_swipe("up")
    nodes = dismiss_rest(capture(f"91c-{cid}-hub-scroll2", wait=0.7))
    log("country_hub_scroll2", id=cid, labels=labels(nodes))

    present = []
    for j in journeys:
        for _ in range(2):
            safe_swipe("down")
        nodes = scroll_until(lambda n, jj=j: find(n, jj, clickable=False), f"92-{cid}-find-{j}", 5)
        if find(nodes, j, clickable=False) and (soft_tap(nodes, j, exact=True) or soft_tap(nodes, j)):
            present.append(j)
            nodes = dismiss_rest(capture(f"93-{cid}-journey-{j}", wait=1.6))
            log("journey", id=cid, journey=j, labels=labels(nodes))
            safe_swipe("up")
            capture(f"93b-{cid}-journey-{j}-scroll", wait=0.6)
            back()
            sleep(1.0)
            nodes = dismiss_rest()
        else:
            log("journey_missing", id=cid, journey=j)
    log("journeys_present", id=cid, present=present, expected=journeys)

    for _ in range(2):
        safe_swipe("down")
    nodes = scroll_until(
        lambda n: find(n, "在地图上看看") or find(n, "从世界地图") or find(n, "打开地图"),
        f"94-{cid}-find-map",
        6,
    )
    map_label = None
    for cand in ["在地图上看看", "从世界地图", "打开地图"]:
        if find(nodes, cand):
            map_label = cand
            break
    if map_label and soft_tap(nodes, map_label):
        nodes = dismiss_rest(capture(f"95-{cid}-map", wait=2.0))
        log("country_map", id=cid, via=map_label, labels=labels(nodes)[:25])
        back()
        sleep(1.0)
    else:
        log("country_map_missing", id=cid)

    # return to encyclopedia
    for _ in range(4):
        nodes = dismiss_rest()
        if find_exact(nodes, "国家百科") or (find_exact(nodes, "国家") and find_exact(nodes, "专题")):
            if find(nodes, "沿着好奇心看世界"):
                soft_tap(nodes, "国家", exact=True)
                sleep(0.8)
                nodes = dismiss_rest(capture("90-ency-countries", wait=0.5))
            break
        if has_tabs(nodes) and find_exact(nodes, "国家百科"):
            break
        back()
        sleep(0.8)
        if not current_app_ok():
            relaunch()
            nodes = tap_tab(dismiss_rest(), "百科")
            break
    log("country_done", id=cid, app_ok=current_app_ok())


def walk_countries():
    nodes = back_to_shell()
    nodes = tap_tab(nodes, "百科")
    if find(nodes, "沿着好奇心看世界"):
        soft_tap(nodes, "国家", exact=True)
        sleep(0.8)
        nodes = dismiss_rest(capture("90-ency", wait=0.6))
    log("encyclopedia", labels=labels(nodes)[:25])
    for cid, name, journeys in EDITORIAL:
        try:
            nodes = dismiss_rest()
            if not (find_exact(nodes, "国家百科") or (find_exact(nodes, "国家") and find_exact(nodes, "专题"))):
                nodes = back_to_shell()
                nodes = tap_tab(nodes, "百科")
            if find(nodes, "沿着好奇心看世界"):
                soft_tap(nodes, "国家", exact=True)
                sleep(0.8)
            walk_country(cid, name, journeys)
        except Exception as e:
            log("country_error", id=cid, error=str(e), trace=traceback.format_exc()[-600:])
            if not current_app_ok():
                relaunch()
            back_to_shell()
            tap_tab(dismiss_rest(), "百科")


def walk_packs():
    try:
        nodes = back_to_shell()
        nodes = tap_tab(nodes, "我的")
        nodes = scroll_until(lambda n: find(n, "家长入口"), "96-me-parent", 5)
        if not find(nodes, "长按 2 秒进入"):
            log("packs_skip_no_parent")
            return
        from walk import long_press
        long_press(nodes, "长按 2 秒进入", 2400)
        nodes = dismiss_rest(capture("96-parent", wait=1.6))
        nodes = scroll_until(lambda n: find(n, "离线内容包"), "96-parent-packs", 4)
        if not soft_tap(nodes, "离线内容包", exact=True):
            return
        for i in range(10):
            nodes = dismiss_rest(capture(f"97-packs-scroll-{i}", wait=0.6))
            log("packs_scroll", i=i, labels=labels(nodes))
            if find(nodes, "移除下载内容会保留收藏与笔记") or find(nodes, "内置内容随应用提供"):
                break
            safe_swipe("up")
        back()
        sleep(0.8)
        if has_tabs(dismiss_rest()) is False:
            back()
            sleep(0.8)
    except Exception as e:
        log("packs_error", error=str(e))


def main():
    log("resume_start", app_ok=current_app_ok())
    if not current_app_ok():
        relaunch()
    walk_remaining_topics()
    walk_countries()
    walk_packs()
    log("resume_done", app_ok=current_app_ok())
    print("RESUME_WALK_DONE", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        log("resume_fatal", trace=traceback.format_exc())
        print("RESUME_WALK_FAILED", flush=True)
        raise
