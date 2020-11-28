#!/usr/bin/env bash

# Check this system has ccache
check_ccache()
{
	type ccache
	if [ "$?" -eq "0" ]; then
		CCACHE=ccache
	fi
}

check_ccache

rm -f output/*
rm -f arch/arm/boot/zImage
rm -f arch/arm/boot/dts/exynos4412-odroidu3.dtb

if ! [ -d output ]; then
	mkdir output
fi

if ! [ -e .config ]; then
	make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- exynos_defconfig
fi

make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- zImage -j 2
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- exynos4412-odroidu3.dtb

cp arch/arm/boot/zImage ./output/
cp arch/arm/boot/dts/exynos4412-odroidu3.dtb ./output

# Check kernel version from Makefile
_major_version=$(cat Makefile | grep "^VERSION = " | awk '{print $3}')
_minor_version=$(cat Makefile | grep "^PATCHLEVEL = " | awk '{print $3}')
_extra_version=$(cat Makefile | grep "^EXTRAVERSION = " | awk '{print $3}')
_version=${_major_version}.${_minor_version}${_extra_version}

cd output
tar cf linux-${_version}-exynos4412-arm.tar zImage exynos4412-odroidu3.dtb
