#!/bin/sh

LOCAL_DIR=/usr/local
SRC_DIR=$LOCAL_DIR/src
PULLS_DIR=$LOCAL_DIR/pulls
BIN_DIR=$LOCAL_DIR/bin
OPAM_DIR=$HOME/.opam

TMUX_VERSION=1.6
GIT_VERSION=1.8.4
OCAML_BOOTSTRAP_VERSION=4.00.1
OCAML_BOOTSTRAP_SHORT_VERSION=`echo $OCAML_BOOTSTRAP_VERSION | cut -d "." -f 1,2`
TIG_VERSION=1.1

OPAM_VERSION=1.0.0
OCAML_OPAM_VERSION=4.01.0

set -x

# Install packages.
yum install -y bash-completion.noarch vim-enhanced.i386 libevent-devel.i386 autoconf.noarch gettext-devel.i386 xen-devel.i386 xen-libs.i386

# Create useful directories.
mkdir -p $OPAM_DIR $PULLS_DIR

# Set up tmux.
if ! which tmux 2> /dev/null
then
    cd $SRC_DIR
    rm -rf tmux-*
    wget "http://downloads.sourceforge.net/project/tmux/tmux/tmux-${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz?r=&ts=1379585437&use_mirror=garr"
    tar zxf tmux-${TMUX_VERSION}.tar.gz
    cd tmux-${TMUX_VERSION}
    ./configure --prefix=$LOCAL_DIR
    make
    make install
fi

# Set up git
if ! which git 2> /dev/null
then
    cd $SRC_DIR
    rm -rf git-*
    wget https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz -O git-${GIT_VERSION}.tar.gz --no-check-certificate
    tar zxf git-${GIT_VERSION}.tar.gz
    cd git-${GIT_VERSION}
    make configure
    ./configure --prefix=$LOCAL_DIR
    make all install
    # Install git bash completion.
    cp contrib/completion/git-completion.bash /etc/bash_completion.d/git
fi

# Set up OCaml.
# This is the initial install needed to build OPAM.
if [ ! -e $BIN_DIR/ocaml ]
then
    cd $SRC_DIR
    rm -rf ocaml-*
    wget http://caml.inria.fr/pub/distrib/ocaml-${OCAML_BOOTSTRAP_SHORT_VERSION}/ocaml-${OCAML_BOOTSTRAP_VERSION}.tar.gz
    tar zxf ocaml-${OCAML_BOOTSTRAP_VERSION}.tar.gz
    cd ocaml-${OCAML_BOOTSTRAP_VERSION}
    ./configure --prefix $LOCAL_DIR
    make world opt opt.opt install
fi

# Set up tig.
if ! which tig 2> /dev/null
then
    cd $PULLS_DIR
    rm -rf tig
    git clone git://github.com/jonas/tig
    cd tig
    git checkout tig-${TIG_VERSION}
    # tig-1.1 doesn't support --prefix, and tig-1.2 doesn't build against old libc.
    # This puts tig into /root/bin, which is OK.
    make
    make install
fi

# Set up OPAM.
if ! which opam 2> /dev/null
then
    ln -sf $OPAM_DIR $HOME/.opam
    cd $PULLS_DIR
    rm -rf opam
    git clone git://github.com/OCamlPro/opam
    cd opam
    git checkout $OPAM_VERSION
    ./configure --prefix=$LOCAL_DIR
    make
    make install
    opam init --no-setup
    opam remote add xapi-project git://github.com/xapi-project/opam-repo-dev
    opam switch $OCAML_OPAM_VERSION
    eval `opam config env`
fi

# Set up .bashrc
grep -q "opam config env" $HOME/.bashrc || (echo >> $HOME/.bashrc && echo "which opam > /dev/null && eval \`opam config env\`" >> $HOME/.bashrc)
