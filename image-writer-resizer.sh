#!/bin/bash

# (C) 2017 Francesco Bonanno <mibofra@frozenbox.org>

# Write and resize image on (micro)SD card for raspberry-pi 1, 2 and 3

if [ ${EUID} -ne 0 ]; then
  echo "this tool must be run as root"
  exit 1
fi

ddrescue=`command -v ddrescue`

if [ "${ddrescue}" == "" ]; then
  echo "You must install ddrescue first."
  exit 1
else
  echo "Good! ddrescue is installed under ${ddrescue}"
fi

parted=`command -v parted`

if [ "${parted}" == "" ]; then
  echo "You must install parted first."
  exit 1
else
  echo "Good! parted is installed under ${parted}"
fi

if [ -f *.img  ]; then
  echo "Image found"
else
  if [ -f *.img.tar.xz ]; then
    echo "Extracting the image"
    tar xvf *.img.tar.xz
  else
    echo "Build the image first!"
    exit 1
  fi
fi

echo "Writing the image"

device=$1
devicep2="${device}p2"

if ! [ -b ${device} ]; then
  echo "${device} is not a block device"
  exit 1
fi

if [ "${device}" == "" ]; then
  echo "no block device given, a block device must be given."
  exit 1
fi

if [[ ${device} =~ ^/dev/sd ]]; then
  devicep2="${device}2"
fi

ddrescue -D --force parrotsec-*-armhf-*.img ${device}

partprobe ${device}

parted ${device} << EOF
resizepart 2

quit
EOF

e2fsck -fy ${devicep2}

echo "Autoresizing the rootfs partition"

sudo resize2fs ${devicep2}
