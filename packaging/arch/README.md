# Arch packaging layout

This package follows the ARGVUS packaging skeleton and keeps separate CI and
local PKGBUILDs because their source inputs differ:

| Path | Use | Source |
| --- | --- | --- |
| `local/PKGBUILD` | `make build` from the working tree | deterministic local archive |
| `ci/PKGBUILD` | tagged release | GitHub tag archive |

Both PKGBUILDs share metadata, source normalization, checks, and package
installation through `common/functions.sh`. The package payload is rooted at
`src/` and retains the network and Bluetooth files owned by this project.
