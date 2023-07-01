#!/bin/bash

cd "$(dirname "$0")" || exit "$?"

BUILD_ENV="./build.env"
BUILD_DIR="./build"

source "$BUILD_ENV"

doNotRunAsRoot() {
	if [[ $EUID == 0 ]]; then
		echo "Don't run this script as root"
		exit 1
	fi
}

pressAnyKeyToContinue() {
	read -n 1 -s -r -p "Press any key to continue"
	echo
}

printHeader() {
	clear
	echo "WRT Build menu"
	echo
}

main() {
	doNotRunAsRoot
	while true; do
		clear
		printHeader
		echo "1. Select device config"
		echo "2. Manual config"
		echo "3. Debug mode (shell)"
		echo
		echo "0. Quit"
		echo
		read -rp "> " select

		case "$select" in
		1)
			echo "Not implemented yet"
			pressAnyKeyToContinue
			;;
		2)
			echo "Not implemented yet"
			pressAnyKeyToContinue
			;;
		3)
			echo "Not implemented yet"
			pressAnyKeyToContinue
			;;
		0)
			exit 0
			;;
		esac
	done
}

main
