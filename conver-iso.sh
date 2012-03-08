#! /bin/bash

BUILD_TMP_DIR=tmp_build

CURRENT_DIR=$PWD
SRC_ISO=$1
DEST_ISO=starlight.iso
ROOT_FS_PACKAGE=$CURRENT_DIR/rootfs.tgz

mkdir -p $BUILD_TMP_DIR
pushd $BUILD_TMP_DIR

mkdir -p cd/install.386

#kdir -p loopdir
#ount -o loop $SRC_ISO loopdir 
#kdir cd
#sync -a -H --exclude-from=$CURRENT_DIR/exclude-iso.txt loopdir/ cd
#mount loopdir
cp -a $CURRENT_DIR/isolinux cd/

# put preseed into initrd
mkdir irmod
cd irmod
gzip -d < $CURRENT_DIR/boot/initrd.img-2.6.32-5-686 | \
    cpio --extract --verbose --make-directories --no-absolute-filenames
#cp $CURRENT_DIR/my_preseed.cfg preseed.cfg
cp $CURRENT_DIR/boot/init .
find . | cpio -H newc --create --verbose | \
    gzip -9 > ../cd/install.386/initrd.gz

cd ../
rm -fr irmod/
#cp $CURRENT_DIR/boot/initrd.img-2.6.32-5-686 cd/install.386/initrd.gz
cp $CURRENT_DIR/boot/vmlinuz-2.6.32-5-686 cd/install.386/vmlinuz
cp $ROOT_FS_PACKAGE cd/rootfs.tgz

# Re-generate md5sum
cd cd
md5sum `find -follow -type f` > md5sum.txt
cd ..

popd

# Build a new ISO
mkisofs -o $DEST_ISO -r -J -no-emul-boot -boot-load-size 4 \
    -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat $BUILD_TMP_DIR/cd

# clean up tmp
rm -rf $BUILD_TMP_DIR

echo 
echo "OK"
echo 