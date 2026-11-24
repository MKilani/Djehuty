#!/usr/bin/env python3
"""Generate the input-method declarations from input-methods.json.

The manifest is the single place where input methods are listed. This script writes:

  resources/Info.plist            ComponentInputModeDict: one macOS input mode per method,
                                  and DjehutyInputMethodSchemas: mode ID -> Rime schema
  resources/InfoPlist.xcstrings   display names of the modes
  data/custom/default.yaml        schema_list, between the BEGIN/END markers

It also checks that ids and schemas are unique, and that each schema has a
data/custom/<schema>.schema.yaml file. Run it with `make input-methods` (the release
and debug builds run it automatically). It is idempotent.

Usage: generate_input_methods.py [project_root]
"""
import json
import pathlib
import plistlib
import re
import sys

ROOT = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "input-methods.json"
INFO_PLIST = ROOT / "resources" / "Info.plist"
STRINGS = ROOT / "resources" / "InfoPlist.xcstrings"
DEFAULT_YAML = ROOT / "data" / "custom" / "default.yaml"
DATA_DIR = ROOT / "data" / "custom"
BEGIN = "# BEGIN schema_list (generated from input-methods.json; do not edit by hand)"
END = "# END schema_list"


def fail(msg):
    sys.exit(f"input-methods.json: {msg}")


def load_manifest():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    bundle_id = manifest.get("bundle_id")
    methods = manifest.get("input_methods", [])
    if not bundle_id:
        fail("missing bundle_id")
    if not methods:
        fail("no input methods listed")
    seen_ids, seen_schemas = set(), set()
    for m in methods:
        for key in ("id", "name", "language", "schema"):
            if not m.get(key):
                fail(f"input method {m!r} is missing '{key}'")
        if not re.fullmatch(r"[A-Za-z0-9]+", m["id"]):
            fail(f"id '{m['id']}' must be letters and digits only")
        if not re.fullmatch(r"[a-z0-9_]+", m["schema"]):
            fail(f"schema '{m['schema']}' must be lowercase letters, digits and underscores")
        if m["id"] in seen_ids:
            fail(f"duplicate id '{m['id']}'")
        if m["schema"] in seen_schemas:
            fail(f"duplicate schema '{m['schema']}'")
        if not (DATA_DIR / f"{m['schema']}.schema.yaml").exists():
            fail(f"no schema file data/custom/{m['schema']}.schema.yaml for '{m['id']}'")
        seen_ids.add(m["id"])
        seen_schemas.add(m["schema"])
    return bundle_id, methods


def mode_entry(bundle_id, method, first):
    mode_id = f"{bundle_id}.{method['id']}"
    return mode_id, {
        "TISInputSourceID": mode_id,
        "TISIntendedLanguage": method["language"],
        "tsInputModeAlternateMenuIconFileKey": "djehuty.pdf",
        "tsInputModeCharacterRepertoireKey": [],
        "tsInputModeDefaultStateKey": first,
        "tsInputModeIsVisibleKey": True,
        "tsInputModeMenuIconFileKey": "djehuty.pdf",
        "tsInputModePaletteIconFileKey": "djehuty.pdf",
        "tsInputModePrimaryInScriptKey": first,
        "tsInputModeScriptKey": "smUnicodeScript",
    }


def write_info_plist(bundle_id, methods):
    info = plistlib.loads(INFO_PLIST.read_bytes())
    modes, order, schemas = {}, [], {}
    for i, m in enumerate(methods):
        mode_id, entry = mode_entry(bundle_id, m, first=(i == 0))
        if not entry["tsInputModeCharacterRepertoireKey"]:
            del entry["tsInputModeCharacterRepertoireKey"]
        modes[mode_id] = entry
        order.append(mode_id)
        schemas[mode_id] = m["schema"]
    info["TISInputSourceID"] = bundle_id
    info["ComponentInputModeDict"] = {"tsInputModeListKey": modes, "tsVisibleInputModeOrderedArrayKey": order}
    info["DjehutyInputMethodSchemas"] = schemas
    INFO_PLIST.write_bytes(plistlib.dumps(info, sort_keys=False))


def write_strings(bundle_id, methods):
    catalog = json.loads(STRINGS.read_text(encoding="utf-8"))
    strings = catalog.setdefault("strings", {})
    # drop stale mode names, then set one per current mode
    for key in [k for k in strings if k.startswith(bundle_id + ".")]:
        del strings[key]
    for m in methods:
        mode_id = f"{bundle_id}.{m['id']}"
        strings[mode_id] = {
            "extractionState": "manual",
            "localizations": {"en": {"stringUnit": {"state": "translated",
                                                     "value": f"Djehuty ({m['name']})"}}},
        }
    STRINGS.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_schema_list(methods):
    text = DEFAULT_YAML.read_text(encoding="utf-8")
    block = BEGIN + "\nschema_list:\n" + "".join(f"  - schema: {m['schema']}\n" for m in methods) + END
    pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END), re.S)
    if not pattern.search(text):
        fail(f"{DEFAULT_YAML.name} has no schema_list markers")
    DEFAULT_YAML.write_text(pattern.sub(lambda _: block, text), encoding="utf-8")


def main():
    bundle_id, methods = load_manifest()
    write_info_plist(bundle_id, methods)
    write_strings(bundle_id, methods)
    write_schema_list(methods)
    print("input methods:", ", ".join(f"{m['id']} ({m['schema']})" for m in methods))


if __name__ == "__main__":
    main()
