#!/usr/bin/env python3
"""Project plan archive helper.

Default mode is dry-run. File moves and rewrites require --write.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any


PLANS_ROOT = Path(".agents/plans")
COMPLETED_ROOT = PLANS_ROOT / "completed"
TEMPLATE_FILES = {"TEMPLATE.md", "EXAMPLE-implementation.md"}
DATE_PREFIX = r"^(\d{4}-\d{2}-\d{2})-.+\.md$"
NULL_ISSUES = {"", "-", "n/a", "na", "none", "null", "nil"}


@dataclass
class Candidate:
    path: Path
    relative_path: str
    basename: str
    plan_date: str
    target_week: str
    target_path: Path
    target_relative_path: str
    execution_issue: str | None
    master_issue: str | None
    selected_issue: str | None
    selected_issue_source: str | None
    missing_issue: bool

    def as_dict(self) -> dict[str, Any]:
        return {
            "path": self.path.as_posix(),
            "relative_path": self.relative_path,
            "basename": self.basename,
            "plan_date": self.plan_date,
            "target_week": self.target_week,
            "target_path": self.target_path.as_posix(),
            "target_relative_path": self.target_relative_path,
            "execution_issue": self.execution_issue,
            "master_issue": self.master_issue,
            "selected_issue": self.selected_issue,
            "selected_issue_source": self.selected_issue_source,
            "missing_issue": self.missing_issue,
        }


@dataclass
class MalformedCandidate:
    path: str
    relative_path: str
    basename: str
    reason: str

    def as_dict(self) -> dict[str, str]:
        return {
            "path": self.path,
            "relative_path": self.relative_path,
            "basename": self.basename,
            "reason": self.reason,
        }


@dataclass
class RewritePreview:
    path: Path
    relative_path: str
    replacement_count: int
    matched_old_paths: list[str]
    updated_text: str

    def as_dict(self) -> dict[str, Any]:
        return {
            "path": self.path.as_posix(),
            "relative_path": self.relative_path,
            "replacement_count": self.replacement_count,
            "matched_old_paths": self.matched_old_paths,
        }


def emit(data: dict[str, Any], as_json: bool) -> None:
    if as_json:
        print(json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True))
        return

    for key, value in data.items():
        if isinstance(value, (dict, list)):
            print(f"{key}: {json.dumps(value, ensure_ascii=False, indent=2)}")
        else:
            print(f"{key}: {value}")


def normalize_issue(raw: str | None) -> str | None:
    if raw is None:
        return None
    value = raw.strip().strip("`").strip()
    if value.lower() in NULL_ISSUES:
        return None
    return value


def issue_key(value: str | None) -> str | None:
    normalized = normalize_issue(value)
    return normalized.upper() if normalized else None


def ensure_repo(repo: str | Path) -> Path:
    path = Path(repo).expanduser().resolve()
    if not path.exists():
        raise SystemExit(f"repo does not exist: {path}")
    if not path.is_dir():
        raise SystemExit(f"repo is not a directory: {path}")
    return path


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def extract_issue(text: str, key: str) -> str | None:
    for line in text.splitlines():
        stripped = line.strip()
        prefix = f"- `{key}`:"
        plain_prefix = f"- {key}:"
        if stripped.startswith(prefix):
            return normalize_issue(stripped[len(prefix) :].strip())
        if stripped.startswith(plain_prefix):
            return normalize_issue(stripped[len(plain_prefix) :].strip())
    return None


def iso_week(value: date) -> str:
    iso = value.isocalendar()
    return f"{iso.year}-W{iso.week:02d}"


def parse_candidate(repo: Path, path: Path) -> Candidate | MalformedCandidate | None:
    import re

    match = re.match(DATE_PREFIX, path.name)
    if not match:
        return None

    relative_path = path.relative_to(repo).as_posix()
    try:
        plan_day = date.fromisoformat(match.group(1))
    except ValueError:
        return MalformedCandidate(
            path=path.as_posix(),
            relative_path=relative_path,
            basename=path.name,
            reason="invalid_plan_date",
        )

    text = read_text(path)
    execution_issue = extract_issue(text, "execution_issue")
    master_issue = extract_issue(text, "master_issue")
    selected_issue = execution_issue or master_issue
    selected_issue_source = None
    if execution_issue:
        selected_issue_source = "execution_issue"
    elif master_issue:
        selected_issue_source = "master_issue"

    week = iso_week(plan_day)
    target_path = repo / COMPLETED_ROOT / week / path.name
    return Candidate(
        path=path,
        relative_path=relative_path,
        basename=path.name,
        plan_date=plan_day.isoformat(),
        target_week=week,
        target_path=target_path,
        target_relative_path=target_path.relative_to(repo).as_posix(),
        execution_issue=execution_issue,
        master_issue=master_issue,
        selected_issue=selected_issue,
        selected_issue_source=selected_issue_source,
        missing_issue=selected_issue is None,
    )


def inspect_repo(repo: str | Path) -> dict[str, Any]:
    repo_path = ensure_repo(repo)
    plans_dir = repo_path / PLANS_ROOT
    candidates: list[Candidate] = []
    malformed: list[MalformedCandidate] = []

    if not plans_dir.exists():
        raise SystemExit(f"missing plan directory: {plans_dir}")

    for path in sorted(plans_dir.glob("*.md")):
        if path.name in TEMPLATE_FILES:
            continue
        parsed = parse_candidate(repo_path, path)
        if parsed is None:
            continue
        if isinstance(parsed, MalformedCandidate):
            malformed.append(parsed)
            continue
        candidates.append(parsed)

    return {
        "repo": repo_path.as_posix(),
        "plans_root": (repo_path / PLANS_ROOT).as_posix(),
        "completed_root": (repo_path / COMPLETED_ROOT).as_posix(),
        "candidates": [candidate.as_dict() for candidate in candidates],
        "malformed": [item.as_dict() for item in malformed],
    }


def git_tracked_files(repo: Path) -> list[Path]:
    try:
        result = subprocess.run(
            ["git", "-C", repo.as_posix(), "ls-files"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return []

    return [repo / line for line in result.stdout.splitlines() if line.strip()]


def is_text_file(path: Path) -> bool:
    try:
        with path.open("rb") as handle:
            chunk = handle.read(4096)
    except OSError:
        return False
    if b"\0" in chunk:
        return False
    try:
        chunk.decode("utf-8")
    except UnicodeDecodeError:
        return False
    return True


def text_scan_files(repo: Path) -> list[Path]:
    seen: set[Path] = set()
    paths: list[Path] = []

    for path in git_tracked_files(repo):
        if path.is_file() and is_text_file(path):
            seen.add(path)
            paths.append(path)

    for pattern in [".agents/runs/**/*.md", ".agents/state/**/*.md"]:
        for path in sorted(repo.glob(pattern)):
            if path.is_file() and path not in seen and is_text_file(path):
                seen.add(path)
                paths.append(path)

    return paths


def replacement_pairs(candidates: list[Candidate]) -> list[tuple[str, str]]:
    return [(candidate.relative_path, candidate.target_relative_path) for candidate in candidates]


def preview_rewrites(repo: Path, candidates: list[Candidate]) -> list[RewritePreview]:
    pairs = replacement_pairs(candidates)
    previews: list[RewritePreview] = []

    for path in text_scan_files(repo):
        text = read_text(path)
        updated = text
        matched: list[str] = []
        count = 0

        for old, new in pairs:
            occurrences = updated.count(old)
            if occurrences:
                matched.append(old)
                count += occurrences
                updated = updated.replace(old, new)

        if count:
            previews.append(
                RewritePreview(
                    path=path,
                    relative_path=path.relative_to(repo).as_posix(),
                    replacement_count=count,
                    matched_old_paths=matched,
                    updated_text=updated,
                )
            )

    return previews


def apply_rewrites(previews: list[RewritePreview]) -> None:
    for preview in previews:
        write_text(preview.path, preview.updated_text)


def archive_repo(repo: str | Path, done_issues: list[str], *, write: bool) -> dict[str, Any]:
    repo_path = ensure_repo(repo)
    inspection = inspect_repo(repo_path)
    done = {issue_key(issue) for issue in done_issues}
    done.discard(None)

    eligible: list[Candidate] = []
    no_issue_default_archive: list[Candidate] = []
    skipped_not_done: list[Candidate] = []
    skipped_malformed: list[MalformedCandidate] = []

    for raw in inspection["malformed"]:
        skipped_malformed.append(
            MalformedCandidate(
                path=raw["path"],
                relative_path=raw["relative_path"],
                basename=raw["basename"],
                reason=raw["reason"],
            )
        )

    candidates_by_path: dict[str, Candidate] = {}
    for path in sorted((repo_path / PLANS_ROOT).glob("*.md")):
        parsed = parse_candidate(repo_path, path)
        if isinstance(parsed, Candidate):
            candidates_by_path[parsed.relative_path] = parsed

    for candidate in candidates_by_path.values():
        if candidate.target_path.exists():
            skipped_malformed.append(
                MalformedCandidate(
                    path=candidate.path.as_posix(),
                    relative_path=candidate.relative_path,
                    basename=candidate.basename,
                    reason="target_exists",
                )
            )
            continue

        selected_key = issue_key(candidate.selected_issue)
        if selected_key is None:
            no_issue_default_archive.append(candidate)
        elif selected_key in done:
            eligible.append(candidate)
        else:
            skipped_not_done.append(candidate)

    movable = eligible + no_issue_default_archive
    rewrites = preview_rewrites(repo_path, movable)

    if write:
        for candidate in movable:
            candidate.target_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(candidate.path.as_posix(), candidate.target_path.as_posix())
        apply_rewrites(rewrites)

    return {
        "repo": repo_path.as_posix(),
        "write": write,
        "done_issues": sorted(issue for issue in done if issue),
        "eligible": [candidate.as_dict() for candidate in eligible],
        "no_issue_default_archive": [candidate.as_dict() for candidate in no_issue_default_archive],
        "skipped_not_done": [candidate.as_dict() for candidate in skipped_not_done],
        "skipped_malformed": [candidate.as_dict() for candidate in skipped_malformed],
        "rewritten_refs": [preview.as_dict() for preview in rewrites],
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect_parser = subparsers.add_parser("inspect", help="inspect archive candidates")
    inspect_parser.add_argument("--repo", required=True, help="repository root")
    inspect_parser.add_argument("--json", action="store_true", help="emit JSON")

    archive_parser = subparsers.add_parser("archive", help="archive completed plans")
    archive_parser.add_argument("--repo", required=True, help="repository root")
    archive_parser.add_argument(
        "--done-issue",
        action="append",
        default=[],
        help="completed issue key, repeatable",
    )
    archive_parser.add_argument("--write", action="store_true", help="move files and rewrite refs")
    archive_parser.add_argument("--json", action="store_true", help="emit JSON")

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.command == "inspect":
        emit(inspect_repo(args.repo), args.json)
        return 0
    if args.command == "archive":
        emit(archive_repo(args.repo, args.done_issue, write=args.write), args.json)
        return 0

    parser.error(f"unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
