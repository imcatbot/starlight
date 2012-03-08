#! /bin/bash

CURRENT_DIR=$PWD
OUTPUT=$CURRENT_DIR/initrd-vmlinuz.tgz

CMDS="fdisk mkfs.ext4"

function COPYCMD {
    B=.
    which $1 &> /dev/null || echo "It is not exist" | retrun 5 
    DIR=`which $1 | grep -o "/.*"`    
    DIR1=`echo $DIR | sed "s@\(.*\)$1@\1@g"`  
  
    [ -d $B$DIR1 ] || mkdir -p $B$DIR1     
    [ -e $B$DIR ] || cp $DIR $B$DIR1      
  
    for I in `ldd $DIR | grep -o "/[^[:space:]]*"`
    do  
	DIR1=`echo $I | sed "s@\(.*\)/[^/]*@\1@g"`  
	[ -d $B$DIR1 ] || mkdir -p $B$DIR1  
	[ -e $B$I ] || cp $I $B$DIR1
    done  
}

echo "Generate a initrd and vmlinuz"

# Create a tmp directory
mkdir -p .tmpinitrd/initrd_dir

pushd .tmpinitrd/initrd_dir

# uncompress initrd
cat /initrd.img|gunzip |cpio -di

# make your modification here
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
