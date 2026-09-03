PREFIX ?= /usr
DESTDIR ?=
INSTALL ?= install
RM ?= rm -f

.DEFAULT_GOAL := help

.PHONY: help install uninstall validate release-archive clean

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
	$(INSTALL) -dm755 "$(DESTDIR)$(PREFIX)/share/argvus"
	cp -a config/. "$(DESTDIR)$(PREFIX)/share/argvus/"
	find "$(DESTDIR)$(PREFIX)/share/argvus/scripts" -type f -name '*.sh' -exec chmod 755 {} \; 2>/dev/null || true
	$(INSTALL) -Dm644 LICENSE \
		"$(DESTDIR)$(PREFIX)/share/licenses/argvus-network/LICENSE"

uninstall:
	$(RM) "$(DESTDIR)$(PREFIX)/bin/argvus-networkctl"
	$(RM) "$(DESTDIR)$(PREFIX)/bin/argvus-bluetoothctl"
	$(RM) "$(DESTDIR)$(PREFIX)/share/argvus/scripts/apps/waybar-netctl.sh"
	$(RM) "$(DESTDIR)$(PREFIX)/share/argvus/scripts/argvus/bluetooth-control.sh"
	$(RM) "$(DESTDIR)$(PREFIX)/share/argvus/scripts/argvus/sysinfo/network.sh"
	$(RM) "$(DESTDIR)$(PREFIX)/share/argvus/network/waybar/argvus-network-modules.jsonc"
	$(RM) "$(DESTDIR)$(PREFIX)/share/licenses/argvus-network/LICENSE"

validate:
	@set -eu; \
	scripts=$$(find bin config -type f \( -name '*.sh' -o -path '*/bin/*' \) | sort); \
	test -n "$$scripts"; \
	for script in $$scripts; do sh -n "$$script"; done; \
	if command -v shellcheck >/dev/null 2>&1; then \
		for script in $$scripts; do shellcheck -e SC1090 -e SC2034 "$$script"; done; \
	else \
		echo "shellcheck not found; skipped"; \
	fi
	@grep -q '"network"' config/network/waybar/argvus-network-modules.jsonc
	@awk '/"group\/right-2"/ { in_group = 1 } in_group && /"custom\/bluetooth"/ { found = 1 } in_group && /^  }/ { in_group = 0 } END { exit found ? 0 : 1 }' \
		config/network/waybar/argvus-network-modules.jsonc
	@! awk '/"tray"/ { in_tray = 1 } in_tray && /"bluetooth"/ { found = 1 } in_tray && /^  }/ { in_tray = 0 } END { exit found ? 0 : 1 }' \
		config/network/waybar/argvus-network-modules.jsonc
	@echo "argvus-network validation ok"

release-archive:
	mkdir -p .release
	git archive --format=tar.gz --prefix="argvus-network-$$(git rev-parse --short HEAD)/" \
		--output=".release/argvus-network-$$(git rev-parse --short HEAD).tar.gz" HEAD

.PHONY: build

build:
	@tools/build-local-package.sh

clean:
	rm -f packaging/arch/*.zst packaging/arch/*.tar.gz
