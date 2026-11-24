# Djehuty

Djehuty is an input method for macOS that types Egyptian hieroglyphs. It is built on
Squirrel and the Rime input engine (librime), and it contains no Chinese input at all.
It installs side by side with the regular Squirrel input method.

Project: https://github.com/MKilani/Djehuty

## Using Djehuty

1. Install the package (see INSTALL.md) and log out and back in.
2. In System Settings > Keyboard > Text Input > Edit, add "Djehuty (Egyptian Hieroglyphs)".
3. Select it from the input menu in the menu bar.

The menu bar shows `𓄿` for hieroglyph input and `A` for ASCII (Latin) mode. Toggle
between them with Shift, as in other Rime-based input methods.

Type a transliteration code and choose a hieroglyph from the candidate list. For
example, `kwi` shows candidates such as 𓎡𓅱𓀀 first. Press `F4` or `Control+Grave` to see
the schema options.

## Adding more input methods

See INPUT_METHODS.md. Input methods are listed in `input-methods.json`; adding one (for example Demotic) is a data change, not a code change.

## Files

| Path | Purpose |
| --- | --- |
| `data/custom/hiero_no_caps.schema.yaml` | Egyptian input schema (speller, algebra, menu-bar states). |
| `data/custom/hiero_no_caps.dict.yaml` | Egyptian hieroglyph dictionary (code to glyph). |
| `data/custom/default.yaml` | Offers only the Egyptian schema; sets paging and punctuation. |
| `data/custom/djehuty.yaml` | Appearance and behavior of the candidate window. |
| `sources/` | macOS frontend (InputMethodKit controller, candidate panel, app delegate). |
| `input-methods.json` | The list of input methods (name, language, schema). |
| `package/generate_input_methods.py` | Generates the macOS input-mode declarations and schema list from the list above. |
| `resources/Info.plist` | Input source registration and bundle identity (generated; see INPUT_METHODS.md). |

Edit files in `data/custom/` and rebuild. The Makefile copies them into the app bundle.

## Side-by-side with Squirrel

Djehuty has its own bundle identifier (`io.github.mkilani.inputmethod.Djehuty`), its own
app name (`Djehuty.app`), its own connection name, its own user data folder
(`~/Library/Djehuty`), and its own notification names. It does not read or change
`~/Library/Rime`, and the two can be installed and used at the same time.

## Known data issues

The dictionary is included as provided. Review these before a wide release:

- **Mixed case.** About 9,700 codes contain uppercase letters (for example `kA`, `Tn`).
  The schema is named `hiero_no_caps` and its description says it is case-insensitive,
  but Rime matches codes case-sensitively, so `ka` will not find `kA`. Decide whether
  to lowercase all codes or keep case-sensitive input.
- **Markup in glyph text.** About 2,900 entries contain Gardiner/Manuel-style markup
  such as `§G7C§` inside the glyph column. These are committed as literal text.
- **Unusual codes.** About 4,000 codes include digits or symbols (for example `A1`, `A5a`).
- **Duplicates.** 632 (glyph, code) pairs appear more than once.

## Known limitations

- The app icon and mode icon are still the Rime artwork (`resources/rime.pdf`, `Rime.icon/`).
  Replace them with your own before distribution.
- Some candidate-window style presets in `djehuty.yaml` name Chinese fonts. They are
  harmless for hieroglyphs but can be removed.
- The menu-bar glyph `𓄿` depends on the system's font fallback for Egyptian hieroglyphs.
  Check it on your macOS version.

## License

Djehuty's source code is licensed under GPL v3 (see LICENSE.txt). See NOTICE for the
upstream projects and their licenses. The Egyptian dictionary carries the license and
attribution stated in its header (CC BY-SA 3.0; see NOTICE).

## Font and icons

- **Hieroglyph font.** The installer includes `EgyptianHiero9_03.ttf` (version 9.03) and
  installs it to `/Library/Fonts` on first installation. It never replaces a copy that is
  as new as the bundled one or newer. An older copy is replaced only when the bundled
  version is newer than every installed copy. The candidate window and the menu-bar glyph
  use this font.
- **App icon.** `resources/DjehutyIcon.icns`: the sacred ibis sign (Gardiner G026) on a
  lapis-blue rounded square.
- **Menu icon.** `resources/djehuty.pdf`: a black vector outline of the same sign.
- `package/make_icons.py` regenerates both from the font (`pip3 install fonttools pillow`).
  Change the sign with its second argument (`G025` gives the standing bird).

The font is by Marwan Kilani (see NOTICE).

## Versioning

The version lives in the `VERSION` file. Increase it for every release: the app,
the Xcode build, and the installer use it, and the release zip is named after it.

## Changing the appearance

Rime keeps a copy of `djehuty.yaml` in `~/Library/Djehuty`, and it only replaces that copy
when `config_version` in the file increases. So whenever `data/custom/djehuty.yaml` changes,
increase `config_version` (for example from '1.1' to '1.2'). Otherwise the change does not
reach users who already have a copy.
