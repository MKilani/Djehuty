#!/usr/bin/env bash

set -e

export ARCHS='arm64 x86_64'
export BUILD_UNIVERSAL=1

./action-install.sh
make package
echo 'Installer package:'
find package -type f -name 'Djehuty.pkg'
