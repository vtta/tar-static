#!/bin/bash
#
# build static tar because we need exercises in minimalism
# MIT licentar: google it or see robxu9.mit-license.org.
#
# For Linux, also builds musl for truly static linking.
# set -ex

tar_version="1.34"
musl_version="1.2.3"
upx_version="4.0.1"

platform=$(uname -s)

# if [ -d build ]; then
#   echo "= removing previous build directory"
#   rm -rf build
# fi

mkdir -p build # make build directory
pushd build

# download tarballs
echo "= downloading tar"
[ -f tar-${tar_version}.tar.xz ] || curl -LO http://ftp.gnu.org/gnu/tar/tar-${tar_version}.tar.xz

echo "= extracting tar"
tar xJf tar-${tar_version}.tar.xz

echo "= downloading upx"
[ -f upx-${upx_version}-amd64_linux.tar.xz ] || curl -LO https://github.com/upx/upx/releases/download/v${upx_version}/upx-${upx_version}-amd64_linux.tar.xz

echo "= extracting upx"
tar xJf upx-${upx_version}-amd64_linux.tar.xz

if [ "$platform" = "Linux" ]; then
  echo "= downloading musl"
  [ -f musl-${musl_version}.tar.gz ] || curl -LO http://www.musl-libc.org/releases/musl-${musl_version}.tar.gz

  echo "= extracting musl"
  tar -xf musl-${musl_version}.tar.gz

  echo "= building musl"
  working_dir=$(pwd)

  install_dir=${working_dir}/musl-install

  pushd musl-${musl_version}
  env CFLAGS="$CFLAGS -Os -ffunction-sections -fdata-sections" LDFLAGS="$LDFLAGS -Wl,--gc-sections" ./configure --prefix=${install_dir}
  make install -j
  popd # musl-${musl-version}

  echo "= setting CC to musl-gcc"
  export CC=${working_dir}/musl-install/bin/musl-gcc
  export CFLAGS="$CFLAGS -static"
else
  echo "= WARNING: your platform does not support static binaries."
  echo "= (This is mainly due to non-static libc availability.)"
fi

echo "= building tar"

pushd tar-${tar_version}
env FORCE_UNSAFE_CONFIGURE=1 CFLAGS="$CFLAGS -Os -ffunction-sections -fdata-sections" LDFLAGS="$LDFLAGS -Wl,--gc-sections" ./configure
make -j
popd # tar-${tar_version}

popd # build

if [ ! -d releases ]; then
  mkdir releases
fi

echo "= striptease"
strip -s -R .comment -R .gnu.version --strip-unneeded build/tar-${tar_version}/src/tar
echo "= compressing"
build/upx-${upx_version}-amd64_linux/upx --ultra-brute build/tar-${tar_version}/src/tar
echo "= extracting tar binary"
cp build/tar-${tar_version}/src/tar releases
echo "= done"
