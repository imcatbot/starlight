#! /bin/bash

CURRENT_DIR=$PWD
OUTPUT=$CURRENT_DIR/initrd-vmlinuz.tgz

echo "Generate a initrd and vmlinuz"

# Create a tmp directory
mkdir -p .tmpinitrd/initrd_dir

pushd .tmpinitrd/initrd_dir

# uncompress initrd
cat /initrd.img|gunzip |cpio -di

# make your modification here

find . -print |cpio -H newc --create |gzip -9fn > ../initrd.img

cd ..
cp /vmlinuz .

tar -czf $OUTPUT initrd.img vmlinuz

popd

# clean up

rm -rf .tmpinitrd/

echo "OK"
