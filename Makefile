.PHONY: build test icon app run clean

build:
	swift build

test:
	swift test

icon:
	./scripts/generate-icon.sh

app:
	./scripts/build-app.sh

run: app
	open .build/BrowserBranch.app

clean:
	swift package clean
