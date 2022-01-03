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
# Performs the installation steps for installing the system on debian systems
#
# @author Anders Henja (HENJAB AB)
# @date 2021-09-26
###########################################################################
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

. "$SCRIPTPATH/utilities.sh"

OS_VARIANT=`get_os_version`

if [ "$OS_VARIANT" != "Ubuntu-18.04" -a "$OS_VARIANT" != "Ubuntu-18.10" \
     -a "$OS_VARIANT" != "Ubuntu-19.04" -a "$OS_VARIANT" != "Ubuntu-19.10" \
     -a "$OS_VARIANT" != "Ubuntu-20.04" -a "$OS_VARIANT" != "Ubuntu-20.10" \
     -a "$OS_VARIANT" != "Ubuntu-21.04" -a "$OS_VARIANT" != "Ubuntu-21.10" ]; then
  exit_with_error 127 "OS variant $OS_VARIANT not supported"
fi

#
sudo apt-get update || exit_with_error 127 "Could not update apt"
sudo apt-get install --no-install-recommends -y git libbz2-dev || exit_with_error 127 "Could not install dependencies"
sudo apt-get install --no-install-recommends -y libconfuse-dev libhdf5-dev gcc g++ wget unzip make cmake zlib1g-dev flex-old file || exit_with_error 127 "Could not install dependencies"
sudo apt-get install --no-install-recommends -y gsl-bin libgsl-dev || exit_with_error 127 "Could not install dependencies"

if [ "$OS_VARIANT" = "Ubuntu-21.04" -o "$OS_VARIANT" = "Ubuntu-21.10" ]; then
  sudo apt-get install --no-install-recommends -y libtirpc-common libtirpc-dev libtirpc3
fi

