# Short names for the shared scripts in packages/script-tools/flutter. `make` lists them.
SCRIPT_TOOLS := packages/script-tools
include $(SCRIPT_TOOLS)/flutter/flutter.mk

# App-local: the shared file has no target for the preflight lane, and this app releases through it.
.PHONY: pre-build
pre-build: ## The release gate — config, signing and the build number. No build.
	@cd ios && LANG=$${LANG:-en_US.UTF-8} && case "$$LANG" in *UTF-8 | *utf8) ;; *) LANG=en_US.UTF-8 ;; esac && export LANG && bundle exec fastlane preflight
