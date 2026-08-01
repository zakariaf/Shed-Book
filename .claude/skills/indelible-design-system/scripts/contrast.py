#!/usr/bin/env python3
"""Check a PROPOSED foreground/background pair against Indelible's measured floors.

This is a proposal tool, not a gate. Shipped tokens are proved by
`dart test test/design/contrast_test.dart`, which uses dart:ui's own
Color.computeLuminance(). Never re-check a shipped token here: a second
implementation of the WCAG formula that could disagree with the Dart one is a
liability, not a safety net.

Usage:
  python3 contrast.py FG BG [--non-text]

  FG, BG   sRGB hex, with or without '#', 3 or 6 digits (e.g. D4685C, #0A0A0B).
  --non-text   Judge against the 3.0 floor (rules, borders, marks) instead of
               the 4.5 text floor. Both floors are always printed.

Exit codes:
  0  the pair meets the floor you asked for
  1  the pair is below that floor
  2  bad usage or an unparseable colour

Floors (indelible.md §1.2 rule 4, §2.1):
  text      >= 4.5 : 1   every text pair, on its actual surface
  non-text  >= 3.0 : 1   every rule and every mark
"""

import sys

TEXT_FLOOR = 4.5
NON_TEXT_FLOOR = 3.0


def parse_hex(raw: str) -> tuple[int, int, int]:
    """Parse '#RGB' or '#RRGGBB' into an (r, g, b) 0-255 triple."""
    s = raw.strip().lstrip("#")
    if len(s) == 3:
        s = "".join(c * 2 for c in s)
    if len(s) != 6:
        raise ValueError(
            f"{raw!r} is not a colour: expected 3 or 6 hex digits, got {len(s)}. "
            "Example: D4685C or #0A0A0B"
        )
    try:
        return int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)
    except ValueError:
        raise ValueError(f"{raw!r} contains a non-hex character. Example: #0A0A0B") from None


def relative_luminance(rgb: tuple[int, int, int]) -> float:
    """WCAG 2.2 relative luminance over linearised sRGB."""
    out = []
    for channel in rgb:
        c = channel / 255.0
        out.append(c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4)
    r, g, b = out
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(fg: tuple[int, int, int], bg: tuple[int, int, int]) -> float:
    la, lb = relative_luminance(fg), relative_luminance(bg)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def main(argv: list[str]) -> int:
    args = [a for a in argv[1:] if a not in ("--non-text", "--nontext")]
    non_text = len(args) != len(argv[1:])

    if any(a in ("-h", "--help") for a in args):
        print(__doc__)
        return 0
    if len(args) != 2:
        print(__doc__, file=sys.stderr)
        print(f"error: expected 2 colours, got {len(args)}", file=sys.stderr)
        return 2

    try:
        fg, bg = parse_hex(args[0]), parse_hex(args[1])
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    ratio = contrast_ratio(fg, bg)
    floor = NON_TEXT_FLOOR if non_text else TEXT_FLOOR
    role = "non-text" if non_text else "text"
    ok = ratio >= floor

    print(f"foreground\t#{args[0].strip().lstrip('#').upper()}\tL={relative_luminance(fg):.5f}")
    print(f"background\t#{args[1].strip().lstrip('#').upper()}\tL={relative_luminance(bg):.5f}")
    print(f"ratio\t{ratio:.2f}:1")
    print(f"text floor 4.5\t{'PASS' if ratio >= TEXT_FLOOR else 'FAIL'}")
    print(f"non-text floor 3.0\t{'PASS' if ratio >= NON_TEXT_FLOOR else 'FAIL'}")
    print(f"verdict\t{'PASS' if ok else 'FAIL'} ({role}, floor {floor})")
    if not ok:
        print(
            "hint\trule 4 is not negotiable by taste — raise the luminance and keep the hue "
            "(indelible.md §2.4)"
        )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
