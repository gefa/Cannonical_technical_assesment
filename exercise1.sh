#!/bin/bash

mkdir -p src
cd src
    # I used the new kernel version, although same works with 5.x kernel
    wget https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-6.3.3.tar.xz
    tar -xf linux-6.3.3.tar.xz
    cd linux-6.3.3
        make defconfig
        make -j$(nproc) || exit # exit if make fails
    cd ..
    # I assume using busybox is allowed for this exercise
    # alternatively adding/building programs from scratch is more involved
    wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
    tar -xf busybox-1.36.1.tar.bz2
    cd busybox-1.36.1
        make defconfig
        # build staticly linked busybox executable
        # instead of --static flag you can enable CONFIG_STATIC=y in .config
        make -j8 busybox ARCH="arm64" LDFLAGS="--static" || exit
    cd ..
cd ..
# copy to root dir kernel image to be on hand
cp src/linux-6.3.3/arch/x86_64/boot/bzImage ./
# create the bare bones file system
mkdir initrd
cd initrd
    mkdir -p bin dev proc sys
    cd bin
        # copy busybox executable we just built into rootfs
        cp ../../src/busybox-1.36.1/busybox ./
        for prog in $(./busybox --list); do
            # link all available programs/commands to busybox
            # for example we will need "echo" command below
            ln -s /bin/busybox ./$prog
        done
    cd ..
    # create the init script in root of rootfs directory
    echo '#!/bin/sh' > init
    # mount sysfs virtual filesystem, provides view of system's device and kernel info
    echo 'mount -t sysfs sysfs /sys' >> init
    # mount proc filesystem which allows access to system info. such as /proc/cpuinfo
    echo 'mount -t proc proc /proc' >> init
    # mount udev vitual filesystem for dynamic device nodes 
    echo 'mount -t devtmpfs udev /dev' >> init
    echo 'sysctl -w kernel.printk="2 4 1 7"' >> init # set kernel's logging behavior
    echo 'clear' >> init # clear shell output so far
    echo '/bin/echo "hello world"' >> init
    echo '/bin/sh' >> init # run shell for experimentation
    echo 'poweroff -f' >> init # quit kernel gracefully
    # below should not matter since we don't have user accounts yet
    chmod -R 777 . # give all r w x permissions to everyone, mainly want: chmod +x init
    # find all files and directories and pipe to cpio that creates initial ram disk
    # image file in Linux. cpio -o creates archive file of newc format and redirects
    # the result to initrd.img file in parent firectory
    find . | cpio -o -H newc > ../initrd.img
cd ..
# run a virtual machine using the QEMU emulator with a specified kernel and initial ramdisk 
qemu-system-x86_64 -kernel bzImage -initrd initrd.img
