#!/bin/bash
#
# this script is exact same copy of https://raw.githubusercontent.com/ioquake/ioq3/master/misc/linux/server_compile.sh
# except, i added --depth=1 argument to git clone command due to my utter shit internet speed.
# and i removed Y/N block.
set -e

export BUILD_CLIENT="${BUILD_CLIENT:-0}"
export BUILD_SERVER="${BUILD_SERVER:-1}"
export USE_CURL="${USE_CURL:-1}"
export USE_CODEC_OPUS="${USE_CODEC_OPUS:-1}"
export USE_VOIP="${USE_VOIP:-1}"
export COPYDIR="${COPYDIR:-/home/ioq3srv/ioquake3}"
IOQ3REMOTE="${IOQ3REMOTE:-https://github.com/ioquake/ioq3.git}"
MAKE_OPTS="${MAKE_OPTS:--j2}"

if ! [ -x "$(command -v git)" ] || ! [ -x "$(command -v make)" ]; then
        echo "This build script requires 'git' and 'make' to be installed." >&2
        echo "Please install them through your normal package installation system." >&2
        exit 1
fi

echo " This build process requires all of the ioquake3 dependencies necessary for an ioquake3 server.
 If you do not have the necessary dependencies the build will fail.

 Please post a message to http://discourse.ioquake.org/ asking for help and include whatever error messages you received during the compile phase.

 We will be building from the git repo at ${IOQ3REMOTE}
 The resulting binary will be installed to ${COPYDIR}

 If you need to change these, please set variables as follows:

 IOQ3REMOTE=https://github.com/something/something.git COPYDIR=~/somewhere $0"

BUILD_DIR="$(mktemp -d)"
trap "rm -rf $BUILD_DIR" EXIT
git clone --depth=1 $IOQ3REMOTE $BUILD_DIR/ioq3
cd $BUILD_DIR/ioq3
make $MAKE_OPTS
make copyfiles
exit