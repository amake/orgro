SHELL := /usr/bin/env bash

version_define = --dart-define=ORGRO_VERSION=$(shell sed -nE 's/version: *(([0-9.])+)\+.*/\1/p' pubspec.yaml)
ui_string_keys = jq -r 'keys | .[] | select(startswith("@") | not)' $(1)

.PHONY: all
all: release

.PHONY: run
run:
	flutter run $(version_define) $(args)

.PHONY: test
test: ## Run tests
	flutter analyze
	flutter test test

.PHONY: dirty-check
dirty-check:
	$(if $(shell git status --porcelain),$(error 'You have uncommitted changes. Aborting.'))

.PHONY: l10n-check
l10n-check: ## Check l10n data for issues
	$(foreach _,$(wildcard lib/l10n/*.arb),\
		diff <($(call ui_string_keys,lib/l10n/app_en.arb)) <($(call ui_string_keys,$(_)));)

.PHONY: build
build:
	flutter build appbundle $(version_define)
	flutter build ios $(version_define)

.PHONY: archive
archive:
	cd ios && xcodebuild -configuration Release -workspace Runner.xcworkspace -scheme Runner archive -sdk iphoneos

.PHONY: release
release: ## Prepare Android bundle and iOS archive for release
release: dirty-check test build archive

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
