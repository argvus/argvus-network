PREFIX ?= /usr
DESTDIR ?=
INSTALL ?= install
RM ?= rm -f

.DEFAULT_GOAL := help

.PHONY: help install uninstall validate lint lint-shell release-archive clean

help:
	@echo "Available targets:"
	@echo "  make build"
	@echo "  make install"
	@echo "  make uninstall"
	@echo "  make validate"
	@echo "  make release-archive"

install:
	$(INSTALL) -Dm755 bin/argvus-networkctl \
		"$(DESTDIR)$(PREFIX)/bin/argvus-networkctl"
	$(INSTALL) -Dm755 bin/argvus-bluetoothctl \
		"$(DESTDIR)$(PREFIX)/bin/argvus-bluetoothctl"
	$(INSTALL) -dm755 "$(DESTDIR)$(PREFIX)/share/argvus/network"
	cp -a src/usr/share/argvus/network/. "$(DESTDIR)$(PREFIX)/share/argvus/network/"
	find "$(DESTDIR)$(PREFIX)/share/argvus/network/sh" -type f -name '*.sh' -exec chmod 755 {} \; 2>/dev/null || true
	$(INSTALL) -Dm644 LICENSE \
		"$(DESTDIR)$(PREFIX)/share/licenses/argvus-network/LICENSE"

lint-shell:
	@for root in tools packaging/arch/common src bin; do \
		if [ -d "$$root" ]; then \
			find "$$root" -type f -name '*.sh' -exec shellcheck -e SC1090 -e SC2034 -e SC2154 {} +; \
		fi; \
	done
	@for root in tools packaging/arch/common src bin; do \
		if [ -d "$$root" ]; then \
			find "$$root" -type f -name '*.sh' -exec bash -n {} +; \
		fi; \
	done
	@git diff --check
	@echo "Lint Shell OK"

lint: lint-shell

uninstall:
	$(RM) "$(DESTDIR)$(PREFIX)/bin/argvus-networkctl"
	$(RM) "$(DESTDIR)$(PREFIX)/bin/argvus-bluetoothctl"
	rm -rf "$(DESTDIR)$(PREFIX)/share/argvus/network"
	$(RM) "$(DESTDIR)$(PREFIX)/share/licenses/argvus-network/LICENSE"

validate:
	@set -eu; \
	scripts=$$(find bin src -type f \( -name '*.sh' -o -path '*/bin/*' \) | sort); \
	test -n "$$scripts"; \
	for script in $$scripts; do sh -n "$$script"; done; \
	if command -v shellcheck >/dev/null 2>&1; then \
		for script in $$scripts; do shellcheck -e SC1090 -e SC2034 "$$script"; done; \
	else \
		echo "shellcheck not found; skipped"; \
	fi
	@grep -q '"network"' src/usr/share/argvus/network/config/waybar/argvus-network-modules.jsonc
	@awk '/"group\/right-2"/ { in_group = 1 } in_group && /"custom\/bluetooth"/ { found = 1 } in_group && /^  }/ { in_group = 0 } END { exit found ? 0 : 1 }' \
		src/usr/share/argvus/network/config/waybar/argvus-network-modules.jsonc
	@! awk '/"tray"/ { in_tray = 1 } in_tray && /"bluetooth"/ { found = 1 } in_tray && /^  }/ { in_tray = 0 } END { exit found ? 0 : 1 }' \
		src/usr/share/argvus/network/config/waybar/argvus-network-modules.jsonc
	@test ! -e src/scripts/argvus/sysinfo
	@echo "argvus-network validation ok"

release-archive:
	mkdir -p .release
	git archive --format=tar.gz --prefix="argvus-network-$$(git rev-parse --short HEAD)/" \
		--output=".release/argvus-network-$$(git rev-parse --short HEAD).tar.gz" HEAD

.PHONY: build

build:
	@tools/build-local-package.sh

clean:
	rm -rf dist
	rm -f packaging/arch/*.zst packaging/arch/*.tar.gz
