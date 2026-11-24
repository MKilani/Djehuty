# Djehuty: changes from Squirrel

## Version 0.1.30
- Dictionary replaced with dictionary_cleaned_5_0 (version 3.0). Zero-width spaces replaced
  with zero-width non-joiners, as decided for the previous version. Exact duplicate lines removed,
  one malformed line trimmed to three fields. Weights and the symbol entries are kept.

## Version 0.1.29
- Hieroglyph font: the corrected EgyptianHiero9_03 (internal version 9.03, same name and
  coverage). Only the version text and checksums differ from the previous 9.03 file.

## Version 0.1.28
- Hieroglyph font replaced with EgyptianHiero9_03.ttf (internal version 9.01, same PostScript
  name, same character coverage as 8.01). The installer replaces the older installed copy.

## Version 0.1.27
- Dictionary: every zero-width space (U+200B) in the glyph text is now a zero-width non-joiner
  (U+200C). Committed text therefore contains non-joiners, which break ligatures.
  Entry count, codes and weights are unchanged.

## Version 0.1.26
- In the candidate list, each zero-width space is drawn as a zero-width non-joiner (U+200C):
  invisible, and it stops ligatures across it. The committed text still has the zero-width space.
  The middle-dot display of 0.1.25 is removed.

## Version 0.1.25
- Zero-width spaces in candidates are drawn as a visible middle dot in the candidate list.
  The committed text is unchanged.

## Version 0.1.24
- Dictionary replaced with dictionary_cleaned_4_0 (version 3.0). Its third column is the weight,
  which sets the candidate order. Exact duplicate lines (281) removed; one line with extra
  empty fields trimmed to three. Learning stays on (Rime's default), so choices you make are
  remembered and move up.

## Version 0.1.23
- Deploy runs automatically once for each newly installed version, about 3 seconds after Djehuty
  starts (the first time it is used after installation). The deployed version is kept in the
  user's defaults (key deployedVersion).

## Version 0.1.22
- The bundled EgyptianHiero font is registered with CoreText for this process at startup.
  Right after installation the system did not yet know the font, so the candidate window fell
  back to another font until Deploy.

## Version 0.1.21
- startRime waits for Rime's maintenance thread (join_maintenance_thread) before the settings are
  loaded. Without the wait, a normal start could read the settings before they were rebuilt.
  The screenshots showed the font was right and only the window size was from the old settings.

## Version 0.1.20
- At every start the compiled build/djehuty.yaml is removed before settings load, so Rime
  rebuilds it from the installed djehuty.yaml. The Rime log showed that Rime reuses the compiled
  copy when it does not detect a change, and that detection did not happen after an update.

## Version 0.1.19
- Startup uses the same full check as Deploy (startRime fullCheck: true). Before, a normal start
  loaded the settings before the updated file was copied, so Deploy was needed.

## Version 0.1.18
- The installer moves the user's djehuty.yaml aside (to djehuty.yaml.previous) and removes the
  cached build/djehuty.yaml, so the new settings apply at the next start without Deploy.

## Version 0.1.17
- Candidate window at 1.5x the original size: candidates 24 pt, labels 18 pt, comments 24 pt;
  line spacing 8, spacing 12, corner radius 10. config_version 1.3 -> 1.4.
- The bundled djehuty.yaml is now copied on every start. Before, the copy ran only when Rime
  started a maintenance pass, so changes did not apply until the user chose Deploy.

## Version 0.1.16
- Candidate window at 2.0x the original size: candidates 32 pt, labels 24 pt, comments 32 pt.
  Line spacing, spacing and corner radius doubled to match. config_version 1.2 -> 1.3.

## Version 0.1.15
- Candidate, label and comment font: EgyptianHiero alone. The fallback list (EgyptianHiero,Avenir)
  was not rendering the hieroglyphs correctly; macOS substitutes other glyphs automatically.
- config_version 1.1 -> 1.2.

## Version 0.1.14
- djehuty.yaml config_version 1.0 -> 1.1. Rime only refreshes a user's copy of the appearance
  settings when this number increases. Earlier appearance changes (font, size) had not reached
  installed copies.

## Version 0.1.13
- Candidate window enlarged by 1.5x: candidate text 24 pt (was 16), labels 18 pt (was 12),
  comments 24 pt (was 16). Spacing and corner radius scaled to match.
- Labels and comments use EgyptianHiero, with Avenir as the fallback if the hieroglyph font is not installed.

## Version 0.1.12
- Weights removed from the symbol entries. The dictionary is set to sort: original, so the
  symbols stay first in file order and the hieroglyph entries keep their order.

## Version 0.1.11
- data/custom/hiero_no_caps.dict.yaml is the single source for the dictionary. The symbol
  entries (weight 1000000000) are in it directly. The separate symbols source is removed.
- The converter is only for importing a new raw table; edit the dictionary after that.

## Version 0.1.10
- Symbols and numerals rank first. They are now entries of the main dictionary with a weight
  of 1000000000, so "1" offers 1, ¹, ₁ before the hieroglyphs. Source: data/source/hiero_symbols.tsv.
- Separate symbols translator removed from the schema.

## Version 0.1.9
- "-" offers "-"; "=" offers "=" and "⸗"; "." offers ".".
- Speller alphabet adds "=" and ".".
- Paging: "," is the only page key, and it turns to the next page. The physical Page Up key turns back.

## Version 0.1.8
- Symbol candidates in data/custom/hiero_symbols.dict.yaml (separate dictionary, offered after the hieroglyphs):
  [ offers [ ⌜ ⌞; ] offers ] ⌝ ⌟; < offers < ⟨; > offers > ⟩; ( ) { } | offer themselves;
  digits 0-9 offer the digit, superscript and subscript forms.
- Speller alphabet adds < > |.
- default.yaml: [ and ] no longer turn pages. Paging is on , . and =.

## Version 0.1.7
- Speller alphabet adds "-" and "?" so hyphenated codes (such as pt-m-Aiw) and "?" codes can be typed.
- default.yaml no longer uses "-" for Page Up (it is now a code character). Page Up stays on "[" and ",".
- Converter reads the alphabet from the schema. Gardiner-markup entries (§...§) are kept.
  Result: 28,592 entries.

## Version 0.1.6
- Egyptian dictionary replaced with hiero_no_caps_2_0_dict, converted with
  package/convert_hiero_dict.py. Zero-width spaces and Gardiner/Manuel markup (§...§) are kept.
  Uppercase and lowercase codes are separate entries. Codes the speller cannot type are skipped.
  Result: 25,122 entries. Preset vocabulary disabled.

## Version 0.1.5
- Egyptian dictionary replaced with the new source table (hiero_no_caps_dict_1). Converted
  with package/convert_hiero_dict.py: one entry per glyph/code pair, zero-width spaces removed,
  Gardiner-markup lines skipped (2,932), duplicates and non-typeable codes removed.
  Result: 39,176 entries. Preset vocabulary disabled.
- Schema replaced with hiero_no_caps_schema_1, with the description and menu-bar glyphs applied.

## Version 0.1.4
- Input menu icon regenerated at 16 pt height with a page exactly the size of the sign.
  The previous 36 pt page with margins drew the bird too large and off-centre in the menu row.

## Version 0.1.3
- More macOS 12 fixes: regex literals in candidate-format handling replaced with plain string search.

## Version 0.1.2
- Minimum macOS lowered from 13.0 to 12.0 (deployment target and installer check).
- Replaced macOS 13-only APIs: URL.path() -> .path; appending(component:) -> appendingPathComponent;
  Swift Regex literals -> NSRegularExpression helpers; String.ranges(of:) -> allRanges(of:).
- The librime binaries' own minimum macOS version is not verified yet.

## Version 0.1.1
- Build fixes: librime headers are fetched from the matching source tag (src/rime_api_stdbool.h, src/rime/key_table.h).
- Version is read from the VERSION file (app, Xcode build, installer).

## Input methods
- Listed in `input-methods.json` (currently: Egyptian hieroglyphs). The app reads modes
  from Info.plist at runtime and switches to each mode's schema on activation. Adding a method
  (for example Demotic) is a data change; see INPUT_METHODS.md.
- Mode IDs are `io.github.mkilani.inputmethod.Djehuty.<Id>`.

## Scope
- Egyptian hieroglyph input only (for now). The Chinese input modes, Plum recipes, OpenCC data and
  Chinese Rime plugins are removed.
- A single input source: "Djehuty (Egyptian Hieroglyphs)".

## Independence from Squirrel (side-by-side installation)
- Product: `Djehuty.app`, executable `Djehuty`.
- Bundle identifier: `io.github.mkilani.inputmethod.Djehuty`.
- IMK connection: `Djehuty_Connection`; controller `Djehuty.SquirrelInputController`.
- User data: `~/Library/Djehuty` (not `~/Library/Rime`).
- Log folder and notification names use `djehuty` / `Djehuty`.
- Config file: `djehuty.yaml` (not `squirrel.yaml`).
- Install location: `/Library/Input Methods/Djehuty.app`.
- Upstream release machinery removed: CI workflows, appcast generation, changelog tooling,
  bump scripts, SKILL.md. The Sparkle update feed and public key are removed; automatic
  update checks are disabled.

## Menu bar and menu
- Status glyphs: `𓄿` (hieroglyph mode) and `A` (ASCII mode), set in the schema
  (`states` / `abbrev`) and in the status item code.
- The "Rime Wiki" and "Check for updates" menu entries are removed.

## Build
- Egyptian data is copied into the app bundle after `xcodebuild` (`copy-shared-data`).
- `project.pbxproj` no longer references Plum, OpenCC, or Chinese plugin files.
- Product name `Djehuty`, module name `Djehuty`.

## Not verified here
- The project has not been compiled. It needs macOS and Xcode.
- The menu-bar glyph depends on macOS font fallback.
- The app icon and mode icon are still the Rime artwork.

## Font and icons
- `resources/fonts/EgyptianHiero8_01.ttf` is bundled and installed by `--install-fonts`
  from postinstall. Install rule: never replace an installed copy that is as new or newer.
- App icon `resources/DjehutyIcon.icns` (sign G026) replaces the Rime icon. The Rime icon
  bundle (`Rime.icon`) is removed from the project.
- Input menu icon `resources/djehuty.pdf` replaces `rime.pdf`.
- Candidate font: `EgyptianHiero,Avenir`. Menu-bar glyph uses the hieroglyph font.
- `package/make_icons.py` regenerates the icons from the font.

- Font license: author is Marwan Kilani (bundled with his permission). Outlines are based on NewGardiner; see NOTICE.
