#! /bin/bash

CURRENT_DIR=$PWD
OUTPUT=$CURRENT_DIR/initrd-vmlinuz.tgz

CMDS="fdisk parted mkfs.ext4 mkfs mkfs.ext3 mkswap lsmod bash mount"

function COPYCMD {
    B=usr/local
    which $1 &> /dev/null || echo "$1 is not exist" | return 5 
    DIR=`which $1 | grep -o "/.*"`    
    DIR1=`echo $DIR | sed "s@\(.*\)$1@\1@g"`  
  
    [ -d $B$DIR1 ] || mkdir -p $B$DIR1     
    echo "cp -f [$DIR] [$B$DIR1]"
    cp -f $DIR $B$DIR1      
   
    B=.
    for I in `ldd $DIR | grep -o "/[^[:space:]]*"`
    do  
	DIR1=`echo $I | sed "s@\(.*\)/[^/]*@\1@g"`  
	[ -d $B$DIR1 ] || mkdir -p $B$DIR1  
	cp -f $I $B$DIR1
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
