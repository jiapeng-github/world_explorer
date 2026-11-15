"""Protocol checks for the publisher; run with python3 -m unittest discover -s tool/packs."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

import atlas_packs as packs


class PackChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        self.catalog = packs.read_json(packs.ROOT / "assets/atlas/catalog.json")
        self.destination = self.directory / "egypt"
        packs.build_pack(self.catalog, "egypt", self.destination, "test")

    def tearDown(self):
        self.temp.cleanup()

    def rewrite_manifest(self, manifest):
        (self.destination / "manifest.json").write_bytes(packs.json_bytes(manifest))

    def test_published_pack_retains_stable_ids_and_namespaces_photos(self):
        result = packs.validate_pack(self.destination)
        self.assertGreaterEqual(result["articles"], 6)
        payload = packs.read_json(self.destination / "articles.json")
        self.assertIn("giza", {p["id"] for p in payload["places"]})
        self.assertTrue(all(m["id"].startswith("egypt-") for m in payload["media"]))
        self.assertTrue(all((self.destination / m["asset"]).exists() for m in payload["media"]))

    def test_tampered_resource_rejected_even_if_size_matches(self):
        file = next((self.destination / "media").iterdir())
        data = bytearray(file.read_bytes())
        data[10] ^= 1
        file.write_bytes(data)
        with self.assertRaisesRegex(packs.PackError, "SHA-256 mismatch"):
            packs.validate_pack(self.destination)

    def test_traversal_absolute_and_encoded_paths_are_rejected(self):
        for path in ("../outside", "/etc/passwd", "https://example.org/a", "a/../b", "a\\b", "%2e%2e/a", "a?query=yes", "a#fragment", ""):
            with self.subTest(path=path), self.assertRaises(packs.PackError):
                packs.safe_path(path)

    def test_duplicate_manifest_entries_are_rejected(self):
        manifest = packs.read_json(self.destination / "manifest.json")
        manifest["files"].append(deepcopy(manifest["files"][0]))
        self.rewrite_manifest(manifest)
        with self.assertRaisesRegex(packs.PackError, "Duplicate/reserved"):
            packs.validate_pack(self.destination)

    def test_structurally_invalid_payload_rejected_after_digest_verification(self):
        payload = packs.read_json(self.destination / "articles.json")
        payload["country"]["sections"]["food"] = ["missing-article"]
        data = packs.json_bytes(payload)
        (self.destination / "articles.json").write_bytes(data)
        manifest = packs.read_json(self.destination / "manifest.json")
        for file in manifest["files"]:
            if file["path"] == "articles.json":
                file.update(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
        self.rewrite_manifest(manifest)
        with self.assertRaisesRegex(packs.PackError, "Invalid article reference"):
            packs.validate_pack(self.destination)

    def test_source_asset_symlink_is_rejected(self):
        (self.directory / "shortcut").symlink_to(packs.ROOT / "pubspec.yaml")
        with self.assertRaises(packs.PackError):
            packs.within(self.directory, "shortcut")

    def test_missing_credit_fails_before_publication(self):
        payload = packs.read_json(self.destination / "articles.json")
        payload["media"][0]["credit"] = ""
        names = {f["path"] for f in packs.read_json(self.destination / "manifest.json")["files"]}
        with self.assertRaisesRegex(packs.PackError, "Incomplete media provenance"):
            packs.validate_payload("egypt", payload, names)

    def test_nested_media_are_bundled_and_remapped_together(self):
        # This shared image is referenced only by newly supported nested fields;
        # an article/cover-only collector would silently omit its bytes.
        catalog = deepcopy(self.catalog)
        extra = deepcopy(catalog["media"][0])
        extra["id"] = "shared-nested-image"
        catalog["media"].append(extra)
        country = next(c for c in catalog["countries"] if c["id"] == "egypt")
        article = next(a for a in catalog["articles"] if a["countryId"] == "egypt")
        place = next(p for p in catalog["places"] if p["countryId"] == "egypt")
        country["editorial"] = {
            "journeys": [{"id": "route", "articleIds": [article["id"]], "mediaId": extra["id"]}],
            "timeline": [{"id": "event", "articleIds": [article["id"]], "mediaId": extra["id"]}],
            "sections": {"overview": {"mediaId": extra["id"]}},
            "featuredPlaceIds": [place["id"]],
        }
        place["mediaIds"].append("nile-aswan")
        place["hotspots"] = [{"mediaId": "nile-aswan", "x": .2, "y": .4}]
        exercise = next(e for e in catalog["exercises"] if e["countryId"] == "egypt")
        exercise["mediaId"] = extra["id"]
        destination = self.directory / "nested"
        packs.build_pack(catalog, "egypt", destination, "nested-test")
        payload = packs.read_json(destination / "articles.json")
        expected = "egypt-shared-nested-image"
        self.assertIn(expected, {m["id"] for m in payload["media"]})
        self.assertNotIn(extra["id"], packs.referenced_media_ids(payload))
        self.assertEqual(payload["country"]["editorial"]["journeys"][0]["mediaId"], expected)
        self.assertEqual(payload["places"][0]["hotspots"][0]["mediaId"], "egypt-nile-aswan")
        self.assertEqual(payload["exercises"][0]["mediaId"], expected)

    def test_nested_missing_image_fails_payload_validation(self):
        payload = packs.read_json(self.destination / "articles.json")
        payload["exercises"][0]["mediaId"] = "egypt-not-bundled"
        names = {f["path"] for f in packs.read_json(self.destination / "manifest.json")["files"]}
        with self.assertRaisesRegex(packs.PackError, "Missing referenced media"):
            packs.validate_payload("egypt", payload, names)

    def test_china_revision_two_pack_keeps_activities_and_archive(self):
        destination = self.directory / "china"
        result = packs.build_pack(self.catalog, "china", destination, "china-test")
        payload = packs.read_json(destination / "articles.json")
        self.assertEqual(result["articles"], 30)
        self.assertEqual(result["places"], 12)
        self.assertEqual(result["exercises"], 24)
        self.assertEqual(payload["country"]["revision"], 2)
        self.assertEqual(sum(a.get("activity", {}).get("type") == "open" for a in payload["articles"]), 6)
        self.assertEqual([e["id"] for e in payload["archivedExercises"]], ["china-transport"])
        self.assertTrue(packs.referenced_media_ids(payload) <= {m["id"] for m in payload["media"]})


if __name__ == "__main__":
    unittest.main()
