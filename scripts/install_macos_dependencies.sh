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
# Performs the installation steps for installing the system on mac systems
#
# @author Anders Henja (HENJAB AB)
# @date 2022-01-04
###########################################################################
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

. "$SCRIPTPATH/utilities.sh"

OS_VARIANT=`get_os_version`

echo "$OS_VARIANT"

brew install proj
brew install confuse hdf5@1.10 gcc wget zlib flex automake libtool cmake || exit_with_error 127 "Could not install dependencies"
brew install gsl libtorch || exit_with_error 127 "Could not install dependencies"

