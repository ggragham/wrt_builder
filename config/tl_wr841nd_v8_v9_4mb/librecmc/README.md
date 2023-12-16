# TP-Link TL-WR841N/ND v8/9 (4mb flash)

## LibreCMC
Supported Versions:
  - LTS
  - v1.5.13

## Config
### Added:
* LuCI web interface
* relayd package
* Some busybox packages (arp, watch)

### Removed:
* IPv6 support
* PPP support
* opkg package
* ca-bundle package
* libpthread package
* Support for Ubiquiti UniFi Outdoor+ access point
* Swap Busybox packages (mkswap, swapon, swapoff)
* Some other Busybox packages (bzcat & zcat[^1], chgrp[^2], echo & printf[^3], halt, head, hexdump, rmdir[^4], uniq)

### Misc:
* Optimized ash for size instead of speed
* Removed ipkg/opkg status data files in final images
* Minified LuCI sources (Lua, JavaScrips, CSS)
* Disabled export mac80211 internals in DebugFS
* Disabled 802.11s mesh support
* Striped unnecessary exports from the kernel image
* Striped unnecessary functions from libraries
* Enabled ccache while building


[^1]: Use **bunzip2 -c** & **gunzip -c** instead
[^2]: Use **chown** command instead
[^3]: Use ash builtin command instead
[^4]: Use **rm -r** command instead
