# TP-Link TL-WR841N/ND v8 (4mb flash)

## OpenWRT
Version (branch): openwrt-19.07

## Config
### Added:
* htop
* opkg
* relayd
* Some busybox pkgs (arp, base64, wget)

### Removed:
* IPv6 support
* PPP support
* LuCI web interface
* Swap Busybox pkgs (mkswap, swapon, swapoff)
* Some other Busybox pkgs (chgrp, echo*, halt, hexdump, printf*, rmdir**)

### Misc:
* Enabled ccache while building
* Enabled "Strip unnecessary exports from the kernel image"
* Enabled "Strip unnecessary functions from libraries"
* Set repo version to 19.07.10

<span style="font-size: smaller;">* Use ash builtin command instead</span>  
<span style="font-size: smaller;">** Use **rm -r** instead </span>
