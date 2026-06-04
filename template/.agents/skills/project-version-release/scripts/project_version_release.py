#!/usr/bin/env python3
"""Project version/release helper.

Default mode is dry-run. File writes require --write.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


CHANGELOG = "CHANGELOG.md"
SEMVER_RE = re.compile(
    r"^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-[0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)?"
    r"(?:\+[0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)?$"
)
CATEGORIES = ["feature", "optimization", "bugFix", "note", "script"]
VERSION_FILE_HINTS = [
    "VERSION",
    "version.txt",
    "package.json",
    "pyproject.toml",
    "go.mod",
    "pom.xml",
    "gradle.properties",
]
UNRELEASED_GUIDANCE_COMMENTS = {
    "<!-- 普通 issue 新增条目只写在本 Unreleased 段；不要写入下面已归档版本段。 -->",
}


@dataclass
class Finding:
    severity: str
    path: str
    message: str
    detail: str = ""

    def as_dict(self) -> dict[str, str]:
        return {
            "severity": self.severity,
            "path": self.path,
            "message": self.message,
            "detail": self.detail,
        }


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def ensure_repo(repo: str) -> Path:
    path = Path(repo).expanduser().resolve()
    if not path.exists():
        raise SystemExit(f"repo does not exist: {path}")
    if not path.is_dir():
        raise SystemExit(f"repo is not a directory: {path}")
    return path


def emit(data: dict[str, Any], as_json: bool) -> None:
    if as_json:
        print(json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True))
        return

    for key, value in data.items():
        if isinstance(value, (dict, list)):
            print(f"{key}: {json.dumps(value, ensure_ascii=False, indent=2)}")
        else:
            print(f"{key}: {value}")


def validate_semver(value: str) -> None:
    if not SEMVER_RE.fullmatch(value.strip()):
        raise SystemExit(f"invalid SemVer: {value!r}")


def check_repo(repo: Path) -> dict[str, Any]:
    findings: list[Finding] = []

    changelog = repo / CHANGELOG
    if not changelog.exists():
        findings.append(Finding("error", CHANGELOG, "missing CHANGELOG.md"))
    else:
        text = read_text(changelog)
        if not re.search(r"(?m)^##\s+Unreleased\s*$", text):
            findings.append(
                Finding(
                    "warning",
                    CHANGELOG,
                    "missing Unreleased section",
                    "issue entries should be staged in Unreleased before release archive",
                )
            )
        releases = re.findall(r"(?m)^###\s+v?\d+\.\d+\.\d+(?:-[^\s(]+)?\(\d{8}\)", text)
        if len(releases) >= 5:
            findings.append(
                Finding(
                    "info",
                    CHANGELOG,
                    "many release headings detected",
                    "confirm these are real releases, not one version per issue",
                )
            )

    version_files = [hint for hint in VERSION_FILE_HINTS if (repo / hint).exists()]

    status = "ok"
    if any(item.severity == "error" for item in findings):
        status = "error"
    elif findings:
        status = "needs_attention"

    return {
        "repo": str(repo),
        "status": status,
        "version_file_hints": version_files,
        "findings": [item.as_dict() for item in findings],
    }


def normalize_changed(paths: list[str]) -> list[str]:
    return [p.strip().lstrip("./") for p in paths if p.strip()]


def classify(paths: list[str], issue: str | None = None, release_intent: bool = False) -> dict[str, Any]:
    changed = normalize_changed(paths)
    classification = "issue-only"
    reasons: list[str] = []

    if any(p == CHANGELOG or p.endswith(f"/{CHANGELOG}") for p in changed):
        classification = "changelog-only"
        reasons.append("CHANGELOG.md changed")

    if any(Path(p).name in VERSION_FILE_HINTS for p in changed):
        classification = "version-bump"
        reasons.append("version file changed")

    if release_intent:
        classification = "release-archive"
        reasons.append("explicit release intent")

    if not reasons:
        reasons.append("no release artifact or version surface detected")

    return {
        "issue": issue or "",
        "changed_files": changed,
        "classification": classification,
        "reasons": reasons,
    }


def find_unreleased_bounds(text: str) -> tuple[int, int, int, int] | None:
    match = re.search(r"(?m)^##\s+Unreleased\s*$", text)
    if not match:
        return None
    next_heading = re.search(r"(?m)^##?\s+", text[match.end() :])
    end = len(text) if not next_heading else match.end() + next_heading.start()
    return match.start(), match.end(), match.end(), end


def ensure_unreleased(text: str) -> str:
    if find_unreleased_bounds(text):
        return text
    insertion = "## Unreleased\n<!-- 普通 issue 新增条目只写在本 Unreleased 段；不要写入下面已归档版本段。 -->\n\n"
    return insertion + text.lstrip()


def split_unreleased_release_content(block: str) -> tuple[list[str], str]:
    lines = block.splitlines()
    preserved: list[str] = []
    content: list[str] = []
    for line in lines:
        if line.strip() in UNRELEASED_GUIDANCE_COMMENTS or not line.strip():
            preserved.append(line)
        else:
            content.append(line)
    return preserved, "\n".join(content).strip()


def next_item_number(section: str) -> int:
    numbers = [int(match.group(1)) for match in re.finditer(r"(?m)^\s*(\d+)\.\s+", section)]
    return max(numbers, default=0) + 1


def add_entry_to_block(block: str, category: str, entry: str) -> str:
    heading = f"#### {category}:"
    if heading not in block:
        prefix = block.rstrip()
        return f"{prefix}\n\n{heading}\n1. {entry}\n".lstrip()

    start = block.index(heading)
    next_heading = block.find("\n#### ", start + 1)
    end = len(block) if next_heading == -1 else next_heading
    section = block[start:end]
    number = next_item_number(section)
    replacement = section.rstrip() + f"\n{number}. {entry}\n"
    return block[:start] + replacement + block[end:]


def changelog_add(repo: Path, issue: str, category: str, text: str, write: bool) -> dict[str, Any]:
    if category not in CATEGORIES:
        raise SystemExit(f"invalid category: {category!r}; expected one of {CATEGORIES}")
    path = repo / CHANGELOG
    if not path.exists():
        raise SystemExit(f"missing {CHANGELOG}")

    original = read_text(path)
    normalized = ensure_unreleased(original)
    bounds = find_unreleased_bounds(normalized)
    if bounds is None:
        raise SystemExit("failed to create Unreleased section")

    _, _, body_start, body_end = bounds
    body = normalized[body_start:body_end]
    entry = f"[{issue}] {text}" if issue else text
    updated_body = add_entry_to_block(body, category, entry)
    updated = normalized[:body_start] + updated_body.rstrip() + "\n\n" + normalized[body_end:].lstrip("\n")

    if write:
        write_text(path, updated)

    return {
        "write": write,
        "path": CHANGELOG,
        "category": category,
        "entry": entry,
        "changed": updated != original,
        "target": f"{CHANGELOG} -> Unreleased -> #### {category}:",
    }


def release_archive(repo: Path, version: str, date_value: str, write: bool) -> dict[str, Any]:
    validate_semver(version)
    if not re.fullmatch(r"\d{8}", date_value):
        raise SystemExit(f"invalid release date: {date_value!r}; expected YYYYMMDD")

    path = repo / CHANGELOG
    if not path.exists():
        raise SystemExit(f"missing {CHANGELOG}")

    original = ensure_unreleased(read_text(path))
    bounds = find_unreleased_bounds(original)
    if bounds is None:
        raise SystemExit("missing Unreleased section")
    heading_start, heading_end, body_start, body_end = bounds
    body = original[body_start:body_end]
    preserved, content = split_unreleased_release_content(body)
    if not content:
        raise SystemExit("Unreleased section is empty; nothing to archive")

    release_block = f"### {version}({date_value})\n{content}\n\n"
    new_unreleased_body = "\n".join(line for line in preserved if line.strip()).strip()
    if new_unreleased_body:
        new_unreleased_body += "\n\n"
    updated = (
        original[:heading_end]
        + "\n"
        + new_unreleased_body
        + release_block
        + original[body_end:].lstrip("\n")
    )

    if write:
        write_text(path, updated)

    return {
        "write": write,
        "path": CHANGELOG,
        "version": version,
        "date": date_value,
        "changed": updated != original,
    }


def version_bump(repo: Path, version: str, files: list[str], write: bool) -> dict[str, Any]:
    validate_semver(version)
    changed: list[str] = []
    missing: list[str] = []

    for rel in files:
        path = repo / rel
        if not path.exists():
            missing.append(rel)
            continue
        if write:
            write_text(path, version + "\n")
        changed.append(rel)

    return {
        "write": write,
        "version": version,
        "changed_files": changed,
        "missing_files": missing,
    }


def policy_plan(channel: str, target_version: str, notes_url: str | None) -> dict[str, Any]:
    validate_semver(target_version)
    return {
        "channel": channel,
        "target_version": target_version,
        "notes_url": notes_url or "<release_notes_url>",
        "operator_intent": [
            "confirm release artifact and changelog archive",
            "publish release metadata through the project-owned release system",
            "run compatibility and update-manifest verification before promoting",
        ],
        "side_effects": "none; this command only prints operator intent",
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    check = sub.add_parser("check")
    check.add_argument("--repo", required=True)
    check.add_argument("--json", action="store_true")

    classify_cmd = sub.add_parser("classify")
    classify_cmd.add_argument("--repo", required=True)
    classify_cmd.add_argument("--changed-files", nargs="+", required=True)
    classify_cmd.add_argument("--issue")
    classify_cmd.add_argument("--release-intent", action="store_true")
    classify_cmd.add_argument("--json", action="store_true")

    add = sub.add_parser("changelog-add")
    add.add_argument("--repo", required=True)
    add.add_argument("--issue", default="")
    add.add_argument("--category", required=True)
    add.add_argument("--text", required=True)
    add.add_argument("--write", action="store_true")
    add.add_argument("--json", action="store_true")

    archive = sub.add_parser("release-archive")
    archive.add_argument("--repo", required=True)
    archive.add_argument("--version", required=True)
    archive.add_argument("--date", required=True)
    archive.add_argument("--write", action="store_true")
    archive.add_argument("--json", action="store_true")

    bump = sub.add_parser("version-bump")
    bump.add_argument("--repo", required=True)
    bump.add_argument("--version", required=True)
    bump.add_argument("--file", action="append", default=[])
    bump.add_argument("--write", action="store_true")
    bump.add_argument("--json", action="store_true")

    plan = sub.add_parser("policy-plan")
    plan.add_argument("--repo", required=True)
    plan.add_argument("--channel", required=True)
    plan.add_argument("--target-version", required=True)
    plan.add_argument("--notes-url")
    plan.add_argument("--json", action="store_true")

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    repo = ensure_repo(args.repo)

    if args.command == "check":
        emit(check_repo(repo), args.json)
    elif args.command == "classify":
        emit(classify(args.changed_files, args.issue, args.release_intent), args.json)
    elif args.command == "changelog-add":
        emit(changelog_add(repo, args.issue, args.category, args.text, args.write), args.json)
    elif args.command == "release-archive":
        emit(release_archive(repo, args.version, args.date, args.write), args.json)
    elif args.command == "version-bump":
        emit(version_bump(repo, args.version, args.file, args.write), args.json)
    elif args.command == "policy-plan":
        emit(policy_plan(args.channel, args.target_version, args.notes_url), args.json)
    else:
        parser.error(f"unknown command: {args.command}")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
