#!/usr/bin/env bash

function help()
{
	echo "Usage: $0 <pkg name | pkg_name.pkg file>"
	echo ""
	echo "------------------------ pkg names ------------------------"
	pkgutil --pkgs
	exit 1
}

function get_list_installed_pkg()
{
	local PKG_NAME="$1"
	local NOW_PATH="$(pwd)"
	local LIST_PKG="${NOW_PATH}/list-${PKG_NAME}.txt"
	local PKG_ROOT="/$(pkgutil --pkg-info $PKG_NAME | grep location | awk '{print $2}')"

	if [ "$PKG_ROOT" = "/" ]; then
		exit 1
	fi

	rm -f $LIST_PKG

	echo -e "Create result file : [$(realpath $LIST_PKG)]\n"
	pkgutil --pkg-info $PKG_NAME >> $LIST_PKG
	echo "" >> $LIST_PKG

	echo "------------------------ pkg receipts ---------------------" >> $LIST_PKG
	find /var/db/receipts -name "${PKG_NAME}*" >> $LIST_PKG
	echo -e "\n" >> $LIST_PKG

	pushd $PKG_ROOT > /dev/null
	echo "ROOT PATH : [$PKG_ROOT]" >> $LIST_PKG
	echo "------------------------ pkg files ------------------------" >> $LIST_PKG
	pkgutil --only-files --files $PKG_NAME | xargs ls -1 >> $LIST_PKG
	popd > /dev/null
}

function get_list_pre_installation_pkg()
{
	local PKG_NAME="$1"
	local TMP_DIR="tmp-${PKG_NAME}"
	local LIST_PKG="list-${PKG_NAME}.txt"

	if [ -z "$(file $PKG_NAME | grep xar)" ]; then
		echo "No such for '$PKG_NAME' contain xar format"
		exit 1
	fi

	rm -f $LIST_PKG
	mkdir $TMP_DIR

	xar -xf $PKG_NAME -C $TMP_DIR

	echo "Create result file : [$(realpath $LIST_PKG)]"
	find $TMP_DIR -name "Bom" -exec lsbom -pf {} >> $LIST_PKG \;
	rm -fr $TMP_DIR
}

OS=$(uname)
if ! [ "$OS" = "Darwin" ]; then
	echo "This script have to used on MacOS!!!"
	exit 1
fi

if [ $# -eq 0 ]; then
	help
fi

if [[ "$1" == *".pkg" ]]; then
	get_list_pre_installation_pkg $1
else
	get_list_installed_pkg $1
fi
