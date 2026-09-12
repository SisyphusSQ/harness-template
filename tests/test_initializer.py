from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
INITIALIZER = ROOT / "scripts/init_harness_project.py"
SKILLS = ROOT / "plugins/project-workflows/skills"


class InitializerTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.target = self.base / "project with spaces"

    def run_init(self, *extra, target=None, launcher=None, success=True):
        command = launcher or [sys.executable, str(INITIALIZER)]
        result = subprocess.run(
            [*command, "--target", str(target or self.target),
             "--project-name", "Demo $name / 中文 & value", "--stack", "go", *extra],
            text=True, capture_output=True, check=False,
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def snapshot(self):
        return {p.relative_to(self.target).as_posix(): p.read_bytes()
                for p in self.target.rglob("*") if p.is_file()}

    def test_default_output_is_guidance_without_skills_or_control_plane(self):
        self.run_init()
        for name in ("AGENTS.md", "README.md", ".gitignore", ".agents/PLANS.md",
                     ".agents/plans/TEMPLATE.md", ".agents/state/TEMPLATE.md",
                     ".agents/runs/TEMPLATE.md", "docs/test/RUNBOOK_TEMPLATE.md"):
            self.assertTrue((self.target / name).is_file(), name)
        for name in (".agents/skills", "docs/issues", "Makefile", "docs/harness",
                     "scripts/harness", ".agents/prompts"):
            self.assertFalse((self.target / name).exists(), name)
        agents = (self.target / "AGENTS.md").read_text()
        self.assertIn("Demo $name / 中文 & value", agents)
        self.assertIn("issue provider：linear", agents)
        self.assertNotIn("__PROJECT_NAME__", agents)

    def test_stack_and_provider_options(self):
        for stack in ("go", "python", "java", "c", "go-node", "python-node",
                      "java-node", "c-node", "java-c", "java-c-node"):
            with self.subTest(stack=stack):
                target = self.base / stack
                self.run_init("--stack", stack, target=target)
                ignore = (target / ".gitignore").read_text()
                for part in stack.split("-"):
                    name = "node-frontend" if part == "node" else part
                    self.assertIn((ROOT / f"sources/gitignore/{name}.gitignore").read_text().strip(), ignore)
        for provider in ("linear", "github", "gitlab", "repo", "other"):
            with self.subTest(provider=provider):
                target = self.base / provider
                self.run_init("--issue-provider", provider, target=target)
                self.assertEqual((target / "docs/issues/TEMPLATE.md").exists(), provider == "repo")

    def test_optional_skills_are_selected_and_executable_from_target(self):
        for source in SKILLS.glob("*/SKILL.md"):
            name = source.parent.name
            target = self.base / name
            self.run_init("--skill", name, target=target)
            installed = target / ".agents/skills"
            self.assertEqual({p.name for p in installed.iterdir()}, {name})
            self.assertEqual((installed / name / "SKILL.md").read_bytes(), source.read_bytes())
            self.assertFalse((installed / name / "tests").exists())
            for script in (installed / name / "scripts").glob("*.py"):
                subprocess.run([sys.executable, str(script), "--help"], check=True, capture_output=True)

    def test_multiple_skill_selection(self):
        self.run_init("--skill", "test-runbook", "--skill", "issue-goal-prompt")
        self.assertEqual({p.name for p in (self.target / ".agents/skills").iterdir()},
                         {"test-runbook", "issue-goal-prompt"})

    def test_existing_project_facts_and_legacy_files_are_preserved(self):
        self.target.mkdir()
        files = {"README.md": "real business", "AGENTS.md": "real build commands",
                 "Makefile": "business build", "docs/harness/control-plane.md": "custom old rules"}
        for name, value in files.items():
            path = self.target / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(value)
        self.run_init()
        for name, value in files.items():
            self.assertEqual((self.target / name).read_text(), value)
        original = self.snapshot()
        self.run_init()
        self.assertEqual(self.snapshot(), original)

    def test_overwrite_replaces_only_the_named_generated_file(self):
        self.run_init()
        (self.target / "AGENTS.md").write_text("keep project facts")
        (self.target / ".agents/plans/TEMPLATE.md").write_text("old template")
        self.run_init("--overwrite", ".agents/plans/TEMPLATE.md")
        self.assertEqual((self.target / "AGENTS.md").read_text(), "keep project facts")
        self.assertEqual((self.target / ".agents/plans/TEMPLATE.md").read_bytes(),
                         (ROOT / "template/.agents/plans/TEMPLATE.md").read_bytes())

    def test_unknown_overwrite_and_force_fail_before_writing(self):
        for options in (("--force",), ("--overwrite", "Makefile"),
                        ("--overwrite", "../outside"), ("--skill", "unknown")):
            with self.subTest(options=options):
                self.run_init(*options, success=False)
                self.assertFalse(self.target.exists())

    def test_gitignore_preserves_custom_bytes_exceptions_and_idempotence(self):
        self.target.mkdir()
        original = b"# custom\r\n!keep.log\r\nprivate-data/\r\n"
        (self.target / ".gitignore").write_bytes(original)
        self.run_init()
        ignore = (self.target / ".gitignore").read_bytes()
        self.assertTrue(ignore.endswith(original))
        subprocess.run(["git", "init", str(self.target)], check=True, capture_output=True)
        result = subprocess.run(["git", "check-ignore", "keep.log"], cwd=self.target, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.run_init()
        self.assertEqual((self.target / ".gitignore").read_bytes(), ignore)

    def test_malformed_gitignore_block_stops_before_creating_files(self):
        self.target.mkdir()
        (self.target / ".gitignore").write_text("# BEGIN agent project baseline\nunfinished\n")
        before = self.snapshot()
        self.run_init(success=False)
        self.assertEqual(self.snapshot(), before)

    def test_destination_collision_is_checked_before_any_write(self):
        (self.target / "docs/test/RUNBOOK_TEMPLATE.md").mkdir(parents=True)
        self.run_init(success=False)
        self.assertFalse((self.target / "AGENTS.md").exists())

    def test_symlink_does_not_write_outside_target(self):
        outside = self.base / "outside"
        outside.mkdir()
        self.target.mkdir()
        try:
            (self.target / ".agents").symlink_to(outside, target_is_directory=True)
        except OSError as exc:
            self.skipTest(f"symlinks unavailable: {exc}")
        self.run_init(success=False)
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse((self.target / "AGENTS.md").exists())

    def test_dry_run_has_no_side_effects_on_fresh_or_existing_target(self):
        self.run_init("--dry-run")
        self.assertFalse(self.target.exists())
        self.run_init()
        before = self.snapshot()
        self.run_init("--dry-run", "--overwrite", "AGENTS.md", "--issue-provider", "github")
        self.assertEqual(self.snapshot(), before)

    def test_relative_path_rejected(self):
        self.run_init(target=Path("relative-project"), success=False)

    @unittest.skipUnless(shutil.which("bash") and shutil.which("python3"), "Bash/python3 unavailable")
    def test_bash_wrapper_matches_core(self):
        other = self.base / "direct"
        self.run_init(target=other)
        self.run_init(launcher=["bash", str(ROOT / "scripts/init_harness_project.sh")])
        self.assertEqual(self.snapshot(), {p.relative_to(other).as_posix(): p.read_bytes()
                                          for p in other.rglob("*") if p.is_file()})

    @unittest.skipUnless(shutil.which("pwsh") or shutil.which("powershell"), "PowerShell runtime unavailable")
    def test_powershell_wrapper_runs_real_initialization(self):
        runtime = shutil.which("pwsh") or shutil.which("powershell")
        result = subprocess.run(
            [runtime, "-NoProfile", "-File", str(ROOT / "scripts/init_harness_project.ps1"),
             "-Target", str(self.target), "-ProjectName", "PowerShell Project", "-Stack", "go",
             "-Skill", "test-runbook", "-IssueProvider", "repo"],
            check=False, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.target / "docs/issues/TEMPLATE.md").is_file())
        self.assertTrue((self.target / ".agents/skills/test-runbook/SKILL.md").is_file())

    def test_plugin_manifest_points_to_real_skills(self):
        plugin = ROOT / "plugins/project-workflows"
        manifest = json.loads((plugin / ".codex-plugin/plugin.json").read_text())
        self.assertEqual(manifest["name"], plugin.name)
        self.assertEqual(manifest["version"], "0.7.0")
        self.assertTrue((plugin / manifest["skills"]).is_dir())


if __name__ == "__main__":
    unittest.main()
