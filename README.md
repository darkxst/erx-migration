# Openwrt Edgerouter X Migration Script for Openwrt 24.10

The OEM layout on the Edgerouter X has two kernel slots that are 3MB each. Starting with Linux 6.6 included with Openwrt 24.10 the kernel images no longer fit into this layout, thus when upgrading to Openwrt 24.10 users will need to migrate to the new layout.

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

The scripts in this repository can be used to migrate existing installs 21.02, 22.03 or 23.05 to the new layout. It will install the latest 24.10 release to your device. Hopefully these scripts will be backported to 23.05 in the next stable release. Unfortunately its not possible to build factory images for Openwrt 24.10, as they have become too large, so new installs should start with the previous factory images then migrate directly to 24.10 per instructions below.

## Migration

**WARNING** All settings will be wiped make sure to backup your settings before proceeding.
1. If you are still on the stock OS, install factory images for 22.03[^2] first.
2. (OPTIONAL) If you need to work without internet, download the correct 24.10 sysupgrade.bin file for your model of router and verify[^3] it ahead of time.
3. Login to your router using ssh.
4. Copy both scripts to the `/tmp/` directory on your router and ensure they are named `ubnt_erx_migrate.sh` and `ubnt_erx_stage2.sh`.
5. (OPTIONAL) Rename and copy the pre-fetched sysupgrade.bin file to `/tmp/sysupgrade.img` on your router the same way you copied the scripts there in the previous step.
6. Run the following shell commands:
	```
	cd /tmp
	chmod +x ubnt_erx_migrate.sh
	./ubnt_erx_migrate.sh
	```
7. This will download the firmware update (if needed) and verify it, then flash the new kernel and rootfs and, finally, reboot.
8. The device will be left in a factory default configuration.

**Restoring backup after upgrade**
1. Login to router using ssh (root, no pwd).
2. Check that the comat version is set to 2: ```uci get system.@system[0].compat_version```.
3. Restore the backup (command line or webinterface) and reboot the device if not done automatically.
4. Login to router using ssh.
5. Ensure migration completed successfully and then manually update compat vesion back to 2.0:
	```
	uci set system.@system[0].compat_version=2.0
	uci commit
	```

## Snapshot
You can instead install a 24.10 snapshot build with this command:
```sh
SNAPSHOT=y ./ubnt_erx_migrate.sh
```
## Local Install
you can also build your own openwrt snapshot and migrate directly to that:
- Host `openwrt-ramips-mt7621-ubnt_edgerouter-x-squashfs-sysupgrade.bin` and `sha256sums` on a webserver on your lan accessible at http://<host>/downloads-path/
- http://<host>/downloads-path/ must be autoindexed or return at least `href=http://<host>/downloads-path/<your-image-file-name>-squashfs-sysupgrade.bin`
- on the router `export TESTSITE="http://<host>/downloads-path/"`
- Then proceed per above instructions

## TFTP Serial Installation
Alternatively you can directly install the new builds over Serial console:
1. Press <1> to enter u-boot menu - TFTP install
2. Boot `openwrt-ramips-mt7621-ubnt_edgerouter-x-initramfs-kernel.bin`
3. Then `sysupgrade -n -F openwrt-ramips-mt7621-ubnt_edgerouter-x-squashfs-sysupgrade.bin`

[^2]: https://github.com/stman/OpenWRT-19.07.2-factory-tar-file-for-Ubiquiti-EdgeRouter-x
[^3]: https://openwrt.org/docs/guide-quick-start/verify_firmware_checksum
