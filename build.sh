#!/bin/bash
 
# Colorize and add text parameters
grn=$(tput setaf 2)             #  green
txtbld=$(tput bold)             # Bold
bldgrn=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
txtrst=$(tput sgr0)             # Reset
 
KERNEL_DIR=~/mi3
KERNEL_OUT=~/mi3/zip/kernel_zip
STRIP=~/toolchains/arm-eabi-4.8s/bin/arm-eabi-strip
 
#Clean the build
echo -n "${bldblu} Do you wanna clean the build (y/n)? ${txtrst}"
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo -e "${bldgrn} Cleaning the old build ${txtrst}"
    make mrproper
    rm -rf $KERNEL_OUT/dt.img
    rm -rf $KERNEL_OUT/zImage
    rm -rf $KERNEL_OUT/../*.zip
    rm -rf $KERNEL_OUT/modules/*
    rm -rf $KERNEL_DIR/arch/arm/boot/*.dtb
    rm -rf $KERNEL_OUT/../kernel_zipmi4/dtb
    rm -rf $KERNEL_OUT/../kernel_zipmi4/zImage
    rm -rf $KERNEL_OUT/../kernel_zipmi4/../*.zip
    rm -rf $KERNEL_OUT/../kernel_zipmi4/modules/*
fi
     
echo -e "${bldgrn} Setting up Build Environment ${txtrst}"
export KBUILD_BUILD_USER="Tarun93"
export KBUILD_BUILD_HOST="GOD'S_KERNEL_R3"
export ARCH=arm
#export CROSS_COMPILE=~/toolchains/Sabermod-arm-eabi-5.2/bin/arm-eabi-
#export CROSS_COMPILE=/home/tarun93/toolchains/arm-cortex_a7-linux-gnueabihf-linaro_4.9/bin/arm-cortex_a7-linux-gnueabihf-
export CROSS_COMPILE=~/toolchains/arm-eabi-4.8s/bin/arm-eabi-
#export CROSS_COMPILE=~/toolchains/UBERTC-arm-eabi-6.0/bin/arm-eabi-
     
     
echo -e "${bldgrn} Building Defconfig ${txtrst}"
make cyanogen_cancro_defconfig
     
echo -n "${bldblu}Do you wanna make changes in the defconfig (y/n)? ${txtrst}"
read answer
if echo "$answer" | grep -iq "^y" ;then
        echo -e "${bldgrn} Building Defconfig GUI ${txtrst}"
    make menuconfig
     
    echo -n "${bldblu}Do you wanna save the changes in the defconfig (y/n)? ${txtrst}"
    read answer
	    if echo "$answer" | grep -iq "^y" ;then
	        echo -e "${bldgrn} Building Defconfig GUI ${txtrst}"
	        cp -f .config $KERNEL_DIR/arch/arm/configs/cyanogen_cancro_defconfig
    fi
fi
     
# Time of build startup
res1=$(date +%s.%N)
     
echo -e "${bldgrn}.....................................................................${txtrst}"
echo -e "${bldgrn}...................${bldblu}STARTING.GOD'S.KERNEL.BUILD${bldgrn}.......................${txtrst}"
echo -e "${bldgrn}.....................................................................${txtrst}"
make -j12
mv $KERNEL_DIR/arch/arm/boot/zImage  $KERNEL_OUT/zImage
cp -f $KERNEL_OUT/zImage $KERNEL_OUT/../kernel_zipmi4/zImage

if ! [ -a  $KERNEL_OUT/zImage ];
    then
    echo -e "${bldblu} Kernel Compilation failed! Fix the errors! ${txtrst}"
    exit 1
fi
     
echo "Copying modules"
find . -name '*.ko' -exec cp {} $KERNEL_OUT/modules/ \;
echo "Stripping modules for size"
$STRIP --strip-unneeded $KERNEL_OUT/modules/*.ko
cp -rf $KERNEL_OUT/modules/* $KERNEL_OUT/../kernel_zipmi4/modules/

echo -e "${bldgrn} DTB Build  ${txtrst}"
.$KERNEL/zip/dtbToolCM -2 -o $KERNEL_OUT/dt.img -s 2048 -p scripts/dtc/ arch/arm/boot/
cp -f $KERNEL_OUT/dt.img $KERNEL_OUT/../kernel_zipmi4/dtb

     
if ! [ -a $KERNEL_OUT/dt.img ];
    then
    echo -e "${bldblu} Kernel Compilation failed! Fix the errors! ${txtrst}"
    exit 1
fi
     

echo -e "${bldgrn} Zipping the Kernel Build  ${txtrst}"
cd $KERNEL_OUT/
zip -r ../GK_CANCRO_LP_KK_$(date +%d%m%Y_%H%M) .
cd $KERNEL_OUT/../kernel_zipmi4/
zip -r ../GK_MI4_LP_KK_$(date +%d%m%Y_%H%M) .

OUTZIP=$(find ../*.zip)
cd $KERNEL_DIR
    
# Get elapsed time
res2=$(date +%s.%N)
echo "${bldgrn}$OUTZIP Compiled Succuessfully in ${txtrst}${bldgrn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"
