#!/bin/sh

. /lib/functions.sh

include /lib/upgrade

. /usr/share/libubox/jshn.sh

export VERBOSE=1
BOARD="$(board_name | sed 's/,/_/g')"

if [ ! -d /etc/ssl/certs/ ]; then
    WGET_OPTS="--no-check-certificate"
fi

REL="24.10.1"
SITE="https://downloads.openwrt.org/releases/${REL}/targets/ramips/mt7621/"
SNAPSITE="https://downloads.openwrt.org/releases/24.10-SNAPSHOT/targets/ramips/mt7621/"

if [ -n "$SNAPSHOT" ]; then
    SITE=${SNAPSITE}
fi

SITE=${TESTSITE:-$SITE}
PATTERN="${BOARD}-squashfs-sysupgrade.bin"
FILE=$(wget ${WGET_OPTS} -qO- "$SITE" | grep -o 'href="[^"]*' | sed 's/href="//' | grep "$PATTERN" | head -n 1)
tar_file="/tmp/sysupgrade.img"

confirm_migration() {
    case "$(board_name)" in
        ubnt,edgerouter-x|\
        ubnt,edgerouter-x-sfp)
            compat=$(uci -q get system.@system[0].compat_version)
            if [ -n "$compat" ] && [ "$compat" == "2.0" ]; then
                echo "Device already migrated to new layout" >&2
                exit 1
            fi
            ;;
        *)
            echo "Incompatible board $(board_name)" >&2
            exit 1
            ;;
    esac

    echo -e "\033[0;31mWARNING:\033[0m This script will migrate your OpenWrt system to a new layout as"
    echo "required for the linux 6.6 kernel. This process will erase all your current settings."
    echo "It is recommended to back up your system before proceeding."
    echo ""

    read -p "Do you want to proceed with the migration? (y/n)" confirm
    if [ "$confirm" != "y" ]; then
        echo "Migration canceled."
        exit 0
    fi
}

download_image(){
    echo "Downloading $SITE/$FILE"
    wget ${WGET_OPTS} -qO "$tar_file" "$SITE/$FILE"
    sha256=$(wget ${WGET_OPTS} -qO- "$SITE/sha256sums" | grep "$PATTERN" | cut -d ' ' -f1)
    sha256local=$(sha256sum "$tar_file" | cut -d ' ' -f1)
    if [ "$sha256" != "$sha256local" ]; then
            echo "Downloaded image checksum mismatch" >&2
            exit 1
    fi
}

check_for_image(){
    if [ -f "$tar_file" ]; then
        echo "Found local $tar_file... Skipping download step."
    else
        download_image
    fi

    board_dir=$( (tar tf "$tar_file" | grep -m 1 '^sysupgrade-.*/$') 2> /dev/null)
    export board_dir="${board_dir%/}"

    tar xC /tmp -f "$tar_file" 2> /dev/null
    if [ ! -f /tmp/$board_dir/kernel ] || [ ! -f /tmp/$board_dir/root ]; then
        echo "Invalid image file" >&2
        exit 1
    fi
}

confirm_migration
check_for_image

install_bin /sbin/upgraded

v "Commencing upgrade. Closing all shell sessions and rebooting."

RAM_ROOT="/tmp/root"
COMMAND="sh /tmp/ubnt_erx_stage2.sh"
SAVE_PARTITIONS=0

json_init
json_add_string prefix "$RAM_ROOT"
json_add_string path "$tar_file"
json_add_boolean force 1
json_add_string command "$COMMAND"
json_add_object options
json_add_int save_partitions "$SAVE_PARTITIONS"
json_close_object

ubus call system sysupgrade "$(json_dump)"
