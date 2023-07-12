#!/usr/bin/env bash

set -e
cd "$(dirname "$0")" || exit "$?"

BUILD_PARAMETER="$1"
CONFIG_DIR="./device_config"
CONFIG_PATH="$CONFIG_DIR/build.config"
FIX_DIR="$CONFIG_DIR/fix"
PATCH_DIR="$CONFIG_DIR/patch"
BUILD_DIR="./bin"
OUTPUT_DIR="./output_dir"

doNotRunAsRoot() {
	if [[ $EUID == 0 ]]; then
		echo "Don't run this script as root"
		exit 1
	fi
}

makeBuild() {
	if [[ "$GET_VERBOSE_STATUS" == "off" ]]; then
		make "$@"
	elif [[ "$GET_VERBOSE_STATUS" == "on" ]]; then
		make V=sc "$@"
	fi
}

makeClean() {
	if [[ "$GET_CLEAN_LEVEL" == "none" ]]; then
		return 0
	else
		makeBuild "$GET_CLEAN_LEVEL"
	fi
}

saveBuild() {
	if [[ $(ls -A "$BUILD_DIR") ]]; then
		cp -r "$BUILD_DIR/." "$OUTPUT_DIR/"
	fi
}

applyPatch() {
	local dir="$PATCH_DIR"
	local regex="[0-9]*.patch"
	local files=("$dir"/$regex)

	if [[ -e "${files[0]}" ]]; then
		for file in "${files[@]}"; do
			if patch --dry-run -f -p1 --reverse <"$file" >/dev/null; then
				echo "$file already applied."
			else
				patch -p1 <"$file"
			fi
		done
	else
		echo "No valid files found in $dir."
	fi
}

applyFix() {
	local dir="$FIX_DIR"
	local regex="[0-9]*.sh"
	local files=("$dir"/$regex)

	if [[ -e "${files[0]}" ]]; then
		for file in "${files[@]}"; do
			if bash "$file" >/dev/null; then
				echo "$file applied."
			else
				echo "$file hasn't applied."
			fi
		done
	else
		echo "No valid files found in $dir."
	fi
}

main() {
	doNotRunAsRoot
	makeClean

	case "$BUILD_PARAMETER" in
	"preconfig")
		applyPatch
		applyFix
		cp "$CONFIG_PATH" .config
		makeBuild defconfig
		makeBuild download
		makeBuild -j$(($(nproc) + 1))
		saveBuild
		;;
	"manual")
		makeBuild menuconfig
		makeBuild download
		makeBuild -j$(($(nproc) + 1))
		saveBuild
		;;
	"shell")
		/bin/bash
		;;
	*)
		echo "Invalid argument. Use 'preconfig', 'manual' or 'shell'."
		exit 1
		;;
	esac
}

main
