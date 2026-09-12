#!/usr/bin/env python3
"""Create missing project guidance; replace only explicitly selected files.

All destinations are checked before writing. Legacy files are never removed.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "template"
SKILLS = ROOT / "plugins/project-workflows/skills"
STACKS = (
    "go", "python", "java", "c", "go-node", "python-node", "java-node",
    "c-node", "java-c", "java-c-node",
)
IGNORE_START = "# BEGIN agent project baseline"
IGNORE_END = "# END agent project baseline"


@dataclass
class Change:
    relative_path: str
    content: bytes
    action: str


def safe_destination(target: Path, relative: str) -> Path:
    """Reject links and directory collisions before any generated file is written."""
    destination = target / relative
    for path in (destination, *destination.parents):
        if path.is_symlink():
            raise ValueError(f"refusing symlink destination: {path}")
        if path == target:
            break
    if destination.exists() and not destination.is_file():
        raise ValueError(f"destination is not a regular file: {destination}")
    for parent in destination.parents:
        if parent.exists() and not parent.is_dir():
            raise ValueError(f"destination parent is not a directory: {parent}")
    return destination


def gitignore_content(stack: str, existing: bytes) -> bytes:
    """Manage one block before user rules so user exceptions retain precedence."""
    names = ["base"] + ["node-frontend" if part == "node" else part
                         for part in stack.split("-")]
    pieces = [(ROOT / "sources/gitignore" / f"{name}.gitignore")
              .read_text(encoding="utf-8").rstrip() for name in names]
    block = (IGNORE_START + "\n" + "\n\n".join(pieces) + "\n"
             + IGNORE_END + "\n").encode()
    start_marker, end_marker = IGNORE_START.encode(), IGNORE_END.encode()
    lines = existing.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.rstrip(b"\r\n") == start_marker]
    ends = [i for i, line in enumerate(lines) if line.rstrip(b"\r\n") == end_marker]
    if not starts and not ends:
        return block + (b"\n" + existing if existing else b"")
    if len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]:
        raise ValueError("ambiguous initializer block in .gitignore; repair it first")
    start, end = starts[0], ends[0]
    return b"".join(lines[:start]) + block + b"".join(lines[end + 1:])


def build_changes(args: argparse.Namespace) -> list[Change]:
    target = Path(args.target)
    if not target.is_absolute():
        raise ValueError("--target must be a native absolute path")
    if target.is_symlink() or (target.exists() and not target.is_dir()):
        raise ValueError("--target must be a directory, not a file or symlink")
    if ".." in target.parts:
        raise ValueError("--target must not contain '..'")
    for parent in target.parents:
        if parent.exists() and not parent.is_dir():
            raise ValueError(f"target parent is not a real directory: {parent}")

    replacements = {
        "__PROJECT_NAME__": args.project_name,
        "__ISSUE_PREFIX__": args.issue_prefix,
        "__ISSUE_PROVIDER__": args.issue_provider,
    }
    desired: dict[str, bytes] = {}
    for source in sorted(TEMPLATE.rglob("*")):
        if not source.is_file():
            continue
        relative = source.relative_to(TEMPLATE).as_posix()
        if relative == ".gitignore":
            continue
        if relative.startswith("docs/issues/") and args.issue_provider != "repo":
            continue
        content = source.read_text(encoding="utf-8")
        for placeholder, value in replacements.items():
            content = content.replace(placeholder, value)
        desired[relative] = content.encode()

    for name in sorted(set(args.skill)):
        source_root = SKILLS / name
        for source in sorted(source_root.rglob("*")):
            if source.is_file() and not any(part in {"tests", "__pycache__"}
                                           for part in source.relative_to(source_root).parts):
                relative = source.relative_to(SKILLS).as_posix()
                desired[f".agents/skills/{relative}"] = source.read_bytes()

    gitignore = safe_destination(target, ".gitignore")
    existing_ignore = gitignore.read_bytes() if gitignore.exists() else b""
    desired[".gitignore"] = gitignore_content(args.stack, existing_ignore)
    unknown = set(args.overwrite) - desired.keys()
    if unknown:
        raise ValueError("--overwrite must name an output file: " + ", ".join(sorted(unknown)))
    changes = []
    for relative, content in desired.items():
        path = safe_destination(target, relative)
        if not path.exists():
            action = "create"
        elif path.read_bytes() == content:
            action = "unchanged"
        elif relative == ".gitignore" or relative in args.overwrite:
            action = "update"
        else:
            action = "keep-existing"
        changes.append(Change(relative, content, action))
    return changes


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True)
    parser.add_argument("--project-name", required=True)
    parser.add_argument("--stack", required=True, choices=STACKS)
    parser.add_argument("--issue-provider", default="linear",
                        choices=("linear", "github", "gitlab", "repo", "other"))
    parser.add_argument("--issue-prefix", default="")
    parser.add_argument("--skill", action="append", default=[],
                        choices=sorted(p.parent.name for p in SKILLS.glob("*/SKILL.md")),
                        help="copy one optional skill; repeat to select more")
    parser.add_argument("--overwrite", action="append", default=[], metavar="RELATIVE_PATH",
                        help="replace this generated file explicitly; repeat as needed")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true", help=argparse.SUPPRESS)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.force:
        parser.error("--force was removed; use --overwrite RELATIVE_PATH after reviewing that file. "
                     "Legacy cleanup is documented separately in docs/migration-v0.7.md")
    if not args.project_name.strip():
        parser.error("--project-name must not be empty")
    try:
        changes = build_changes(args)
        for change in changes:
            print(f"{'[dry-run] ' if args.dry_run else ''}{change.action}: {change.relative_path}")
            if not args.dry_run and change.action in {"create", "update"}:
                path = Path(args.target) / change.relative_path
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(change.content)
    except (OSError, ValueError) as exc:
        print(f"initialization failed: {exc}", file=sys.stderr)
        return 1
    print("Next: fill project facts in AGENTS.md; use plans and runbooks only when needed.")
    print("Existing files marked keep-existing retain their original project/provider metadata.")
    print("No legacy files were removed; no project tests or external operations were performed.")
    return 0


if __name__ == "__main__":
    if sys.version_info < (3, 10):
        raise SystemExit("Python 3.10+ is required")
    raise SystemExit(main())
