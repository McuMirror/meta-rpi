#!/bin/bash

MACHINE=raspberrypi2

BOOTLDRFILES="bcm2835-bootfiles-20151021.stamp \
              bootcode.bin \
              cmdline.txt \
              config.txt \
              fixup_cd.dat \
              fixup_db.dat \
              fixup_x.dat \
              start_cd.elf \
              start_db.elf \
              start.elf \
              start_x.elf"

OVERLAYDTBS="hifiberry-amp-overlay.dtb \
             hifiberry-dac-overlay.dtb \
             hifiberry-dacplus-overlay.dtb \
             i2c-rtc-overlay.dtb \
             iqaudio-dac-overlay.dtb \
             iqaudio-dacplus-overlay.dtb \
             lirc-rpi-overlay.dtb \
             pps-gpio-overlay.dtb \
             w1-gpio-overlay.dtb \
             w1-gpio-pullup-overlay.dtb"

KERNELFILES="Image \
             Image-bcm2709-rpi-2-b.dtb"

if [ "x${1}" = "x" ]; then
	echo -e "\nUsage: ${0} <block device>\n"
	exit 0
fi

if [ ! -d /media/card ]; then
	echo "Temporary mount point [/media/card] not found"
	exit 1
fi

if [ -z "$OETMP" ]; then
	echo -e "\nWorking from local directory"
	SRCDIR=.
else
	echo -e "\nOETMP: $OETMP"

	if [ ! -d ${OETMP}/deploy/images/${MACHINE} ]; then
		echo "Directory not found: ${OETMP}/deploy/images/${MACHINE}"
		exit 1
	fi

	SRCDIR=${OETMP}/deploy/images/${MACHINE}
fi 

for f in ${BOOTLDRFILES}; do
	if [ ! -f ${SRCDIR}/bcm2835-bootfiles/${f} ]; then
		echo "Bootloader file not found: ${SRCDIR}/bcm2835-bootfiles/$f"
		exit 1
	fi
done

for f in ${OVERLAYDTBS}; do
	if [ ! -f ${SRCDIR}/Image-${f} ]; then
		echo "Overlay dtb not found: ${SRCDIR}/Image-${f}"
		exit 1
	fi
done
	
if [ ! -f ${SRCDIR}/Image ]; then
	echo "Kernel file not found: ${SRCDIR}/Image"
	exit 1
fi

if [ ! -f ${SRCDIR}/Image-bcm2709-rpi-2-b.dtb ]; then
	echo "DTB file not found: ${SRCDIR}/Image-bcm2709-rpi-2-b.dtb"
	exit 1
fi

DEV=/dev/${1}1

if [ ! -b ${DEV} ]; then
	echo -e "\nBlock device not found: ${DEV}\n"
	exit 1
fi

echo "Formatting FAT partition on ${DEV}"
sudo mkfs.vfat -F 32 ${DEV} -n BOOT

echo "Mounting ${DEV}"
sudo mount ${DEV} /media/card

echo "Copying bootloader files"
for f in ${BOOTLDRFILES}; do
	sudo cp ${SRCDIR}/bcm2835-bootfiles/${f} /media/card

	if [ $? -ne 0 ]; then
		echo "Error copying ${f}"
		sudo umount ${DEV}
		exit 1
	fi
done

echo "Copying overlay dtbs"
sudo mkdir /media/card/overlays

if [ $? -ne 0 ]; then
	echo "Error creating overlays directory"
	sudo umount ${DEV}
	exit 1
fi

echo "Copying overlay dtbs"
for f in ${OVERLAYDTBS}; do
	sudo cp ${SRCDIR}/Image-${f} /media/card/overlays/${f}

	if [ $? -ne 0 ]; then
		echo "Error copying $f"
		sudo umount ${DEV}
		exit 1
	fi
done

echo "Copying kernel"
sudo cp ${SRCDIR}/Image /media/card/kernel7.img

if [ $? -ne 0 ]; then
	echo "Error copying kernel"
	sudo umount ${DEV}
	exit 1
fi
 
echo "Copying rpi2 dtb"
sudo cp ${SRCDIR}/Image-bcm2709-rpi-2-b.dtb /media/card/bcm2709-rpi-2-b.dtb

if [ $? -ne 0 ]; then
	echo "Error copying rpi2 dtb"
	sudo umount ${DEV}
	exit 1
fi

echo "Unmounting ${DEV}"
sudo umount ${DEV}

echo "Done"

