import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "plugins/project-workflows/skills/project-version-release/scripts/project_version_release.py"
spec = importlib.util.spec_from_file_location("project_version_release", SCRIPT)
release = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = release
spec.loader.exec_module(release)


class VersionReleaseTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name).resolve()

    def test_dependency_change_is_not_version_bump(self):
        result = release.classify(["go.mod", "go.sum"])
        self.assertEqual(result["classification"], "issue-only")
        self.assertEqual(result["version_review_files"], [])

    def test_manifest_requires_inspection_instead_of_implying_version_bump(self):
        result = release.classify(["package.json", "pyproject.toml"])
        self.assertEqual(result["classification"], "issue-only")
        self.assertEqual(result["version_review_files"], ["package.json", "pyproject.toml"])

    def test_explicit_release_and_plain_version_file_classification(self):
        self.assertEqual(release.classify(["VERSION"])["classification"], "version-bump")
        self.assertEqual(release.classify(["go.mod"], release_intent=True)["classification"], "release-archive")
        self.assertEqual(release.classify(["CHANGELOG.md"])["classification"], "changelog-only")

    def test_manifest_cannot_be_replaced_by_version_string(self):
        path = self.repo / "package.json"
        original = '{"version":"0.6.0","dependencies":{"example":"1.0.0"}}'
        path.write_text(original)
        with self.assertRaises(SystemExit):
            release.version_bump(self.repo, "0.7.0", ["package.json"], write=True)
        self.assertEqual(path.read_text(), original)

    def test_plain_version_preview_and_write(self):
        path = self.repo / "VERSION"
        path.write_text("0.6.0\n")
        release.version_bump(self.repo, "0.7.0", ["VERSION"], write=False)
        self.assertEqual(path.read_text(), "0.6.0\n")
        release.version_bump(self.repo, "0.7.0", ["VERSION"], write=True)
        self.assertEqual(path.read_text(), "0.7.0\n")

    def test_all_version_targets_are_checked_before_writing(self):
        path = self.repo / "VERSION"
        path.write_text("0.6.0\n")
        with self.assertRaises(SystemExit):
            release.version_bump(self.repo, "0.7.0", ["VERSION", "version.txt"], write=True)
        self.assertEqual(path.read_text(), "0.6.0\n")

    def test_version_path_cannot_escape_repo(self):
        for name in ("../VERSION", str(self.repo / "VERSION")):
            with self.subTest(name=name), self.assertRaises(SystemExit):
                release.version_bump(self.repo, "0.7.0", [name], write=True)

    def test_version_file_symlink_is_rejected(self):
        other = self.repo / "other"
        other.write_text("0.6.0\n")
        try:
            (self.repo / "VERSION").symlink_to(other)
        except OSError as exc:
            self.skipTest(f"symlinks unavailable: {exc}")
        with self.assertRaises(SystemExit):
            release.version_bump(self.repo, "0.7.0", ["VERSION"], write=True)
        self.assertEqual(other.read_text(), "0.6.0\n")

    def test_changelog_preview_write_and_archive(self):
        path = self.repo / "CHANGELOG.md"
        original = "# Changelog\n\n## Unreleased\n\n### v0.6.0(20260822)\nold entry\n"
        path.write_text(original)
        release.changelog_add(self.repo, "APP-1", "bugFix", "repair", write=False)
        self.assertEqual(path.read_text(), original)
        release.changelog_add(self.repo, "APP-1", "bugFix", "repair", write=True)
        self.assertIn("[APP-1] repair", path.read_text())
        release.release_archive(self.repo, "v0.7.0", "20260912", write=True)
        self.assertIn("### v0.7.0(20260912)", path.read_text())
        self.assertIn("### v0.6.0(20260822)\nold entry", path.read_text())
        self.assertEqual(path.read_text().count("### v0.6.0"), 1)
        before = path.read_text()
        with self.assertRaises(SystemExit):
            release.release_archive(self.repo, "v0.8.0", "20260913", write=True)
        self.assertEqual(path.read_text(), before)

    def test_changelog_symlink_cannot_modify_other_file(self):
        other = self.repo / "other.md"
        original = "# Other\n\n## Unreleased\n"
        other.write_text(original)
        try:
            (self.repo / "CHANGELOG.md").symlink_to(other)
        except OSError as exc:
            self.skipTest(f"symlinks unavailable: {exc}")
        with self.assertRaises(SystemExit):
            release.changelog_add(self.repo, "APP-1", "bugFix", "repair", write=True)
        self.assertEqual(other.read_text(), original)


if __name__ == "__main__":
    unittest.main()
