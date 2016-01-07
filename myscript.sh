#!/bin/bash

#echo "All clean"
#make distclean

#echo "Config Odroidxu3"
#make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- odroidxu3_defconfig

echo "Make Device Tree B"
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- exynos5422-odroidxu3.dtb

echo "Make zImage"
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- zImage -j 5

echo "cp exynos5422-odroidxu3.dtb & zImage"
cp arch/arm/boot/dts/exynos5422-odroidxu3.dtb ./
cp arch/arm/boot/zImage ./

echo "tar : xu3_kernel.tar"
tar cf xu3_kernel.tar zImage exynos5422-odroidxu3.dtb

echo "Script Finish"
