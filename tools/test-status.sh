#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
bin="$tmp/bin"
mkdir -p "$bin"

cat >"$bin/nmcli" <<'EOF'
#!/usr/bin/env sh
case " $* " in
  *" -t networking "*) printf 'enabled\n' ;;
  *" -t radio wifi "*) printf 'enabled\n' ;;
  *" -t -g CONNECTIVITY general "*) printf '%s\n' "${NM_CONNECTIVITY:-full}" ;;
  *" -t -f DEVICE,STATE device status "*) printf '%s\n' "${NM_DEVICE_STATE:-wlan0:connected}" ;;
  *" -g GENERAL.TYPE device show "*) printf '%s\n' "${NM_TYPE:-wifi}" ;;
  *" device wifi list "*) printf 'yes:TestNet\n' ;;
  *) exit 0 ;;
esac
EOF
cat >"$bin/ip" <<'EOF'
#!/usr/bin/env sh
case " $* " in
  *" route show default "*) printf 'default via 192.0.2.1 dev wlan0\n' ;;
  *" addr show "*) printf '    inet 192.0.2.10/24\n' ;;
  *) exit 0 ;;
esac
EOF
chmod 755 "$bin/nmcli" "$bin/ip"

run() { PATH="$bin:/usr/bin:/bin" sh "$root/bin/argvus-networkctl" status; }
test "$(NM_CONNECTIVITY=full run | sed -n 's/^status=//p')" = connected
test "$(NM_CONNECTIVITY=limited run | sed -n 's/^status=//p')" = limited
test "$(NM_CONNECTIVITY=portal run | sed -n 's/^status=//p')" = limited
test "$(NM_CONNECTIVITY=none run | sed -n 's/^status=//p')" = limited
test "$(NM_CONNECTIVITY=unknown run | sed -n 's/^status=//p')" = limited
test "$(NM_DEVICE_STATE='eno1:connected' NM_TYPE=ethernet NM_CONNECTIVITY=full run | sed -n 's/^status=//p')" = connected
test "$(NM_DEVICE_STATE='wlan0:disconnected' NM_CONNECTIVITY=full run | sed -n 's/^status=//p')" = disconnected
printf 'Network status mapping tests passed\n'
