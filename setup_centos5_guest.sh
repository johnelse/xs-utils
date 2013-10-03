#!/bin/sh

LOCAL_DIR=/usr/local
SRC_DIR=$LOCAL_DIR/src
PULLS_DIR=$LOCAL_DIR/pulls
BIN_DIR=$LOCAL_DIR/bin
OPAM_DIR=$HOME/.opam

OCAML_BOOTSTRAP_VERSION=4.00.1
OCAML_BOOTSTRAP_SHORT_VERSION=`echo $OCAML_BOOTSTRAP_VERSION | cut -d "." -f 1,2`

OPAM_VERSION=1.0.0
OCAML_OPAM_VERSION=4.01.0

set -x

wget http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
rpm -Uvh epel-release-5*.rpm

# Install packages.
yum install -y bash-completion.noarch vim-enhanced.i386 libevent-devel.i386 \
               autoconf.noarch gettext-devel.i386 xen-devel.i386 xen-libs.i386 \
               git.i386 tig.i386 tmux.i386

# Create useful directories.
mkdir -p $OPAM_DIR $PULLS_DIR

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
