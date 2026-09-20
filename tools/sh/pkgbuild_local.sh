#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
DIST_DIR="$BUILD_DIR/dist"
PKGBUILD_DIR="$ROOT_DIR/packaging/arch/local"
PKGBUILD="$PKGBUILD_DIR/PKGBUILD"

for command_name in makepkg sha256sum tar awk find; do
	command -v "$command_name" >/dev/null 2>&1 || {
		printf 'error: required command not found: %s\n' "$command_name" >&2
		exit 1
	}
done
[[ -f "$PKGBUILD" ]] || { printf 'error: missing PKGBUILD: %s\n' "$PKGBUILD" >&2; exit 1; }
read -r pkgname pkgver <<<"$(bash -c 'source "$1"; printf "%s %s" "$pkgname" "$pkgver"' bash "$PKGBUILD")"
[[ "$pkgname" =~ ^[a-z0-9@._+-]+$ ]] || { printf 'error: invalid package name: %s\n' "$pkgname" >&2; exit 1; }
[[ "$pkgver" =~ ^[0-9]+([.][0-9]+)*([._+-][A-Za-z0-9]+)*$ ]] || { printf 'error: unsupported package version: %s\n' "$pkgver" >&2; exit 1; }

mkdir -p "$ARTIFACTS_DIR" "$DIST_DIR"
archive="$ARTIFACTS_DIR/${pkgname}-${pkgver}.tar.gz"
echo "Creating local source archive: $archive"
tar -czf "$archive" --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
	--exclude='./.git' --exclude='./.release' --exclude='./packages-repo' --exclude='./build' --exclude='./dist' --exclude='./target' --exclude='./tools' \
	--exclude='./packaging/arch/local/src' --exclude='./packaging/arch/local/pkg' --exclude='./packaging/arch/ci/src' --exclude='./packaging/arch/ci/pkg' \
	--exclude='./packaging/arch/*/PKGBUILD.local' --exclude='./packaging/arch/local/*.pkg.tar*' --exclude='./packaging/arch/ci/*.pkg.tar*' \
	--exclude='./packaging/arch/local/*.tar.gz' --exclude='./packaging/arch/ci/*.tar.gz' --exclude='./*.pkg.tar*' \
	--transform "s#^\./#${pkgname}-${pkgver}/#" -C "$ROOT_DIR" .

if [[ -n "${MAKEPKG_FLAGS:-}" ]]; then
	# shellcheck disable=SC2206
	flags=(${MAKEPKG_FLAGS})
else
	flags=(--nodeps --noconfirm --needed --cleanbuild --force --check)
fi
cd "$PKGBUILD_DIR"
export BUILDDIR="$ARTIFACTS_DIR" SRCDEST="$ARTIFACTS_DIR" PKGDEST="$DIST_DIR"
generated_pkgbuild="$(mktemp "$PKGBUILD_DIR/.PKGBUILD.local.XXXXXX")"
trap 'rm -f "$generated_pkgbuild"' EXIT
cp "$PKGBUILD" "$generated_pkgbuild"
sha256="$(sha256sum "$archive" | awk '{print $1}')"
sed -i "s/^sha256sums=.*/sha256sums=(\"${sha256}\")/" "$generated_pkgbuild"
find "$DIST_DIR" -maxdepth 1 -type f -name "${pkgname}-${pkgver}-*.pkg.tar.zst" -delete
makepkg -p "$generated_pkgbuild" "${flags[@]}" "$@"
mapfile -t package_files < <(find "$DIST_DIR" -maxdepth 1 -type f -name "${pkgname}-${pkgver}-*.pkg.tar.zst" -print | sort)
if (( ${#package_files[@]} != 1 )); then
	printf 'error: expected exactly one package in %s, found %s\n' "$DIST_DIR" "${#package_files[@]}" >&2
	exit 1
fi
if command -v namcap >/dev/null 2>&1; then namcap "${package_files[0]}"; fi
printf 'Packages created in %s:\n' "$DIST_DIR"
find "$DIST_DIR" -maxdepth 1 -type f -name "${pkgname}-*.pkg.tar.zst" -printf '  %f\n' | sort
printf 'Artifacts kept in %s:\n' "$ARTIFACTS_DIR"
find "$ARTIFACTS_DIR" -mindepth 1 -maxdepth 1 -printf '  %f\n' | sort
