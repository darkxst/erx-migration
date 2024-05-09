# Openwrt Edgerouter X Migration Script for Linux 6.6

The OEM layout on the Edgerouter X has two kernel slots that are 3MB each. Starting with Linux 6.6 the kernel images no longer fit into this layout, thus starting with Openwrt 24.x[^1] users will need to migrate to the new layout.

PR [#15194](https://github.com/openwrt/openwrt/pull/15194) introduces a new partition layout allowing for kernels up to 6MB:

```
root@OpenWrt:/# cat /proc/mtd
dev:    size   erasesize  name
mtd0: 00080000 00020000 "u-boot"
mtd1: 00060000 00020000 "u-boot-env"
mtd2: 00060000 00020000 "factory"
mtd3: 00600000 00020000 "kernel"
mtd4: 0f7c0000 00020000 "ubi"
```

The scripts in this repository can be used to migrate existing installs 21.02, 22.03 and 23.05 to migrate to the new layout. Hopefully these scripts will be backported to 23.05 in the next stable release

## Pre-step
Until [#15194](https://github.com/openwrt/openwrt/pull/15194) is merged, you can build an openwrt snapshot from that PR, then:
- Host `openwrt-ramips-mt7621-ubnt_edgerouter-x-squashfs-sysupgrade.bin` on a webserver on your lan
- on the router `export TESTSITE="http://<host>/downloads-path/"`
- Then proceed per below

## Migration

**WARNING** All settings will be wiped make sure to backup your settings before proceeding.

1. If you are still on Stock OS install factory images for 22.03[^2] first
2. Login to router using ssh
3. Copy both scripts to `/tmp/` on your router
	- `ubnt_erx_migrate.sh
	- `ubnt_erx_stage2.sh
4. Run below shell commands
	```
	cd /tmp
	./ubnt_erx_migrate.sh
	```
5. This will download firmware update, then flash new kernel and rootfs and finally reboot.




## TFTP Serial Installation
Alternatively you can directly install the new builds over Serial console:
1. Press <1> to enter u-boot menu - TFTP install
2. Boot `openwrt-ramips-mt7621-ubnt_edgerouter-x-initramfs-kernel.bin`
3. Then `sysupgrade -n -F openwrt-ramips-mt7621-ubnt_edgerouter-x-squashfs-sysupgrade.bin`

[^1]: Snapshot builds once they are re-enabled will also need this migration.  
[^2]: https://github.com/stman/OpenWRT-19.07.2-factory-tar-file-for-Ubiquiti-EdgeRouter-x