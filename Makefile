# Djehuty: Egyptian hieroglyph input method for macOS (frontend for librime)

.PHONY: all install release debug package install-release install-debug input-methods \
        librime copy-rime-binaries copy-shared-data \
        sparkle copy-sparkle-framework clean clean-deps clean-sparkle clean-package permission-check

all: release
install: install-release

APP_NAME = Djehuty
RIME_BIN_DIR = librime/dist/bin
RIME_LIB_DIR = librime/dist/lib
DERIVED_DATA_PATH = build
APP_DIR = $(DERIVED_DATA_PATH)/Build/Products/Release/$(APP_NAME).app
SHARED_DATA_SRC = data/custom

RIME_LIBRARY_FILE_NAME = librime.1.dylib
RIME_LIBRARY = lib/$(RIME_LIBRARY_FILE_NAME)

RIME_DEPS = librime/lib/libmarisa.a \
	librime/lib/libleveldb.a \
	librime/lib/libopencc.a \
	librime/lib/libyaml-cpp.a
SPARKLE_FRAMEWORK = Frameworks/Sparkle.framework
PACKAGE = package/$(APP_NAME).pkg
DEPS_CHECK = $(RIME_LIBRARY) $(SPARKLE_FRAMEWORK)

INSTALL_NAME_TOOL = $(shell xcrun -find install_name_tool)
INSTALL_NAME_TOOL_ARGS = -add_rpath @loader_path/../Frameworks

$(RIME_LIBRARY):
	$(MAKE) librime

$(RIME_DEPS):
	$(MAKE) -C librime deps

librime: $(RIME_DEPS)
	$(MAKE) -C librime release install
	$(MAKE) copy-rime-binaries

copy-rime-binaries:
	mkdir -p lib
	cp -L $(RIME_LIB_DIR)/$(RIME_LIBRARY_FILE_NAME) lib/

# Egyptian schema, dictionary, default.yaml and djehuty.yaml. Copied into the bundle after
# the build (not via Xcode), so the Xcode project does not have to list them.
copy-shared-data:
	mkdir -p $(APP_DIR)/Contents/SharedSupport
	cp $(SHARED_DATA_SRC)/* $(APP_DIR)/Contents/SharedSupport/
	mkdir -p $(APP_DIR)/Contents/Resources/fonts
	cp resources/fonts/EgyptianHiero9_03.ttf $(APP_DIR)/Contents/Resources/fonts/
	cp resources/DjehutyIcon.icns $(APP_DIR)/Contents/Resources/

BUILD_SETTINGS =
ifdef ARCHS
BUILD_SETTINGS += ARCHS="$(ARCHS)"
BUILD_SETTINGS += ONLY_ACTIVE_ARCH=NO
_=$() $()
export CMAKE_OSX_ARCHITECTURES = $(subst $(_),;,$(ARCHS))
endif

ifdef MACOSX_DEPLOYMENT_TARGET
BUILD_SETTINGS += MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)"
endif

BUILD_SETTINGS += COMPILER_INDEX_STORE_ENABLE=YES
# Single source of truth for the version: the VERSION file
APP_VERSION := $(shell cat VERSION)
BUILD_SETTINGS += MARKETING_VERSION=$(APP_VERSION) CURRENT_PROJECT_VERSION=$(APP_VERSION)

# Regenerate Info.plist, the mode names and the schema list from input-methods.json.
input-methods:
	python3 package/generate_input_methods.py

release: $(DEPS_CHECK) input-methods
	mkdir -p $(DERIVED_DATA_PATH)
	xcodebuild -project Squirrel.xcodeproj -configuration Release -scheme Squirrel -derivedDataPath $(DERIVED_DATA_PATH) $(BUILD_SETTINGS) build
	$(MAKE) copy-shared-data

debug: $(DEPS_CHECK) input-methods
	mkdir -p $(DERIVED_DATA_PATH)
	xcodebuild -project Squirrel.xcodeproj -configuration Debug -scheme Squirrel -derivedDataPath $(DERIVED_DATA_PATH) $(BUILD_SETTINGS) build
	$(MAKE) copy-shared-data APP_DIR=$(DERIVED_DATA_PATH)/Build/Products/Debug/$(APP_NAME).app

.PHONY: sparkle copy-sparkle-framework
sparkle:
	xcodebuild -project Sparkle/Sparkle.xcodeproj -configuration Release $(BUILD_SETTINGS) build
	$(MAKE) copy-sparkle-framework

copy-sparkle-framework:
	mkdir -p Frameworks
	cp -RP Sparkle/build/Release/Sparkle.framework Frameworks/

$(SPARKLE_FRAMEWORK):
	git submodule update --init --recursive Sparkle
	$(MAKE) sparkle

# Signing and packaging. Set DEV_ID to your Apple Developer team name (see INSTALL.md).
package: release
ifdef DEV_ID
	bash package/sign_app "$(DEV_ID)" "$(DERIVED_DATA_PATH)"
endif
	bash package/make_package "$(DERIVED_DATA_PATH)"
ifdef DEV_ID
	productsign --sign "Developer ID Installer: $(DEV_ID)" package/$(APP_NAME).pkg package/$(APP_NAME)-signed.pkg
	rm package/$(APP_NAME).pkg
	mv package/$(APP_NAME)-signed.pkg package/$(APP_NAME).pkg
	xcrun notarytool submit package/$(APP_NAME).pkg --keychain-profile "$(DEV_ID)" --wait
	xcrun stapler staple package/$(APP_NAME).pkg
endif

DSTROOT = /Library/Input Methods
APP_ROOT = $(DSTROOT)/$(APP_NAME).app

permission-check:
	[ -w "$(DSTROOT)" ] && [ -w "$(APP_ROOT)" ] || sudo chown -R $(USER) "$(DSTROOT)"

install-debug: debug permission-check
	rm -rf "$(APP_ROOT)"
	cp -R $(DERIVED_DATA_PATH)/Build/Products/Debug/$(APP_NAME).app "$(DSTROOT)"
	DSTROOT="$(DSTROOT)" RIME_NO_PREBUILD=1 bash scripts/postinstall

install-release: release permission-check
	rm -rf "$(APP_ROOT)"
	cp -R $(APP_DIR) "$(DSTROOT)"
	DSTROOT="$(DSTROOT)" bash scripts/postinstall

clean:
	rm -rf build > /dev/null 2>&1 || true
	rm -f build.log > /dev/null 2>&1 || true
	rm -f lib/* > /dev/null 2>&1 || true

clean-package:
	rm -rf package/*.pkg > /dev/null 2>&1 || true

clean-deps:
	$(MAKE) -C librime clean
	rm -rf librime/dist > /dev/null 2>&1 || true
	$(MAKE) clean-sparkle

clean-sparkle:
	rm -rf Frameworks/* > /dev/null 2>&1 || true
	rm -rf Sparkle/build > /dev/null 2>&1 || true
