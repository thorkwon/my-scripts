#!/usr/bin/env bash

function help()
{
	echo "Usage: $0 go-version.tar.gz"
	exit 1
}

OS=$(uname)
if ! [ "$OS" = "Linux" ]; then
	exit 0
fi

if [ $# -eq 0 ]; then
	help
fi

if ! [ -f $1 ]; then
	echo "This is not file : [$1]"
	exit 1
fi

ROOTDIR="/opt"

GO_REAL_PATH=$(realpath $1)
echo "real path : [$GO_REAL_PATH]"
GO_TAR_FILE=$(basename $1)
echo "base name :[$GO_TAR_FILE]"
GO_VERSION=$(echo "$GO_TAR_FILE" | awk -F'.tar.gz' '{print $1}')
echo "golang version : [$GO_VERSION]"

sudo mkdir -p ${ROOTDIR}/${GO_VERSION}
sudo tar -C ${ROOTDIR}/${GO_VERSION} -xzf ${GO_REAL_PATH} --strip-components 1

pushd $ROOTDIR
sudo rm go
sudo ln -sf $GO_VERSION go
popd

go version
