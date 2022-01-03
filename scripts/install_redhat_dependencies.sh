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
# Performs the installation steps for installing the system on redhat based systems
#
# @author Anders Henja (HENJAB AB)
# @date 2021-12-06
###########################################################################
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

. "$SCRIPTPATH/utilities.sh"

OS_VARIANT=`get_os_version`

echo "OS_VARIANT=$OS_VARIANT"
if [ "$OS_VARIANT" != "CentOS-8" -a "$OS_VARIANT" != "CentOS-7" \
     -a "$OS_VARIANT" != "RedHat-8" -a "$OS_VARIANT" != "RedHat-7" ]; then
  exit_with_error 127 "OS variant $OS_VARIANT not supported"
fi

#
sudo yum update -y || exit_with_error 127 "Could not update apt"
sudo dnf -y install dnf-plugins-core || exit_with_error 127 "Could not install dnf plugins core"

if [ "$OS_VARIANT" = "CentOS-8" -a "$OS_VARIANT" = "CentOS-7" ]; then
  sudo yum install -y epel-release || exit_with_error 127 "Could not install epel-release"
  sudo dnf config-manager --set-enabled powertools || exit_with_error 127 "Could not enable powertools"
elif [ "$OS_VARIANT" = "RedHat-7" ]; then
  sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y || exit_with_error 127 "Could not enable latest epel release"
elif [ "$OS_VARIANT" = "RedHat-8" ]; then
  sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y || exit_with_error 127 "Could not enable latest epel release"
fi
sudo yum install -y patch || exit_with_error 127 "Could not install patch"
sudo yum install -y python3 python3-devel || exit_with_error 127 "Could not install python"
sudo yum install -y git bzip2-devel || exit_with_error 127 "Could not install dependencies"
sudo yum install -y libconfuse-devel hdf5-devel gcc gcc-c++ wget unzip make cmake zlib zlib-devel flex file || exit_with_error 127 "Could not install dependencies"
sudo yum install -y gsl gsl-devel || exit_with_error 127 "Could not install dependencies"
sudo yum install -y libtirpc-devel || exit_with_error 127 "Could not install libtirpc"
sudo yum install -y yum-utils || exit_with_error 127 "Could not install yum utils"
sudo yum install -y autoconf || exit_with_error 127 "Could not install autoconf"
