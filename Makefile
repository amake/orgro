SHELL := /usr/bin/env bash

flutter := ./flutter/bin/flutter
dart := ./flutter/bin/dart
version_define = --dart-define=ORGRO_VERSION=$(shell sed -nE 's/version: *(([0-9.])+)\+.*/\1/p' pubspec.yaml)
ui_string_keys = jq -r 'keys | .[] | select(startswith("@") | not)' $(1)
ui_string_values = jq -r 'to_entries | .[] | select(.key | startswith("@") | not) | .value' $(1)
spellcheck = $(call ui_string_values,lib/l10n/app_$(1).arb) | \
	aspell pipe --lang=$(1) --home-dir=. --personal=.aspell.$(1).pws | \
	awk '/^&/ {w++; print} END {exit w}'
key_store = $(shell sed -nE 's/storeFile=(.+)/\1/p' android/key.properties)

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

.PHONY: generate
generate:
	$(flutter) pub get
	$(flutter) gen-l10n

.PHONY: dirty-check
dirty-check: generate
	$(if $(shell git status --porcelain),$(error 'You have uncommitted changes. Aborting.'))

.PHONY: format-check
format-check:
	$(dart) format --set-exit-if-changed lib test

required_locales := en_US en_GB ja

.PHONY: l10n-check
l10n-check: ## Check l10n data for issues
	$(foreach _,$(required_locales:%=lib/l10n/app_%.arb),\
		diff <($(call ui_string_keys,lib/l10n/app_en.arb)) <($(call ui_string_keys,$(_))) &&) true
	$(call spellcheck,en_US)
	$(call spellcheck,en_GB)

.PHONY: build
build:
	find ./assets -name '*~' -delete
	$(flutter) build appbundle $(version_define)
	$(flutter) build ipa $(version_define)

.PHONY: release
release: ## Prepare Android bundle and iOS archive for release
release: dirty-check keystore-check format-check l10n-check web-assets-deploy-check test build
	open -a Transporter build/ios/ipa/Orgro.ipa

.PHONY: release-wait
release-wait: keystore-wait release

.PHONY: keystore-wait
keystore-wait:
	$(if $(wildcard android/key.properties),,$(error android/key.properties not found))
	while [ ! -f $(key_store) ]; do echo "Waiting for key store..."; ls -al $(key_store); sleep 3; done

.PHONY: keystore-check
keystore-check:
	$(if $(wildcard android/key.properties),,$(error android/key.properties not found))
	$(if $(wildcard $(key_store)),,$(error key_store not found))
	@exit 0

dryrun := --dryrun
config_get = awk -F ' = ' '/^$(1) *=/ {print $$2}' config.ini

.PHONY: deploy-web-assets
deploy-web-assets:
	deploy_path=s3://$$($(call config_get,deploy_bucket)) && \
	aws s3 cp $(dryrun) --recursive --exclude '*~' --exclude .DS_Store assets/web $$deploy_path

check_web_asset_deploy = cd ./assets/web/$(1)/ && find . -type f ! -name '*~' -print0 | xargs -0 -I % $(SHELL) -c 'diff <(curl -s https://$(2)/%) %'

.PHONY: web-assets-deploy-check
web-assets-deploy-check:
	$(call check_web_asset_deploy,debug,debug.orgro.org)
	$(call check_web_asset_deploy,profile,profile.orgro.org)
	$(call check_web_asset_deploy,release,orgro.org)

app_site_cdn := https://app-site-association.cdn-apple.com/a/v1
check_app_site_cdn = diff <(curl -s $(app_site_cdn)/$(2)) ./assets/web/$(1)/.well-known/apple-app-site-association

.PHONY: web-assets-cdn-check
web-assets-cdn-check:
	$(call check_app_site_cdn,debug,debug.orgro.org)
	$(call check_app_site_cdn,profile,profile.orgro.org)
	$(call check_app_site_cdn,release,orgro.org)

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
