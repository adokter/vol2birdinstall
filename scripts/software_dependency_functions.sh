#!/bin/sh
###########################################################################
# Copyright (C) 2021 HENJAB AB
#
# This file is part of vol2birdinstall.
#
# vol2birdinstall is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# vol2birdinstall is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with vol2birdinstall.  If not, see <http://www.gnu.org/licenses/>.
###########################################################################
#
# Provides functionality for installing dependencies provided by source code.
#
# @author Anders Henja (HENJAB AB)
# @date 2021-09-26
###########################################################################
PROJ4_SOURCE_CODE=https://download.osgeo.org/proj/proj-4.9.3.tar.gz

HLHDF_SOURCE_CODE=https://github.com/baltrad/hlhdf.git
HLHDF_VERSION=hlhdf-build-9

RAVE_SOURCE_CODE=https://github.com/baltrad/rave.git
RAVE_VERSION=rave-build-25

IRIS2ODIM_SOURCE_CODE=https://github.com/adokter/iris2odim.git
IRIS2ODIM_VERSION=376ae90cf93baafe225e4d394f634fd178e9a238

RSL_SOURCE_CODE=https://github.com/adokter/rsl.git
#RSL_VERSION=v1.49-25-ga69cd97
#RSL_VERSION=a69cd97ca457949ac1d8f83eff9bf85cb3c39fc5
RSL_VERSION=740f89e129b8e0a78eaee61f33626d3bf4b17ea5

VOL2BIRD_SOURCE_CODE=https://github.com/adokter/vol2bird.git
#VOL2BIRD_VERSION=0.5.0-81-g8a23dfb
#VOL2BIRD_VERSION=45cd1caae3ce2328bcc7016945676eef655e9b31
VOL2BIRD_VERSION=d8365d249fb4a82907a30a7f62e84bfc9a86cc86

CURRENT_MODULES="PROJ4 HLHDF RAVE IRIS2ODIM RSL LIBTORCH VOL2BIRD"

print_module_status()
{ 
  BUILDDIR=$1
  BUILD_LOG="$BUILDDIR/.built_packages"
  for m in $CURRENT_MODULES; do
    VERSION=`installed_version "$BUILD_LOG" $m`
    if [ "$VERSION" != "" ]; then
      printf "%-15s\t%-15s\n" "$m" "$VERSION"
    else
      printf "%-15s\t%-15s\n" "$m" "NOT INSTALLED"
    fi
  done
}

remove_built_module()
{
  BUILDDIR=$1
  MODULE=$2
  BUILD_LOG="$BUILDDIR/.built_packages"
  remove_installed "$BUILD_LOG" $MODULE
}

hdf5_include_dir()
{
  OS_NAME=`get_os_name`
  OS_VARIANT=`get_os_version`
  if [ "$OS_NAME" = "Ubuntu" ]; then
    echo "/usr/include/hdf5/serial"
  elif [ "$OS_VARIANT" = "CentOS-8" -o "$OS_VARIANT" = "RedHat-8" ]; then
    echo "/usr/include"
  elif [ "$OS_NAME" = "Darwin" ]; then
    if [ -f "/usr/local/opt/hdf5@1.10/include/hdf5.h" ]; then
      echo "/usr/local/opt/hdf5@1.10/include"
    elif [ -f "/usr/local/include/hdf5.h" ]; then
      echo "/usr/local/include"
    elif [ -f "/opt/homebrew/opt/hdf5@1.10/include/hdf5.h" ]; then
      echo "/opt/homebrew/opt/hdf5@1.10/include"
    else
      echo "/usr/local/include"
    fi
  else
    X=`locate hdf5.h  | head -1 | sed -e "s/\/hdf5.h//g"`
    echo "$X"
  fi
}

hlhdf_config_param()
{
  PREFIX=$1
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`
  HLHDF_CONFIG_PARAMS=""
  if [ "$OS_NAME" = "Ubuntu" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
    HLHDF_CONFIG_PARAMS="--with-hdf5=/usr/include/hdf5/serial,/usr/lib/x86_64-linux-gnu/hdf5/serial --with-zlib=/usr/include,/usr/lib/x86_64-linux-gnu"
  elif [ "$OS_NAME" = "Darwin" ]; then
    SDKPATH=`xcrun --show-sdk-path` || exit_with_error 127 "Could not run xcrun --show-sdk-path"
    if [ -f "/usr/local/opt/hdf5@1.10/lib/libhdf5.dylib" ]; then
      HLHDF_CONFIG_PARAMS="--with-hdf5=/usr/local/opt/hdf5@1.10/include,/usr/local/opt/hdf5@1.10/lib --with-zlib=$SDKPATH/usr/include,$SDKPATH/usr/lib"
    elif [ -f "/usr/local/lib/libhdf5.dylib" ]; then
      HLHDF_CONFIG_PARAMS="--with-hdf5=/usr/local/include,/usr/local/lib --with-zlib=$SDKPATH/usr/include,$SDKPATH/usr/lib"
    elif [ -f "/opt/homebrew/opt/hdf5@1.10/lib/libhdf5.dylib" ]; then
      HLHDF_CONFIG_PARAMS="--with-hdf5=/opt/homebrew/opt/hdf5@1.10/include,/opt/homebrew/opt/hdf5@1.10/lib --with-zlib=$SDKPATH/usr/include,$SDKPATH/usr/lib"
    else
      HLHDF_CONFIG_PARAMS="--with-hdf5=yes --with-zlib=yes"
    fi
  else
    echo "Not a prededfined OS, using best effort to identify hlhdf config parameters" >&2
  fi
  echo "--without-python $HLHDF_CONFIG_PARAMS"
}

rave_config_param()
{
  PREFIX=$1
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`
  RAVE_CONFIG_PARAMS=""
  if [ "$OS_NAME" = "Ubuntu" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
    RAVE_CONFIG_PARAMS="--with-hlhdf=$PREFIX/hlhdf --with-proj=$PREFIX"
  elif [ "$OS_NAME" = "CentOS" -o "$OS_NAME" = "RedHat" ]; then
    RAVE_CONFIG_PARAMS="--with-hlhdf=$PREFIX/hlhdf --with-proj=$PREFIX"
  elif [ "$OS_NAME" = "Darwin" -o "$OS_NAME" = "darwin" ]; then
    RAVE_CONFIG_PARAMS="--with-hlhdf=$PREFIX/hlhdf"
    if [ "$(arch)" = "arm64" ]; then
      RAVE_CONFIG_PARAMS="$RAVE_CONFIG_PARAMS --with-proj=/opt/homebrew"    
    else
      RAVE_CONFIG_PARAMS="$RAVE_CONFIG_PARAMS --with-proj=/usr/local"    
    fi
  else
    echo "Not a prededfined OS, using best effort to identify rave config parameters" >&2
  fi
  echo "$RAVE_CONFIG_PARAMS"
}

rsl_cflags()
{
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`
  if [ "$OS_VARIANT" = "Ubuntu-20.10" -o "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
    echo "-I"`dpkg-query -L libtirpc-dev | grep "rpc/rpc.h" | sed -e "s/rpc\/rpc.h//g"`
  elif [ "$OS_VARIANT" = "CentOS-8" -o "$OS_VARIANT" = "RedHat-8" ]; then
    echo "-I/usr/include/tirpc"
  fi
  echo ""
}

rsl_ldflags()
{
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`  
  if [ "$OS_VARIANT" = "Ubuntu-20.10" -o "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10"-o "$OS_NAME" = "Debian GNU/Linux" ]; then
    echo "-L"`dpkg-query -L libtirpc-dev | egrep -e 'libtirpc.so$' | sed -e "s/\/libtirpc.so//g"`
  elif [ "$OS_VARIANT" = "CentOS-8" -o "$OS_VARIANT" = "RedHat-8" ]; then
    echo "-ltirpc"
  fi
  echo ""
}

rsl_libs()
{
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`  
  if [ "$OS_VARIANT" = "Ubuntu-20.10" -o "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
    echo "-ltirpc"
  elif [ "$OS_VARIANT" = "CentOS-8" -o "$OS_VARIANT" = "RedHat-8" ]; then
    echo "-ltirpc"
  fi
  echo ""
}

vol2bird_config_param()
{
  PREFIX=$1
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`
  VOL2BIRD_CONFIG_PARAMS="--with-libtorch=$PREFIX/libtorch --with-rsl=$PREFIX/rsl --with-rave=$PREFIX/rave --with-iris=yes"
  
  if [ "$OS_NAME" = "Ubuntu" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
    GSLINC=`dpkg-query -L libgsl-dev | grep gsl/gsl_vector.h | sed -e "s/\/gsl\/gsl_vector.h//g"`
    GSLLIB=`dpkg-query -L libgsl-dev | egrep -e "libgsl.so$" | sed -e "s/\/libgsl.so//g"`
    CONFUSEINC=`dpkg-query -L libconfuse-dev | grep confuse.h | sed -e "s/\/confuse.h//g"`
    CONFUSELIB=`dpkg-query -L libconfuse-dev | grep libconfuse.so | sed -e "s/\/libconfuse.so//g"`
    VOL2BIRD_CONFIG_PARAMS="$VOL2BIRD_CONFIG_PARAMS --with-gsl=$GSLINC,$GSLLIB --with-confuse=$CONFUSEINC,$CONFUSELIB"
  elif [ "$OS_VARIANT" = "CentOS-8" -o "$OS_VARIANT" = "RedHat-8"  ]; then
    GSLINC=`locate gsl/gsl_vector.h 2>/dev/null | sed -e "s/\/gsl\/gsl_vector.h//g" | tail -1`
    if [ "$GSLINC" = "" ]; then
      GSLINC=`repoquery -q -l gsl-devel | grep gsl/gsl_vector.h | sed -e "s/\/gsl\/gsl_vector.h//g" | tail -1`
    fi
    GSLLIB=`locate libgsl.so 2>/dev/null | egrep -e 'libgsl.so$' | sed -e "s/\/libgsl.so//g" | tail -1`
    if [ "$GSLLIB" = "" ]; then
      GSLLIB=`repoquery -q -l gsl-devel | egrep -e "libgsl.so$" | sed -e "s/\/libgsl.so//g" | tail -1`
    fi
    CONFUSEINC=`locate confuse.h | egrep -e 'confuse.h$' | sed -e "s/\/confuse.h//g" | tail -1`
    if [ "$CONFUSEINC" = "" ]; then
      CONFUSEINC=`repoquery -q -l libconfuse-devel | grep confuse.h | sed -e "s/\/confuse.h//g" | tail -1`
    fi
    CONFUSELIB=`locate libconfuse.so | egrep -e 'libconfuse.so$'  | sed -e "s/\/libconfuse.so//g" | tail -1`
    if [ "$CONFUSELIB" = "" ]; then
      CONFUSELIB=`repoquery -q -l libconfuse-devel | grep libconfuse.so | sed -e "s/\/libconfuse.so//g" | tail -1`
    fi
    VOL2BIRD_CONFIG_PARAMS="$VOL2BIRD_CONFIG_PARAMS --with-gsl=$GSLINC,$GSLLIB --with-confuse=$CONFUSEINC,$CONFUSELIB"
  elif [ "$OS_NAME" = "Darwin" -o "$OS_NAME" = "darwin" ]; then
    GSLINC=`brew ls --verbose gsl | grep gsl/gsl_vector.h | sed -e "s/\/gsl\/gsl_vector.h//g" | tail -1`
    GSLLIB=`brew ls --verbose gsl | egrep -e "libgsl.dylib$" | sed -e "s/\/libgsl.dylib//g" | tail -1`
    CONFUSEINC=`brew ls --verbose confuse | grep confuse.h | sed -e "s/\/confuse.h//g" | tail -1`
    CONFUSELIB=`brew ls --verbose confuse | egrep -e 'libconfuse.dylib$' | sed -e "s/\/libconfuse.dylib//g" | tail -1`
    if [ "$(arch)" = "arm64" ]; then
      VOL2BIRD_CONFIG_PARAMS="--with-rsl=$PREFIX/rsl --with-rave=$PREFIX/rave --with-iris=yes"
    fi
    
    VOL2BIRD_CONFIG_PARAMS="$VOL2BIRD_CONFIG_PARAMS --with-gsl=$GSLINC,$GSLLIB --with-confuse=$CONFUSEINC,$CONFUSELIB"
  else
    echo "Not a prededfined OS, using best effort to identify vol2bird config parameters" >&2
  fi
  echo "$VOL2BIRD_CONFIG_PARAMS"
}

get_vol2bird_configure_LIBS()
{
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`  
  VOL2BIRD_configure_LIBS=
  
  if [ "$OS_VARIANT" = "Ubuntu-20.10" -o "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
    VOL2BIRD_configure_LIBS=-ltirpc
  elif [ "$OS_VARIANT" = "CentOS-8" -o "$OS_VARIANT" = "RedHat-8"  ]; then
    VOL2BIRD_configure_LIBS=-ltirpc
  else
    VOL2BIRD_configure_LIBS=
  fi
  echo "$VOL2BIRD_configure_LIBS"
}

install_proj4()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  BUILD_LOG="$BUILDDIR/.built_packages"

  TARBALL=`basename $PROJ4_SOURCE_CODE`
  echo "$TARBALL"
  EXPECTED_PROJ4_VERSION=`echo $TARBALL | sed -e "s/\.tar\.gz//g" | sed -e "s/proj-//g"`

  # INSTALL PROJ.4
  echo -n "Installing PROJ.4...."
  mkdir -p "$DOWNLOADS" || exit_with_error 127 "Could not create download directory"
  
  is_installed_version "$BUILD_LOG" PROJ4 "$EXPECTED_PROJ4_VERSION" && echo "skipping" && return 0

  if [ ! -f "$DOWNLOADS/$TARBALL" ]; then
    wget "$PROJ4_SOURCE_CODE" -O- > "$DOWNLOADS/$TARBALL" || exit_with_error 127 "Could not fetch PROJ.4 tarball"
  fi

  CURRDIR=`pwd`
  
  cd $BUILDDIR || exit_with_error 127 "(PROJ.4) Could not change to folder $BUILDDIR"
  tar -xvzf "$DOWNLOADS/$TARBALL"
  cd `echo $TARBALL | sed -e "s/\.tar\.gz//g"` || exit_with_error 127 "(PROJ.4) Could not change to proj folder"
  ./configure --prefix="$PREFIX" --without-jni || exit_with_error 127 "(PROJ.4) Could not configure"
  make                                         || exit_with_error 127 "(PROJ.4) Could not make"
  make install                                 || exit_with_error 127 "(PROJ.4) Could not install"

  cd $CURRDIR || exit_with_error 127 "(PROJ.4) Could not change back to folder $CURRDIR"

  add_installed_version "$BUILD_LOG" PROJ4 "$EXPECTED_PROJ4_VERSION"
}

install_hlhdf()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  BUILD_LOG="$BUILDDIR/.built_packages"
  OS_NAME=`get_os_name`
  
  CURRDIR=`pwd`
  
  echo "Installing HLHDF...."

  is_installed_version "$BUILD_LOG" HLHDF "$HLHDF_VERSION" && echo "skipping" && return 0

  cd "$DOWNLOADS" || exit_with_error 127 "(HLHDF) Could not change to download directory $DOWNLOADS"
  
  NVER=`fetch_git_software HLHDF "$HLHDF_SOURCE_CODE" hlhdf "$HLHDF_VERSION"` || exit_with_error 127 "(HLHDF) Failed to update software"
  echo "HLHDF is at version: $NVER"

  \rm -fr "$BUILDIR/hlhdf" || exit_with_error 127 "(HLHDF) Could not remove build folder"
  
  cp -r hlhdf "$BUILDDIR/" || exit_with_error 127 "(HOLHDF) Could not copy source to build dir"
  \rm -fr "$BUILDDIR/hlhdf/.git" || exit_with_error 127 "(HOLHDF) Could not remove unused git info"

  cd "$BUILDDIR/hlhdf" || exit_with_error 127 "(HOLHDF) Could not change directory to $BUILDDIR/hlhdf"

  make distclean || true
  if [ "$OS_NAME" = "Darwin" -o "$OS_NAME" = "darwin" ]; then
    patch -p1 < "$PATCHDIR/hlhdf-mac-patch.patch" || exit_with_error 127 "(HLHDF) Could not patch system for building"
  fi
  
  HLHDF_CONFIG_PARAM=`hlhdf_config_param $PREFIX`

  echo "Using $HLHDF_CONFIG_PARAM to configure hlhdf"

  ./configure --prefix="$PREFIX/hlhdf" $HLHDF_CONFIG_PARAM || exit_with_error 127 "(HOLHDF) Could not configure HLHDF"
  make         || exit_with_error 127 "(HLHDF) Failed to compile software"
  make install || exit_with_error 127 "(HLHDF) Failed to install software"
  
  cd "$CURRDIR" || exit_with_error 127 "(HOLHDF) Could not change directory back to $CURRDIR"

  add_installed_version "$BUILD_LOG" HLHDF "$HLHDF_VERSION"
}

install_rave()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  PATCHDIR=$4
  
  BUILD_LOG="$BUILDDIR/.built_packages"
  CURRDIR=`pwd`
  
  echo -n "Installing RAVE...."

  is_installed_version "$BUILD_LOG" RAVE "$RAVE_VERSION" && echo "skipping" && return 0

  cd "$DOWNLOADS" || exit_with_error 127 "(RAVE) Could not change to download directory $DOWNLOADS"
  
  NVER=`fetch_git_software RAVE "$RAVE_SOURCE_CODE" rave "$RAVE_VERSION"` || exit_with_error 127 "(RAVE) Failed to update software"
  echo "RAVE is at version: $NVER"

  \rm -fr "$BUILDIR/rave" || exit_with_error 127 "(RAVE) Could not remove build folder"
  
  cp -r rave "$BUILDDIR/" || exit_with_error 127 "(RAVE) Could not copy source to build dir"
  \rm -fr "$BUILDDIR/rave/.git" || exit_with_error 127 "(RAVE) Could not remove unused git info"
  
  cd "$BUILDDIR/rave" || exit_with_error 127 "(RAVE) Could not change to folder $BUILDDIR/rave"
  
  #patch -p1 < "$PATCHDIR/rave.patch" || exit_with_error 127 "(RAVE) Could not patch system for building"

  RAVE_CONFIG_PARAM=`rave_config_param $PREFIX`

  echo "Using $RAVE_CONFIG_PARAM to configure rave"

  ./configure --prefix="$PREFIX/rave" --without-python $RAVE_CONFIG_PARAM || exit_with_error 127 "(RAVE) Failed to configure system"
  make         || exit_with_error 127 "(RAVE) Failed to compile software"
  make install || exit_with_error 127 "(RAVE) Failed to install software"
  
  cd "$CURRDIR" || exit_with_error 127 "(RAVE) Could not change back to folder $CURRDIR"

  add_installed_version "$BUILD_LOG" RAVE "$RAVE_VERSION"
}

install_iris2odim()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  PATCHDIR=$4
  
  BUILD_LOG="$BUILDDIR/.built_packages"
  CURRDIR=`pwd`
  
  echo -n "Installing iris2odim...."

  is_installed_version "$BUILD_LOG" IRIS2ODIM "$IRIS2ODIM_VERSION" && echo "skipping" && return 0

  cd "$DOWNLOADS" || exit_with_error 127 "(IRIS2ODIM) Could not change to download directory $DOWNLOADS"
  
  NVER=`fetch_git_software IRIS2ODIM "$IRIS2ODIM_SOURCE_CODE" iris2odim "$IRIS2ODIM_VERSION"` || exit_with_error 127 "(IRIS2ODIM) Failed to update software"
  echo "IRIS2ODIM is at version: $NVER"

  \rm -fr "$BUILDIR/iris2odim" || exit_with_error 127 "(IRIS2ODIM) Could not remove build folder"
  
  cp -r iris2odim "$BUILDDIR/" || exit_with_error 127 "(IRIS2ODIM) Could not copy source to build dir"
  \rm -fr "$BUILDDIR/iris2odim/.git" || exit_with_error 127 "(IRIS2ODIM) Could not remove unused git info"
  
  cd "$BUILDDIR/iris2odim" || exit_with_error 127 "(IRIS2ODIM) Could not change to folder $BUILDDIR/iris2odim"
  
  patch -p1 < "$PATCHDIR/iris2odim.patch" || exit_with_error 127 "(RAVE) Could not patch system for building"

  RAVEROOT=$PREFIX make         || exit_with_error 127 "(IRIS2ODIM) Failed to compile software"
  RAVEROOT=$PREFIX make install || exit_with_error 127 "(IRIS2ODIM) Failed to install software"
  
  cd "$CURRDIR" || exit_with_error 127 "(IRIS2ODIM) Could not change back to folder $CURRDIR"

  add_installed_version "$BUILD_LOG" IRIS2ODIM "$IRIS2ODIM_VERSION"
}

install_rsl()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  PATCHDIR=$4
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`
    
  BUILD_LOG="$BUILDDIR/.built_packages"
  CURRDIR=`pwd`
  
  echo -n "Installing RSL...."

  is_installed_version "$BUILD_LOG" RSL "$RSL_VERSION" && echo "skipping" && return 0

  cd "$DOWNLOADS" || exit_with_error 127 "(RSL) Could not change to download directory $DOWNLOADS"
  
  NVER=`fetch_git_software RSL "$RSL_SOURCE_CODE" rsl "$RSL_VERSION"` || exit_with_error 127 "(RSL) Failed to update software"
  echo "RSL is at version: $NVER"

  \rm -fr "$BUILDIR/rsl" || exit_with_error 127 "(RSL) Could not remove build folder"
  
  ## Imporant to preserve datetime (-p) when copying. Otherwise yacc will cause problems
  cp -p -r rsl "$BUILDDIR/" || exit_with_error 127 "(RSL) Could not copy source to build dir"
  \rm -fr "$BUILDDIR/rsl/.git" || exit_with_error 127 "(RSL) Could not remove unused git info"

  cd "$BUILDDIR/rsl" || exit_with_error 127 "(IRIS2ODIM) Could not change to folder $BUILDDIR/rsl"

  if [ "$OS_VARIANT" = "Ubuntu-20.10" -o "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
    patch -p1 < "$PATCHDIR/rsl_tirpc.patch" || exit_with_error 127 "(RSL) Failed to patch system"
  fi
  #patch -p1 < "$PATCHDIR/rsl_fwd_declarations.patch" || exit_with_error 127 "(RSL) Failed to patch fwd declarations"
    
  RSL_CFLAGS=`rsl_cflags`
  RSL_LDFLAGS=`rsl_ldflags`
  RSL_LIBS=`rsl_libs`
  
  aclocal #2>&1 >> /dev/null || exit_with_error 127 "(RSL) Could not run aclocal"
  automake #2>&1 >> /dev/null || exit_with_error 127 "(RSL) Could not run automake"
  
  if [ "$OS_VARIANT" = "Ubuntu-20.10" -o "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
    CFLAGS="$RSL_CFLAGS" LDFLAGS="$RSL_LDFLAGS" LIBS="$RSL_LIBS" ./configure --prefix="$PREFIX/rsl"
    make AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=:         || exit_with_error 127 "(RSL) Failed to compile software"
    make AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=: install || exit_with_error 127 "(RSL) Failed to install software"
  else
    CFLAGS="$RSL_CFLAGS" LDFLAGS="$RSL_LDFLAGS" LIBS="$RSL_LIBS" ./configure --prefix="$PREFIX/rsl"  || exit_with_error 127 "(RSL) Failed to configure rsl"
    make AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=:         || exit_with_error 127 "(RSL) Failed to compile software"
    make AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=: install || exit_with_error 127 "(RSL) Failed to install software"
  fi
  
  cd "$CURRDIR" || exit_with_error 127 "(RSL) Could not change back to folder $CURRDIR"

  add_installed_version "$BUILD_LOG" RSL "$RSL_VERSION"
}

install_libtorch()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  PATCHDIR=$4

  BUILD_LOG="$BUILDDIR/.built_packages"
  CURRDIR=`pwd`

  OS_NAME=`get_os_name`

  echo -n "Installing libtorch...."

  is_installed_version "$BUILD_LOG" LIBTORCH "1.10.2" && echo "skipping" && return 0

  cd "$DOWNLOADS" || exit_with_error 127 "(LIBTORCH) Could not change to download directory $DOWNLOADS"

  if [ "$OS_NAME" = "Ubuntu" -o "$OS_NAME" = "CentOS" -o "$OS_NAME" = "RedHat" -o "$OS_NAME" = "Debian GNU/Linux" ]; then
     if [ ! -f "libtorch-shared-with-deps-1.10.2+cpu.zip" ]; then
       wget https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-1.10.2%2Bcpu.zip || exit_with_error 127 "(LIBTORCH) Failed to fetch libtorch dependency"
     fi
     unzip -u libtorch-shared-with-deps-1.10.2+cpu.zip -d "${PREFIX}" || exit_with_error 127 "(LIBTORCH) Failed to unzip libtorch"
  elif [ "$OS_NAME" = "Darwin" -o "$OS_NAME" = "darwin" ]; then
     if [ "$(arch)" != "arm64" ]; then
       if [ ! -f "libtorch-macos-1.10.2.zip" ]; then
         wget https://download.pytorch.org/libtorch/cpu/libtorch-macos-1.10.2.zip || exit_with_error 127 "(LIBTORCH) Failed to fetch libtorch dependency"
       fi
       unzip -u libtorch-macos-1.10.2.zip -d "${PREFIX}" || exit_with_error 127 "(LIBTORCH) Failed to unzip libtorch"
     fi
  fi
  
  cd "$CURRDIR" || exit_with_error 127 "(LIBTORCH) Could not change back to folder $CURRDIR"

  add_installed_version "$BUILD_LOG" LIBTORCH "1.10.2"
}

install_vol2bird()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  PATCHDIR=$4
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`
  BUILD_LOG="$BUILDDIR/.built_packages"
  CURRDIR=`pwd`

  echo -n "Installing vol2bird...."

  is_installed_version "$BUILD_LOG" VOL2BIRD "$VOL2BIRD_VERSION" && echo "skipping" && return 0

  cd "$DOWNLOADS" || exit_with_error 127 "(LIBTORCH) Could not change to download directory $DOWNLOADS"
  
  NVER=`fetch_git_software VOL2BIRD "$VOL2BIRD_SOURCE_CODE" vol2bird "$VOL2BIRD_VERSION"` || exit_with_error 127 "(VOL2BIRD) Failed to update software"
  echo "VOL2BIRD is at version: $NVER"

  \rm -fr "$BUILDIR/vol2bird" || exit_with_error 127 "(VOL2BIRD) Could not remove build folder"
  
  cp -r vol2bird "$BUILDDIR/" || exit_with_error 127 "(VOL2BIRD) Could not copy source to build dir"
  \rm -fr "$BUILDDIR/vol2bird/.git" || exit_with_error 127 "(VOL2BIRD) Could not remove unused git info"
  
  cd "$BUILDDIR/vol2bird" || exit_with_error 127 "(VOL2BIRD) Could not change to folder $BUILDDIR/vol2bird"
  
  #patch -p1 < "$PATCHDIR/vol2bird.patch" || exit_with_error 127 "(VOL2BIRD) Could not patch system for building"
  #patch -p1 < "$PATCHDIR/vol2bird_defines.patch" || exit_with_error 127 "(VOL2BIRD) Could not patch defines for building"
  
  if  [ "$OS_VARIANT" = "CentOS-8" -o "$OS_VARIANT" = "RedHat-8" ]; then
    autoconf || exit_with_error 127 "(VOL2BIRD) Could not recreate configure file"
  fi

  VOL2BIRD_CONFIG_PARAM=`vol2bird_config_param $PREFIX`

  echo "VOL2BIRD PARAM: $VOL2BIRD_CONFIG_PARAM"

  echo "Using $VOL2BIRD_CONFIG_PARAM to configure vol2bird"
  echo "Using CPPFLAGS=-I`hdf5_include_dir` CFLAGS=-I`hdf5_include_dir` LIBS=`get_vol2bird_configure_LIBS`"
  CPPFLAGS=-I`hdf5_include_dir` CFLAGS=-I`hdf5_include_dir` LIBS=`get_vol2bird_configure_LIBS` ./configure --prefix="$PREFIX/vol2bird" $VOL2BIRD_CONFIG_PARAM || exit_with_error 127 "(VOL2BIRD) Failed to configure software"
  make         || exit_with_error 127 "(VOL2BIRD) Failed to compile software"
  make install || exit_with_error 127 "(VOL2BIRD) Failed to install software"

  LDPATH=`cat def.mk | grep LD_PRINTOUT | sed -e"s/LD_PRINTOUT=//" | xargs`
  
  cd "$CURRDIR" || exit_with_error 127 "(VOL2BIRD) Could not change back to folder $CURRDIR"
  
  LL_PATH_NAME=LD_LIBRARY_PATH
  if [ "$OS_NAME" = "Darwin" -o "$OS_NAME" = "darwin" ]; then
    LL_PATH_NAME=DYLD_LIBRARY_PATH
  fi
  
  cat <<EOF > "$PREFIX/vol2bird/bin/vol2bird.sh"
#!/bin/bash
export $LL_PATH_NAME=$LDPATH
export PATH=$PREFIX/rsl/bin:\$PATH
$PREFIX/vol2bird/bin/vol2bird \$@
EOF
  if [ $? -ne 0 ]; then
    exit_with_error 127 "(VOL2BIRD) Could not create start script for vol2bird"
  fi
  chmod +x "$PREFIX/vol2bird/bin/vol2bird.sh" || exit_with_error 127 "(VOL2BIRD) Could not change permissions on $PREFIX/vol2bird/bin/vol2bird.sh"
  echo "vol2bird.sh installed in $PREFIX/vol2bird/bin/vol2bird.sh"

  cat <<EOF > "$PREFIX/vol2bird/bin/rsl2odim.sh"
#!/bin/bash
export $LL_PATH_NAME=$LDPATH
export PATH=$PREFIX/rsl/bin:\$PATH
$PREFIX/vol2bird/bin/rsl2odim \$@
EOF
  if [ $? -ne 0 ]; then
    exit_with_error 127 "(VOL2BIRD) Could not create start script for rsl2odim"
  fi
  chmod +x "$PREFIX/vol2bird/bin/rsl2odim.sh" || exit_with_error 127 "(VOL2BIRD) Could not change permissions on $PREFIX/vol2bird/bin/rsl2odim.sh"
  echo "rsl2odim.sh installed in $PREFIX/vol2bird/bin/rsl2odim.sh"

  add_installed_version "$BUILD_LOG" VOL2BIRD "$VOL2BIRD_VERSION"
}


