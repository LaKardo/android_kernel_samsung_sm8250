#!/bin/bash

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

BASE_DIR="$HOME/project"
KERNEL_DIR="$BASE_DIR/android_kernel_samsung_sm8250"
TOOLCHAIN_DIR="$BASE_DIR/neutron-clang"
REPACK_DIR="$BASE_DIR/AnyKernel3"
ZIP_DIR="$BASE_DIR/zip"
KBUILD_OUTPUT="$KERNEL_DIR/out"

IMAGE="$KBUILD_OUTPUT/arch/arm64/boot/Image.gz"
DTB="$KBUILD_OUTPUT/arch/arm64/boot/dts/vendor/qcom"
DTBO="$KBUILD_OUTPUT/arch/arm64/boot/dts/samsung"

DEFCONFIG="soviet-star_defconfig"

BASE_AK_VER="SOVIET-STAR"
DATE=`date +"%Y%m%d-%H%M"`
AK_VER="$BASE_AK_VER"
ZIP_NAME="$AK_VER"-"$DATE"

function exports() {
	export ARCH=arm64
	export SUBARCH=arm64
	export KBUILD_BUILD_USER=LaKardo
	export KBUILD_BUILD_HOST=KREMLIN

	export CLANG_DIR=$TOOLCHAIN_DIR/bin/
	export PATH=${CLANG_DIR}:${PATH}
	export CROSS_COMPILE=${CLANG_DIR}/aarch64-linux-gnu-
	export CROSS_COMPILE_COMPAT=${CLANG_DIR}/arm-linux-gnueabi-
}

function compiler_version() {
	echo -e "${green}"
	echo "----------------------------------------------"
	echo "Compiler version:" $($CLANG_DIR/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
	echo "----------------------------------------------"
	echo -e "${restore}"
}

function make_kernel() {
	exports
	compiler_version
	echo -e "${green}"
	echo "-----------------"
	echo "Making Kernel:"
	echo "-----------------"
	echo -e "${restore}"
	BUILD_START=$(date +"%s")
	cd $KERNEL_DIR
	make O=$KBUILD_OUTPUT LLVM=1 CC="ccache clang" $DEFCONFIG
	make O=$KBUILD_OUTPUT LLVM=1 CC="ccache clang" -j8
	make O=$KBUILD_OUTPUT LLVM=1 CC="ccache clang" -j8 dtbs
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
	make_zip
}

function make_zip() {
	if [ -f $IMAGE ]
		then
			mkdir -p $ZIP_DIR && rm -f $ZIP_DIR/*
			cp $IMAGE $REPACK_DIR/Image.gz
			cat $DTB/*.dtb > $REPACK_DIR/dtb
			#tools/mkdtimg create $REPACK_DIR/dtbo.img `find $DTBO/ -name "*.dtbo"`
			cd $REPACK_DIR
			zip -r9 `echo $ZIP_NAME`.zip *
			mv `echo $ZIP_NAME`*.zip $ZIP_DIR
			echo -e "${green}"
			echo "------------------------------------------------"
			echo "Build Completed in: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
			echo "------------------------------------------------"
			echo -e "${restore}"
	else
		echo -e "${red}"
		echo "----------------------"
		echo "Build kernel failed"
		echo "----------------------"
		echo -e "${restore}"
	fi
}

make_kernel
