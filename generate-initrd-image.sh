#! /bin/bash

CURRENT_DIR=$PWD
OUTPUT=$CURRENT_DIR/initrd-vmlinuz.tgz

CMDS="fdisk parted mkfs.ext4 mkfs mkfs.ext3 mkswap lsmod bash mount dialog whiptail"

function COPYCMD {
    DEST=usr/local/bin
    which $1 > /dev/null || echo "$1 is not exist" | return 5
    BIN=`which $1`
  
    [ -d $DEST ] || mkdir -p $DEST
    echo "cp -f $BIN $DEST"
    cp -f $BIN $DEST
   
    RELATED_DIR=./
    for I in `ldd $BIN | grep -o "/[^[:space:]]*"`
    do  
	DIRNAME=`dirname $I`
	[ -d ${RELATED_DIR}${DIRNAME} ] || mkdir -p ${RELATED_DIR}${DIRNAME}
	echo "cp -f $I ${RELATED_DIR}${DIRNAME}"
	cp -f $I ${RELATED_DIR}${DIRNAME}
    done  
}

echo "Generate a initrd and vmlinuz"

# Create a tmp directory
mkdir -p .tmpinitrd/initrd_dir

pushd .tmpinitrd/initrd_dir

# uncompress initrd
cat /initrd.img|gunzip |cpio -di

#create empty mtab
touch etc/mtab

# make your modification here
mkdir -p usr/local
for c in $CMDS
do
    COPYCMD $c
done

# re-generate a new initrd image
find . -print |cpio -H newc --create |gzip -9fn > ../initrd.img

cd ..
cp /vmlinuz .

tar -czf $OUTPUT initrd.img vmlinuz

popd

# clean up

rm -rf .tmpinitrd/

echo "OK"
