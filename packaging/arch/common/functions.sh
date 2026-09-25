#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2154
# srcdir, pkgdir, pkgname, and pkgver are supplied by makepkg.

# Normalize GitHub and local archive directory names before package phases run.
arch_normalize_source_tree() {
	local expected="${srcdir}/${pkgname}-${pkgver}"
	local -a roots=()

	while IFS= read -r -d '' root; do
		roots+=("$root")
	done < <(find "$srcdir" -mindepth 1 -maxdepth 1 -type d -print0)

	if (( ${#roots[@]} != 1 )); then
		printf 'error: expected exactly one extracted source directory in %s\n' "$srcdir" >&2
		return 1
	fi

	if [[ "${roots[0]}" != "$expected" ]]; then
		[[ ! -e "$expected" ]] || {
			printf 'error: source destination already exists: %s\n' "$expected" >&2
			return 1
		}
		mv -- "${roots[0]}" "$expected"
	fi
}

arch_check_network_payload() {
	local source_root="${srcdir}/${pkgname}-${pkgver}"

	test -x "${source_root}/src/usr/bin/argvus-networkctl"
	test -x "${source_root}/src/usr/bin/argvus-bluetoothctl"
	test -f "${source_root}/src/usr/share/argvus/network/config/waybar/argvus-network-modules.jsonc"
	test -f "${source_root}/src/usr/share/argvus/network/sh/bluetooth-control.sh"
	test -x "${source_root}/src/usr/share/argvus/network/sh/waybar-network.sh"
	find "${source_root}/src" -type f -name '*.sh' -exec bash -n {} +
	grep -q '"custom/network"' \
		"${source_root}/src/usr/share/argvus/network/config/waybar/argvus-network-modules.jsonc"
}

arch_package_network_payload() {
	local source_root="${srcdir}/${pkgname}-${pkgver}"

	cp -a "${source_root}/src/." "${pkgdir}/"
	find "${pkgdir}" -type f -name '*.sh' -exec chmod 755 {} +
	install -Dm644 "${source_root}/LICENSE" \
		"${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
