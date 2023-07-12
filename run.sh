#!/usr/bin/env bash

cd "$(dirname "$0")" || exit "$?"

BUILD_ENV_PATH="./build.env"
SCRIPT_PATH="./build.sh"
OUTPUT_DIR="./output"
CONFIG_DIR="./config"
SELECTED_DEVICE=""
SELECTED_FIRMWARE=""
SELECTED_FIRMWARE_REPO=""
SELECTED_FIRMWARE_VERSION=""
SELECTED_FIRMWARE_DEPS=""
DOCKER_BUILD_PATH="/home/build/wrt"
CACHE_VOLUME=""
CONFIG_VOLUME=""
OUTPUT_VOLUME="$OUTPUT_DIR:$DOCKER_BUILD_PATH/output_dir"
BUILD_SCRIPT_VOLUME="$SCRIPT_PATH:$DOCKER_BUILD_PATH/$SCRIPT_PATH"
SET_CLEAN_LEVEL="none"
SET_VERBOSE_STATUS="off"

source "$BUILD_ENV_PATH"

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
	WRT_MAJOR_VERSION=$(echo "$SELECTED_FIRMWARE_VERSION" | sed -E 's/.*-([0-9]+)\..*/\1/')

	if [[ $SELECTED_FIRMWARE == "OPENWRT" ]]; then
		if [[ "$SELECTED_FIRMWARE_VERSION" == "master" || "$WRT_MAJOR_VERSION" -ge 21 ]]; then
			echo "Setting dependencies for OpenWRT 21.x.x and above..."
			SELECTED_FIRMWARE_DEPS="$OPENWRT_CURRENT_DEPENDENCIES"
		elif [[ "$WRT_MAJOR_VERSION" -le 19 && "$SELECTED_FIRMWARE_VERSION" != "master" ]]; then
			echo "Setting dependencies for OpenWRT 19.x.x and below..."
			SELECTED_FIRMWARE_DEPS="$OPENWRT_OLD_DEPENDENCIES"
		fi
	elif [[ $SELECTED_FIRMWARE == "LIBRECMC" ]]; then
		echo "Setting dependencies for LibreCMC..."
		SELECTED_FIRMWARE_DEPS="$LIBRECMC_CURRENT_DEPENDENCIES"
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
		-e GET_CLEAN_LEVEL="$SET_CLEAN_LEVEL" \
		-e GET_VERBOSE_STATUS="$SET_VERBOSE_STATUS" \
		-v "$BUILD_SCRIPT_VOLUME" \
		-v "$CACHE_VOLUME" \
		-v "$OUTPUT_VOLUME" \
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
	firmwareDirs=(./config/*) # Get dir list.

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
	arg="$1"
	# Fetch and select firmware version.
	selectVersionAndRunBuild() {
		OPENWRT_VERSIONS=()

		# Read build.env file line by line and checks each line for pattern match.
		while IFS= read -r line; do
			if [[ $line =~ ^"${SELECTED_FIRMWARE}"_BRANCH_.* ]]; then
				value=$(echo "$line" | cut -d'=' -f2 | tr -d '"')
				OPENWRT_VERSIONS+=("$value")
			fi
		done <"$BUILD_ENV_PATH"

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
					makeBuild "$arg"
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
			selectVersionAndRunBuild "$arg"
			;;
		2)
			SELECTED_FIRMWARE="LIBRECMC"
			SELECTED_FIRMWARE_REPO="$LIBRECMC_REPO"
			selectVersionAndRunBuild "$arg"
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

cleanMenu() {
	while :; do
		printHeader
		echo "Select clean level:"
		echo "1. none"
		echo "2. clean"
		echo "3. targetclean"
		echo "4. dirclean"
		echo "5. config-clean"
		echo "6. distclean"
		echo
		echo "0. Back"
		echo
		echo "More info: https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#cleaning_up"
		echo

		read -rp "> " select
		case "$select" in
		1)
			SET_CLEAN_LEVEL="none"
			break
			;;
		2)
			SET_CLEAN_LEVEL="clean"
			break
			;;
		3)
			SET_CLEAN_LEVEL="targetclean"
			break
			;;
		4)
			SET_CLEAN_LEVEL="dirclean"
			break
			;;
		5)
			SET_CLEAN_LEVEL="config-clean"
			break
			;;
		6)
			SET_CLEAN_LEVEL="distclean"
			break
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
	mkdir -p "$OUTPUT_DIR"

	while :; do
		printHeader
		echo "1. Select device config"
		echo "2. Manual config"
		echo "3. Enter container shell"
		echo
		echo "8. Clean level $SET_CLEAN_LEVEL"
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
			manualConfigMenu manual
			;;
		3)
			manualConfigMenu shell
			;;
		8)
			cleanMenu
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
