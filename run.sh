#!/usr/bin/env bash

cd "$(dirname "$0")" || exit "$?"

BUILD_ENV="./build.env"
BUILD_DIR="./build"
CONFIG_DIR="./config"
SELECTED_DEVICE=""
SELECTED_FIRMWARE=""
SELECTED_FIRMWARE_REPO=""
SELECTED_FIRMWARE_VERSION=""
SELECTED_FIRMWARE_DEPS=""
DOCKER_BUILD_PATH="/home/build/wrt"
CACHE_VOLUME=""
CONFIG_VOLUME=""
BUILDS_VOLUME="$BUILD_DIR:$DOCKER_BUILD_PATH/bin"
SET_VERBOSE_STATUS="off"

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
		SELECTED_FIRMWARE_DEPS="$OPENWRT_CURRENT_DEPENDENCIES"
	elif [[ "$OPENWRT_MAJOR_VERSION" -le 19 && "$SELECTED_FIRMWARE_VERSION" != "master" ]]; then
		echo "Setting dependencies for OpenWRT 19.x.x and below..."
		SELECTED_FIRMWARE_DEPS="$OPENWRT_OLD_DEPENDENCIES"
	fi
}

dockerBuild() {
	docker build \
		--build-arg USERNAME="$USER" \
		--build-arg USERID="$UID" \
		--build-arg WRT_DEPENDENCIES="$SELECTED_FIRMWARE_DEPS" \
		--build-arg WRT_FIRMWARE_REPO="$SELECTED_FIRMWARE_REPO" \
		--build-arg WRT_BRANCH="$SELECTED_FIRMWARE_VERSION" \
		-t "${SELECTED_FIRMWARE,,}_${SELECTED_FIRMWARE_VERSION,,}" .
}

cockerRun() {
	local dockerArg
	dockerArg="$1"
	CACHE_VOLUME="${SELECTED_FIRMWARE}_${SELECTED_FIRMWARE_VERSION}_cache_volume:$DOCKER_BUILD_PATH"
	# Mount root of config dir when $SELECTED_DEVICE is empty is a feature (. ❛ ᴗ ❛.)
	CONFIG_VOLUME="$CONFIG_DIR/$SELECTED_DEVICE:$DOCKER_BUILD_PATH/device_config"

	docker run -it \
		-e GET_VERBOSE_STATUS="$SET_VERBOSE_STATUS" \
		-v "$CACHE_VOLUME" \
		-v "$BUILDS_VOLUME" \
		-v "$CONFIG_VOLUME" \
		"${SELECTED_FIRMWARE,,}_${SELECTED_FIRMWARE_VERSION,,}" "$dockerArg"
}

makeBuild() {
	local dockerArg
	dockerArg="$1"

	getDepsList
	dockerBuild
	cockerRun "$dockerArg"
	pressAnyKeyToContinue
}

firmwareMenu() {
	getVersion() {
		local firmwareDir
		firmwareDir="$1"
		source "$CONFIG_DIR/$firmwareDir/version.env"
		SELECTED_FIRMWARE="$FIRMWARE_NAME"
		SELECTED_FIRMWARE_REPO="$FIRMWARE_REPO"
		SELECTED_FIRMWARE_VERSION="$FIRMWARE_BRANCH"
	}

	local firmwareDirs
	local selectedFirmware
	# Get dir list.
	firmwareDirs=(./config/*)

	while :; do
		printHeader
		echo "Select firmware config:"
		for i in "${!firmwareDirs[@]}"; do
			echo "$(("$i" + 1)). ${firmwareDirs[$i]#./config/}"
		done
		echo
		echo "0. Back"
		echo

		read -rp "> " select
		# Validate selection is a number and within the available options.
		if [[ "$select" =~ ^[0-9]+$ ]]; then
			if ((select >= 1)) && ((select <= ${#firmwareDirs[@]})); then
				# Set chosen dir to variable.
				selectedFirmware="${firmwareDirs[$((select - 1))]##*/}"
				SELECTED_DEVICE="$selectedFirmware"
				if getVersion "$SELECTED_DEVICE"; then
					makeBuild preconfig
				fi
			elif ((choice == 0)); then
				return 42
			fi
		else
			continue
		fi
	done
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
				makeBuild manual
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

verboseMode() {
	if [[ "$SET_VERBOSE_STATUS" == "off" ]]; then
		SET_VERBOSE_STATUS="on"
	elif [[ "$SET_VERBOSE_STATUS" == "on" ]]; then
		SET_VERBOSE_STATUS="off"
	fi
}

main() {
	doNotRunAsRoot
	while :; do
		printHeader
		echo "1. Select device config"
		echo "2. Manual config"
		echo "3. Enter container shell"
		echo
		echo "9. Verbose mode $SET_VERBOSE_STATUS"
		echo
		echo "0. Quit"
		echo

		read -rp "> " select
		case "$select" in
		1)
			firmwareMenu
			;;
		2)
			manualConfigMenu
			;;
		3)
			echo "Not implemented yet"
			pressAnyKeyToContinue
			;;
		9)
			verboseMode
			;;
		0)
			exit 0
			;;
		esac
	done
}

main
