#!/bin/bash
#
# Copyright © 2015, Tarun Kapadia "tarun93" <tarunmyid@gmail.com>
#
# Custom build script
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Please maintain this if you use this script or any part of it
#
# Colorize and add text parameters
grn=$(tput setaf 2)             #  green
txtbld=$(tput bold)             # Bold
bldgrn=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
txtrst=$(tput sgr0)             # Reset

# PATH FOR KERNEL DIRECTORIES N OUT FOLDER
KERNEL_DIR=$PWD
KERNEL_OUT=$KERNEL_DIR/zip/kernel_zip

#Toolchains path

#STOCK GCC 
GCC4_8=~/toolchains/arm-eabi-4.8s/bin/arm-eabi

#SABERMOD TOOLCHAINS
sm4_9=~/toolchains/Sabermod-arm-eabi-4.9/bin/arm-eabi
sm5_1=~/toolchains/Sabermod-arm-eabi-5.1/bin/arm-eabi
sm5_2=~/toolchains/Sabermod-arm-eabi-5.2/bin/arm-eabi
sm6_0=~/toolchains/Sabermod-arm-eabi-6.0/bin/arm-eabi

#UBERTC TOOLCHAINS
ub4_9=~/toolchains/UBERTC-arm-eabi-4.9/bin/arm-eabi
ub5_1=~/toolchains/UBERTC-arm-eabi-5.1/bin/arm-eabi
ub6_0=~/toolchains/UBERTC-arm-eabi-6.0/bin/arm-eabi

#LINRO CORTEX OPTIMIZED TOOLCHAINS
l4_8a7=~/toolchains/arm-cortex_a7-linux-gnueabihf-linaro_4.9/bin/arm-cortex_a7-linux-gnueabihf
l4_9a15=~/toolchains/arm-cortex_a7-linux-gnueabihf-linaro_4.9/bin/arm-cortex_a7-linux-gnueabihf

l5_2=~/toolchains/linaro-5.2/bin/arm-eabi

#ENTER THE TOOLCHAIN PATH 

echo -e "${bldgrn} Setting up Build Environment ${txtrst}"
export KBUILD_BUILD_USER="Buildbot"
export KBUILD_BUILD_HOST="GOD'S_KERNEL_R4"
export ARCH=arm
export CROSS_COMPILE=$ub6_0-

#Clean the build
rm -rf $KERNEL_OUT/dtb
rm -rf $KERNEL_OUT/zImage
rm -rf $KERNEL_OUT/modules/*
echo -n "${bldblu} Do you wanna clean the build (y/n)? ${txtrst}"
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo -e "${bldgrn} Cleaning the old build ${txtrst}"
    make mrproper
    rm -rf $KERNEL_OUT/../*.zip
    rm -rf $KERNEL_DIR/arch/arm/boot/*.dtb
fi
     
echo -e "${bldgrn} Building Defconfig ${txtrst}"
make cancro_user_defconfig
     
echo -n "${bldblu}Do you wanna make changes in the defconfig (y/n)? ${txtrst}"
read answer
if echo "$answer" | grep -iq "^y" ;then
        echo -e "${bldgrn} Building Defconfig GUI ${txtrst}"
    make menuconfig
     
    echo -n "${bldblu}Do you wanna save the changes in the defconfig (y/n)? ${txtrst}"
    read answer
	    if echo "$answer" | grep -iq "^y" ;then
	        echo -e "${bldgrn} Building Defconfig GUI ${txtrst}"
	        cp -f .config $KERNEL_DIR/arch/arm/configs/cancro_user_defconfig
    fi
fi
     
# Time of build startup
res1=$(date +%s.%N)
     
echo -e "${bldgrn}.....................................................................${txtrst}"
echo -e "${bldgrn}...................${bldblu}STARTING.GOD'S.KERNEL.BUILD${bldgrn}.......................${txtrst}"
echo -e "${bldgrn}.....................................................................${txtrst}"
make -j12
mv $KERNEL_DIR/arch/arm/boot/zImage  $KERNEL_OUT/zImage
     
if ! [ -a  $KERNEL_OUT/zImage ];
    then
    echo -e "${bldblu} Kernel Compilation failed! Fix the errors! ${txtrst}"
    exit 1
fi
     
echo "${bldgrn}Copying modules${txtrst}"
find . -name '*.ko' -exec cp {} $KERNEL_OUT/modules/ \;

#MAKE SURE YOU GIVE THE CORRECT PATH FOR THE TOOLCHAIN
echo "${bldgrn}Stripping modules for size${txtrst}"
$ub6_0-strip --strip-unneeded $KERNEL_OUT/modules/*.ko

echo -e "${bldgrn} DTB Build  ${txtrst}"
.$KERNEL/zip/dtbToolCM -2 -o $KERNEL_OUT/dtb -s 2048 -p scripts/dtc/ arch/arm/boot/
     
if ! [ -a $KERNEL_OUT/dtb ];
    then
    echo -e "${bldblu} DTB Compilation failed! Fix the errors! ${txtrst}"
    exit 1
fi

echo -e "${bldgrn} Zipping the Kernel Build  ${txtrst}"
cd $KERNEL_OUT/
zip -r9 ../GK_CANCRO_MM_LP_KK_MIUI_$(date +%d%m%Y_%H%M) .

cd ../
ZIP=$(find *$(date +%d%m%Y_%H%M).zip)
cd $KERNEL_DIR
    
# Get elapsed time
res2=$(date +%s.%N)
echo "${bldgrn}$ZIP Compiled Succuessfully in ${txtrst}${bldgrn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"
