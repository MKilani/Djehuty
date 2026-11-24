# Building and installing Djehuty (macOS)

These steps build `package/Djehuty.pkg`, an installer for the Djehuty input method.

## Requirements

- macOS 12 or later.
- Xcode (the full app) with its command-line tools.
- Git.
- For distribution: an Apple Developer ID (see the end of this file).

## 1. Get the sources with submodules

The downloaded zip does not contain the librime and Sparkle submodules. Clone with git:

```sh
git clone --recurse-submodules https://github.com/MKilani/Djehuty.git
cd Djehuty
```

If you downloaded the zip, run `git submodule update --init --recursive` inside a git clone of
the same project, or copy the librime and Sparkle sources in yourself.

## 2. Fetch the librime and Sparkle binaries

```sh
./action-install.sh
```

This downloads the librime binaries and the Sparkle framework. Chinese data and the plum
recipe manager are not needed or downloaded.

## 3. Build the installer

```sh
make package
```

This produces `package/Djehuty.pkg`. The Egyptian schema, dictionary and config are copied
into the app automatically.

## 4. Install on your Mac

```sh
sudo installer -pkg package/Djehuty.pkg -target /
```

Then log out and back in, and add "Djehuty (Egyptian Hieroglyphs)" in System Settings >
Keyboard > Text Input.

## Distributing to other Macs

Unsigned installers from the internet are blocked by macOS. To distribute Djehuty, sign and
notarize the installer with an Apple Developer ID:

1. Install your "Developer ID Application" and "Developer ID Installer" certificates.
2. Store notarization credentials under a profile named after your team, for example:

   ```sh
   xcrun notarytool store-credentials "Your Name (TEAMID)" \
     --apple-id you@example.com --team-id TEAMID --password <app-specific-password>
   ```

3. Build with that identity:

   ```sh
   make package DEV_ID="Your Name (TEAMID)"
   ```

Distribute the resulting `package/Djehuty.pkg`.

## Updating the data

Edit files in `data/custom/`, run `make package` again, and reinstall. Existing users must
reinstall to receive the new data.

## Troubleshooting

- The input source is missing: run the installer again, log out and back in, then check
  System Settings > Keyboard > Text Input.
- No hieroglyph candidates: choose "Deploy" from the Djehuty input menu to rebuild the
  schema, then check the log folder from the same menu.
- Changes do not take effect: rebuild, reinstall, and use "Deploy".

## Font

The installer runs `Djehuty --install-fonts`, which installs `EgyptianHiero9_03.ttf` into
`/Library/Fonts` only when no installed copy is as new. If you rebuild the font, bump its
version (name table ID 5, "Version X.YY ...") so installed Macs pick it up.
