#!/usr/bin/env bash

cd "$(dirname "$0")" || exit "$?"

BUILD_ENV="./build.env"
BUILD_DIR="./build"
BUILDS_VOLUME="$BUILD_DIR:/home/build/wrt/bin"
SELECTED_FIRMWARE=""
SELECTED_FIRMWARE_REPO=""
SELECTED_FIRMWARE_VERSION=""
SELECTED_FIRMWARE_DEPS=""

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

getDepsList() {
	OPENWRT_MAJOR_VERSION=$(echo "$SELECTED_FIRMWARE_VERSION" | sed -E 's/.*-([0-9]+)\..*/\1/')
	if [[ "$SELECTED_FIRMWARE_VERSION" == "master" || "$OPENWRT_MAJOR_VERSION" -ge 21 ]]; then
		echo "Setting dependencies for OpenWRT 21.x.x and above..."
		SELECTED_FIRMWARE_DEPS="$OPENWRT_CURRENT_DEPS"
	elif [[ "$OPENWRT_MAJOR_VERSION" -le 19 && "$SELECTED_FIRMWARE_VERSION" != "master" ]]; then
		echo "Setting dependencies for OpenWRT 19.x.x and below..."
		SELECTED_FIRMWARE_DEPS="$OPENWRT_OLD_DEPS"
	fi
}

dockerBuild() {
	docker build \
		--build-arg WRT_DEPS="$SELECTED_FIRMWARE_DEPS" \
		--build-arg WRT_FIRMWARE="$SELECTED_FIRMWARE_REPO" \
		--build-arg WRT_BRANCH="$SELECTED_FIRMWARE_VERSION" \
		-t "${SELECTED_FIRMWARE,,}_${SELECTED_FIRMWARE_VERSION,,}" .
}

cockerRun() {
	local dockerArg
	dockerArg="$1"
	docker run -it -u "$(id -u):$(id -g)" -v "$BUILDS_VOLUME" \
		"${SELECTED_FIRMWARE,,}_${SELECTED_FIRMWARE_VERSION,,}" "$dockerArg"
}

manualConfigMenu() {
	# Fetch available versions for a selected firmware.
	getVersions() {
		local firmwareName="$1"
		OPENWRT_VERSIONS=()
		# Read build.env file line by line and checks each line for pattern match.
		while IFS= read -r line; do
			if [[ $line =~ ^"${firmwareName}"_BRANCH_.* ]]; then
				value=$(echo "$line" | cut -d'=' -f2 | tr -d '"')
				OPENWRT_VERSIONS+=("$value")
			fi
		done <"$BUILD_ENV"
	}

	# List and select firmware version.
	selectVersion() {
		getVersions "$SELECTED_FIRMWARE"
		while :; do
			printHeader
			echo "Select version:"
			# List firmware versions.
			for i in "${!OPENWRT_VERSIONS[@]}"; do
				echo "$(("$i" + 1)). ${OPENWRT_VERSIONS[$i]}"
			done
			echo
			echo "0. Back"
			echo

			read -rp "> " choice
			# Validate selection is a number and within the available options.
			if [[ "$choice" =~ ^[0-9]+$ ]]; then
				if ((choice >= 1)) && ((choice <= ${#OPENWRT_VERSIONS[@]})); then
					SELECTED_FIRMWARE_VERSION="${OPENWRT_VERSIONS[$((choice - 1))]}" # Set the selected version.
					return 0
				elif ((choice == 0)); then
					return 42
				fi
			else
				continue
			fi
		done
	}

	makeManualConfig() {
		getDepsList
		dockerBuild
		cockerRun manual
		pressAnyKeyToContinue
	}

	while :; do
		printHeader
		echo "Select firmware:"
		echo "1. OpenWRT"
		echo "2. LibreCMC"
		echo
		echo "0. Back"
		echo

		read -rp "> " select
		case "$select" in
		1)
			SELECTED_FIRMWARE="OPENWRT"
			SELECTED_FIRMWARE_REPO="$OPENWRT_REPO"
			if selectVersion; then
				makeManualConfig
			fi
			;;
		2)
			echo "Not implemented yet"
			pressAnyKeyToContinue
			;;
		0)
			break
			;;
		*)
			continue
			;;
		esac
	done

}

main() {
	doNotRunAsRoot
	while :; do
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
			manualConfigMenu
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
