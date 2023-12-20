# Overview
This project will modify an Ubuntu Desktop 22.04 ISO into an ubuntu autoinstaller.  The ISO is built in a docker container to help with portability.

## Requirements
- Linux Host (may work on MacOS and Linux with docker command tweaks)
- Docker installed on the host
- NOTE: If using this autoinstaller ISO to install arctica, it is not currently compatiable with NVME internal drives, only SATA drives. If you would like to install arctica on an NVME drive you must first install vanilla ubuntu manually and then import the arctica binary.

## Setup
These setup steps only need to be done once on the build machine.

1. [Install Docker Engine](https://docs.docker.com/engine/install/)
	
2. After installing Docker Engine, follow directions to [Managee Docker as non-root-user](https://docs.docker.com/engine/install/linux-postinstall/)

3. Now you are ready to build the docker image 
	```
	./docker.sh -b
	```
## Run the docker image to create new ISO
First, copy the latest Arctica binary into the `./builder/iso-overlay` directory before building the iso, the binary must be named `Arctica`.

To start an ISO build, run the following command:
```
./docker.sh -r ./build.sh
```
If the build is successful, the ISO will be in the `work/out` directory.

For debbuging, you can launch directly into the container shell:
```
./docker.sh -r
```

> **NOTE:**  The Ubuntu ISO will be downloaded during the build process.  The ISO is stored in the `work/cache` directory.  If another build is done later, the ISO will be checked in the cache directory. If the ISO is valid, it will not be downloaded again.


## Changing the "first-run" script
There is a first-run script added to the ISO that will be run the first time the OS boots after a successful install.  This script is located at: `builder/iso-overlay/arctica-first-run.sh`
