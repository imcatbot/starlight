#! /bin/bash

CURRENT_DIR=$PWD
BUILD_TMP_DIR=$CURRENT_DIR/tmp_build

DEST_ISO=starlight.iso
ROOT_FS_PACKAGE=$CURRENT_DIR/filesystem.squash

INITRD_VMLINUZ=$CURRENT_DIR/initrd-vmlinuz.tgz

ORIG_INITRD=$BUILD_TMP_DIR/boot/initrd.img
ORIG_VMLINUZ=$BUILD_TMP_DIR/boot/vmlinuz

mkdir -p $BUILD_TMP_DIR
pushd $BUILD_TMP_DIR

mkdir -p boot
tar -zxf $INITRD_VMLINUZ -C boot

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
gzip -d < $ORIG_INITRD | \
    cpio --extract  --make-directories --no-absolute-filenames

cp $CURRENT_DIR/boot/init .
find . | cpio -H newc --create --verbose | \
    gzip -9 > ../cd/install.386/initrd.gz

cd ../
rm -fr irmod/
#cp $CURRENT_DIR/boot/initrd.img-2.6.32-5-686 cd/install.386/initrd.gz
cp $ORIG_VMLINUZ cd/install.386/vmlinuz
cp $ROOT_FS_PACKAGE cd/

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