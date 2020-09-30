#!/bin/bash

# AdGuardHome installation script

# 1. Download the package
# 2. Unpack it
# 3. Install as a service

# Requirements:
# . bash
# . which
# . printf
# . uname
# . head, tail
# . curl or wget
# . tar or unzip
# . rm

# Get OS
# Return: darwin, linux, freebsd
function detect_os()
{
	local UNAME_S="$(uname -s)"
	local OS=
	case "$UNAME_S" in
		Linux)
			OS=linux
			;;

		FreeBSD)
			OS=freebsd
			;;

		Darwin)
			OS=darwin
			;;

		*)
			return 1
			;;

	esac

	echo $OS
}

# Get CPU endianness
# Return: le, ""
function cpu_little_endian()
{
	local ENDIAN_FLAG="$(head -c 6 /bin/bash | tail -c 1)"
	if [ "$ENDIAN_FLAG" = "$(printf '\001')" ]; then
		echo 'le'
		return 0
	fi
}

# Get CPU
# Return: amd64, 386, armv5, armv6, armv7, arm64, mips_softfloat, mipsle_softfloat, mips64_softfloat, mips64le_softfloat
function detect_cpu()
{
	local UNAME_M="$(uname -m)"
	local CPU=

	case "$UNAME_M" in

		x86_64 | x86-64 | x64 | amd64)
			CPU=amd64
			;;

		i386 | i486 | i686 | i786 | x86)
			CPU=386
			;;

		armv5l)
			CPU=armv5
			;;

		armv6l)
			CPU=armv6
			;;

		armv7l | armv8l)
			CPU=armv7
			;;

		aarch64)
			CPU=arm64
			;;

		mips)
			LE=$(cpu_little_endian)
			CPU=mips${LE}_softfloat
			;;

		mips64)
			LE=$(cpu_little_endian)
			CPU=mips64${LE}_softfloat
			;;

		*)
			return 1

	esac

	echo $CPU
}

# Get package file name extension
# Return: tar.gz, zip
function package_extension()
{
	if [ "$OS" = "darwin" ]; then
		echo "zip"
		return 0
	fi
	echo "tar.gz"
}

# Download data to a file
# Use: download URL OUTPUT
function download()
{
	echo "downloading package from $1 -> $2"
	if [ $(which curl) ]; then
		curl $1 --output $2 || return 1
	elif [ $(which wget) ]; then
		wget $1 -o $2 || return 1
	else
		echo "need curl or wget"
		return 1
	fi
}

# Unpack package to a directory
# Use: unpack INPUT OUTPUT_DIR PKG_EXT
function unpack()
{
	echo "unpacking package from $1 -> $2"
	if [ "$3" = "zip" ]; then
		unzip $1 -d $2 || return 1
	elif [ "$3" = "tar.gz" ]; then
		tar xzf $1 -C $2 || return 1
	else
		return 1
	fi
}

# Print error message and exit
# Use: error_exit MESSAGE
function error_exit()
{
	echo $1
	exit 1
}

OS=$(detect_os) || error_exit "ERROR: Can not detect your OS"
CPU=$(detect_cpu) || error_exit "ERROR: Can not detect your CPU"
PKG_EXT=$(package_extension)
PKG_NAME=AdGuardHome_${OS}_$CPU.$PKG_EXT
CHANNEL=release
URL=https://static.adguard.com/adguardhome/$CHANNEL/$PKG_NAME
OUT_DIR=/opt

download $URL $PKG_NAME || error_exit "ERROR: Can not download package"

echo "Please enter a root directory AdGuard Home will be unpacked to or just press Enter to use default directory /opt:"
read USER_OUT_DIR
if [ "$USER_OUT_DIR" != "" ]; then
	OUT_DIR=$USER_OUT_DIR
fi

unpack $PKG_NAME $OUT_DIR $PKG_EXT || error_exit "ERROR: Can not unpack the package"

$OUT_DIR/AdGuardHome/AdGuardHome -s install || error_exit "ERROR: Can not install AdGuardHome as a service"

rm $PKG_NAME
echo "Installation script is successfully finished"
