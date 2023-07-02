#!/usr/bin/env bash

set -e
cd "$(dirname "$0")" || exit "$?"

BUILD_PARAMETER="$1"
CONFIG_DIR="./device_config"
CONFIG_PATH="./$CONFIG_DIR/build.config"
FIX_DIR="$CONFIG_DIR/fix"
PATCH_DIR="$CONFIG_DIR/patch"
BUILD_DIR="./bin"

doNotRunAsRoot() {
	if [[ $EUID == 0 ]]; then
		echo "Don't run this script as root"
		exit 1
	fi
}

processFiles() {
	local dir=$1
	local pattern=$2
	local action=$3

	local regex="[0-9]*_$pattern"
	local files=("$dir"/$regex)

	if [[ -d "$dir" ]] && [[ -e "${files[0]}" ]]; then
		for file in "${files[@]}"; do
			echo "Processing $file..."
			$action "$file"
		done
	else
		echo "No valid files found in $dir."
	fi
}

main() {
	doNotRunAsRoot

	case "$BUILD_PARAMETER" in
	"preconfig")
		processFiles "$PATCH_DIR" "*.patch" "patch -p1 <"
		processFiles "$FIX_DIR" "*.sh" "bash"

		cp "$CONFIG_PATH" .config
		make defconfig
		make download
		make -j$(($(nproc) + 1))
		;;
	"manual")
		make menuconfig

		if [[ -f .config ]]; then
			cp .config "$BUILD_DIR"
		fi

		make download
		make -j$(($(nproc) + 1))
		;;
	"debug")
		/bin/bash
		;;
	*)
		echo "Invalid argument. Use 'preconfig', 'manual' or 'debug'."
		exit 1
		;;
	esac
}

main
