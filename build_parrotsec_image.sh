#!/bin/bash

# (C) 2015-2017 Francesco Bonanno <mibofra@frozenbox.org>

# Write or create raspberry-pi 1, 2 and 3 image

if [ ${EUID} -ne 0 ]; then
  echo "this tool must be run as root"
  exit 1
fi

device=$1
if ! [ -b ${device} ]; then
  echo "${device} is not a block device"
  exit 1
fi

bootsize="64M"

relative_path=`dirname $0`

# locate path of this script
absolute_path=`cd ${relative_path}; pwd`

# define destination folder where created image file will be stored
buildenv=`cd ${absolute_path}; mkdir -p parrotsec-rpi; cd parrotsec-rpi; pwd`
# buildenv="/tmp/rpi"

# cd ${absolute_path}

rootfs="${buildenv}/rootfs"
bootfs="${rootfs}/boot"


if [ "${device}" == "" ]; then
  echo "no block device given, just creating an image"
  mkdir -p ${buildenv}
  image="${buildenv}/parrot-armhf-image.img"
  dd if=/dev/zero of=${image} bs=1MB count=7168
  device=`losetup -f --show ${image}`
  echo "image ${image} created and mounted as ${device}"
else
  image=""
  dd if=/dev/zero of=${device} bs=512 count=1
fi

fdisk ${device} << EOF
n
p
1

+${bootsize}
t
c
n
p
2


w
EOF


if [ "${image}" != "" ]; then
  losetup -d ${device}
  device=`kpartx -va ${image} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
  device="/dev/mapper/${device}"
  bootp=${device}p1
  rootp=${device}p2
else
  if ! [ -b ${device}1 ]; then
    bootp=${device}p1
    rootp=${device}p2
    if ! [ -b ${bootp} ]; then
      echo "uh, oh, something went wrong, can't find bootpartition neither as ${device}1 nor as ${device}p1, exiting."
      exit 1
    fi
  else
    bootp=${device}1
    rootp=${device}2
  fi
fi

sleep 1

mkfs.vfat ${bootp}
mkfs.btrfs ${rootp}

mkdir -p ${rootfs}
mkdir -p ${bootfs}

mount ${rootp} ${rootfs}

echo "Unpacking rootfs tarball"

tar -C ${rootfs} --transform 's,binary,.,' --show-transformed -xzf ${absolute_path}/*.tar.gz

sleep 1

echo "Unpacked rootfs tarball"

mkdir rpi-firmware

echo "Copying firmware to boot partition"

cp -pr ${bootfs}/* rpi-firmware/ 

rm -fr ${bootfs}/*

mount ${bootp} ${bootfs}

cp -pr rpi-firmware/* ${bootfs}/

sleep 1

echo "Copied firmware to boot partition"

echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=btrfs elevator=deadline fsck.repair=yes rootwait quiet" > ${bootfs}/cmdline.txt

echo "proc            /proc           proc    defaults        0       0
/dev/mmcblk0p1  /boot           vfat    defaults        0       0
/dev/mmcblk0p2  /               btrfs    errors=remount-ro,noatime,nodiratime,compress=lzo,ssd 0       1
" > ${rootfs}/etc/fstab

echo "vchiq
snd_bcm2835
" >> ${rootfs}/etc/modules

sync
sleep 15

cd

umount -l ${bootp}

umount -l ${rootp}

dmsetup remove_all

echo "writing ${image}"

if [ "${image}" != "" ]; then
  kpartx -d ${image}
  md5sum ${image} > ${image}.md5sum.txt
  sha1sum ${image} > ${image}.sha1sum.txt
  echo "created image ${image}"
fi

echo "done."
