#! /bin/bash

# File: convert-iso.sh
# Build a distribution based on Debian
# 2013

VERBOSE=v

CURRENT_DIR=$PWD
BUILD_TMP_DIR=$CURRENT_DIR/tmp_build
CD_DIR=${BUILD_TMP_DIR}/cd

SRC_ISO=
DEST_ISO=starlight.iso

ORIG_INITRD=$BUILD_TMP_DIR/cd/install.386/initrd.gz

PRESEED_FILE=${CURRENT_DIR}/my_preseed.cfg

# Create a temporery directory for build
mkdir -p $BUILD_TMP_DIR
mkdir -p ${CD_DIR}

pushd $BUILD_TMP_DIR

# Mount iso and sync to a new directory
mkdir -p loopdir
if [ -e "${SRC_ISO}" ]
then
    mount -o loop loopdir
else
    mount /dev/sr0 loopdir 
fi

rsync -a -H --exclude-from=$CURRENT_DIR/exclude-iso.txt loopdir/ ${CD_DIR}
umount loopdir

# Use our isolinux
cp -a $CURRENT_DIR/isolinux ${CD_DIR}

# Put preseed into initrd and re-package
mkdir irmod
cd irmod
gzip -d < $ORIG_INITRD | \
    cpio --extract  --make-directories --no-absolute-filenames

cp ${PRESEED_FILE} ./preseed.cfg

find . | cpio -H newc --create -${VERBOSE} | \
    gzip -9 > ../cd/install.386/initrd.gz

cd ../
rm -fr irmod/

# Re-generate Packages
pushd ${CD_DIR}
dpkg-scanpackages pool/main /dev/null  > dists/wheezy/main/binary-i386/Packages
cat dists/wheezy/main/binary-i386/Packages | gzip >dists/wheezy/main/binary-i386/Packages.gz
popd

# Re-generate Release
pushd ${CD_DIR}
apt-ftparchive -c ${CURRENT_DIR}/indices/apt.conf generate ${CURRENT_DIR}/indices/milkly-di.conf
apt-ftparchive -c ${CURRENT_DIR}/indices/apt.conf generate ${CURRENT_DIR}/indices/milkly-pool.conf
apt-ftparchive -c ${CURRENT_DIR}/indices/apt.conf release dists/wheezy > dists/wheezy/Release
popd

# Re-generate md5sum
cd ${CD_DIR}
md5sum `find -follow -type f` > md5sum.txt
cd ..

popd

# Build a new ISO
genisoimage -o $DEST_ISO -r -J -no-emul-boot -boot-load-size 4 \
    -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat ${CD_DIR}

# clean up tmp
rm -rf $BUILD_TMP_DIR

echo 
echo "OK"
echo .....
