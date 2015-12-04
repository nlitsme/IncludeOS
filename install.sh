#! /bin/bash
set -e
. ./etc/set_traps.sh

export BUILD_DIR=$HOME/IncludeOS_build
export TEMP_INSTALL_DIR=$BUILD_DIR/IncludeOS_TEMP_install

export INSTALL_DIR=$HOME/IncludeOS_install
export PREFIX=$TEMP_INSTALL_DIR
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
export build_dir=$HOME/cross-dev

# Multitask-parameter to make
export num_jobs=-j$((`lscpu -p | tail -1 | cut -d',' -f1` + 1 ))

export newlib_version=2.2.0-1

export IncludeOS_src=`pwd`
export newlib_inc=$TEMP_INSTALL_DIR/i686-elf/include
export llvm_src=llvm
export llvm_build=build_llvm
export clang_version=3.6

export gcc_version=5.1.0
export binutils_version=2.25

# Options to skip steps
[ -z $do_binutils ] && do_binutils=1
[ -z $do_gcc ] && do_gcc=1
[ -z $do_newlib ] && do_newlib=1
[ -z $do_includeos ] &&  do_includeos=1
[ -z $do_llvm ] &&  do_llvm=1
# TODO: These should be determined by inspecting if local llvm repo is up-to-date

[ -z $install_llvm_dependencies ] &&  export install_llvm_dependencies=1
[ -z $download_llvm ] && export download_llvm=1



# BUILDING IncludeOS
PREREQS_BUILD="build-essential make nasm texinfo clang clang++"

echo -e "\n\n >>> Trying to install prerequisites for *building* IncludeOS"
echo -e  "        Packages: $PREREQS_BUILD \n"
sudo apt-get install -y $PREREQS_BUILD

mkdir -p $BUILD_DIR
cd $BUILD_DIR

if [ ! -z $do_binutils ]; then
    echo -e "\n\n >>> GETTING / BUILDING binutils (Required for libgcc / unwind / crt) \n"
    $IncludeOS_src/etc/build_binutils.sh
fi

if [ ! -z $do_gcc ]; then
    echo -e "\n\n >>> GETTING / BUILDING GCC COMPILER (Required for libgcc / unwind / crt) \n"
    $IncludeOS_src/etc/cross_compiler.sh
fi

if [ ! -z $do_newlib ]; then
    echo -e "\n\n >>> GETTING / BUILDING NEWLIB \n"
    $IncludeOS_src/etc/build_newlib.sh
fi

if [ ! -z $do_llvm ]; then
    echo -e "\n\n >>> GETTING / BUILDING llvm / libc++ \n"
    $IncludeOS_src/etc/build_llvm32.sh
    #echo -e "\n\n >>> INSTALLING libc++ \n"
    #cp $BUILD_DIR/$llvm_build/lib/libc++.a $INSTALL_DIR/lib/
fi

echo -e "\n >>> DEPENDENCIES SUCCESSFULLY BUILT. Creating binary bundle \n"
$IncludeOS_src/etc/create_binary_bundle.sh


if [ ! -z $do_includeos ]; then
    # Build and install the vmbuilder 
    echo -e "\n >>> Installing vmbuilder"
    pushd $IncludeOS_src/vmbuild
    make 
    cp vmbuild $INSTALL_DIR/
    popd
    
    echo -e "\n >>> Building IncludeOS"
    pushd $IncludeOS_src/src
    make $num_jobs
        
    echo -e "\n >>> Linking IncludeOS test-service"
    make test
    
    echo -e "\n >>> Installing IncludeOS"
    make install

    popd
   
    
    # RUNNING IncludeOS
    PREREQS_RUN="bridge-utils qemu-kvm"
    echo -e "\n\n >>> Trying to install prerequisites for *running* IncludeOS"
    echo -e   "        Packages: $PREREQS_RUN \n"
    sudo apt-get install -y $PREREQS_RUN
    
    # Set up the IncludeOS network bridge
    echo -e "\n\n >>> Create IncludeOS network bridge  *Requires sudo* \n"
    sudo $IncludeOS_src/etc/create_bridge.sh
    
    # Copy qemu-ifup til install loc.
    mkdir -p $INSTALL_DIR/etc
    cp $IncludeOS_src/etc/qemu-ifup $INSTALL_DIR/etc/
    cp $IncludeOS_src/etc/qemu_cmd.sh $INSTALL_DIR/etc/
fi

echo -e "\n >>> Done. Test the installation by running ./test.sh \n"

trap - EXIT
