#!/usr/bin/env python3
"""Mechanical validator for the Shed Book Claude Code skill set.

Walks `.claude/skills/`, parses each SKILL.md's frontmatter, and enforces the
constraints that are *verifiable from disk*. It says nothing about whether a
skill is well written — only whether it is well formed. Prose quality is the
job of the authoring review; this file is the part that can be run in CI.

Dependency-free by design: Python 3 standard library only, no PyYAML.

    WHY A HAND-ROLLED FRONTMATTER PARSER
    ------------------------------------
    PyYAML is not in the stdlib, and this script must run on a bare `python3`
    in CI and on a fresh clone with no `pip install` step. Pulling in a
    third-party parser to validate a file whose whole purpose is "no
    surprises" would be self-defeating.

    The subset we must parse is small and closed: SKILL.md frontmatter is a
    flat mapping of scalar values, where the only non-trivial construct is a
    block scalar (`>-`, `>`, `|`, `|-`) used to wrap long descriptions. There
    is no nesting, no anchors, no flow mappings, no multi-document streams.
    Hand-parsing that subset is correct and auditable in ~90 lines.

    The trade-off is deliberate and has one consequence worth naming: this
    parser is *more permissive* than a real YAML parser on constructs it does
    not model. It therefore also runs an explicit check for the one
    documented silent-failure trap — an unquoted inline value containing
    `": "`, which real YAML rejects and which Claude Code responds to by
    loading the skill with EMPTY metadata (the skill still answers to its
    slash command, but never auto-triggers). See MALFORMED_INLINE_COLON below.
    Anything stranger than that will pass here and should be caught by
    `claude plugin validate`, which is the authority on YAML parseability.

Exit codes: 0 = clean or warnings only, 1 = at least one failure,
2 = the skills root does not exist.
"""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Thresholds and known values. Every number this script enforces lives here.
# ---------------------------------------------------------------------------

SKILLS_ROOT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".claude", "skills"
)

# Hard platform limits (docs/skills/research/01-skill-mechanics.md, frontmatter reference).
NAME_MAX_CHARS = 64
DESCRIPTION_MAX_CHARS = 1024

# SKILL.md body length. 500 is Anthropic's documented ceiling; 200 is this
# project's own target, sitting just above the ~132-line median of Anthropic's
# shipped skills. Over 200 is a smell, not a defect.
BODY_FAIL_LINES = 500
BODY_WARN_LINES = 200

# Total skill-listing budget. Claude Code loads every name + description at
# startup within ~1% of the context window and, on overflow, silently drops
# descriptions starting with the least-invoked skills. These two numbers are
# this project's own guard rails, not published limits — they are set well
# under the real budget so the set has headroom to grow.
LISTING_WARN_CHARS = 6000
LISTING_FAIL_CHARS = 8000

# A supporting reference file longer than this needs a table of contents, so a
# partial read still tells Claude what is in the rest of the file.
REFERENCE_TOC_LINES = 100
# How far into a reference file we look for that table of contents.
TOC_SEARCH_LINES = 45

# Frontmatter keys verified against the Claude Code frontmatter reference plus
# the agentskills.io spec fields. An unknown key is a WARNING, never a failure
# — see check_unknown_keys() for the reasoning.
KNOWN_FRONTMATTER_KEYS = {
    # Claude Code frontmatter reference
    "name",
    "description",
    "when_to_use",
    "argument-hint",
    "arguments",
    "disable-model-invocation",
    "user-invocable",
    "allowed-tools",
    "disallowed-tools",
    "model",
    "effort",
    "context",
    "agent",
    "background",
    "hooks",
    "paths",
    "shell",
    # agentskills.io spec fields (portable skills)
    "license",
    "compatibility",
    "metadata",
}

# `name` may not contain these. Documented constraint on the platform.
RESERVED_NAME_WORDS = ("anthropic", "claude")

NAME_PATTERN = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

# First/second-person openings. A description is read by Claude as a
# third-person catalogue entry; "I" and "You" address the wrong party and
# "Use this to" wastes the leading tokens that carry trigger keywords.
FIRST_SECOND_PERSON_OPENERS = ("I ", "You ", "I can", "Use this to")

# Directory names that are unambiguously skill-internal. A path starting with
# one of these is checked for existence even when the directory is absent, so a
# typo like `references/harnes.md` in a skill with no references/ still fails.
#
# `assets/` and `templates/` are deliberately NOT here. In a Flutter repo
# `assets/` is the application's asset directory, and a SKILL.md that writes
# `assets/fonts/Inter.ttf` is naming a project path, not a skill payload.
# Those names count as skill-internal only when the skill actually contains
# such a directory — see check_named_files_exist().
SKILL_SUPPORT_DIRS = {"references", "reference", "examples", "scripts"}

# Files that are not part of a skill's payload and are ignored on disk.
IGNORED_FILENAMES = {".DS_Store", "Thumbs.db"}

# Extensions treated as prose references (TOC rule applies). Source examples
# are exempt: a table of contents inside a .dart file is not a real construct.
REFERENCE_EXTENSIONS = {".md", ".markdown", ".txt"}

MALFORMED_INLINE_COLON = re.compile(r":\s")

# Windows-style path detection.
#
# A naive "any backslash between word characters" rule is useless in this
# corpus: SKILL.md bodies quote grep patterns (`save\w*\(`, `SemanticsService\.`)
# and binary magic numbers (`PK\x03\x04`, `SQLite format 3\0`), and every one
# of those matches. So a backslash is reported only when it is demonstrably
# acting as a PATH SEPARATOR, which means one of:
#
#   (a) a drive-letter prefix          C:\Users\...
#   (b) mixed separators in one token  lib/data\repo.dart
#   (c) the segment after it is a filename with an extension
#                                      android\app\build.gradle
#   (d) the segment before it is a known repo or skill directory
#                                      docs\engineering
#
# KNOWN BLIND SPOT, stated rather than hidden: a two-segment Windows path with
# no extension, no drive letter and an unfamiliar first segment (`foo\bar`) is
# not reported, because on disk it is indistinguishable from a regex escape.
# Widening the rule to catch it costs four false positives in this repo alone.
BACKSLASH_ANY = re.compile(r"[A-Za-z0-9_.\-/]+\\[A-Za-z0-9_.\-/]+(\\[A-Za-z0-9_.\-/]+)*")
DRIVE_LETTER = re.compile(r"^[A-Za-z]:\\")
FILENAME_WITH_EXT = re.compile(r"^[A-Za-z0-9_.\-]+\.[A-Za-z0-9]{1,6}$")
PATHISH_DIR_NAMES = {
    "lib",
    "test",
    "docs",
    "doc",
    "tool",
    "android",
    "ios",
    "macos",
    "windows",
    "linux",
    "web",
    "assets",
    "references",
    "reference",
    "examples",
    "scripts",
    "src",
    "bin",
}

# Candidate file paths named in prose: backticked, or a bare slashed path.
BACKTICK_TOKEN = re.compile(r"`([^`\n]+)`")
MD_LINK_TARGET = re.compile(r"\]\(([^)\s]+)\)")


# ---------------------------------------------------------------------------
# Result plumbing
# ---------------------------------------------------------------------------


@dataclass
class Report:
    failures: list[tuple[str, str]] = field(default_factory=list)
    warnings: list[tuple[str, str]] = field(default_factory=list)

    def fail(self, scope: str, message: str) -> None:
        self.failures.append((scope, message))

    def warn(self, scope: str, message: str) -> None:
        self.warnings.append((scope, message))


@dataclass
class Frontmatter:
    keys: dict[str, str]
    order: list[str]
    body_line_count: int
    body_offset: int


# ---------------------------------------------------------------------------
# Frontmatter parsing (see module docstring for why this is hand-rolled)
# ---------------------------------------------------------------------------


def parse_frontmatter(text: str, scope: str, report: Report) -> Frontmatter | None:
    """Parse the flat `key: value` frontmatter block. Returns None if absent."""
    lines = text.split("\n")
    if not lines or lines[0].rstrip() != "---":
        report.fail(scope, "no YAML frontmatter: file does not open with `---` on line 1")
        return None

    end = None
    for i in range(1, len(lines)):
        if lines[i].rstrip() == "---":
            end = i
            break
    if end is None:
        report.fail(scope, "malformed frontmatter: opening `---` is never closed")
        return None

    keys: dict[str, str] = {}
    order: list[str] = []
    i = 1
    while i < end:
        raw = lines[i]
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        if raw[:1].isspace():
            report.fail(
                scope,
                f"malformed frontmatter line {i + 1}: unexpected indentation "
                f"(frontmatter here must be a flat key/value map) -> {stripped[:60]!r}",
            )
            i += 1
            continue
        if ":" not in raw:
            report.fail(
                scope,
                f"malformed frontmatter line {i + 1}: not a `key: value` pair -> {stripped[:60]!r}",
            )
            i += 1
            continue

        key, _, rest = raw.partition(":")
        key = key.strip()
        rest = rest.strip()

        if key in keys:
            report.fail(scope, f"duplicate frontmatter key `{key}` (line {i + 1})")
        order.append(key)

        block_marker = rest.rstrip("0123456789")
        if block_marker in (">", ">-", ">+", "|", "|-", "|+"):
            folded = block_marker.startswith(">")
            chunk: list[str] = []
            i += 1
            while i < end:
                nxt = lines[i]
                if nxt.strip() and not nxt[:1].isspace():
                    break
                chunk.append(nxt.strip())
                i += 1
            keys[key] = _join_block(chunk, folded)
            continue

        if rest and rest[0] not in "\"'[{" and MALFORMED_INLINE_COLON.search(rest):
            report.fail(
                scope,
                f"frontmatter key `{key}` is an unquoted inline value containing `: ` — "
                "real YAML rejects this, and Claude Code responds by loading the skill "
                "with EMPTY metadata (it answers /slash but never auto-triggers). "
                "Quote the value or move it to a `>-` block scalar.",
            )
        keys[key] = _unquote(rest)
        i += 1

    body_lines = lines[end + 1 :]
    while body_lines and not body_lines[-1].strip():
        body_lines.pop()
    return Frontmatter(keys, order, len(body_lines), end + 1)


def _join_block(chunk: list[str], folded: bool) -> str:
    if not folded:
        return "\n".join(chunk).strip()
    out: list[str] = []
    for line in chunk:
        if not line:
            out.append("\n")
        elif out and out[-1] != "\n":
            out.append(" " + line)
        else:
            out.append(line)
    return "".join(out).strip()


def _unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


# ---------------------------------------------------------------------------
# Individual checks
# ---------------------------------------------------------------------------


def check_name(name: str | None, dirname: str, scope: str, report: Report) -> None:
    if name is None:
        report.fail(
            scope,
            "`name` is absent. It defaults to the directory name, but stating it "
            "keeps the file self-describing and survives a directory rename.",
        )
        return
    if not name:
        report.fail(scope, "`name` is empty")
        return
    if name != dirname:
        report.fail(scope, f"`name: {name}` does not match its directory `{dirname}/`")
    if not NAME_PATTERN.match(name):
        report.fail(
            scope,
            f"`name: {name}` is not kebab-case "
            "(lowercase letters, digits and single interior hyphens only)",
        )
    if len(name) > NAME_MAX_CHARS:
        report.fail(scope, f"`name` is {len(name)} chars, over the {NAME_MAX_CHARS}-char limit")
    for word in RESERVED_NAME_WORDS:
        if word in name.lower():
            report.fail(scope, f"`name` contains the reserved word {word!r}")


def check_description(description: str | None, scope: str, report: Report) -> None:
    if description is None:
        report.fail(
            scope,
            "`description` is absent. Without it the skill has nothing to match "
            "against and will never auto-trigger.",
        )
        return
    if not description.strip():
        report.fail(scope, "`description` is empty")
        return
    length = len(description)
    if length > DESCRIPTION_MAX_CHARS:
        report.fail(
            scope, f"`description` is {length} chars, over the {DESCRIPTION_MAX_CHARS}-char limit"
        )
    for opener in FIRST_SECOND_PERSON_OPENERS:
        if description.startswith(opener):
            report.fail(
                scope,
                f"`description` opens in first/second person ({opener.strip()!r}). "
                "Descriptions are third-person catalogue entries: say what the skill "
                "does and when it applies.",
            )
            break
    if re.search(r"\b(you|your|I|my)\b", description):
        report.warn(
            scope,
            "`description` contains a first/second-person pronoun. Check it reads as a "
            "third-person catalogue entry.",
        )


def check_unknown_keys(fm: Frontmatter, scope: str, report: Report) -> None:
    for key in fm.order:
        if key not in KNOWN_FRONTMATTER_KEYS:
            report.warn(
                scope,
                f"unknown frontmatter key `{key}`. WARNING, not a failure: the field set "
                "is versioned by the Claude Code release, so an unrecognised key is "
                "either a typo the loader silently drops or a field newer than this "
                "script's verified list. From disk alone the two are indistinguishable, "
                "so this script refuses to guess. Confirm against the frontmatter "
                "reference for your CLI version.",
            )


def check_body_length(fm: Frontmatter, scope: str, report: Report) -> None:
    n = fm.body_line_count
    if n > BODY_FAIL_LINES:
        report.fail(
            scope, f"body is {n} lines, over the {BODY_FAIL_LINES}-line ceiling. Split it."
        )
    elif n > BODY_WARN_LINES:
        report.warn(
            scope,
            f"body is {n} lines, over the {BODY_WARN_LINES}-line target "
            f"(ceiling is {BODY_FAIL_LINES}). Consider moving detail to a reference file.",
        )


def documented_paths(text: str) -> set[str]:
    """Every path-shaped token written in the file."""
    found: set[str] = set()
    for token in BACKTICK_TOKEN.findall(text) + MD_LINK_TARGET.findall(text):
        token = token.strip()
        token = token.replace("${CLAUDE_SKILL_DIR}/", "").replace("$CLAUDE_SKILL_DIR/", "")
        token = re.sub(r"^\./", "", token)
        # Strip a trailing command argument, e.g. `scripts/contrast.py <fg> <bg>`.
        token = token.split()[0] if token.split() else ""
        if not token or "/" not in token:
            continue
        found.add(token)
    return found


def check_named_files_exist(
    skill_dir: str, text: str, subdirs: set[str], scope: str, report: Report
) -> set[str]:
    """Fail on a path under the skill directory that does not exist on disk.

    Only paths whose first segment is a support directory of THIS skill are
    considered. Everything else (`docs/engineering/…`, `lib/…`, `pubspec.yaml`)
    points at the wider repo, which is out of scope for a skill-set validator.
    """
    resolved: set[str] = set()
    candidates = SKILL_SUPPORT_DIRS | subdirs
    for path in documented_paths(text):
        head = path.split("/", 1)[0]
        if head not in candidates:
            continue
        full = os.path.join(skill_dir, path)
        if path.endswith("/"):
            if not os.path.isdir(full):
                report.fail(scope, f"names directory `{path}`, which does not exist on disk")
            continue
        resolved.add(os.path.normpath(path))
        if not os.path.isfile(full):
            report.fail(scope, f"names `{path}`, which does not exist on disk")
    return resolved


def check_orphan_files(
    skill_dir: str, text: str, named: set[str], scope: str, report: Report
) -> list[str]:
    """Fail on a supporting file that exists but is never named in SKILL.md.

    An unnamed file is dead weight: progressive disclosure only works if
    SKILL.md tells Claude the file exists and when to open it.
    """
    on_disk: list[str] = []
    for root, dirs, files in os.walk(skill_dir):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for fname in sorted(files):
            if fname in IGNORED_FILENAMES:
                continue
            rel = os.path.relpath(os.path.join(root, fname), skill_dir).replace(os.sep, "/")
            if rel == "SKILL.md":
                continue
            on_disk.append(rel)
            if rel in named or rel in text:
                continue
            if os.path.basename(rel) in text:
                report.warn(
                    scope,
                    f"`{rel}` is referenced only by bare filename, not by its path "
                    "relative to the skill. Write the relative path so the reference "
                    "is unambiguous.",
                )
                continue
            report.fail(
                scope,
                f"`{rel}` exists on disk but is never named in SKILL.md — Claude will "
                "never know to open it. Name it with a load condition, or delete it.",
            )
    return on_disk


def check_empty_dirs(skill_dir: str, scope: str, report: Report) -> None:
    for root, dirs, files in os.walk(skill_dir):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        if root == skill_dir:
            continue
        real = [f for f in files if f not in IGNORED_FILENAMES]
        if not real and not dirs:
            rel = os.path.relpath(root, skill_dir).replace(os.sep, "/")
            report.fail(scope, f"`{rel}/` is an empty directory")


def strip_code_fences(text: str) -> str:
    out, fenced = [], False
    for line in text.split("\n"):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if not fenced:
            out.append(line)
    return "\n".join(out)


def _is_windows_path(token: str) -> bool:
    if DRIVE_LETTER.match(token):
        return True
    if "/" in token:
        return True
    segments = token.split("\\")
    if FILENAME_WITH_EXT.match(segments[-1]):
        return True
    return segments[0].lower() in PATHISH_DIR_NAMES


def check_backslash_paths(path_label: str, text: str, scope: str, report: Report) -> None:
    body = strip_code_fences(text)
    seen: set[str] = set()
    for match in BACKSLASH_ANY.finditer(body):
        token = match.group(0)
        if token in seen or not _is_windows_path(token):
            continue
        seen.add(token)
        report.fail(
            scope,
            f"{path_label} documents a path with a backslash: `{token}`. "
            "Skill paths are POSIX; a backslash breaks on macOS and Linux.",
        )


def has_toc(text: str) -> bool:
    head = text.split("\n")[:TOC_SEARCH_LINES]
    linked = 0
    for line in head:
        low = line.strip().lower()
        if low.startswith("#") and ("contents" in low or "table of contents" in low):
            return True
        if re.match(r"^([-*]|\d+\.)\s+\[", line.strip()):
            linked += 1
    return linked >= 3


def check_reference_tocs(skill_dir: str, rel_files: list[str], scope: str, report: Report) -> None:
    for rel in rel_files:
        if os.path.splitext(rel)[1].lower() not in REFERENCE_EXTENSIONS:
            continue
        full = os.path.join(skill_dir, rel)
        text = read_text(full)
        n = len(text.rstrip("\n").split("\n"))
        if n > REFERENCE_TOC_LINES and not has_toc(text):
            report.fail(
                scope,
                f"`{rel}` is {n} lines (over {REFERENCE_TOC_LINES}) with no table of "
                "contents in its first "
                f"{TOC_SEARCH_LINES} lines. Add one so a partial read still shows what "
                "the rest of the file holds.",
            )


def build_cross_ref_pattern(skill_names: set[str]) -> re.Pattern[str] | None:
    """A regex for tokens that look like a skill name in THIS set.

    The prefixes are derived from the directories on disk rather than
    hardcoded, so the check configures itself for any skill set.
    """
    prefixes = sorted({n.split("-", 1)[0] for n in skill_names if "-" in n})
    if not prefixes:
        return None
    alt = "|".join(re.escape(p) for p in prefixes)
    return re.compile(rf"\b(?:{alt})-[a-z0-9]+(?:-[a-z0-9]+)*\b")


def check_cross_references(
    text: str,
    pattern: re.Pattern[str] | None,
    skill_names: set[str],
    scope: str,
    report: Report,
) -> None:
    """Fail on a pointer to a sibling skill that does not exist.

    Descriptions in this set end with `Do NOT use for X (other-skill)`. A
    pointer at a renamed or never-built skill sends Claude nowhere, and no
    other check here can see it.
    """
    if pattern is None:
        return
    for name in sorted(set(pattern.findall(text))):
        if name not in skill_names:
            report.fail(
                scope,
                f"points at sibling skill `{name}`, which is not a directory in the "
                "skills root",
            )


def read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------


def main(argv: list[str]) -> int:
    # An explicit root lets CI point at another tree, and lets this script be
    # tested against a deliberately broken fixture. Defaults to this repo.
    root = os.path.abspath(argv[1]) if len(argv) > 1 else SKILLS_ROOT
    if not os.path.isdir(root):
        print(f"FATAL: no skills directory at {root}")
        return 2

    report = Report()
    skill_dirs = sorted(
        d
        for d in os.listdir(root)
        if os.path.isdir(os.path.join(root, d)) and not d.startswith(".")
    )
    skill_names = set(skill_dirs)
    cross_ref = build_cross_ref_pattern(skill_names)

    stray_root = [
        f
        for f in sorted(os.listdir(root))
        if os.path.isfile(os.path.join(root, f)) and f not in IGNORED_FILENAMES
    ]
    for f in stray_root:
        report.fail("<skills root>", f"stray file `{f}` at the skills root")

    listing_chars = 0
    per_skill: list[tuple[str, int, int, bool]] = []

    print(f"validate_skills.py — {root}")
    print(f"{len(skill_dirs)} skill directories\n")

    for dirname in skill_dirs:
        skill_dir = os.path.join(root, dirname)
        scope = dirname
        skill_md = os.path.join(skill_dir, "SKILL.md")

        if not os.path.isfile(skill_md):
            report.fail(scope, "directory has no SKILL.md")
            check_empty_dirs(skill_dir, scope, report)
            continue

        text = read_text(skill_md)
        fm = parse_frontmatter(text, scope, report)
        subdirs = {
            d for d in os.listdir(skill_dir) if os.path.isdir(os.path.join(skill_dir, d))
        }

        if fm is None:
            check_empty_dirs(skill_dir, scope, report)
            continue

        check_name(fm.keys.get("name"), dirname, scope, report)
        description = fm.keys.get("description")
        check_description(description, scope, report)
        check_unknown_keys(fm, scope, report)
        check_body_length(fm, scope, report)
        check_backslash_paths("SKILL.md", text, scope, report)
        check_cross_references(text, cross_ref, skill_names, scope, report)

        named = check_named_files_exist(skill_dir, text, subdirs, scope, report)
        on_disk = check_orphan_files(skill_dir, text, named, scope, report)
        check_reference_tocs(skill_dir, on_disk, scope, report)
        check_empty_dirs(skill_dir, scope, report)

        for rel in on_disk:
            if os.path.splitext(rel)[1].lower() in REFERENCE_EXTENSIONS:
                check_backslash_paths(rel, read_text(os.path.join(skill_dir, rel)), scope, report)

        desc_len = len(description or "")

        # A skill with `disable-model-invocation: true` is never auto-invoked, so
        # Claude Code keeps its DESCRIPTION out of context entirely — only the name
        # stays in the listing:
        #
        #   "disable-model-invocation: true | Model-invocable: No | User-invocable:
        #    Yes | Description NOT in context; content on invoke"
        #   — code.claude.com/docs/en/skills.md, "Control who invokes"
        #
        # Counting those descriptions against the budget overstates it and pressures
        # an author into shortening runbook descriptions that cost nothing. The name
        # is still charged, because the listing always contains every skill name.
        manual_only = fm.keys.get("disable-model-invocation", "").strip().lower() == "true"
        listing_chars += len(dirname) + (0 if manual_only else desc_len)
        per_skill.append((dirname, desc_len, fm.body_line_count, manual_only))

    # Listing budget: every name, plus the description of every model-invocable
    # skill. Runbook descriptions are excluded — see the note above.
    if listing_chars > LISTING_FAIL_CHARS:
        report.fail(
            "<listing budget>",
            f"names + descriptions total {listing_chars} chars, over the "
            f"{LISTING_FAIL_CHARS}-char ceiling. Claude Code will truncate descriptions "
            "and the dropped keywords are the ones that make skills trigger.",
        )
    elif listing_chars > LISTING_WARN_CHARS:
        report.warn(
            "<listing budget>",
            f"names + descriptions total {listing_chars} chars, over the "
            f"{LISTING_WARN_CHARS}-char target (ceiling {LISTING_FAIL_CHARS}). "
            "Headroom is thin; check `/context` before adding more skills.",
        )

    # ---- report -----------------------------------------------------------
    print("PER SKILL")
    print(f"  {'skill':<34} {'desc':>5} {'body':>5}")
    manual_count = 0
    manual_chars = 0
    for dirname, desc_len, body_lines, manual_only in per_skill:
        flag = ""
        if body_lines > BODY_FAIL_LINES:
            flag = "  FAIL body"
        elif body_lines > BODY_WARN_LINES:
            flag = "  warn body"
        if manual_only:
            manual_count += 1
            manual_chars += desc_len
            flag = "  manual-only, desc not in context" + flag
        print(f"  {dirname:<34} {desc_len:>5} {body_lines:>5}{flag}")
    print(
        f"\n  listing budget: {listing_chars} chars "
        f"(warn {LISTING_WARN_CHARS} / fail {LISTING_FAIL_CHARS})"
    )
    if manual_count:
        print(
            f"  excluded: {manual_chars} chars of description across {manual_count} "
            f"manual-only skill(s), which Claude Code keeps out of context"
        )

    if report.failures:
        print(f"\nFAILURES ({len(report.failures)})")
        for scope, message in report.failures:
            print(f"  [FAIL] {scope}: {message}")
    if report.warnings:
        print(f"\nWARNINGS ({len(report.warnings)})")
        for scope, message in report.warnings:
            print(f"  [WARN] {scope}: {message}")

    status = "FAIL" if report.failures else ("PASS with warnings" if report.warnings else "PASS")
    print(
        f"\nSUMMARY: {status} — {len(skill_dirs)} skills, "
        f"{len(report.failures)} failures, {len(report.warnings)} warnings, "
        f"listing {listing_chars}/{LISTING_FAIL_CHARS} chars"
    )
    return 1 if report.failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
