#!/usr/bin/env sh

set -eu

json_text() {
  awk '
    BEGIN {
      printf "{\"text\":\""
    }
    {
      gsub(/\\/, "\\\\")
      gsub(/"/, "\\\"")
      printf "%s%s", sep, $0
      sep = "\\n"
    }
    END {
      printf "\"}\n"
    }
  '
}

human() {
  awk -v b="$1" '
    BEGIN {
      if (b >= 1073741824)
        printf "%.1fGiB/s", b / 1073741824
      else if (b >= 1048576)
        printf "%.1fMiB/s", b / 1048576
      else if (b >= 1024)
        printf "%.1fKiB/s", b / 1024
      else
        printf "%dB/s", b
    }'
}

status="$(argvus-networkctl status)"
iface="$(printf '%s\n' "$status" | awk -F= '$1 == "iface" { print $2; exit }')"
ip_addr="$(printf '%s\n' "$status" | awk -F= '$1 == "ip" { print $2; exit }')"
connected="$(printf '%s\n' "$status" | awk -F= '$1 == "connected" { print $2; exit }')"
rx1="$(printf '%s\n' "$status" | awk -F= '$1 == "rx" { print $2; exit }')"
tx1="$(printf '%s\n' "$status" | awk -F= '$1 == "tx" { print $2; exit }')"

if [ "$connected" != "yes" ] || [ -z "$iface" ]; then
  printf '%s\n' "Disconnected" | json_text
  exit 0
fi

sleep 1

status="$(argvus-networkctl status)"
rx2="$(printf '%s\n' "$status" | awk -F= '$1 == "rx" { print $2; exit }')"
tx2="$(printf '%s\n' "$status" | awk -F= '$1 == "tx" { print $2; exit }')"

rx1="${rx1:-0}"
tx1="${tx1:-0}"
rx2="${rx2:-$rx1}"
tx2="${tx2:-$tx1}"

rx_rate=$((rx2 - rx1))
tx_rate=$((tx2 - tx1))

rx_h="$(human "$rx_rate")"
tx_h="$(human "$tx_rate")"

{
  printf '%s\n' "IFACE  IP              Traffic"
  printf '%s  %s  ↓ %s ↑ %s\n' "$iface" "${ip_addr:-none}" "$rx_h" "$tx_h"
} | json_text
