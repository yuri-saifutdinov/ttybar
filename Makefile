SWIFT ?= swift
APP := build/ttybar.app
EXECUTABLE := TTYBar

# Swift Testing ships with the Command Line Tools but is not on the default
# search path there, and its Foundation cross-import overlay ships without a
# module. With a full Xcode selected, plain `swift test` works.
DEVELOPER_DIR := $(shell xcode-select -p 2>/dev/null)
ifeq ($(findstring .app/,$(DEVELOPER_DIR)),)
TESTING_FRAMEWORKS := $(DEVELOPER_DIR)/Library/Developer/Frameworks
TESTING_LIBS := $(DEVELOPER_DIR)/Library/Developer/usr/lib
TEST_FLAGS := -Xswiftc -F$(TESTING_FRAMEWORKS) \
	-Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays \
	-Xlinker -F$(TESTING_FRAMEWORKS) \
	-Xlinker -rpath -Xlinker $(TESTING_FRAMEWORKS) \
	-Xlinker -rpath -Xlinker $(TESTING_LIBS)
endif

.PHONY: build test app run clean

build:
	$(SWIFT) build

test:
	$(SWIFT) test $(TEST_FLAGS)

app:
	$(SWIFT) build -c release
	rm -rf build/ttybar.app
	mkdir -p $(APP)/Contents/MacOS
	cp "$$($(SWIFT) build -c release --show-bin-path)/$(EXECUTABLE)" $(APP)/Contents/MacOS/
	cp Resources/Info.plist $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)

run: app
	-pkill -x $(EXECUTABLE)
	open $(APP)

clean:
	rm -rf .build build
