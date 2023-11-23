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
DOCKER_TAG=""
DOCKER_BUILD_PATH="/home/build/wrt"
CACHE_VOLUME=""
CONFIG_VOLUME=""
OUTPUT_VOLUME="$OUTPUT_DIR:$DOCKER_BUILD_PATH/output_dir"
BUILD_SCRIPT_VOLUME="$SCRIPT_PATH:$DOCKER_BUILD_PATH/$SCRIPT_PATH"
SET_CLEAN_LEVEL=""
PRINT_CLEAN_LEVEL=""
SET_VERBOSE_STATUS=""
PRINT_VERBOSE_STATUS=""

# Text format.
NORMAL='\033[0m'
BOLD='\033[1m'
BLUE='\033[1;34m'
LIGHTBLUE='\033[1;94m'
LIGHTRED='\033[0;91m'

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

asciiLogo() {
	cat <<'EOF'
   _ _ _  _____  _____    _____       _  _    _           
  | | | || __  ||_   _|  | __  | _ _ |_|| | _| | ___  ___ 
  | | | ||    -|  | |    | __ -|| | || || || . || -_||  _|
  |_____||__|__|  |_|    |_____||___||_||_||___||___||_|  
                                                          
EOF
}

printHeader() {
	clear
	echo -e "${BLUE}${BOLD}"
	asciiLogo
	echo -e "${NORMAL}"
	echo -e "${LIGHTBLUE}Choose an option:${NORMAL}"
	echo
}

menuItem() {
	local number="$1"
	local text="$2"
	echo -e "${LIGHTBLUE}$number.${NORMAL} $text"
}

printUrgentText() {
	local value="$1"
	echo -e "${LIGHTRED}${BOLD}$value${NORMAL}"
}

printNonUrgentText() {
	local value="$1"
	echo -e "${BOLD}$value${NORMAL}"
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
		-t "$DOCKER_TAG" .
}

cockerRun() {
	local dockerArg="$1"
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
		"$DOCKER_TAG" "$dockerArg"
}

makeBuild() {
	local dockerArg="$1"
	getDepsList
	dockerBuild
	cockerRun "$dockerArg"
	pressAnyKeyToContinue
}

firmwareMenu() {
	getVersion() {
		local firmwareDir="$1"
		source "$CONFIG_DIR/$firmwareDir/version.env"
		SELECTED_FIRMWARE="$FIRMWARE_NAME"
		SELECTED_FIRMWARE_REPO="$FIRMWARE_REPO"
		SELECTED_FIRMWARE_VERSION="$FIRMWARE_BRANCH"
		DOCKER_TAG="$(echo "$SELECTED_FIRMWARE" | tr '[:upper:]' '[:lower:]')_$(echo "$SELECTED_FIRMWARE_VERSION" | tr '[:upper:]' '[:lower:]')"
	}

	local firmwareDirs=""
	local selectedFirmware=""
	firmwareDirs=(./config/*) # Get dir list.

	while :; do
		printHeader
		for i in "${!firmwareDirs[@]}"; do
			menuItem "$((i + 1))" "${firmwareDirs[$i]#./config/}"
		done
		echo
		menuItem "0" "Back"
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
			# List firmware versions.
			for i in "${!OPENWRT_VERSIONS[@]}"; do
				menuItem "$((i + 1))" "${OPENWRT_VERSIONS[$i]}"
			done
			echo
			menuItem "0" "Back"
			echo

			read -rp "> " select
			# Validate selection is a number and within the available options.
			if [[ "$select" =~ ^[0-9]+$ ]]; then
				if ((select >= 1)) && ((select <= ${#OPENWRT_VERSIONS[@]})); then
					SELECTED_FIRMWARE_VERSION="${OPENWRT_VERSIONS[$((select - 1))]}" # Set the selected version.
					makeBuild "$arg"
				elif ((select == 0)); then
					return 42
				fi
			fi
		done
	}

	while :; do
		printHeader
		menuItem "1" "OpenWRT"
		menuItem "2" "LibreCMC"
		echo
		menuItem "0" "Back"
		echo

		read -rp "> " select
		case "$select" in
		1)
			SELECTED_FIRMWARE="OPENWRT"
			SELECTED_FIRMWARE_REPO="$OPENWRT_REPO"
			selectVersionAndRunBuild
			;;
		2)
			SELECTED_FIRMWARE="LIBRECMC"
			SELECTED_FIRMWARE_REPO="$LIBRECMC_REPO"
			selectVersionAndRunBuild
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
		menuItem "1" "clean"
		menuItem "2" "targetclean"
		menuItem "3" "dirclean"
		menuItem "4" "config-clean"
		menuItem "5" "distclean"
		echo
		menuItem "0" "none"
		echo
		echo "More info: https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#cleaning_up"
		echo

		read -rp "> " select
		case "$select" in
		1)
			SET_CLEAN_LEVEL="clean"
			PRINT_CLEAN_LEVEL="$(printUrgentText $SET_CLEAN_LEVEL)"
			break
			;;
		2)
			SET_CLEAN_LEVEL="targetclean"
			PRINT_CLEAN_LEVEL="$(printUrgentText $SET_CLEAN_LEVEL)"
			break
			;;
		3)
			SET_CLEAN_LEVEL="dirclean"
			PRINT_CLEAN_LEVEL="$(printUrgentText $SET_CLEAN_LEVEL)"
			break
			;;
		4)
			SET_CLEAN_LEVEL="config-clean"
			PRINT_CLEAN_LEVEL="$(printUrgentText $SET_CLEAN_LEVEL)"
			break
			;;
		5)
			SET_CLEAN_LEVEL="distclean"
			PRINT_CLEAN_LEVEL="$(printUrgentText $SET_CLEAN_LEVEL)"
			break
			;;
		0)
			SET_CLEAN_LEVEL="none"
			PRINT_CLEAN_LEVEL="$(printNonUrgentText $SET_CLEAN_LEVEL)"
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
		PRINT_VERBOSE_STATUS="$(printUrgentText $SET_VERBOSE_STATUS)"
	elif [[ "$SET_VERBOSE_STATUS" == "on" ]]; then
		SET_VERBOSE_STATUS="off"
		PRINT_VERBOSE_STATUS="$(printNonUrgentText $SET_VERBOSE_STATUS)"
	fi
}

main() {
	doNotRunAsRoot
	mkdir -p "$OUTPUT_DIR"

	SET_CLEAN_LEVEL="none"
	PRINT_CLEAN_LEVEL="$(printNonUrgentText $SET_CLEAN_LEVEL)"
	SET_VERBOSE_STATUS="off"
	PRINT_VERBOSE_STATUS="$(printNonUrgentText $SET_VERBOSE_STATUS)"

	while :; do
		printHeader
		menuItem "1" "Select device config"
		menuItem "2" "Manual config"
		menuItem "3" "Enter container shell"
		echo
		menuItem "8" "Clean level: $PRINT_CLEAN_LEVEL"
		menuItem "9" "Verbose mode: $PRINT_VERBOSE_STATUS"
		echo
		menuItem "0" "Quit"
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
