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
HLHDF_VERSION=hlhdf-build-4

RAVE_SOURCE_CODE=https://github.com/baltrad/rave.git
RAVE_VERSION=rave-build-10

IRIS2ODIM_SOURCE_CODE=https://github.com/adokter/iris2odim.git
IRIS2ODIM_VERSION=376ae90cf93baafe225e4d394f634fd178e9a238

RSL_SOURCE_CODE=https://github.com/adokter/rsl.git
RSL_VERSION=v1.49-25-ga69cd97

VOL2BIRD_SOURCE_CODE=https://github.com/adokter/vol2bird.git
VOL2BIRD_VERSION=0.5.0-81-g8a23dfb

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
  if [ "$OS_NAME" = "Ubuntu" ]; then
    echo "/usr/include/hdf5/serial"
  else
    X=`locate hdf5.h  | head -h | sed -e "s/\/hdf5.h//g"`
    echo "$X"
  fi
}

hlhdf_config_param()
{
  PREFIX=$1
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`
  HLHDF_CONFIG_PARAMS=""
  if [ "$OS_NAME" = "Ubuntu" ]; then
    HLHDF_CONFIG_PARAMS="--with-hdf5=/usr/include/hdf5/serial,/usr/lib/x86_64-linux-gnu/hdf5/serial --with-zlib=/usr/include,/usr/lib/x86_64-linux-gnu"
  else
    echo "Not a prededfined OS, using best effort to identify hlhdf config parameters"
    echo ""
  fi
  echo "--without-python $HLHDF_CONFIG_PARAMS"
}

rave_config_param()
{
  PREFIX=$1
  OS_VARIANT=`get_os_version`
  OS_NAME=`get_os_name`
  RAVE_CONFIG_PARAMS=""
  if [ "$OS_NAME" = "Ubuntu" ]; then
    RAVE_CONFIG_PARAMS="--with-hlhdf=$PREFIX/hlhdf --with-proj=/opt/vol2bird"
  else
    echo "Not a prededfined OS, using best effort to identify rave config parameters"
    echo ""
  fi
  echo "$RAVE_CONFIG_PARAMS"
}

rsl_cflags()
{
  OS_VARIANT=`get_os_version`
  if [ "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" ]; then
    echo "-I"`dpkg-query -L libtirpc-dev | grep "rpc/rpc.h" | sed -e "s/rpc\/rpc.h//g"`
  fi
  echo ""
}

rsl_ldflags()
{
  OS_VARIANT=`get_os_version`
  if [ "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" ]; then
    echo "-L"`dpkg-query -L libtirpc-dev | egrep -e 'libtirpc.so$' | sed -e "s/\/libtirpc.so//g"`
  fi
  echo ""
}

vol2bird_config_param()
{
  PREFIX=$1
  OS_VARIANT=`get_os_version`
  VOL2BIRD_CONFIG_PARAMS="--with-libtorch=$PREFIX/libtorch --with-rsl=$PREFIX/rsl --with-rave=$PREFIX/rave --with-iris=yes"
  
  if [ "$OS_VARIANT" = "Ubuntu-18.04" -o "$OS_VARIANT" = "Ubuntu-18.10" ]; then
    GSLINC=`dpkg-query -L libgsl-dev | grep gsl/gsl_vector.h | sed -e "s/\/gsl\/gsl_vector.h//g"`
    GSLLIB=`dpkg-query -L libgsl-dev | egrep -e "libgsl.so$" | sed -e "s/\/libgsl.so//g"`
    CONFUSEINC=`dpkg-query -L libconfuse-dev | grep confuse.h | sed -e "s/\/confuse.h//g"`
    CONFUSELIB=`dpkg-query -L libconfuse-dev | grep libconfuse.so | sed -e "s/\/libconfuse.so//g"`
    VOL2BIRD_CONFIG_PARAMS="$VOL2BIRD_CONFIG_PARAMS --with-gsl=$GSLINC,$GSLLIB --with-confuse=$CONFUSEINC,$CONFUSELIB"
  elif [ "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" != "Ubuntu-21.10" ]; then
    GSLINC=`dpkg-query -L libgsl-dev | grep gsl/gsl_vector.h | sed -e "s/\/gsl\/gsl_vector.h//g"`
    GSLLIB=`dpkg-query -L libgsl-dev | egrep -e "libgsl.so$" | sed -e "s/\/libgsl.so//g"`
    CONFUSEINC=`dpkg-query -L libconfuse-dev | grep confuse.h | sed -e "s/\/confuse.h//g"`
    CONFUSELIB=`dpkg-query -L libconfuse-dev | grep libconfuse.so | sed -e "s/\/libconfuse.so//g"`
    VOL2BIRD_CONFIG_PARAMS="$VOL2BIRD_CONFIG_PARAMS --with-gsl=$GSLINC,$GSLLIB --with-confuse=$CONFUSEINC,$CONFUSELIB"
  else
    echo "Not a prededfined OS, using best effort to identify vol2bird config parameters"
    GSLROOT=`locate "gsl/gsl_vector.h" | head -1 | sed -e "s/\/gsl\/gsl_vector.h//g"`
  fi
  echo "$VOL2BIRD_CONFIG_PARAMS"
}

get_vol2bird_configure_LIBS()
{
  OS_VARIANT=`get_os_version`
  VOL2BIRD_configure_LIBS=
  
  if [ "$OS_VARIANT" = "Ubuntu-18.04" -o "$OS_VARIANT" = "Ubuntu-18.10" ]; then
    VOL2BIRD_configure_LIBS=
  elif [ "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" != "Ubuntu-21.10" ]; then
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
    wget "$PROJ4_SOURCE_CODE" -O- > "$DOWNLOADS/$TARBALL"
  fi

  CURRDIR=`pwd`
  
  cd $BUILDDIR
  tar -xvzf "$DOWNLOADS/$TARBALL"
  cd `echo $TARBALL | sed -e "s/\.tar\.gz//g"`
  ./configure --prefix="$PREFIX" --without-jni || exit_with_error 127 "(PROJ.4) Could not configure"
  make                                         || exit_with_error 127 "(PROJ.4) Could not make"
  make install                                 || exit_with_error 127 "(PROJ.4) Could not install"

  cd $CURRDIR

  add_installed_version "$BUILD_LOG" PROJ4 "$EXPECTED_PROJ4_VERSION"
}

install_hlhdf()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  BUILD_LOG="$BUILDDIR/.built_packages"

  CURRDIR=`pwd`
  
  echo -n "Installing HLHDF...."

  is_installed_version "$BUILD_LOG" HLHDF "$HLHDF_VERSION" && echo "skipping" && return 0

  cd "$DOWNLOADS"
  
  NVER=`fetch_git_software HLHDF "$HLHDF_SOURCE_CODE" hlhdf "$HLHDF_VERSION"` || exit_with_error 127 "(HLHDF) Failed to update software"
  echo "HLHDF is at version: $NVER"

  \rm -fr "$BUILDIR/hlhdf" || exit_with_error 127 "(HLHDF) Could not remove build folder"
  
  cp -r hlhdf "$BUILDDIR/"
  \rm -fr "$BUILDDIR/hlhdf/.git"

  cd "$BUILDDIR/hlhdf"

  HLHDF_CONFIG_PARAM=`hlhdf_config_param $PREFIX`

  echo "Using $HLHDF_CONFIG_PARAM to configure hlhdf"

  ./configure --prefix="$PREFIX/hlhdf" $HLHDF_CONFIG_PARAM
  make         || exit_with_error 127 "(HLHDF) Failed to compile software"
  make install || exit_with_error 127 "(HLHDF) Failed to install software"
  
  cd "$CURRDIR"

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

  cd "$DOWNLOADS"
  
  NVER=`fetch_git_software RAVE "$RAVE_SOURCE_CODE" rave "$RAVE_VERSION"` || exit_with_error 127 "(RAVE) Failed to update software"
  echo "RAVE is at version: $NVER"

  \rm -fr "$BUILDIR/rave" || exit_with_error 127 "(RAVE) Could not remove build folder"
  
  cp -r rave "$BUILDDIR/"
  \rm -fr "$BUILDDIR/rave/.git"
  
  cd "$BUILDDIR/rave"
  
  patch -p1 < "$PATCHDIR/rave.patch"

  RAVE_CONFIG_PARAM=`rave_config_param $PREFIX`

  echo "Using $RAVE_CONFIG_PARAM to configure rave"

  ./configure --prefix="$PREFIX/rave" --without-python $RAVE_CONFIG_PARAM
  make         || exit_with_error 127 "(RAVE) Failed to compile software"
  make install || exit_with_error 127 "(RAVE) Failed to install software"
  
  cd "$CURRDIR"

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

  cd "$DOWNLOADS"
  
  NVER=`fetch_git_software IRIS2ODIM "$IRIS2ODIM_SOURCE_CODE" iris2odim "$IRIS2ODIM_VERSION"` || exit_with_error 127 "(IRIS2ODIM) Failed to update software"
  echo "IRIS2ODIM is at version: $NVER"

  \rm -fr "$BUILDIR/iris2odim" || exit_with_error 127 "(IRIS2ODIM) Could not remove build folder"
  
  cp -r iris2odim "$BUILDDIR/"
  \rm -fr "$BUILDDIR/iris2odim/.git"
  
  cd "$BUILDDIR/iris2odim"
  
  patch -p1 < "$PATCHDIR/iris2odim.patch"

  RAVEROOT=$PREFIX make         || exit_with_error 127 "(IRIS2ODIM) Failed to compile software"
  RAVEROOT=$PREFIX make install || exit_with_error 127 "(IRIS2ODIM) Failed to install software"
  
  cd "$CURRDIR"

  add_installed_version "$BUILD_LOG" IRIS2ODIM "$IRIS2ODIM_VERSION"
}

install_rsl()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  PATCHDIR=$4
  
  BUILD_LOG="$BUILDDIR/.built_packages"
  CURRDIR=`pwd`
  
  echo -n "Installing RSL...."

  is_installed_version "$BUILD_LOG" RSL "$RSL_VERSION" && echo "skipping" && return 0

  cd "$DOWNLOADS"
  
  NVER=`fetch_git_software RSL "$RSL_SOURCE_CODE" rsl "$RSL_VERSION"` || exit_with_error 127 "(RSL) Failed to update software"
  echo "RSL is at version: $NVER"

  \rm -fr "$BUILDIR/rsl" || exit_with_error 127 "(RSL) Could not remove build folder"
  
  ## Imporant to preserve datetime (-p) when copying. Otherwise yacc will cause problems
  cp -p -r rsl "$BUILDDIR/"
  \rm -fr "$BUILDDIR/rsl/.git"

  cd "$BUILDDIR/rsl"

  OS_VARIANT=`get_os_version`
  if [ "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" ]; then
    patch -p1 < "$PATCHDIR/rsl_tirpc.patch" || exit_with_error 127 "Failed to patch rsl"
  fi
  
  RSL_CFLAGS=`rsl_cflags`
  RSL_LDFLAGS=`rsl_ldflags`
  
  aclocal #2>&1 >> /dev/null
  automake #2>&1 >> /dev/null
  
  if [ "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" ]; then
    CFLAGS="$RSL_CFLAGS" LDFLAGS="$RSL_LDFLAGS" LIBS=-ltirpc ./configure --prefix="$PREFIX/rsl"
    make AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=:         || exit_with_error 127 "(RSL) Failed to compile software"
    make AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=: install || exit_with_error 127 "(RSL) Failed to install software"
  else
    CFLAGS="$RSL_CFLAGS" LDFLAGS="$RSL_LDFLAGS" ./configure --prefix="$PREFIX/rsl"  || exit_with_error 127 "(RSL) Failed to configure rsl"
    make AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=:         || exit_with_error 127 "(RSL) Failed to compile software"
    make AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=: install || exit_with_error 127 "(RSL) Failed to install software"
  fi
  
  cd "$CURRDIR"

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

  is_installed_version "$BUILD_LOG" LIBTORCH "1.7.1" && echo "skipping" && return 0

  cd "$DOWNLOADS"

  if [ "$OS_NAME" = "Ubuntu" ]; then
     if [ ! -f "libtorch-shared-with-deps-1.7.1+cpu.zip" ]; then
       wget https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-1.7.1%2Bcpu.zip || exit_with_error 127 "Failed to fetch libtorch dependency"
     fi
     unzip -u libtorch-shared-with-deps-1.7.1+cpu.zip -d "${PREFIX}" || exit_with_error 127 "Failed to unzip libtorch"
  elif [ "$OS_NAME" = "MacOS" ]; then  
     if [ ! -f "libtorch-shared-with-deps-1.7.1+cpu.zip" ]; then
       wget https://download.pytorch.org/libtorch/cpu/libtorch-macos-1.7.1.zip || exit_with_error 127 "Failed to fetch libtorch dependency"
     fi
     unzip -u libtorch-macos-1.7.1.zip -d "${PREFIX}" || exit_with_error 127 "Failed to unzip libtorch"
  fi
  
  cd "$CURRDIR"

  add_installed_version "$BUILD_LOG" LIBTORCH "1.7.1"
}

install_vol2bird()
{
  DOWNLOADS=$1
  BUILDDIR=$2
  PREFIX=$3
  PATCHDIR=$4

  BUILD_LOG="$BUILDDIR/.built_packages"
  CURRDIR=`pwd`

  echo -n "Installing vol2bird...."

  is_installed_version "$BUILD_LOG" VOL2BIRD "$VOL2BIRD_VERSION" && echo "skipping" && return 0

  cd "$DOWNLOADS"
  
  NVER=`fetch_git_software VOL2BIRD "$VOL2BIRD_SOURCE_CODE" vol2bird "$VOL2BIRD_VERSION"` || exit_with_error 127 "(VOL2BIRD) Failed to update software"
  echo "VOL2BIRD is at version: $NVER"

  \rm -fr "$BUILDIR/vol2bird" || exit_with_error 127 "(VOL2BIRD) Could not remove build folder"
  
  cp -r vol2bird "$BUILDDIR/"
  \rm -fr "$BUILDDIR/vol2bird/.git"
  
  cd "$BUILDDIR/vol2bird"
  
  patch -p1 < "$PATCHDIR/vol2bird.patch"

  VOL2BIRD_CONFIG_PARAM=`vol2bird_config_param $PREFIX`

  echo "VOL2BIRD PARAM: $VOL2BIRD_CONFIG_PARAM"

  echo "Using $VOL2BIRD_CONFIG_PARAM to configure vol2bird"

  CPPFLAGS=-I`hdf5_include_dir` CFLAGS=-I`hdf5_include_dir` LIBS=`get_vol2bird_configure_LIBS` ./configure --prefix="$PREFIX/vol2bird" $VOL2BIRD_CONFIG_PARAM
  make         || exit_with_error 127 "(VOL2BIRD) Failed to compile software"
  make install || exit_with_error 127 "(VOL2BIRD) Failed to install software"

  LDPATH=`cat def.mk | grep LD_PRINTOUT | sed -e"s/LD_PRINTOUT=//" | xargs`
  
  cd "$CURRDIR"
  
  cat <<EOF > "$PREFIX/vol2bird/bin/vol2bird.sh"
#!/bin/bash
export LD_LIBRARY_PATH=$LDPATH
$PREFIX/vol2bird/bin/vol2bird \$@
EOF
  chmod +x "$PREFIX/vol2bird/bin/vol2bird.sh"
  echo "vol2bird.sh installed in $PREFIX/vol2bird/bin/vol2bird.sh"
  add_installed_version "$BUILD_LOG" VOL2BIRD "$VOL2BIRD_VERSION"
}


