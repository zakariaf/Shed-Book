#!/usr/bin/env python3
"""Mechanical validator for the Shed Book epic/task backlog.

Walks `epics/`, parses every `epic.md` and every task file, and enforces the
constraints that are *verifiable from disk*. It says nothing about whether a
task is well conceived — only whether it is well formed and internally
consistent. Judgement is the audit's job; this file is the part that runs in
CI, wired into `make check` alongside `tool/check_policy.dart` and
`tool/validate_skills.py`.

Dependency-free by design: Python 3 standard library only.

WHAT IT REFUSES
---------------
  1. an epic directory with no `epic.md`
  2. a task file missing any required section, the named first failing test,
     the `/simplify` step, the review step, the Skills-to-load table, the
     Definition of Done or the Verification block
  3. a skill name that is not one of the twenty-four that exist on disk
     (an invented name is a defect: the developer types it and gets nothing)
  4. a task referenced by an `epic.md` with no file, or a task file its own
     `epic.md` does not reference
  5. a `Depends on` id that does not exist anywhere in the backlog
  6. a `Depends on` id that is not *earlier* than the task depending on it —
     epics are strictly sequential and one PR each, so a forward reference is
     a task that cannot be started when the plan says it starts

WHAT IT WARNS ABOUT
-------------------
  7. a sentence repeated across more than five task files. The backlog was
     once written by filling one template with one generic sentence
     ("the layers this task reaches are the ones named in §1 ...") 236 times;
     that sentence told a developer nothing and this check exists so it cannot
     come back unnoticed. The sections whose text the template deliberately
     fixes — the close-out sequence and the two stock TDD instructions — are
     exempt by name in TEMPLATE_FIXED_SENTENCES below, because there the
     repetition *is* the requirement. A warning, not a failure: judging whether
     a repeated sentence is boilerplate or a binding constraint restated is the
     audit's job, and this check only has to make the repetition visible.

Exit codes: 0 = clean (warnings allowed), 1 = at least one failure,
2 = the epics root does not exist.
"""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Roots
# ---------------------------------------------------------------------------

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EPICS_ROOT = os.path.join(REPO_ROOT, "epics")
SKILLS_ROOT = os.path.join(REPO_ROOT, ".claude", "skills")

# ---------------------------------------------------------------------------
# The twenty-four skills. Embedded as a constant so this script runs on a
# checkout with no `.claude/` directory, and cross-checked against disk when
# the directory is present — a skill added to one and not the other is a
# WARNING here and a failure in `tool/validate_skills.py`, which owns it.
# ---------------------------------------------------------------------------

AUTO_FIRING_SKILLS = {
    "shed-conventions",
    "shed-dependencies-and-toolchain",
    "shed-bootstrap-and-errors",
    "shed-riverpod-providers",
    "shed-write-path",
    "shed-drift-schema",
    "shed-domain",
    "shed-withdrawal",
    "shed-safety-rules",
    "shed-screens-and-routing",
    "shed-accessibility-and-copy",
    "shed-platform-gateways",
    "shed-export-and-restore",
    "shed-monetization",
    "shed-testing",
    "indelible-design-system",
    "indelible-page-and-screens",
    "indelible-controls",
    "indelible-marks-and-strikes",
    "indelible-states-and-feedback",
}

RUNBOOK_SKILLS = {
    "shed-migrations",
    "shed-release",
    "shed-goldens-rebaseline",
    "shed-code-review",
}

KNOWN_SKILLS = AUTO_FIRING_SKILLS | RUNBOOK_SKILLS

# Slash commands a task file may name that are NOT project skills. Anything
# else typed as `/name` is treated as an invented skill.
BUILTIN_SLASH_COMMANDS = {"simplify", "code-review"}

# ---------------------------------------------------------------------------
# Thresholds. Every number this script enforces lives here.
# ---------------------------------------------------------------------------

MAX_SKILLS_PER_TASK = 3          # CLAUDE.md: at most two auto-firing, plus one
MAX_AUTO_FIRING_PER_TASK = 2     # CLAUDE.md: "at most two auto-firing skills per intent"
MIN_SKILLS_PER_TASK = 1
MIN_DOD_ITEMS = 3
MIN_VERIFY_COMMANDS = 1
MIN_TASKS_PER_EPIC = 2           # one task is not an epic; it is a commit
MAX_TASKS_PER_EPIC = 12          # more than this is not one reviewing sitting
MIN_DELIVER_WORDS = 25           # a task whose "why" is one line has no why

MAX_FILES_PER_SENTENCE = 5       # a sentence in more than five task files is boilerplate
MIN_SENTENCE_WORDS = 10          # shorter than this and identical phrasing is not evidence

# R1 — RULED BY THE OWNER, 2026-07-31. Resolved by level, not by picking a winner.
#
#   Per TASK, before every commit: `/simplify`, then `/code-review`. Exactly the
#   two the owner specified, in that order.
#
#   Per EPIC, once over the whole branch before the PR is opened:
#   `/shed-code-review`, read in irreversibility order. That is where the spec
#   §12 safety questions actually belong — they are branch-shaped, not
#   commit-shaped, and the PR template (N01-T07) carries them verbatim.
#
# Running the project runbook on all 240 commits was one redundant review pass
# per task and is not what the owner asked for. Every epic.md states the
# branch-level step, so nothing was lost by removing it from the task files.
REQUIRE_BUNDLED_CODE_REVIEW = True
REQUIRE_PROJECT_CODE_REVIEW = False   # task level; epic.md holds the branch-level step

# ---------------------------------------------------------------------------
# Shapes
# ---------------------------------------------------------------------------

EPIC_DIR_RE = re.compile(r"^(N\d{2})-[a-z0-9-]+$")
TASK_ID_RE = re.compile(r"\bN\d{2}-T\d{2}[a-z]?\b")
TASK_FILE_RE = re.compile(r"^(N\d{2}-T\d{2}[a-z]?)-[a-z0-9-]+\.md$")

# Required task-file sections, in the order `00-AUDIT-template.md` §6 fixes.
REQUIRED_TASK_SECTIONS = [
    "## 1. Why this task exists",
    "## 2. Sources",
    "## 3. Skills to load",
    "## 4. TDD",
    "## 5. What you build",
    "## 6. Constraints that bind this task",
    "## 7. Definition of Done",
    "## 8. Verification",
    "## 9. Close out",
]

REQUIRED_EPIC_SECTIONS = ["## Goal", "## Tasks", "## Definition of Done", "## Demoable on merge"]

# The first failing test, as the template writes it.
ANCHOR_FILE_RE = re.compile(r"^- \*\*File\*\* — `([^`]+)`\s*$", re.M)
ANCHOR_NAME_RE = re.compile(r"^- \*\*Test\*\* — `['\"]([^`]+)['\"]`\s*$", re.M)
ANCHOR_WHY_RE = re.compile(r"^- \*\*Why it is red today\*\* — (.+)$", re.M)
ANCHOR_PATH_RE = re.compile(r"^(test|integration_test)/[A-Za-z0-9_/]+\.dart$")

SKILL_ROW_RE = re.compile(r"^\|\s*`([a-z0-9-]+)`\s*\|\s*(.+?)\s*\|\s*$", re.M)
BACKTICK_TOKEN_RE = re.compile(r"`([a-z]+(?:-[a-z]+)+)`")

# --- slash commands ---------------------------------------------------------
# A slash command is an *invocation*. Three things in this backlog look like one
# and are not, and a lookbehind cannot tell them apart because the character
# before the slash is the same in each case:
#
#   `/simplify`                  an invocation           ← the only one we want
#   `is`/`switch`/serialisation  an alternation          (backtick before)
#   `/tmp/seed_a`, `res/values`  a path                  (backtick before)
#   </resources>, </dict>        a closing XML/plist tag ('<' before)
#
# So the text is lexed instead of pattern-matched: fenced blocks are dropped,
# inline code spans are examined on their own (a span whose whole content is
# `/name` with no second slash is an invocation; anything else is a path), and
# each span is then replaced by \x01 — never whitespace — so that the prose scan
# cannot mistake the slash that *followed* a span for a command at word start.
FENCE_RE = re.compile(r"```.*?```", re.S)
CODE_SPAN_RE = re.compile(r"`([^`\n]*)`")
CODE_SPAN_CMD_RE = re.compile(r"^/([a-z][a-z0-9-]{2,})\b")
BARE_SLASH_RE = re.compile(r"(?:(?<=^)|(?<=[\s(\[]))/([a-z][a-z0-9-]{2,})\b(?![/.=])", re.M)
DEPENDS_ROW_RE = re.compile(r"^\|\s*\*\*Depends on\*\*\s*\|\s*(.+?)\s*\|\s*$", re.M)
DOD_ITEM_RE = re.compile(r"^- \[ \] ", re.M)
BASH_BLOCK_RE = re.compile(r"```bash\n(.*?)```", re.S)

# --- repeated-boilerplate detection ----------------------------------------
# Split on a full stop that ends a sentence — one followed by whitespace or the
# end of the text. A full stop inside `app_en.arb`, `CLAUDE.md` or `§5.4` is
# followed by a letter or a digit and must not end a sentence, or the check
# reports fragments instead of the boilerplate it is looking for.
SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?])\s+")

# The sentences the template fixes on purpose. Every task file carries these
# word for word because the owner requires the same closing sequence and the
# same "confirm it fails for the right reason" instruction everywhere; counting
# them as boilerplate would bury the sentences that *are* boilerplate. Matched
# as a prefix, so the task-specific tail of the Green step never matters.
TEMPLATE_FIXED_SENTENCES = (
    "Write this test first, run it, and confirm it fails",
    "With the suite green, fold any duplication into the smallest shared helper",
    "The minimum code that passes, and nothing beyond it",
)
# Sections whose whole body the template fixes. Their text is required to be
# identical and is not evidence of a generically filled task file.
TEMPLATE_FIXED_SECTIONS = ("## 9. Close out",)


@dataclass
class Problem:
    path: str
    rule: str
    message: str


@dataclass
class Report:
    failures: list = field(default_factory=list)
    warnings: list = field(default_factory=list)

    def fail(self, path, rule, message):
        self.failures.append(Problem(path, rule, message))

    def warn(self, path, rule, message):
        self.warnings.append(Problem(path, rule, message))


def rel(path: str) -> str:
    return os.path.relpath(path, REPO_ROOT)


def section_body(text: str, heading: str) -> str:
    """Everything from `heading` to the next `## ` heading."""
    idx = text.find(heading)
    if idx < 0:
        return ""
    rest = text[idx + len(heading):]
    nxt = re.search(r"^## ", rest, re.M)
    return rest[: nxt.start()] if nxt else rest


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

def slash_commands(text: str) -> set:
    """Every `/name` in `text` that is an invocation rather than a path, an
    alternation or a closing XML tag. See the comment on BARE_SLASH_RE."""
    text = FENCE_RE.sub(" ", text)
    found = set()

    def swallow(m):
        content = m.group(1).strip()
        cmd = CODE_SPAN_CMD_RE.match(content)
        if cmd and "/" not in content[1:]:
            found.add(cmd.group(1))
        return "\x01"

    prose = CODE_SPAN_RE.sub(swallow, text)
    found.update(BARE_SLASH_RE.findall(prose))
    return found


def sentences_of(text: str) -> set:
    """Prose sentences worth comparing across files. Fenced code, table rows,
    blockquotes, headings and the sections the template fixes are all dropped:
    none of them is a place where a generic sentence would be hiding, and a
    heading run into the paragraph below it produces a fragment that matches
    everywhere and means nothing."""
    for heading in TEMPLATE_FIXED_SECTIONS:
        idx = text.find(heading)
        if idx >= 0:
            text = text[:idx]
    text = FENCE_RE.sub(" ", text)
    lines = [ln for ln in text.splitlines()
             if not ln.lstrip().startswith(("|", ">", "#"))]
    flat = re.sub(r"\s+", " ", "\n".join(lines))
    out = set()
    for s in SENTENCE_SPLIT_RE.split(flat):
        s = s.strip()
        if len(s.split()) < MIN_SENTENCE_WORDS:
            continue
        if any(fixed in s for fixed in TEMPLATE_FIXED_SENTENCES):
            continue
        out.add(s)
    return out


def check_skill_names(path: str, text: str, report: Report, skills_table: list) -> None:
    """Rule 3 — no invented skill names, anywhere in the file."""
    for name, why in skills_table:
        if name not in KNOWN_SKILLS:
            report.fail(rel(path), "skill.unknown",
                        f"skills table names `{name}`, which is not one of the 24 skills")
        if not why or len(why.split()) < 3:
            report.fail(rel(path), "skill.no_reason",
                        f"`{name}` has no real one-line reason in the skills table")

    # Anywhere else in the prose: a backticked shed-*/indelible-* token, or a
    # slash-invoked name, must also be real.
    for tok in set(BACKTICK_TOKEN_RE.findall(text)):
        if tok.startswith(("shed-", "indelible-")) and tok not in KNOWN_SKILLS:
            report.fail(rel(path), "skill.unknown",
                        f"prose names `{tok}`, which is not one of the 24 skills")
    for tok in slash_commands(text):
        if tok in BUILTIN_SLASH_COMMANDS or tok in KNOWN_SKILLS:
            continue
        report.fail(rel(path), "skill.unknown_command",
                    f"prose invokes `/{tok}`, which is neither a built-in command nor one of the 24 skills")


def check_task_file(path: str, text: str, report: Report) -> dict:
    """Rules 2, 3 and the shape half of 5/6. Returns parsed facts."""
    r = rel(path)
    facts = {"depends": [], "id": None, "anchor": None}

    m = TASK_FILE_RE.match(os.path.basename(path))
    if not m:
        report.fail(r, "task.filename", "task file name is not <TASK-ID>-<slug>.md")
        return facts
    facts["id"] = m.group(1)

    if not text.startswith(f"# {facts['id']} — "):
        report.fail(r, "task.title", f"first line must be `# {facts['id']} — <title>`")

    for heading in REQUIRED_TASK_SECTIONS:
        if heading not in text:
            report.fail(r, "task.section_missing", f"missing required section `{heading}`")

    # --- the named first failing test -------------------------------------
    tdd = section_body(text, "## 4. TDD")
    f_m, n_m, w_m = ANCHOR_FILE_RE.search(tdd), ANCHOR_NAME_RE.search(tdd), ANCHOR_WHY_RE.search(tdd)
    if not (f_m and n_m and w_m):
        report.fail(r, "tdd.no_anchor",
                    "the TDD section must name a first failing test: a File, a Test name and why it is red today")
    else:
        anchor_path, anchor_name, why = f_m.group(1), n_m.group(1), w_m.group(1)
        facts["anchor"] = (anchor_path, anchor_name)
        if not ANCHOR_PATH_RE.match(anchor_path):
            report.fail(r, "tdd.anchor_path",
                        f"first failing test path `{anchor_path}` is not a .dart file under test/ or integration_test/")
        if len(anchor_name.split()) < 4:
            report.fail(r, "tdd.anchor_name",
                        f"test name `{anchor_name}` is not a property; it reads like a label")
        if len(why.split()) < 5:
            report.fail(r, "tdd.anchor_why", "the reason the anchor is red today is not stated")
    for word in ("**Green.**", "**Refactor.**"):
        if word not in tdd:
            report.fail(r, "tdd.incomplete", f"the TDD section has no {word.strip('*.')} step")

    # --- the skills table --------------------------------------------------
    skills_body = section_body(text, "## 3. Skills to load")
    rows = [(a, b) for a, b in SKILL_ROW_RE.findall(skills_body)]
    if not rows:
        report.fail(r, "skill.no_table", "the Skills to load section has no table rows")
    elif not (MIN_SKILLS_PER_TASK <= len(rows) <= MAX_SKILLS_PER_TASK):
        report.fail(r, "skill.count",
                    f"{len(rows)} skills named; the budget is {MIN_SKILLS_PER_TASK}-{MAX_SKILLS_PER_TASK}")
    auto = [n for n, _ in rows if n in AUTO_FIRING_SKILLS]
    if len(auto) > MAX_AUTO_FIRING_PER_TASK:
        report.fail(r, "skill.too_many_auto",
                    f"{len(auto)} auto-firing skills named; CLAUDE.md allows {MAX_AUTO_FIRING_PER_TASK}")
    check_skill_names(path, text, report, rows)

    # --- the closing sequence ---------------------------------------------
    # Blockquote lines are commentary (the R1 note names both reviewers), so they
    # are stripped before the check — otherwise the boilerplate satisfies it and
    # a task file with no closing steps passes.
    close = "\n".join(ln for ln in section_body(text, "## 9. Close out").splitlines()
                      if not ln.lstrip().startswith(">"))
    if "/simplify" not in close:
        report.fail(r, "close.no_simplify", "the closing sequence does not run `/simplify`")
    if REQUIRE_BUNDLED_CODE_REVIEW and "/code-review" not in close:
        report.fail(r, "close.no_code_review", "the closing sequence does not run `/code-review`")
    if REQUIRE_PROJECT_CODE_REVIEW and "/shed-code-review" not in close:
        report.fail(r, "close.no_shed_code_review", "the closing sequence does not run `/shed-code-review`")
    if "**Commit**" not in close:
        report.fail(r, "close.no_commit", "the closing sequence does not end in a commit")
    else:
        s_idx, c_idx = close.find("/simplify"), close.rfind("**Commit**")
        if s_idx > c_idx:
            report.fail(r, "close.order", "`/simplify` is listed after the commit")

    # --- definition of done ------------------------------------------------
    dod = section_body(text, "## 7. Definition of Done")
    items = DOD_ITEM_RE.findall(dod)
    if len(items) < MIN_DOD_ITEMS:
        report.fail(r, "dod.too_thin",
                    f"{len(items)} checkable items; the floor is {MIN_DOD_ITEMS}")

    # --- verification ------------------------------------------------------
    verify = section_body(text, "## 8. Verification")
    blocks = BASH_BLOCK_RE.findall(verify)
    if not blocks:
        report.fail(r, "verify.no_block", "the Verification section has no ```bash block")
    else:
        cmds = [ln.strip() for ln in blocks[0].splitlines() if ln.strip() and not ln.strip().startswith("#")]
        if len(cmds) < MIN_VERIFY_COMMANDS:
            report.fail(r, "verify.empty", "the Verification block runs no command")

    # --- why it exists -----------------------------------------------------
    why_body = section_body(text, "## 1. Why this task exists")
    if len(why_body.split()) < MIN_DELIVER_WORDS:
        report.fail(r, "task.thin",
                    f"the 'why this task exists' section is {len(why_body.split())} words; the floor is {MIN_DELIVER_WORDS}")

    # --- dependencies ------------------------------------------------------
    d_m = DEPENDS_ROW_RE.search(text)
    if not d_m:
        report.fail(r, "depends.missing", "the header table has no **Depends on** row")
    else:
        facts["depends"] = TASK_ID_RE.findall(d_m.group(1))
        if facts["id"] in facts["depends"]:
            report.fail(r, "depends.self", "the task depends on itself")

    return facts


def check_epic_file(path: str, text: str, report: Report) -> list:
    r = rel(path)
    for heading in REQUIRED_EPIC_SECTIONS:
        if heading not in text:
            report.fail(r, "epic.section_missing", f"missing required section `{heading}`")
    for phrase in ("/simplify", "/code-review"):
        if phrase not in text:
            report.warn(r, "epic.workflow", f"the epic's Definition of Done does not mention `{phrase}`")
    if "pull request" not in text.lower():
        report.fail(r, "epic.no_pr", "the epic does not state that it is one pull request")
    check_skill_names(path, text, report, [])
    return TASK_ID_RE.findall(section_body(text, "## Tasks"))


def main() -> int:
    if not os.path.isdir(EPICS_ROOT):
        print(f"FATAL: no epics root at {EPICS_ROOT}", file=sys.stderr)
        return 2

    report = Report()

    # Cross-check the embedded skill list against disk, when disk is available.
    if os.path.isdir(SKILLS_ROOT):
        on_disk = {d for d in os.listdir(SKILLS_ROOT)
                   if os.path.isdir(os.path.join(SKILLS_ROOT, d))}
        if on_disk != KNOWN_SKILLS:
            for name in sorted(on_disk - KNOWN_SKILLS):
                report.warn(".claude/skills", "skill.disk_only",
                            f"`{name}` exists on disk but is not in this script's constant")
            for name in sorted(KNOWN_SKILLS - on_disk):
                report.warn(".claude/skills", "skill.constant_only",
                            f"`{name}` is in this script's constant but not on disk")

    epic_dirs = sorted(d for d in os.listdir(EPICS_ROOT)
                       if os.path.isdir(os.path.join(EPICS_ROOT, d)))
    if not epic_dirs:
        report.fail("epics/", "backlog.empty", "no epic directories found")

    all_task_ids: set = set()
    task_order: dict = {}      # task id -> (epic index, task index)
    task_depends: dict = {}    # task id -> [ids]
    task_paths: dict = {}
    epic_task_counts: dict = {}
    pending_refs: list = []    # (epic_md, epic_id, referenced ids, own ids)
    sentence_files: dict = {}  # sentence -> [task file]

    for epic_index, d in enumerate(epic_dirs):
        dpath = os.path.join(EPICS_ROOT, d)
        if not EPIC_DIR_RE.match(d):
            report.fail(rel(dpath), "epic.dirname", "epic directory is not named <EPIC-ID>-<slug>")
            continue
        epic_id = EPIC_DIR_RE.match(d).group(1)

        epic_md = os.path.join(dpath, "epic.md")
        if not os.path.isfile(epic_md):
            report.fail(rel(dpath), "epic.no_epic_md", "epic directory has no epic.md")
            referenced = []
        else:
            referenced = check_epic_file(epic_md, open(epic_md).read(), report)

        files = sorted(f for f in os.listdir(dpath) if f.endswith(".md") and f != "epic.md")
        present = []
        for i, f in enumerate(files):
            fpath = os.path.join(dpath, f)
            body = open(fpath).read()
            facts = check_task_file(fpath, body, report)
            for s in sentences_of(body):
                sentence_files.setdefault(s, []).append(rel(fpath))
            tid = facts["id"]
            if not tid:
                continue
            if not tid.startswith(epic_id):
                report.fail(rel(fpath), "task.wrong_epic",
                            f"task id {tid} does not belong to epic {epic_id}")
            present.append(tid)
            all_task_ids.add(tid)
            task_order[tid] = (epic_index, i)
            task_depends[tid] = facts["depends"]
            task_paths[tid] = rel(fpath)

        epic_task_counts[epic_id] = len(present)
        if not (MIN_TASKS_PER_EPIC <= len(present) <= MAX_TASKS_PER_EPIC):
            report.fail(rel(epic_md), "epic.task_count",
                        f"{len(present)} tasks; the band is {MIN_TASKS_PER_EPIC}-{MAX_TASKS_PER_EPIC}")

        # An `epic.md`'s Tasks section names its own tasks *and* the tasks in
        # earlier epics they depend on. Both must resolve to a file, but only
        # its own must resolve inside this directory — so the cross-epic half
        # is checked against the whole backlog once every file has been read.
        pending_refs.append((rel(epic_md), epic_id, referenced, set(present)))
        for tid in present:
            if tid not in referenced:
                report.fail(task_paths[tid], "task.unreferenced",
                            f"{tid} is not referenced by its epic.md")

    # --- epic.md task references -------------------------------------------
    for epic_md_r, epic_id, referenced, own in pending_refs:
        for tid in referenced:
            if tid.startswith(epic_id):
                if tid not in own:
                    report.fail(epic_md_r, "epic.dangling_task",
                                f"epic.md references {tid}, which has no file in this epic")
            elif tid not in all_task_ids:
                report.fail(epic_md_r, "epic.dangling_task",
                            f"epic.md references {tid}, which has no file anywhere in the backlog")

    # --- repeated boilerplate ------------------------------------------------
    repeats = sorted(((len(f), s, f) for s, f in sentence_files.items()
                      if len(f) > MAX_FILES_PER_SENTENCE), reverse=True)
    for n, sentence, files_with in repeats:
        report.warn(files_with[0], "task.boilerplate",
                    f"this sentence appears in {n} task files (the ceiling is "
                    f"{MAX_FILES_PER_SENTENCE}) — say what *this* task does "
                    f"instead: \"{sentence[:110]}\"")

    # --- dependency graph ---------------------------------------------------
    for tid, deps in sorted(task_depends.items()):
        for dep in deps:
            if dep not in all_task_ids:
                report.fail(task_paths[tid], "depends.unknown",
                            f"depends on {dep}, which does not exist anywhere in the backlog")
            elif task_order[dep] >= task_order[tid]:
                report.fail(task_paths[tid], "depends.forward",
                            f"depends on {dep}, which lands later — epics are sequential and one PR each")

    # --- report -------------------------------------------------------------
    print("Shed Book backlog validation")
    print("=" * 72)
    print(f"epics: {len(epic_dirs)}   tasks: {len(all_task_ids)}   "
          f"skills known: {len(KNOWN_SKILLS)}")
    print()
    for epic_id in sorted(epic_task_counts):
        print(f"  {epic_id}  {epic_task_counts[epic_id]:>2} tasks")
    print()

    if report.warnings:
        print(f"WARNINGS ({len(report.warnings)})")
        for p in report.warnings:
            print(f"  ~ [{p.rule}] {p.path}: {p.message}")
        print()

    if report.failures:
        print(f"FAILURES ({len(report.failures)})")
        by_rule: dict = {}
        for p in report.failures:
            by_rule.setdefault(p.rule, []).append(p)
        for rule in sorted(by_rule):
            print(f"  [{rule}] — {len(by_rule[rule])}")
            for p in by_rule[rule]:
                print(f"      {p.path}: {p.message}")
        print()

    ok = not report.failures
    print("-" * 72)
    print(f"SUMMARY: {len(epic_dirs)} epics, {len(all_task_ids)} tasks, "
          f"{len(report.failures)} failures, {len(report.warnings)} warnings — "
          f"{'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
