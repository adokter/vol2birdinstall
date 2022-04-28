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
# Useful script functions
#
# @author Anders Henja (HENJAB AB)
# @date 2021-09-26
###########################################################################

get_os_name()
{
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=`echo $NAME | sed -e"s/^[[:space:]]*//g" | sed -e's/[[:space:]]*$//g'`
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
      OS=RedHat
    fi
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
  elif [ -f /etc/debian_version ]; then
    OS=Debian
  elif [ -f /etc/redhat-release ]; then
    OS=`cat /etc/redhat-release`
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
      OS=RedHat
    fi
  else
    OS=$(uname -s)
  fi
  echo "$OS"
}

get_os_version()
{
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=`echo $NAME | sed -e"s/^[[:space:]]*//g" | sed -e's/[[:space:]]*$//g'`
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
      OS=RedHat
      VER=`echo $VERSION_ID | cut -d '.' -f1`
    elif [ "$OS" = "CentOS" ]; then
      VER=`echo $VERSION_ID | cut -d '.' -f1`
    else
      VER=`echo $VERSION_ID`  
    fi
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    OS=Debian
    VER=$(cat /etc/debian_version)
  elif [ -f /etc/redhat-release ]; then
    OS=`cat /etc/redhat-release`
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
      OS=RedHat
    fi    
    VER=`cat /etc/redhat-release | cut -d' ' -f4 | cut -d'.' -f1`
  else
    OS=$(uname -s)
    VER=$(uname -r)
  fi
  echo "$OS-$VER"
}

exit_with_error()
{
  echo "$2" 1>&2
  exit $1
}

# Verifies if the arg exists as a unique string in the file f
# Arguments:
#   1  : The file that should be used queried
#   2  : The string that should be matched, will be ^$2$
#   3  : (optional, if specified, then this string will be printed on success)
# Returns:
#   1  : If exists
#   0  : If not exist
#
has_been_installed() {
  if [ ! -f "$1" ]; then
    echo ""
    return 0
  fi
  VAR=`cat "$1" | egrep '^'"$2"'$'`
  if [ "$VAR" != "" ]; then
    if [ "$3" != "" ]; then
      echo "$3"
    fi
    return 1
  fi
  echo ""
  return 0;
}

# Returns the installed version.
# Arguments:
#   1  : The file that should be queried
#   2  : The module name
# Returns:
#   1  : If exists (will also echo the version, might be empty meaning that there is no version info available but module is there)
#   0  : If not exists
installed_version() {
  if [ ! -f "$1" ]; then
    echo ""
    return 0
  fi
  VAR=`cat "$1" | egrep "MODULE=$2[[:space:]]+"`
  if [ "$VAR" = "" ]; then
    # Verify old info
    VAR=`cat "$1" | egrep '^'"$2"'$'`
    if [ "$VAR" != "" ]; then
      echo ""
      return 1
    fi
    return 0
  fi
  VER=`echo $VAR | sed -e"s/\(.*\)\(VERSION=\)\([^$]*\)/\3/g"`
  echo "$VER"
  return 1
}

# Returns if the specified module version is installed
# Arguments:
#   1  : The file that should be queried
#   2  : The module name
#   3  : The expected version
# Returns:
#   0  : If it is installed
#   1  : Otherwise
is_installed_version() {
  VER=`installed_version "$1" "$2"`
  RES=$?
  #echo "RES: $RES VER=$VER, EXP=$3" 1>&2
  if [ $RES -eq 1 -a "$VER" = "$3" ]; then
    return 0
  fi
  return 1
}

# Removes an installed entity from the install file
# Arguments:
#   1  : The file that should get one entity removed
#   2  : The string that should be removed
#
remove_installed() {
  if [ ! -f "$1" ]; then
    return
  fi
  cat "$1" | egrep -v '^'"$2"'$' | egrep -v "^MODULE=$2[[:space:]]+" > "$1.new"
  \mv "$1.new" "$1"
}

# Adds the arg string to a file
# Arguments:
#   1  : The file that should be appended to
#   2  : The string that should be appended
#   3  : The version of the installed module
#
add_installed_version() {
  if [ ! -f "$1" ]; then
    touch "$1"
  fi
  remove_installed "$1" "$2"
  echo "MODULE=$2	VERSION=$3" >> "$1"
}

# Adds the arg string to a file
# Arguments:
#   1  : The file that should be appended to
#   2  : The string that should be appended
#
add_installed() {
  if [ ! -f "$1" ]; then
    touch "$1"
  fi
  echo $2 >> "$1"
}

# Fetches the specific project from the gitrepository
# and atempts to get the correct version. It will only
# fetch from the master refspec for now.
# Arguments:
#   1  : The debug printout tag
#   2  : Specifies the full git uri
#   3  : Specifies the directory that will originate from the above git uri
#   4  : Specify the version to build from (default is 'latest')
# Returns:
#   0  on success
# Stdout:
#   The current version (git describe)
# Exits:
#   On any type of error except if it not is possible to describe the project
#
fetch_git_software() 
{
  MODULE=$1
  GITURI=$2
  REPODIR=$3
  VERSION=$4
  
  if [ ! -d "$REPODIR" ]; then
    git clone "$GITURI" 1>&2      || exit_with_error "($MODULE) Could not fetch $GITURI from git repository"
  fi
  cd "$REPODIR"                                      || exit_with_error "($MODULE) Could not enter $REPODIR directory"
  git pull "$GITURI" HEAD:master 1>&2 || exit_with_error "($MODULE) Could not update $REPODIR"

  if [ "$VERSION" != "" ]; then
    git checkout "$VERSION" 1>&2                     || exit_with_error "($MODULE) Could not checkout $REPODIR ($VERSION)"
  fi
  CVER=`git describe`
  if [ $? -eq 0 ]; then
    echo "$CVER"
  else
    echo "$VERSION"
  fi
  cd ..
  return 0
}

