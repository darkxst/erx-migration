# Openwrt Edgerouter X Migration Script for Linux 6.6

The OEM layout on the Edgerouter X has two kernel slots that are 3MB each. Starting with Linux 6.6 the kernel images no longer fit into this layout, thus when upgrading to Openwrt 24.10 users will need to migrate to the new layout.

PR [#15194](https://github.com/openwrt/openwrt/pull/15194) introduced a new partition layout allowing for kernels up to 6MB:

```
root@OpenWrt:/# cat /proc/mtd
dev:    size   erasesize  name
mtd0: 00080000 00020000 "u-boot"
mtd1: 00060000 00020000 "u-boot-env"
mtd2: 00060000 00020000 "factory"
mtd3: 00600000 00020000 "kernel"
mtd4: 0f7c0000 00020000 "ubi"
```

The scripts in this repository can be used to migrate existing installs 21.02, 22.03 or 23.05 to the new layout. It will install the latest 24.10 release to your device. Hopefully these scripts will be backported to 23.05 in the next stable release

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
	chmod +x ./ubnt_erx_migrate.sh
	./ubnt_erx_migrate.sh
	```
5. This will download firmware update, check sha256 sums, then flash new kernel and rootfs and finally reboot.
6. If you restore a backup after migration is complete, this will override the `compat` version, with the previous version from the backup. Ensure migration completed successfully and then manually update compat vesion back to 2.0:

```
uci get system.@system[0].compat_version = "2.0"
```


## Snapshot
You can instead install a 24.10 snapshot build with this command:
```sh
SNAPSHOT=y ./ubnt_erx_migrate.sh
```
## Local Install
you can also build your own openwrt snapshot and migrate directly to that:
- Host `openwrt-ramips-mt7621-ubnt_edgerouter-x-squashfs-sysupgrade.bin` on a webserver on your lan
- on the router `export TESTSITE="http://<host>/downloads-path/"`
- Then proceed per above instructions

## TFTP Serial Installation
Alternatively you can directly install the new builds over Serial console:
1. Press <1> to enter u-boot menu - TFTP install
2. Boot `openwrt-ramips-mt7621-ubnt_edgerouter-x-initramfs-kernel.bin`
3. Then `sysupgrade -n -F openwrt-ramips-mt7621-ubnt_edgerouter-x-squashfs-sysupgrade.bin`


[^2]: https://github.com/stman/OpenWRT-19.07.2-factory-tar-file-for-Ubiquiti-EdgeRouter-x