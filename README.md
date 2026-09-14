# argvus-network

NetworkManager, Wi-Fi and Bluetooth integration for ARGVUS.

This package owns the ARGVUS network domain helpers extracted from the legacy
`argvus` repository:

- `argvus-networkctl` for NetworkManager status, global networking toggles,
  Wi-Fi toggles and opening a connection manager.
- `argvus-bluetoothctl` for native Bluetooth status and power control using
  BlueZ.
- Compatibility wrappers at the existing Waybar and Quickshell script paths.
- A Waybar module fragment for the `network` and `bluetooth` modules.

Bluetooth is native ARGVUS by default. Blueman remains optional for users who
want its manager or the legacy tray applet.

`argvus-network` exports network/Bluetooth commands and module fragments.
The full ARGVUS Waybar taskbar layout, including `group/right-2` placement, is
owned by `argvus-shell`. The patched Waybar package remains `argvus-waybar`.

## Install

```sh
make DESTDIR=/tmp/argvus-network-dest PREFIX=/usr install
```

Installed compatibility paths:

```text
/usr/share/argvus/network/sh/waybar-netctl.sh
/usr/share/argvus/network/sh/bluetooth-control.sh
/usr/share/argvus/widget-telemetry/sh/network.sh
```

The Waybar fragment is installed to:

```text
/usr/share/argvus/network/waybar/argvus-network-modules.jsonc
```

The Bluetooth module remains in `group/right-2`; Blueman is not auto-started by
this package.

## Validate

```sh
make validate
makepkg --printsrcinfo
```
