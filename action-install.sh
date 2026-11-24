#!/usr/bin/env bash

set -e

rime_version=1.17.0
rime_git_hash="33e7814"
sparkle_version=2.6.2

rime_archive="rime-${rime_git_hash}-macOS-universal.tar.bz2"
rime_download_url="https://github.com/rime/librime/releases/download/${rime_version}/${rime_archive}"

rime_deps_archive="rime-deps-${rime_git_hash}-macOS-universal.tar.bz2"
rime_deps_download_url="https://github.com/rime/librime/releases/download/${rime_version}/${rime_deps_archive}"

sparkle_archive="Sparkle-${sparkle_version}.tar.xz"
sparkle_download_url="https://github.com/sparkle-project/Sparkle/releases/download/${sparkle_version}/${sparkle_archive}"

mkdir -p download && (
    cd download
    [ -z "${no_download}" ] && curl -LO "${rime_download_url}"
    tar --bzip2 -xf "${rime_archive}"
    [ -z "${no_download}" ] && curl -LO "${rime_deps_download_url}"
    tar --bzip2 -xf "${rime_deps_archive}"
    [ -z "${no_download}" ] && curl -LO "${sparkle_download_url}"
    tar -xJf "${sparkle_archive}"
)

mkdir -p librime/share
mkdir -p Frameworks
cp -R download/dist librime/
cp -R download/Sparkle.framework Frameworks/

# The bridging header includes librime's C headers: <rime_api_stdbool.h> and <rime/key_table.h>.
# The release archive does not ship them, and the build searches librime/src for them. Fetch
# the headers from the source tag that matches the librime binaries, keeping their folders.
rm -rf download/librime-src
git clone --depth 1 --branch "${rime_version}" https://github.com/rime/librime.git download/librime-src
mkdir -p librime/src librime/include
(
    cd download/librime-src/src
    find . -name '*.h' | while read -r header; do
        mkdir -p "../../../librime/src/$(dirname "$header")"
        cp "$header" "../../../librime/src/$header"
    done
)
for header in rime_api_stdbool.h rime/key_table.h; do
    if [ ! -f "librime/src/${header}" ]; then
        echo "error: librime/src/${header} is missing; cannot build" >&2
        exit 1
    fi
done

# use the downloaded librime artifacts (no Chinese data or plum recipes are installed)
make copy-rime-binaries
