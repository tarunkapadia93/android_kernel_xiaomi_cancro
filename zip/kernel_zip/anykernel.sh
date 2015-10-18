# AnyKernel 2.0 Ramdisk Mod Script 
# osm0sis @ xda-developers

## AnyKernel setup
# EDIFY properties
kernel.string=God Kernel by Tarun93 @ xda-developers
do.devicecheck=1
do.initd=1
do.modules=1
do.cleanup=0
device.name1=cancro

# shell variables
block=/dev/block/platform/msm_sdcc.1/by-name/boot;

## end setup


## AnyKernel methods (DO NOT CHANGE)
# set up extracted files and directories
ramdisk=/tmp/anykernel/ramdisk;
bin=/tmp/anykernel/tools;
split_img=/tmp/anykernel/split_img;
patch=/tmp/anykernel/patch;

chmod -R 755 $bin;
mkdir -p $ramdisk $split_img;
cd $ramdisk;

OUTFD=`ps | grep -v "grep" | grep -oE "update(.*)" | cut -d" " -f3`;
ui_print() { echo "ui_print $1" >&$OUTFD; echo "ui_print" >&$OUTFD; }

# dump boot and extract ramdisk
dump_boot() {
  dd if=$block of=/tmp/anykernel/boot.img;
  $bin/unpackbootimg -i /tmp/anykernel/boot.img -o $split_img;
  if [ $? != 0 ]; then
    ui_print " "; ui_print "Dumping/unpacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
  gunzip -c $split_img/boot.img-ramdisk.gz | cpio -i;
  cp /tmp/anykernel/fstab.qcom .
}

# repack ramdisk then build and write image
write_boot() {
  cd $split_img;
  cmdline=`cat *-cmdline`;
  cmdline="$cmdline androidboot.selinux=permissive";
  board=`cat *-board`;
  base=`cat *-base`;
  pagesize=`cat *-pagesize`;
  kerneloff=`cat *-kerneloff`;
  ramdiskoff=`cat *-ramdiskoff`;
  tagsoff=`cat *-tagsoff`;
  if [ -f *-second ]; then
    second=`ls *-second`;
    second="--second $split_img/$second";
    secondoff=`cat *-secondoff`;
    secondoff="--second_offset $secondoff";
  fi;
  if [ -f /tmp/anykernel/zImage ]; then
    kernel=/tmp/anykernel/zImage;
  else
    kernel=`ls *-zImage`;
    kernel=$split_img/$kernel;
  fi;
  if [ -e /tmp/anykernel/dt.img ]; then
    dtb="--dt /tmp/anykernel/dt.img";
  elif [ -f *-dt.img ]; then
    dtb=`ls *-dt.img`;
    dtb="--dt $split_img/$dt.img";
  fi;
  cd $ramdisk;
  find . | cpio -H newc -o | gzip > /tmp/anykernel/ramdisk-new.cpio.gz;
  $bin/mkbootimg --kernel $kernel --ramdisk /tmp/anykernel/ramdisk-new.cpio.gz $second --cmdline "$cmdline" --base $base --pagesize $pagesize --kernel_offset $kerneloff --ramdisk_offset $ramdiskoff  --tags_offset $tagsoff $dtb --output /tmp/anykernel/boot-new.img;
  if [ $? != 0 -o `wc -c < /tmp/anykernel/boot-new.img` -gt `wc -c < /tmp/anykernel/boot.img` ]; then
    ui_print " "; ui_print "Repacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
  dd if=/tmp/anykernel/boot-new.img of=$block;
}

# backup_file <file>
backup_file() { cp $1 $1~; }

# replace_string <file> <if search string> <original string> <replacement string>
replace_string() {
  if [ -z "$(grep "$2" $1)" ]; then
      sed -i "s;${3};${4};" $1;
  fi;
}

## AnyKernel permissions
# set permissions for included files
chmod -R 755 $ramdisk


## Remove stock MPD and Thermal Binaries
mv $bindir/mpdecision $bindir/mpdecision-bak
mv $bindir/thermal-engine $bindir/thermal-engine-bak
rm -rf $bindir/../lib/modules/*

## AnyKernel install
dump_boot;
# begin ramdisk changes


# adb secure
backup_file default.prop;
replace_string default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
replace_string default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";

# Add custom loader script
found=$(find init.rc -type f | xargs grep -oh "import /init.god.rc");
if [ "$found" != 'import /init.god.rc' ]; then
	#append the new lines for this option at the bottom
        echo "" >> init.rc
	echo "import /init.god.rc" >> init.rc
fi

# end ramdisk changes

write_boot;

## end install

