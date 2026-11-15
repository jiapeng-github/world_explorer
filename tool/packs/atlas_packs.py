#!/usr/bin/env python3
"""Build, verify and serve offline atlas packs using only the Python standard library.

The client resolves ``<CONTENT_BASE_URL>/<country>/manifest.json``. Publish each
release to a new directory and point CONTENT_BASE_URL at that release directory.
This tool never publishes to a remote host or downloads source material.
"""
from __future__ import annotations

import argparse
from copy import deepcopy
import hashlib
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import math
from pathlib import Path, PurePosixPath
import re
import shutil
import sys
import tempfile
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
MAX_BYTES = 150 * 1024 * 1024
MAX_FILES = 500
ID = re.compile(r"^[a-z0-9-]+$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
# The v0.2 application persisted these IDs in bookmarks and notes. They must not
# be renamed when the corresponding country receives a content update.
LEGACY_PLACES = {
    "egypt": {"giza", "nile-delta", "abu-simbel"},
    "china": {"great-wall", "jiuzhaigou", "grand-canal"},
    "brazil": {"iguazu", "amazon", "brasilia"},
}


class PackError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise PackError(message)


def read_json(path: Path):
    def pairs(items):
        result = {}
        for key, value in items:
            require(key not in result, f"Repeated JSON key: {key}")
            result[key] = value
        return result
    try:
        return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=pairs)
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise PackError(f"Cannot read JSON {path}: {error}") from error


def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def safe_path(value):
    require(isinstance(value, str) and bool(value), "Empty or non-string resource path")
    decoded = unquote(value)
    uri = urlsplit(decoded)
    require(not uri.scheme and not uri.netloc and not uri.query and not uri.fragment,
            f"Resource must be a relative path: {value}")
    require(not decoded.startswith("/") and "\\" not in decoded and "%" not in decoded,
            f"Unsafe resource path: {value}")
    require(all(part not in ("", ".", "..") for part in decoded.split("/")),
            f"Unsafe resource path: {value}")
    require(decoded == value, f"Use unescaped resource paths: {value}")
    return PurePosixPath(value)


def within(root: Path, path: str):
    relative = safe_path(path)
    root = root.resolve()
    candidate = root.joinpath(*relative.parts)
    require(candidate.resolve().is_relative_to(root), f"Resource escapes its directory: {path}")
    require(not any(p.is_symlink() for p in [candidate, *candidate.parents] if p != root and p.is_relative_to(root)),
            f"Symlink resources are not publishable: {path}")
    require(candidate.is_file(), f"Missing resource: {candidate}")
    return candidate


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def web_url(value):
    if not isinstance(value, str):
        return False
    parsed = urlsplit(value)
    return parsed.scheme in ("http", "https") and bool(parsed.netloc)


def unique(items, label):
    require(isinstance(items, list), f"{label} must be a list")
    ids = [item.get("id") for item in items if isinstance(item, dict)]
    require(len(ids) == len(items) and all(nonempty(i) for i in ids), f"Missing {label} ID")
    require(len(set(ids)) == len(ids), f"Duplicate {label} ID")
    return set(ids)


def media_fields(value):
    """Yield media references throughout content, including nested editorial UI.

    Returning containers keeps collection and remapping on the exact same paths:
    country editorial, exercise illustrations, and place hotspots cannot drift
    apart as new optional content fields are added.
    """
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "mediaId":
                require(child in (None, "") or nonempty(child), "Invalid mediaId")
                if child:
                    yield value, key, False
            elif key == "mediaIds":
                require(isinstance(child, list) and all(nonempty(mid) for mid in child),
                        "Invalid mediaIds")
                yield value, key, True
            else:
                yield from media_fields(child)
    elif isinstance(value, list):
        for child in value:
            yield from media_fields(child)


def referenced_media_ids(payload):
    result = set()
    for container, key, multiple in media_fields(payload):
        result.update(container[key] if multiple else [container[key]])
    return result


def remap_media_ids(payload, remap):
    for container, key, multiple in media_fields(payload):
        value = container[key]
        container[key] = [remap[mid] for mid in value] if multiple else remap[value]


def validate_payload(pack_id, payload, file_names):
    require(isinstance(payload, dict), "articles.json must contain an object")
    country = payload.get("country", {})
    require(isinstance(country, dict) and country.get("id") == pack_id, "Country and pack IDs differ")
    for field in ("name", "englishName", "continent", "intro"):
        require(nonempty(country.get(field)), f"Country is missing {field}")
    for field, limit in (("latitude", 90), ("longitude", 180)):
        value = country.get(field)
        require(type(value) in (int, float) and math.isfinite(value) and abs(value) <= limit,
                f"Country has invalid {field}")
    sources = country.get("sources", [])
    require(sources and all(web_url(s.get("url")) and nonempty(s.get("checkedAt")) for s in sources),
            "Country needs sources and their review dates")
    articles = payload.get("articles", [])
    article_ids = unique(articles, "article")
    require(bool(articles), "A downloadable pack must contain at least one article")
    media = payload.get("media", [])
    media_ids = unique(media, "media")
    referenced_media = referenced_media_ids(payload)
    for article in articles:
        require(article.get("countryId") == pack_id and article["id"].startswith(pack_id + "-"),
                f"Article outside its country namespace: {article['id']}")
        for field in ("title", "summary", "sectionId"):
            require(nonempty(article.get(field)), f"Article {article['id']} is missing {field}")
        blocks = article.get("blocks", [])
        unique(blocks, "article block")
        require(blocks and all(nonempty(b.get("title")) and nonempty(b.get("text")) for b in blocks),
                f"Article {article['id']} contains an empty block")
        require(article.get("sourceUrls") and all(web_url(u) for u in article["sourceUrls"]),
                f"Article {article['id']} needs valid source URLs")
        referenced_media.update({article.get("mediaId", "")} - {""})
        referenced_media.update(b["mediaId"] for b in blocks if b.get("mediaId"))
    sections = country.get("sections", {})
    require(isinstance(sections, dict), "Country sections must be an object")
    for section, refs in sections.items():
        require(isinstance(refs, list) and all(ref in article_ids for ref in refs),
                f"Invalid article reference in country section {section}")
    places = payload.get("places", [])
    place_ids = unique(places, "place")
    for place in places:
        place_id = place["id"]
        require(place.get("countryId") == pack_id and
                (place_id.startswith(pack_id + "-") or place_id in LEGACY_PLACES.get(pack_id, set())),
                f"Place outside its country namespace: {place_id}")
        require(web_url(place.get("sourceUrl")), f"Place {place_id} needs a source URL")
        referenced_media.update(place.get("mediaIds", []))
        for hotspot in place.get("hotspots", []):
            require(hotspot.get("mediaId") in place.get("mediaIds", []),
                    f"Hotspot image outside place gallery: {place_id}")
            require(all(type(hotspot.get(axis)) in (int, float) and
                        math.isfinite(hotspot[axis]) and 0 <= hotspot[axis] <= 1 for axis in ("x", "y")),
                    f"Invalid hotspot coordinates: {place_id}")
    editorial = country.get("editorial", {})
    for kind in ("journeys", "timeline"):
        for entry in editorial.get(kind, []):
            require(entry.get("articleIds") and all(aid in article_ids for aid in entry["articleIds"]),
                    f"Invalid editorial article reference: {kind}")
    require(all(pid in place_ids for pid in editorial.get("featuredPlaceIds", [])),
            "Invalid editorial featured place")
    require(referenced_media <= media_ids, f"Missing referenced media: {sorted(referenced_media - media_ids)}")
    for image in media:
        require(image["id"].startswith(pack_id + "-"), f"Media outside its country namespace: {image['id']}")
        require(image.get("asset") in file_names, f"Missing media bytes for {image['id']}")
        safe_path(image["asset"])
        require(all(nonempty(image.get(k)) for k in ("caption", "credit", "license")) and
                web_url(image.get("sourceUrl")) and web_url(image.get("licenseUrl")),
                f"Incomplete media provenance: {image['id']}")
    exercises = payload.get("exercises", [])
    unique(exercises, "exercise")
    for exercise in exercises:
        require(exercise.get("countryId") == pack_id and exercise["id"].startswith(pack_id + "-") and
                exercise.get("articleId") in article_ids, f"Invalid exercise reference: {exercise['id']}")
        options = exercise.get("options", [])
        option_ids = unique(options, "answer option")
        require(exercise.get("answerId") in option_ids and nonempty(exercise.get("explanation")),
                f"Invalid answer or missing explanation: {exercise['id']}")
        article = next(a for a in articles if a["id"] == exercise["articleId"])
        block_ids = {b["id"] for b in article["blocks"]}
        require(all(b in block_ids for b in exercise.get("evidenceBlockIds", [])),
                f"Invalid exercise evidence: {exercise['id']}")
    archived = payload.get("archivedExercises", [])
    archived_ids = unique(archived, "archived exercise")
    require(not archived_ids & {e["id"] for e in exercises}, "Archived exercise is still active")
    require(all(e.get("countryId") == pack_id and e.get("articleId") in article_ids for e in archived),
            "Invalid archived exercise reference")
    return {"articles": len(articles), "places": len(places), "media": len(media), "exercises": len(exercises)}


def validate_pack(directory: Path):
    manifest = read_json(directory / "manifest.json")
    require(isinstance(manifest, dict) and manifest.get("schemaVersion") == 1, "Unsupported manifest schema")
    pack_id = manifest.get("packId", "")
    require(isinstance(pack_id, str) and ID.fullmatch(pack_id), "Invalid pack ID")
    require(nonempty(manifest.get("contentVersion")), "Missing content version")
    files = manifest.get("files", [])
    require(isinstance(files, list) and 0 < len(files) <= MAX_FILES, "Invalid file count")
    names, total = set(), 0
    for item in files:
        require(isinstance(item, dict), "Invalid file entry")
        path = item.get("path")
        safe_path(path)
        require(path != "manifest.json" and path not in names, f"Duplicate/reserved resource path: {path}")
        names.add(path)
        require(type(item.get("bytes")) is int and item["bytes"] >= 0, f"Invalid byte count: {path}")
        require(isinstance(item.get("sha256"), str) and SHA256.fullmatch(item["sha256"]), f"Invalid digest: {path}")
        total += item["bytes"]
        require(total <= MAX_BYTES, "Pack exceeds the 150 MiB client limit")
        file = within(directory, path)
        require(file.stat().st_size == item["bytes"], f"Size mismatch: {path}")
        require(hashlib.sha256(file.read_bytes()).hexdigest() == item["sha256"], f"SHA-256 mismatch: {path}")
    require("articles.json" in names, "Missing articles.json")
    counts = validate_payload(pack_id, read_json(directory / "articles.json"), names)
    return {"packId": pack_id, "contentVersion": manifest["contentVersion"], "bytes": total, **counts}


def build_pack(catalog, pack_id, target: Path, version, asset_root=ROOT):
    country = next((deepcopy(c) for c in catalog["countries"] if c["id"] == pack_id), None)
    require(country is not None, f"Unknown country: {pack_id}")
    payload = {"country": country}
    for kind in ("articles", "places", "exercises", "archivedExercises"):
        payload[kind] = deepcopy([item for item in catalog.get(kind, []) if item["countryId"] == pack_id])
    required = referenced_media_ids(payload)
    images = {m["id"]: m for m in catalog["media"]}
    require(required <= images.keys(), f"Missing catalog media: {sorted(required - images.keys())}")
    remap = {mid: mid if mid.startswith(pack_id + "-") else f"{pack_id}-{mid}" for mid in required}
    require(len(set(remap.values())) == len(remap), "Media namespace collision")
    target.mkdir(parents=True, exist_ok=False)
    payload["media"] = []
    for mid in sorted(required):
        image = deepcopy(images[mid])
        source = within(asset_root, image["asset"])
        image["id"] = remap[mid]
        image["asset"] = f"media/{remap[mid]}{source.suffix.lower()}"
        destination = target / image["asset"]
        destination.parent.mkdir(exist_ok=True)
        shutil.copyfile(source, destination)
        payload["media"].append(image)
    remap_media_ids(payload, remap)
    (target / "articles.json").write_bytes(json_bytes(payload))
    (target / "credits.json").write_bytes(json_bytes({"sources": country["sources"], "media": payload["media"]}))
    files = []
    for file in sorted(p for p in target.rglob("*") if p.is_file()):
        value = file.read_bytes()
        files.append({"path": file.relative_to(target).as_posix(), "bytes": len(value),
                      "sha256": hashlib.sha256(value).hexdigest()})
    (target / "manifest.json").write_bytes(json_bytes({"schemaVersion": 1, "packId": pack_id,
                                                     "contentVersion": version, "files": files}))
    return validate_pack(target)


def build_release(args):
    catalog = read_json(args.catalog)
    version = args.version or catalog["contentVersion"]
    require(re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9._-]*", version), "Invalid release directory name")
    target = args.out.resolve() / version
    require(not target.exists(), f"Release already exists: {target}; use a new version or output directory")
    countries = args.country or sorted({a["countryId"] for a in catalog["articles"]})
    require(len(countries) == len(set(countries)), "Repeated --country")
    args.out.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix=".atlas-stage-", dir=args.out))
    try:
        summaries = [build_pack(catalog, cid, staging / cid, version, args.asset_root) for cid in countries]
        (staging / "index.json").write_bytes(json_bytes({"schemaVersion": 1, "contentVersion": version, "packs": summaries}))
        staging.rename(target)
    except BaseException:
        shutil.rmtree(staging, ignore_errors=True)
        raise
    print(json.dumps({"directory": str(target), "packs": summaries}, ensure_ascii=False, indent=2))


def serve(args):
    directory = args.directory.resolve()
    require(directory.is_dir(), f"Server directory does not exist: {directory}")
    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *items, **kwargs):
            super().__init__(*items, directory=str(directory), **kwargs)

        def end_headers(self):
            # This server exposes only published, public content packs. CORS
            # allows a Flutter Web preview running on another localhost port.
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Cache-Control", "no-cache")
            super().end_headers()

        def do_OPTIONS(self):
            self.send_response(204)
            self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
            self.end_headers()
    server = ThreadingHTTPServer((args.bind, args.port), Handler)
    print(f"Serving {directory} at http://{args.bind}:{args.port}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build", help="Build an immutable release locally")
    build.add_argument("--catalog", type=Path, default=ROOT / "assets/atlas/catalog.json")
    build.add_argument("--asset-root", type=Path, default=ROOT)
    build.add_argument("--country", action="append", help="Country ID; repeat or omit for every country with articles")
    build.add_argument("--version", help="Defaults to catalog contentVersion")
    build.add_argument("--out", type=Path, default=ROOT / "build/content")
    verify = sub.add_parser("validate", help="Verify a pack directory or a release directory")
    verify.add_argument("directory", type=Path)
    server = sub.add_parser("serve", help="Local content-only server with Web preview CORS headers")
    server.add_argument("directory", type=Path)
    server.add_argument("--bind", default="127.0.0.1")
    server.add_argument("--port", default=5291, type=int)
    args = parser.parse_args(argv)
    try:
        if args.command == "build":
            build_release(args)
        elif args.command == "validate":
            paths = [args.directory] if (args.directory / "manifest.json").is_file() else sorted(p.parent for p in args.directory.glob("*/manifest.json"))
            require(bool(paths), "No manifests found")
            print(json.dumps([validate_pack(p) for p in paths], ensure_ascii=False, indent=2))
        else:
            serve(args)
    except (PackError, OSError, KeyError, TypeError) as error:
        parser.exit(1, f"Pack error: {error}\n")


if __name__ == "__main__":
    main()
