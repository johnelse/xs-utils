#!/bin/sh

set -x

YUM_INSTALL="yum install --disablerepo=citrix --enablerepo=base,updates -y"

INSTALL_DEVICE=/dev/xvdc
MOUNT_POINT=/usr/local2
SRC_DIR=$MOUNT_POINT/src

TMUX_VERSION=1.6
GIT_VERSION=1.8.4
OCAML_BOOTSTRAP_VERSION=4.00.1

if [ ! -b $INSTALL_DEVICE ]
then
    echo "$INSTALL_DEVICE does not exist"
else
    # Install packages.
    $YUM_INSTALL vim-enhanced.i386
    $YUM_INSTALL libevent-devel.i386
    $YUM_INSTALL autoconf.noarch
    $YUM_INSTALL gettext-devel.i386

    # Setup new disk.
    mountpoint -q $MOUNT_POINT && umount $MOUNT_POINT
    mkfs.ext3 /dev/xvdc
    mkdir -p $MOUNT_POINT
    mount $INSTALL_DEVICE $MOUNT_POINT
    grep -q $INSTALL_DEVICE /etc/fstab || echo "$INSTALL_DEVICE	$MOUNT_POINT	ext3	defaults	1  1" >> /etc/fstab

    # Set up source directory.
    mkdir -p $SRC_DIR

    # Set up tmux.
    cd $SRC_DIR
    wget "http://downloads.sourceforge.net/project/tmux/tmux/tmux-${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz?r=&ts=1379585437&use_mirror=garr"
    tar zxf tmux-${TMUX_VERSION}.tar.gz
    cd tmux-${TMUX_VERSION}
    ./configure --prefix=$MOUNT_POINT
    make
    make install

    # Set up git
    cd $SRC_DIR
    wget https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz -O git-${GIT_VERSION}.tar.gz
    tar zxf git-${GIT_VERSION}.tar.gz
    cd git-${GIT_VERSION}
    make configure
    ./configure --prefix=$MOUNT_POINT
    make all install

    # Set up OCaml.
    # This is the initial install needed to build OPAM.
    cd $SRC_DIR
    wget http://caml.inria.fr/pub/distrib/ocaml-4.00/ocaml-${OCAML_BOOTSTRAP_VERSION}.tar.gz
    tar zxf ocaml-${OCAML_BOOTSTRAP_VERSION}.tar.gz
    cd ocaml-${OCAML_BOOTSTRAP_VERSION}
    ./configure --prefix $MOUNT_POINT
    make world opt opt.opt

    # Set up paths.
    # echo "export PATH=/usr/local2/bin:$PATH" >> ~/.bashrc
fi
