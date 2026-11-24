# Input methods

Djehuty can host several input methods, for example Egyptian hieroglyphs now and Demotic
later. Each input method is one entry in the macOS input menu, with its own Rime schema.

## How it is wired

- `input-methods.json` is the single list of input methods (name, language, schema).
- `package/generate_input_methods.py` (run by `make input-methods`, and by `make release`
  and `make debug`) turns that list into:
  - `resources/Info.plist`: one macOS input mode per method, plus the mapping from mode to
    schema (`DjehutyInputMethodSchemas`);
  - `resources/InfoPlist.xcstrings`: the mode names shown in System Settings;
  - `data/custom/default.yaml`: the `schema_list` between its BEGIN/END markers.
- The app reads the modes from Info.plist at runtime. When a user switches to a mode, the
  session selects that mode's schema. No Swift code changes when a method is added.

The generator rejects duplicate IDs, duplicate schemas, bad characters, and a schema
without a `data/custom/<schema>.schema.yaml` file.

## Adding an input method (for example Demotic)

1. Write the Rime files for the new script and put them in `data/custom/`:
   `<schema>.schema.yaml` and `<schema>.dict.yaml`. Use a schema name that is unique and
   lowercase, for example `demotic`.
2. Add an entry to `input-methods.json`:

   ```json
   {
     "id": "Demotic",
     "name": "Demotic",
     "language": "egy-dem",
     "schema": "demotic"
   }
   ```

   `id` becomes part of the macOS input source ID, so pick it once and keep it.
   `language` is a language tag for macOS (use `egy` for Egyptian; for Demotic a more
   specific tag such as `egy-dem` is only a label and may not be recognized by macOS).
3. Run `make input-methods` to check and regenerate. Then `make package` and reinstall.
4. Log out and back in if the new entry does not appear, then add it in System Settings >
   Keyboard > Text Input.

## Things to know

- **Changing an existing ID breaks users' setup.** macOS remembers an enabled input
  source by its ID. Keep IDs stable once users have installed them.
- **New modes are enabled automatically only on a fresh install.** The installer enables
  all modes when none is enabled yet. A method added in an update must be added by the
  user in System Settings.
- **The first mode in the list is the primary one** and is selected after install.
- **Shared settings.** All input methods share one Rime user folder (`~/Library/Djehuty`)
  and one `djehuty.yaml` for candidate-window appearance. Each schema keeps its own
  dictionary and settings.
- **Generated files.** `resources/Info.plist`, the mode entries in `InfoPlist.xcstrings`,
  and the `schema_list` block in `default.yaml` are generated. Edit `input-methods.json`
  instead.
