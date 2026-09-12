#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "plugins/project-workflows/skills/project-plan-archive/scripts"
    / "project_plan_archive.py"
)


def load_module():
    spec = importlib.util.spec_from_file_location("project_plan_archive", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError("failed to load project_plan_archive")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ProjectPlanArchiveTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        subprocess.run(["git", "init"], cwd=self.repo, check=True, capture_output=True)
        (self.repo / ".agents/plans").mkdir(parents=True)
        (self.repo / ".agents/runs").mkdir(parents=True)
        (self.repo / ".agents/state").mkdir(parents=True)
        self.write(".agents/plans/TEMPLATE.md", "template\n")
        self.write(".agents/plans/EXAMPLE-implementation.md", "example\n")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write(self, rel: str, text: str) -> Path:
        path = self.repo / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def make_plan(self, rel: str, execution_issue: str | None = None) -> None:
        issue_line = f"- `execution_issue`: {execution_issue}\n" if execution_issue else ""
        self.write(rel, f"# Plan\n{issue_line}\n")

    def test_inspect_selects_execution_issue(self) -> None:
        archive = load_module()
        self.make_plan(".agents/plans/2026-04-30-demo.md", "APP-1")

        result = archive.inspect_repo(self.repo)

        self.assertEqual(result["candidates"][0]["selected_issue"], "APP-1")
        self.assertEqual(result["candidates"][0]["target_week"], "2026-W18")

    def test_archive_dry_run_does_not_move(self) -> None:
        archive = load_module()
        self.make_plan(".agents/plans/2026-04-30-demo.md", "APP-1")

        result = archive.archive_repo(self.repo, ["APP-1"], write=False)

        self.assertEqual(len(result["eligible"]), 1)
        self.assertTrue((self.repo / ".agents/plans/2026-04-30-demo.md").exists())

    def test_archive_write_moves_and_rewrites_refs(self) -> None:
        archive = load_module()
        old = ".agents/plans/2026-04-30-demo.md"
        new = ".agents/plans/completed/2026-W18/2026-04-30-demo.md"
        self.make_plan(old, "APP-1")
        self.write("README.md", f"See {old}\n")
        subprocess.run(["git", "add", "README.md"], cwd=self.repo, check=True, capture_output=True)

        result = archive.archive_repo(self.repo, ["APP-1"], write=True)

        self.assertEqual(len(result["eligible"]), 1)
        self.assertFalse((self.repo / old).exists())
        self.assertTrue((self.repo / new).exists())
        self.assertIn(new, (self.repo / "README.md").read_text(encoding="utf-8"))

    def test_help_runs(self) -> None:
        completed = subprocess.run(
            ["python3", str(SCRIPT), "--help"],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("inspect", completed.stdout)

    def test_missing_issue_does_not_mean_complete(self) -> None:
        archive = load_module()
        plan = ".agents/plans/2026-09-12-pending.md"
        template = Path(__file__).resolve().parents[1] / "template/.agents/plans/TEMPLATE.md"
        self.write(plan, template.read_text())
        result = archive.archive_repo(self.repo, [], write=True)
        self.assertEqual(len(result["skipped_missing_issue"]), 1)
        self.assertTrue((self.repo / plan).exists())

    def test_current_issue_id_selects_completion_evidence(self) -> None:
        archive = load_module()
        plan = ".agents/plans/2026-09-12-current.md"
        self.write(plan, "# Plan\n- issue_id: APP-2\n")
        self.assertEqual(len(archive.archive_repo(self.repo, [], write=True)["skipped_not_done"]), 1)
        result = archive.archive_repo(self.repo, ["APP-2"], write=True)
        self.assertEqual(len(result["eligible"]), 1)
        self.assertFalse((self.repo / plan).exists())

    def test_issue_less_plan_requires_explicit_path(self) -> None:
        archive = load_module()
        selected = ".agents/plans/2026-09-12-complete.md"
        pending = ".agents/plans/2026-09-12-pending.md"
        self.make_plan(selected)
        self.make_plan(pending)
        result = archive.archive_repo(self.repo, [], write=True, done_plans=[selected])
        self.assertEqual(len(result["eligible"]), 1)
        self.assertFalse((self.repo / selected).exists())
        self.assertTrue((self.repo / pending).exists())

    def test_explicit_plan_cannot_override_unfinished_issue(self) -> None:
        archive = load_module()
        selected = ".agents/plans/2026-09-12-pending.md"
        self.make_plan(selected, "APP-3")
        result = archive.archive_repo(self.repo, [], write=True, done_plans=[selected])
        self.assertEqual(len(result["skipped_not_done"]), 1)
        self.assertTrue((self.repo / selected).exists())

    def test_rewrites_inside_moved_plans_do_not_recreate_originals(self) -> None:
        archive = load_module()
        old = ".agents/plans/2026-09-12-complete.md"
        self.write(old, f"# Plan\n- issue_id: APP-4\nSee {old}\n")
        subprocess.run(["git", "add", old], cwd=self.repo, check=True, capture_output=True)
        result = archive.archive_repo(self.repo, ["APP-4"], write=True)
        new = result["eligible"][0]["target_relative_path"]
        self.assertFalse((self.repo / old).exists())
        self.assertIn(new, (self.repo / new).read_text())

    def test_unknown_explicit_plan_stops_without_moving_files(self) -> None:
        archive = load_module()
        old = ".agents/plans/2026-09-12-complete.md"
        self.make_plan(old, "APP-4")
        with self.assertRaises(SystemExit):
            archive.archive_repo(self.repo, ["APP-4"], write=True, done_plans=["../outside.md"])
        self.assertTrue((self.repo / old).exists())

    def test_git_failure_does_not_silently_skip_reference_repairs(self) -> None:
        archive = load_module()
        from unittest.mock import patch
        old = ".agents/plans/2026-09-12-complete.md"
        self.make_plan(old, "APP-4")
        with patch.object(archive.subprocess, "run", side_effect=FileNotFoundError):
            with self.assertRaises(SystemExit):
                archive.archive_repo(self.repo, ["APP-4"], write=True)
        self.assertTrue((self.repo / old).exists())

    def test_archive_symlink_target_stops_before_moving(self) -> None:
        archive = load_module()
        old = ".agents/plans/2026-09-12-complete.md"
        self.make_plan(old, "APP-4")
        other = self.repo / "unrelated"
        other.mkdir()
        try:
            (self.repo / ".agents/plans/completed").symlink_to(other, target_is_directory=True)
        except OSError as exc:
            self.skipTest(f"symlinks unavailable: {exc}")
        with self.assertRaises(SystemExit):
            archive.archive_repo(self.repo, ["APP-4"], write=True)
        self.assertTrue((self.repo / old).exists())
        self.assertEqual(list(other.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
