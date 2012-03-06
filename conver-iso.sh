#! /bin/bash

BUILD_TMP_DIR=tmp_build

CURRENT_DIR=$PWD
SRC_ISO=$1
DEST_ISO=starlight.iso

mkdir -p $BUILD_TMP_DIR
pushd $BUILD_TMP_DIR

mkdir -p loopdir
mount -o loop $SRC_ISO loopdir 
mkdir cd
rsync -a -H --exclude=TRANS.TBL loopdir/ cd
umount loopdir

# put preseed into initrd
mkdir irmod
cd irmod
gzip -d < ../cd/install.386/initrd.gz | \
    cpio --extract --verbose --make-directories --no-absolute-filenames
cp $CURRENT_DIR/my_preseed.cfg preseed.cfg
find . | cpio -H newc --create --verbose | \
    gzip -9 > ../cd/install.386/initrd.gz

cd ../
rm -fr irmod/

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

echo "OK"
