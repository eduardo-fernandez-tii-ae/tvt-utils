#!/bin/bash
#
# This script installs and configures valgrind.

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please, run with sudo or as root.'
  exit 1
fi

NUM_PROCESSORS=8
TMP_DIR=/tmp

# Download valgrind.
if ! wget -O $TMP_DIR/valgrind.tar.bz2 "https://sourceware.org/pub/valgrind/valgrind-3.16.1.tar.bz2"
then
  echo 'Valgrind could not be downloaded.'
  exit 1
fi

# Extract valgrind files.
if ! tar -xf $TMP_DIR/valgrind.tar.bz2 -C $TMP_DIR
then
  echo 'Valgrind files could not be extracted.'
  exit 1
fi

# Install Valgrind.
cd $TMP_DIR/valgrind-3.16.1 || exit

if ! ./configure --prefix=/usr/share/valgrind
then
  echo 'Valgrind could not be configured.'
  exit 1
fi

if ! make -j$NUM_PROCESSORS
then
  echo 'Valgrind could not be built.'
  exit 1
fi

if ! make install
then
  echo 'Valgrind could not be installed.'
  exit 1
fi

exit 0
