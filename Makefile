TEMPORARY_FOLDER_ROOT?=/tmp
HERMETIC?=0
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild
REPO_URL?=https://github.com/birdrides/mockingbird
ARTIFACTS_URL?=$(REPO_URL)/releases/download
VERIFY_SIGNATURES?=1
AC_USERNAME?=
AC_PASSWORD?=
PKG_IDENTITY?=Developer ID Installer: Bird Rides, Inc. (P2T4T6R4SL)
BIN_IDENTITY?=Developer ID Application: Bird Rides, Inc. (P2T4T6R4SL)

# Prevent bad things from happening when cleaning the temporary folder.
TEMPORARY_FOLDER=$(TEMPORARY_FOLDER_ROOT)/Mockingbird.make.dst
TEMPORARY_INSTALLER_FOLDER=$(TEMPORARY_FOLDER)/install
XCODEBUILD_DERIVED_DATA=$(TEMPORARY_FOLDER)/xcodebuild/DerivedData/MockingbirdFramework
XCODE_PATH=$(shell xcode-select --print-path)
CLI_BUNDLE_PLIST=Sources/MockingbirdCli/Info.plist
MKB_VERSION?=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$(CLI_BUNDLE_PLIST)")
VERSION_STRING=$(MKB_VERSION)

# Needs to be kept in sync with `LoadDylib.swift` and `build-framework-cli.yml`.
$(eval RELATIVE_RPATH_FLAG = $(shell [[ $(HERMETIC) -eq 1 ]] && echo '-Xswiftc -DRELATIVE_RPATH' || echo ''))
$(eval MOCKINGBIRD_RPATH = $(shell [[ $(HERMETIC) -eq 1 ]] && echo '@executable_path' || echo '/var/tmp/mockingbird/$(VERSION_STRING)/libs'))

SIMULATOR_NAME=iphone11-mockingbird
SIMULATOR_DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-11
SIMULATOR_RUNTIME=$(shell xcrun simctl list runtimes | pcregrep -o1 '(com\.apple\.CoreSimulator\.SimRuntime\.iOS\-.*)')

SWIFT_BUILD_FLAGS=--configuration release -Xlinker -weak-l_InternalSwiftSyntaxParser $(RELATIVE_RPATH_FLAG)
XCODEBUILD_FLAGS=-project 'Mockingbird.xcodeproj' DSTROOT=$(TEMPORARY_FOLDER)
XCODEBUILD_MACOS_FLAGS=$(XCODEBUILD_FLAGS) -destination 'platform=OS X'
XCODEBUILD_FRAMEWORK_FLAGS=$(XCODEBUILD_FLAGS) \
	-derivedDataPath "$(XCODEBUILD_DERIVED_DATA)" \
	ONLY_ACTIVE_ARCH=NO \
	DEFINES_MODULE=YES \
	STRIP_INSTALLED_PRODUCT=NO \
	SKIP_INSTALL=YES

EXAMPLE_XCODEBUILD_FLAGS=DSTROOT=$(TEMPORARY_FOLDER)
EXAMPLE_COCOAPODS_XCODEBUILD_FLAGS=$(EXAMPLE_XCODEBUILD_FLAGS) \
	-workspace 'Examples/iOSMockingbirdExample-CocoaPods/iOSMockingbirdExample-CocoaPods.xcworkspace' \
	-scheme 'iOSMockingbirdExample-CocoaPods'
EXAMPLE_CARTHAGE_XCODEBUILD_FLAGS=$(EXAMPLE_XCODEBUILD_FLAGS) \
	-project 'Examples/iOSMockingbirdExample-Carthage/iOSMockingbirdExample-Carthage.xcodeproj' \
	-scheme 'iOSMockingbirdExample-Carthage'
EXAMPLE_SPM_XCODEBUILD_FLAGS=$(EXAMPLE_XCODEBUILD_FLAGS) \
	-project 'Examples/iOSMockingbirdExample-SPM/iOSMockingbirdExample-SPM.xcodeproj' \
	-scheme 'iOSMockingbirdExample-SPM'

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=$(PREFIX)/bin
DEFAULT_XCODE_RPATH=$(XCODE_PATH)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx

PKG_BUNDLE_IDENTIFIER=co.bird.mockingbird
CLI_DESIGNATED_REQUIREMENT=Codesigning/MockingbirdCli.dr
CLI_FILENAME=mockingbird
$(eval CLI_PATH = $(shell [[ $(HERMETIC) -eq 1 ]] && echo "bin/$(VERSION_STRING)" || echo "bin/$(VERSION_STRING)-portable"))
$(eval ZIP_FILENAME = $(shell [[ $(HERMETIC) -eq 1 ]] && echo 'Mockingbird-cisafe.zip' || echo 'Mockingbird.zip'))

FRAMEWORK_FILENAME=Mockingbird.framework

MACOS_FRAMEWORK_FILENAME=Mockingbird-macOS.framework
IPHONESIMULATOR_FRAMEWORK_FILENAME=Mockingbird-iOS.framework
APPLETVSIMULATOR_FRAMEWORK_FILENAME=Mockingbird-tvOS.framework

EXECUTABLE_PATH=$(shell cd Sources && swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/mockingbird

MACOS_FRAMEWORK_FOLDER=$(XCODEBUILD_DERIVED_DATA)/Build/Products/Release
MACOS_FRAMEWORK_PATH=$(MACOS_FRAMEWORK_FOLDER)/$(FRAMEWORK_FILENAME)

IPHONESIMULATOR_FRAMEWORK_FOLDER=$(XCODEBUILD_DERIVED_DATA)/Build/Products/Release-iphonesimulator
IPHONESIMULATOR_FRAMEWORK_PATH=$(IPHONESIMULATOR_FRAMEWORK_FOLDER)/$(FRAMEWORK_FILENAME)

APPLETVSIMULATOR_FRAMEWORK_FOLDER=$(XCODEBUILD_DERIVED_DATA)/Build/Products/Release-appletvsimulator
APPLETVSIMULATOR_FRAMEWORK_PATH=$(APPLETVSIMULATOR_FRAMEWORK_FOLDER)/$(FRAMEWORK_FILENAME)

LICENSE_FILENAME=LICENSE
LICENSE_PATH=$(shell pwd)/$(LICENSE_FILENAME)

INSTALLABLE_FILENAMES="$(CLI_PATH)/$(CLI_FILENAME)" \
	"$(MACOS_FRAMEWORK_FILENAME)" \
	"$(IPHONESIMULATOR_FRAMEWORK_FILENAME)" \
	"$(APPLETVSIMULATOR_FRAMEWORK_FILENAME)" \
	"$(LICENSE_FILENAME)"

STARTER_PACK_FOLDER=MockingbirdSupport

OUTPUT_PACKAGE=Mockingbird.pkg
OUTPUT_ZIP=Mockingbird.zip
OUTPUT_STARTER_PACK_ZIP=MockingbirdSupport.zip
OUTPUT_DOCS_FOLDER=docs/$(VERSION_STRING)

ZIP_RELEASE_URL?=$(ARTIFACTS_URL)/$(VERSION_STRING)/$(ZIP_FILENAME)
SUCCESS_MSG=✅ Verified the CLI binary code signature
ERROR_MSG=❌ The CLI binary is not signed with the expected code signature! (Set VERIFY_SIGNATURES=0 to ignore this error.)

REDIRECT_DOCS_PAGE=<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=/mockingbird/$(VERSION_STRING)/"></head></html>

.PHONY: all
all: build

.PHONY: clean-mocks
clean-mocks:
	rm -f Tests/MockingbirdTests/Mocks/*.generated.swift
	rm -f Mockingbird.xcodeproj/MockingbirdCache/*.lock

.PHONY: clean-temporary-files
clean-temporary-files:
	rm -rf "$(TEMPORARY_FOLDER)"

.PHONY: clean-xcode
clean-xcode: clean-temporary-files
	$(BUILD_TOOL) -scheme 'MockingbirdFramework' $(XCODEBUILD_MACOS_FLAGS) clean
	$(BUILD_TOOL) -scheme 'MockingbirdTestsHost' $(XCODEBUILD_MACOS_FLAGS) clean

.PHONY: clean-swift
clean-swift:
	(cd Sources && swift package clean)

.PHONY: clean-installables
clean-installables:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -f "$(OUTPUT_ZIP)"

.PHONY: clean-dylibs
clean-dylibs:
	rm -f Sources/MockingbirdCli/Libraries/*.generated.swift
	rm -rf "$(MOCKINGBIRD_RPATH)"

.PHONY: clean
clean: clean-mocks clean-xcode clean-swift clean-installables clean-dylibs

.PHONY: setup-project
setup-project:
	cp -rf .xcode/xcschemes/*.xcscheme Mockingbird.xcodeproj/xcshareddata/xcschemes

.PHONY: bootstrap
bootstrap: setup-project

.PHONY: save-xcschemes
save-xcschemes:
	cp -rf Mockingbird.xcodeproj/xcshareddata/xcschemes/*.xcscheme .xcode/xcschemes

.PHONY: print-debug-info
print-debug-info:
	@echo "Mockingbird version: $(VERSION_STRING)"
	@echo "Installation prefix: $(PREFIX)"
	@echo "Temporary folder: $(TEMPORARY_FOLDER)"
	@echo "Mockingbird rpath: $(MOCKINGBIRD_RPATH)"
	@echo "Build tool: $(BUILD_TOOL)"
	$(eval XCODE_PATH_VAR = $(XCODE_PATH))
	@echo "Xcode path: $(XCODE_PATH_VAR)"
	@echo "Built CLI path: $(EXECUTABLE_PATH)"
	$(eval CURRENT_REV = $(shell git rev-parse HEAD))
	@echo "Current revision: $(CURRENT_REV)"
	$(eval SWIFT_VERSION = $(shell swift --version))
	@echo "Swift version: $(SWIFT_VERSION)"
	$(eval XCODEBUILD_VERSION = $(shell xcodebuild -version))
	@echo "Xcodebuild version: $(XCODEBUILD_VERSION)"
	@echo "Swift build flags: $(SWIFT_BUILD_FLAGS)"
	@echo "Simulator runtime: $(SIMULATOR_RUNTIME)"

.PHONY: generate-embedded-dylibs
generate-embedded-dylibs:
	Sources/MockingbirdCli/Scripts/generate-resource-file.sh \
		Sources/MockingbirdCli/Libraries/lib_InternalSwiftSyntaxParser.dylib \
		Sources/MockingbirdCli/Libraries/SwiftSyntaxParserDylib.generated.swift \
		'swiftSyntaxParserDylib'

.PHONY: build-cli
build-cli: generate-embedded-dylibs
	(cd Sources && swift build $(SWIFT_BUILD_FLAGS) --product mockingbird)
	# Inject custom rpath into binary.
	$(eval RPATH = $(DEFAULT_XCODE_RPATH))
	install_name_tool -delete_rpath "$(RPATH)" "$(EXECUTABLE_PATH)"
	install_name_tool -add_rpath "$(MOCKINGBIRD_RPATH)" "$(EXECUTABLE_PATH)"

.PHONY: build-framework-macos
build-framework-macos:
	$(BUILD_TOOL) -scheme 'MockingbirdFramework' -configuration 'Release' -sdk macosx -arch x86_64 $(XCODEBUILD_FRAMEWORK_FLAGS)

.PHONY: build-framework-iphonesimulator
build-framework-iphonesimulator:
	$(BUILD_TOOL) -scheme 'MockingbirdFramework' -configuration 'Release' -sdk iphonesimulator -arch x86_64 $(XCODEBUILD_FRAMEWORK_FLAGS)

.PHONY: build-framework-appletvsimulator
build-framework-appletvsimulator:
	$(BUILD_TOOL) -scheme 'MockingbirdFramework' -configuration 'Release' -sdk appletvsimulator -arch arm64 $(XCODEBUILD_FRAMEWORK_FLAGS)

.PHONY: build-framework
build-framework: build-framework-macos build-framework-iphonesimulator build-framework-appletvsimulator

.PHONY: build
build: build-cli build-framework

.PHONY: setup-cocoapods
setup-cocoapods:
	(cd Examples/iOSMockingbirdExample-CocoaPods && pod install)
	(cd Examples/iOSMockingbirdExample-CocoaPods/Pods/MockingbirdFramework && make install-prebuilt)

.PHONY: setup-carthage
setup-carthage:
	(cd Examples/iOSMockingbirdExample-Carthage && carthage update --use-xcframeworks --platform ios)
	(cd Examples/iOSMockingbirdExample-Carthage/Carthage/Checkouts/mockingbird && make install-prebuilt)

.PHONY: setup-spm
setup-spm:
	(cd Examples/iOSMockingbirdExample-SPM && xcodebuild -resolvePackageDependencies)
	$(eval DERIVED_DATA = $(shell xcodebuild -project Examples/iOSMockingbirdExample-SPM/iOSMockingbirdExample-SPM.xcodeproj -showBuildSettings | pcregrep -o1 'OBJROOT = (/.*)/Build'))
	(cd $(DERIVED_DATA)/SourcePackages/checkouts/mockingbird && make install-prebuilt)

.PHONY: test-cocoapods
test-cocoapods: setup-cocoapods
	$(eval DEVICE_UUID = $(shell xcrun simctl create "$(SIMULATOR_NAME)" "$(SIMULATOR_DEVICE_TYPE)" "$(SIMULATOR_RUNTIME)"))
	$(BUILD_TOOL) -destination "platform=iOS Simulator,id=$(DEVICE_UUID)" $(EXAMPLE_COCOAPODS_XCODEBUILD_FLAGS) test
	xcrun simctl delete "$(DEVICE_UUID)"
	# Ensure the pinned prebuilt binary for CocoaPods exists.
	[[ -f Examples/iOSMockingbirdExample-CocoaPods/Pods/MockingbirdFramework/mockingbird ]]

.PHONY: test-carthage
test-carthage: setup-carthage
	$(eval DEVICE_UUID = $(shell xcrun simctl create "$(SIMULATOR_NAME)" "$(SIMULATOR_DEVICE_TYPE)" "$(SIMULATOR_RUNTIME)"))
	$(BUILD_TOOL) -destination "platform=iOS Simulator,id=$(DEVICE_UUID)" $(EXAMPLE_CARTHAGE_XCODEBUILD_FLAGS) test
	xcrun simctl delete "$(DEVICE_UUID)"

.PHONY: test-spm
test-spm: setup-spm
	$(eval DEVICE_UUID = $(shell xcrun simctl create "$(SIMULATOR_NAME)" "$(SIMULATOR_DEVICE_TYPE)" "$(SIMULATOR_RUNTIME)"))
	$(BUILD_TOOL) -destination "platform=iOS Simulator,id=$(DEVICE_UUID)" $(EXAMPLE_SPM_XCODEBUILD_FLAGS) test
	xcrun simctl delete "$(DEVICE_UUID)"

.PHONY: test-examples
test-examples: test-cocoapods test-carthage test-spm

.PHONY: clean-cocoapods
clean-cocoapods: clean-temporary-files
	rm -f Examples/iOSMockingbirdExample-CocoaPods/MockingbirdMocks/*.generated.swift
	rm -f Examples/iOSMockingbirdExample-CocoaPods/iOSMockingbirdExample-CocoaPods.xcodeproj/MockingbirdCache/*.lock
	rm -f Examples/iOSMockingbirdExample-CocoaPods/Podfile.lock
	rm -rf Examples/iOSMockingbirdExample-CocoaPods/Pods
	$(BUILD_TOOL) $(EXAMPLE_COCOAPODS_XCODEBUILD_FLAGS) clean

.PHONY: clean-carthage
clean-carthage: clean-temporary-files
	rm -f Examples/iOSMockingbirdExample-Carthage/MockingbirdMocks/*.generated.swift
	rm -f Examples/iOSMockingbirdExample-Carthage/iOSMockingbirdExample-Carthage.xcodeproj/MockingbirdCache/*.lock
	rm -f Examples/iOSMockingbirdExample-Carthage/Cartfile.resolved
	rm -rf Examples/iOSMockingbirdExample-Carthage/Carthage
	$(BUILD_TOOL) $(EXAMPLE_CARTHAGE_XCODEBUILD_FLAGS) clean

.PHONY: clean-spm
clean-spm: clean-temporary-files
	rm -f Examples/iOSMockingbirdExample-SPM/MockingbirdMocks/*.generated.swift
	rm -f Examples/iOSMockingbirdExample-SPM/iOSMockingbirdExample-SPM.xcodeproj/MockingbirdCache/*.lock
	rm -f Examples/iOSMockingbirdExample-SPM/iOSMockingbirdExample-SPM.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
	$(BUILD_TOOL) $(EXAMPLE_SPM_XCODEBUILD_FLAGS) clean

.PHONY: clean-test-examples
clean-test-examples: clean-cocoapods clean-carthage clean-spm test-examples

.PHONY: test
test:
	$(BUILD_TOOL) -scheme 'MockingbirdTests' $(XCODEBUILD_MACOS_FLAGS) test

.PHONY: clean-test
clean-test: clean test

.PHONY: test-flaky
test-flaky:
	$(BUILD_TOOL) -scheme 'MockingbirdTests' $(XCODEBUILD_MACOS_FLAGS) test
	mv -f Tests/MockingbirdTests/Mocks/MockingbirdTestsHostMocks.generated.swift \
		Tests/MockingbirdTests/Mocks/MockingbirdTestsHostMocks.tmp.generated.swift

	set -e
	for i in {1..4}; do \
		$(BUILD_TOOL) -scheme 'MockingbirdTests' $(XCODEBUILD_MACOS_FLAGS) test; \
		diff Tests/MockingbirdTests/Mocks/MockingbirdTestsHostMocks.generated.swift \
			Tests/MockingbirdTests/Mocks/MockingbirdTestsHostMocks.tmp.generated.swift; \
		[[ $$? == 0 ]] && echo "[Test $$i completed]" || exit 1; \
	done

.PHONY: setup-swiftdoc
setup-swiftdoc:
	(cd docs/swift-doc && make install)

.PHONY: clean-docs
clean-docs:
	rm -rf "$(OUTPUT_DOCS_FOLDER)"
	rm -rf docs/latest
	rm -f docs/index.html

docs/latest:
	mkdir $@

docs/index.html docs/latest/index.html: | docs/latest
	echo '$(REDIRECT_DOCS_PAGE)' > $@

.PHONY: docs
docs: clean-docs setup-swiftdoc docs/index.html docs/latest/index.html
	swift doc generate \
		Sources/MockingbirdFramework \
		--module-name Mockingbird \
		--version "$(VERSION_STRING)" \
		--output "$(OUTPUT_DOCS_FOLDER)" \
		--format html \
		--base-url "/mockingbird/$(VERSION_STRING)"
	cp -f docs/swift-doc/Resources/all.min.css "$(OUTPUT_DOCS_FOLDER)/all.css"

.PHONY: download
download:
	$(eval CURL_AUTH_HEADER = $(shell [[ -z "${GH_ACCESS_TOKEN}" ]] || echo '-H "Authorization: token' ${GH_ACCESS_TOKEN}'"'))
	curl $(CURL_AUTH_HEADER) --progress-bar -Lo "$(ZIP_FILENAME)" "$(ZIP_RELEASE_URL)"
	mkdir -p "$(CLI_PATH)"
	unzip -o "$(ZIP_FILENAME)" "$(CLI_FILENAME)" -d "$(CLI_PATH)"
	chmod +x "$(CLI_PATH)/$(CLI_FILENAME)"
	@if [[ $(VERIFY_SIGNATURES) -eq 1 ]]; then $(MAKE) verify; fi

.PHONY: verify
verify:
	@codesign -v -R "$(CLI_DESIGNATED_REQUIREMENT)" "$(CLI_PATH)/$(CLI_FILENAME)" \
		&& echo "$(SUCCESS_MSG)" \
		|| $$(echo "$(ERROR_MSG)" >&2; exit 1)

.PHONY: install
install: build-cli
	install -d "$(BINARIES_FOLDER)"
	install "$(EXECUTABLE_PATH)" "$(BINARIES_FOLDER)"

.PHONY: install-prebuilt
install-prebuilt: download
	install -d "$(BINARIES_FOLDER)"
	install "$(CLI_PATH)/$(CLI_FILENAME)" "$(BINARIES_FOLDER)"

.PHONY: uninstall
uninstall:
	rm -f "$(BINARIES_FOLDER)/$(CLI_FILENAME)"
	rm -rf "$(FRAMEWORKS_FOLDER)/$(MACOS_FRAMEWORK_FILENAME)"
	rm -rf "$(FRAMEWORKS_FOLDER)/$(IPHONESIMULATOR_FRAMEWORK_PATH)"
	rm -rf "$(FRAMEWORKS_FOLDER)/$(APPLETVSIMULATOR_FRAMEWORK_PATH)"

.PHONY: installables
installables: build
	install -d "$(TEMPORARY_INSTALLER_FOLDER)$(BINARIES_FOLDER)"
	install -d "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)"

	install "$(EXECUTABLE_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)$(BINARIES_FOLDER)"

	cp -rf "$(MACOS_FRAMEWORK_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(MACOS_FRAMEWORK_FILENAME)"
	cp -rf "$(IPHONESIMULATOR_FRAMEWORK_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(IPHONESIMULATOR_FRAMEWORK_FILENAME)"
	cp -rf "$(APPLETVSIMULATOR_FRAMEWORK_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(APPLETVSIMULATOR_FRAMEWORK_FILENAME)"

.PHONY: bundle-artifacts
bundle-artifacts:
	mkdir -p "$(TEMPORARY_INSTALLER_FOLDER)$(BINARIES_FOLDER)"
	cp -f "$(EXECUTABLE_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)$(BINARIES_FOLDER)"

	mkdir -p "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)"
	cp -rf "$(MACOS_FRAMEWORK_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(MACOS_FRAMEWORK_FILENAME)"
	cp -rf "$(IPHONESIMULATOR_FRAMEWORK_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(IPHONESIMULATOR_FRAMEWORK_FILENAME)"
	cp -rf "$(APPLETVSIMULATOR_FRAMEWORK_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(APPLETVSIMULATOR_FRAMEWORK_FILENAME)"

.PHONY: signed-installables
signed-installables: build bundle-artifacts
	codesign --sign "$(BIN_IDENTITY)" -v --timestamp --options runtime \
		"$(TEMPORARY_INSTALLER_FOLDER)$(BINARIES_FOLDER)/$(CLI_FILENAME)"

.PHONY: package
package: installables
	pkgbuild \
		--identifier "$(PKG_BUNDLE_IDENTIFIER)" \
		--install-location "/" \
		--root "$(TEMPORARY_INSTALLER_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

.PHONY: signed-package
signed-package: signed-installables
	pkgbuild \
		--identifier "$(PKG_BUNDLE_IDENTIFIER)" \
		--install-location "/" \
		--root "$(TEMPORARY_INSTALLER_FOLDER)" \
		--version "$(VERSION_STRING)" \
		--sign "$(PKG_IDENTITY)" \
		"$(OUTPUT_PACKAGE)"
	@[[ -z "$(AC_USERNAME)" ]] || xcrun altool \
		--notarize-app \
		--primary-bundle-id "$(PKG_BUNDLE_IDENTIFIER).pkg" \
		--username "$(AC_USERNAME)" \
		--password "$(AC_PASSWORD)" \
		--file "$(OUTPUT_PACKAGE)"

.PHONY: stapled-package
stapled-package:
	xcrun stapler staple "$(OUTPUT_PACKAGE)"

.PHONY: prepare-zip
prepare-zip:
	cp -f "$(TEMPORARY_INSTALLER_FOLDER)$(BINARIES_FOLDER)/$(CLI_FILENAME)" "$(TEMPORARY_INSTALLER_FOLDER)"
	cp -rf "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(MACOS_FRAMEWORK_FILENAME)" "$(TEMPORARY_INSTALLER_FOLDER)"
	cp -rf "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(IPHONESIMULATOR_FRAMEWORK_FILENAME)" "$(TEMPORARY_INSTALLER_FOLDER)"
	cp -rf "$(TEMPORARY_INSTALLER_FOLDER)$(FRAMEWORKS_FOLDER)/$(APPLETVSIMULATOR_FRAMEWORK_FILENAME)" "$(TEMPORARY_INSTALLER_FOLDER)"
	cp -f "$(LICENSE_PATH)" "$(TEMPORARY_INSTALLER_FOLDER)"

.PHONY: archive
archive:
	(cd "$(TEMPORARY_INSTALLER_FOLDER)"; zip -yr - $(INSTALLABLE_FILENAMES)) > "$(OUTPUT_ZIP)"

.PHONY: zip
zip: installables prepare-zip archive

.PHONY: signed-zip
signed-zip: signed-installables prepare-zip archive
	# Generate designated requirement.
	codesign -d -r- "$(TEMPORARY_INSTALLER_FOLDER)/$(CLI_FILENAME)" | cut -c 15- > "$(CLI_DESIGNATED_REQUIREMENT)"
	codesign -vvv -R "$(CLI_DESIGNATED_REQUIREMENT)" "$(TEMPORARY_INSTALLER_FOLDER)/$(CLI_FILENAME)"

	@[[ -z "$(AC_USERNAME)" ]] || xcrun altool \
		--notarize-app \
		--primary-bundle-id "$(PKG_BUNDLE_IDENTIFIER).zip" \
		--username "$(AC_USERNAME)" \
		--password "$(AC_PASSWORD)" \
		--file "$(OUTPUT_ZIP)"

.PHONY: starter-pack-zip
starter-pack-zip:
	(cd Sources; zip -yr - $(STARTER_PACK_FOLDER)) > "$(OUTPUT_STARTER_PACK_ZIP)"

.PHONY: release
release: package zip starter-pack-zip

.PHONY: signed-release
signed-release: signed-package signed-zip starter-pack-zip

.PHONY: get-version
get-version:
	@echo $(VERSION_STRING)

.PHONY: get-zip-sha256
get-zip-sha256:
	@echo $(shell shasum --algorithm 256 "$(OUTPUT_ZIP)" | awk '{print $$1}')

get-repo-url:
	@echo $(REPO_URL)

get-release-url:
	@echo $(ZIP_RELEASE_URL)

%:
	@:
