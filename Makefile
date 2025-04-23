SHELL := /usr/bin/env bash

flutter := ./flutter/bin/flutter
version_define = --dart-define=ORGRO_VERSION=$(shell sed -nE 's/version: *(([0-9.])+)\+.*/\1/p' pubspec.yaml)
ui_string_keys = jq -r 'keys | .[] | select(startswith("@") | not)' $(1)
ui_string_values = jq -r 'to_entries | .[] | select(.key | startswith("@") | not) | .value' $(1)
spellcheck = $(call ui_string_values,lib/l10n/app_$(1).arb) | \
	aspell pipe --lang=$(1) --home-dir=. --personal=.aspell.$(1).pws | \
	awk '/^&/ {w++; print} END {exit w}'
keyStore = $(shell sed -nE 's/storeFile=(.+)/\1/p' android/key.properties)

.PHONY: all
all: release

.PHONY: run
run: ## Run app with full environment
	$(flutter) run $(version_define) $(args)

.PHONY: clean
clean: ## Clean project
clean:
	$(flutter) clean

.PHONY: test
test: ## Run tests
	$(flutter) analyze
	$(flutter) test

.PHONY: dirty-check
dirty-check:
	$(if $(shell git status --porcelain),$(error 'You have uncommitted changes. Aborting.'))

.PHONY: format-check
format-check:
	dart format --set-exit-if-changed lib test

.PHONY: l10n-check
l10n-check: ## Check l10n data for issues
	$(foreach _,$(wildcard lib/l10n/*.arb),\
		diff <($(call ui_string_keys,lib/l10n/app_en.arb)) <($(call ui_string_keys,$(_)));)
	$(call spellcheck,en_US)
	$(call spellcheck,en_GB)

.PHONY: build
build:
	find ./assets -name '*~' -delete
	$(flutter) build appbundle $(version_define)
	$(flutter) build ipa $(version_define)

.PHONY: release
release: ## Prepare Android bundle and iOS archive for release
release: dirty-check keystore-check format-check l10n-check test build
	open -a Transporter build/ios/ipa/Orgro.ipa

.PHONY: release-wait
release-wait: keystore-wait release

.PHONY: keystore-wait
keystore-wait:
	$(if $(wildcard android/key.properties),,$(error android/key.properties not found))
	while [ ! -f $(keyStore) ]; do echo "Waiting for keyStore..."; ls -al $(keyStore); sleep 3; done

.PHONY: keystore-check
keystore-check:
	$(if $(wildcard android/key.properties),,$(error android/key.properties not found))
	$(if $(wildcard $(keyStore)),,$(error keyStore not found))
	@exit 0

dryrun := --dryrun
config_get = awk -F ' = ' '/^$(1) *=/ {print $$2}' config.ini

.PHONY: deploy-web-assets
deploy-web-assets:
	deploy_path=s3://$$($(call config_get,deploy_bucket)) && \
	aws s3 cp $(dryrun) --recursive --exclude '*~' --exclude .DS_Store assets/web $$deploy_path

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
