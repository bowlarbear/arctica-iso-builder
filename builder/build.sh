#!/bin/bash

source utils.sh

ISO_LABEL=arctica-ubuntu-22.04

# time used to track build time
START_TIME=$SECONDS

# useful dirs
WORK_DIR=~/work
CACHE_DIR=$WORK_DIR/cache
BUILDER_DIR=~/builder

# source ISO info
SOURCE_ISO_NAME="ubuntu-source-iso"
SOURCE_ISO_URL=https://old-releases.ubuntu.com/releases/jammy/ubuntu-22.04.4-desktop-amd64.iso
SOURCE_ISO_SHASUM="b98dac940a82b110e6265ca78d1320f1f7103861e922aa1a54e4202686e9bbd3"
SOURCE_ISO_FILE=$CACHE_DIR/$(basename $SOURCE_ISO_URL)


function help() {
    echo -e "Basic usage: ./build.sh"\\n
    echo -e "The following switches are recognized."
    echo -e "   -h --Displays this help message."
    echo -e "Example: ./build.sh -r"\\n
    exit 1
}

function clean_up() {
    sudo umount -q content/base > /dev/null 2>&1
    sudo umount -q content/ol > /dev/null 2>&1
    sudo rm -fr content
}


# Start script
#######################################################

cd $WORK_DIR

# process options
while getopts hr FLAG; do
  case $FLAG in
    h)
      help
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -$FLAG not allowed."
      help
      ;;
  esac
done

NEW_ISO=${ISO_LABEL}-amd64.iso

# reset 
clean_up
# source ISO should be mounted ro, so it won't be deleted
rm *.iso > /dev/null 2>&1
rm -fr out

mkdir -p ${CACHE_DIR}

# download source iso
print_task "Download Source ISO"
download_package ${SOURCE_ISO_NAME} ${SOURCE_ISO_FILE} ${SOURCE_ISO_URL} ${SOURCE_ISO_SHASUM}

print_task "Validating Preseed Config"
if debconf-set-selections -v -c ${BUILDER_DIR}/iso-overlay/preseed.cfg; then
    echo
else
    # Error info will be printed by debconf-set-selections
    echo "Preseed validation falied (look for error above)"
    exit 1
fi

print_task "Create /content overlay"
# create ISO overlay directories
mkdir -p content/base 
mkdir -p content/upper
# work has to be empty on same filesystem as upper 
mkdir -p content/work
mkdir -p content/ol 
mkdir out

# mount original ISO to base
sudo mount ${SOURCE_ISO_FILE} content/base

# modify upper with our changes
print_task "Copying iso-overlay"
cp -a ${BUILDER_DIR}/iso-overlay/* content/upper

# mounts new content/ol that combines all the base,upper, and work layers
sudo mount -t overlay -o lowerdir=content/base,upperdir=content/upper,workdir=content/work non content/ol


# Now create ISO based on content/ol
# The options passed in here were created by running a option report on the original ISO
# For example,
# 	xorriso -indev source.iso -report_el_torito as_mkisofs
echo ""
print_task "Creating new ISO"
xorriso -as mkisofs -V "arctica-os" \
--grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:"$SOURCE_ISO_FILE" \
--protective-msdos-label \
-partition_cyl_align off \
-partition_offset 16 \
--mbr-force-bootable \
-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:9613460d-9623527d::"$SOURCE_ISO_FILE" \
-appended_part_as_gpt \
-iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
-c '/boot.catalog' \
-b '/boot/grub/i386-pc/eltorito.img' \
-no-emul-boot \
-boot-load-size 4 \
-boot-info-table \
--grub2-boot-info \
-eltorito-alt-boot \
-e '--interval:appended_partition_2_start_2403365s_size_10068d:all::' \
-no-emul-boot \
-boot-load-size 10068 \
-o out/$NEW_ISO ./content/ol


if [ "$?" != "0" ]; then
    echo "ERROR: failed to create ISO"
    exit 1
fi

clean_up

ln -s out/$NEW_ISO new.iso

# Generate checksum of files in out/
pushd $(pwd) > /dev/null 
cd out
print_task "Generating MD5 sums"
md5sum * > hashes.md5
popd > /dev/null

ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo -e "\n\n"
echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
echo -e "Build Complete\n"
echo -e "ISO: work/out/$NEW_ISO\n"
echo -e "Build Duration: $ELAPSED_TIME seconds\n"
echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
