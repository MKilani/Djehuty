#!/usr/bin/env python3
"""Convert a Hiero dictionary (glyphs, then one or more transliteration codes per line)
into the Rime format used by the build: one "glyphs<TAB>code" entry per line.

Rules:
  1. Glyph text is kept as it is, including zero-width spaces and Gardiner/Manuel
     markup such as §E6A§ (these signs are not in Unicode and are typed literally).
  2. Glyph text with neither hieroglyphs nor §...§ markup is skipped (for example a
     zero-width space alone). Glyph text with ASCII letters or digits outside §...§ markup is skipped: it is not
     hieroglyphs (for example the entry "iw").
  3. Every tab field after the glyph text is a separate code for the same glyphs.
  4. Codes must use only characters in the schema's speller alphabet. Others are
     skipped and counted in the report, because they cannot be typed.
  5. Duplicates are judged on the exact (glyphs, code) pair, so the same glyphs with an
     uppercase code and with a lowercase code are both kept.

The header is kept, except that `use_preset_vocabulary` is set to false (the preset
vocabulary is Chinese-only) and tabs become spaces (YAML requires that).

Usage: convert_hiero_dict.py <input.yaml> <output.yaml> <schema.yaml>

This is only for importing a new raw table. Edit the dictionary directly after that:
the symbol entries at the top of data/custom/hiero_no_caps.dict.yaml would be lost on re-import.
"""
import re
import sys
from collections import Counter

import yaml

HIERO = re.compile(r"[\U00013000-\U0001343F]")
MARKUP = re.compile(r"§[^§]*§")


def speller_alphabet(schema_path):
    """The characters the speller accepts, read from the schema's speller.alphabet."""
    with open(schema_path, encoding="utf-8") as f:
        return set(yaml.safe_load(f)["speller"]["alphabet"])


def convert(src, dst, schema):
    alphabet = speller_alphabet(schema)
    text = open(src, encoding="utf-8").read()
    header, sep, body = text.partition("\n...\n")
    if not sep:
        sys.exit("input has no '...' line ending the YAML header")
    header = header.replace("\t", " ")
    header = header.replace("sort: by_weight", "sort: original")
    header = header.replace("use_preset_vocabulary: true", "use_preset_vocabulary: false")
    if "use_preset_vocabulary: false" not in header:
        sys.exit("could not set use_preset_vocabulary to false")

    report = Counter()
    seen = set()
    out = []
    for line in body.split("\n"):
        if not line.strip():
            continue
        fields = line.split("\t")
        glyphs = fields[0].strip()
        codes = [c.strip() for c in fields[1:] if c.strip()]
        if not glyphs:
            report["skipped: empty glyph text"] += 1
            continue
        if not (HIERO.search(glyphs) or MARKUP.search(glyphs)):
            report["skipped: neither hieroglyphs nor §...§ markup"] += 1
            continue
        if re.search(r"[A-Za-z0-9]", MARKUP.sub("", glyphs)):
            report["skipped: ASCII letters or digits outside §...§ markup"] += 1
            continue
        if not codes:
            report["skipped: no code"] += 1
            continue
        for code in codes:
            if not set(code) <= alphabet:
                report["skipped: code outside the speller alphabet"] += 1
                continue
            key = (glyphs, code)
            if key in seen:
                report["skipped: duplicate (glyphs, code) pair"] += 1
                continue
            seen.add(key)
            out.append(f"{glyphs}\t{code}")
            report["kept entries"] += 1

    with open(dst, "w", encoding="utf-8") as f:
        f.write(header + sep + "\n".join(out) + "\n")
    for key, n in sorted(report.items()):
        print(f"{n:8d}  {key}")
    return len(out)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    convert(sys.argv[1], sys.argv[2], sys.argv[3])
