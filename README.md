```
 _ _ _  _____  _____    _____       _  _    _           
| | | || __  ||_   _|  | __  | _ _ |_|| | _| | ___  ___ 
| | | ||    -|  | |    | __ -|| | || || || . || -_||  _|
|_____||__|__|  |_|    |_____||___||_||_||___||___||_|  
                                                        
```
<p align="center">
  <strong>WRT-Based Firmware Builder</strong>
</p>


## Description
Welcome to the **WRT Builder**, a comprehensive, Dockerized solution designed to streamline the process of OpenWRT and LibreCMC firmware compilation. This solution automates the configuration and setup of the build environment, providing an easy and efficient way to compile your own firmware.

## Table of contents
- [Features](#features)
- [Devices](#devices)
- [Usage](#usage)
- [Additional Resources](#additional-resources)
- [Contributing](#contributing)
- [License](#license)

## Features
**Automated build environment setup**: Make use of Docker to quickly set up the build environment, saving both time and effort.

**Predefined and custom build configurations**: Choose from a selection of predefined configurations suitable for common use-cases. For a more customized firmware, there's also an option to manually create a build configuration.

**Interactive menu**: A user-friendly menu guides through the process, offering the choice of using a predefined configuration or creating a custom one.


## Devices
The script supports a variety of devices. Below is a list of supported devices along with links to their respective info within the repository:

- **TP-link TL-WR841N/ND v8/v9 (4mb flash)**:
  - [OpenWRT](./config/tl_wr841nd_v8_v9_4mb/openwrt/README.md)
  - [LibreCMC](./config/tl_wr841nd_v8_v9_4mb/librecmc/README.md)


## Usage
The script can be run using the following command:
```bash
bash run.sh
```

### Options

#### 1. Select device config
Select device configuration.

#### 2. Manual config
Specify firmware and version manually.

#### 3. Enter container shell
Access the Docker container shell.

#### 8. Clean level
Access cleaning options for the build environment. [More info](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#cleaning_up).

#### 9. Verbose mode
Toggle verbose mode `on/off`. Provides detailed script operation information.

#### 0. Quit
Exit the script.

### Running the script with command line arguments
The script supports command line arguments for specifying the device, firmware, and version. The command syntax is as follows:
```bash
bash run.sh -d <device> -f <firmware> -v <version>
```

Replace ```<device>```, ```<firmware>```, and ```<version>``` with the desired values. For example:
```bash
bash run.sh -d "tl_wr841nd_v8_v9_4mb" -f "openwrt" -v "v19.07.10"
```
Executing the above command initiates the script and automatically builds the specified firmware for the given device.

### Output Directory
Upon successful completion of the script, an `output/` directory is generated. This directory comprises two subdirectories:

- `packages/`: Stores the compiled packages.
- `targets/`: Stores the compiled firmwares.


## Additional Resources
For more information about OpenWRT and LibreCMC, please refer to their official documentation:

- [OpenWRT Build Documentation](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem)
- [LibreCMC Build Documentation](https://librecmc.org/fossil/librecmc/wiki?name=How_To_Build_libreCMC)


## Contributing
Your help is valuable to make this script even better. If you've managed to compile firmware for a device that's not currently listed, please consider contributing. You can do this by adding the device to the list and providing a link to a new documentation file with more detailed information about the device. Every contribution enriches this project and is highly appreciated.


## License
This software is published under the GPL-3.0 License license.
