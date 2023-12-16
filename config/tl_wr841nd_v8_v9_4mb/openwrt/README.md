# TP-Link TL-WR841N/ND v8/9 (4mb flash)

## OpenWRT
Supported Versions:
  - v19.07.10
  - v18.06.9

## Config
### Added:
* htop package
* opkg package
* relayd package
* Some busybox pkgs (arp, base64, wget)

### Removed:
* IPv6 support
* PPP support
* LuCI web interface
* Swap Busybox pkgs (mkswap, swapon, swapoff)
* Some other Busybox pkgs (chgrp[^1], echo & printf[^2], halt, hexdump, rmdir[^3])

### Misc:
* Set repo version to 19.07.10
* Striped unnecessary exports from the kernel image
* Striped unnecessary functions from libraries
* Enabled ccache while building

[^1]: Use **chown** command instead
[^2]: Use **ash** builtin command instead
[^3]: Use **rm -r** command instead
