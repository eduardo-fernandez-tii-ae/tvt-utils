#!/bin/bash
#
# This script installs and configures ctgrind.

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please, run with sudo or as root.'
  exit 1
fi

# Build and install ctgrind.
CTGRIND_SHARE_DIR=/usr/share/ctgrind
CTGRIND_TMP_DIR=/tmp/ctgrind
INCLUDE_DIR=/usr/include
TMP_DIR=/tmp

# Create ctgrind share directory.
mkdir $CTGRIND_SHARE_DIR

# Copy ctgrind libraries to ctgrind share directory.
if ! find $CTGRIND_TMP_DIR -type f -name "ctgrind.*" -exec cp {} $CTGRIND_SHARE_DIR \;
then
  echo 'Ctgrind libraries could not be copied to ctgrind share directory.'
  exit 1
fi

# Copy ctgrind header file to include directory.
if ! find $CTGRIND_TMP_DIR -type f -name "ctgrind.h" -exec cp {} $INCLUDE_DIR \;
then
  echo 'Ctgrind header file could not be copied to include directory.'
  exit 1
fi

# Build ctgrind.
cd $CTGRIND_SHARE_DIR || exit

if ! gcc -o libctgrind.so -shared $CTGRIND_TMP_DIR/src/ctgrind.c -Wall -std=c99 -fPIC -Wl,-soname,libctgrind.so.1
then
  echo 'Ctgrind could not be built.'
  exit 1
fi

cp libctgrind.so /usr/lib
cd /usr/lib || exit

if ! ln -s libctgrind.so libctgrind.so.1
then
  echo 'Ctgrind symbolic link could not be created.'
  exit 1
fi

# Patch with ctgrind.
if ! find $CTGRIND_TMP_DIR -type f -name "valgrind.patch" -exec cp {} $TMP_DIR \;
then
  echo 'Valgrind patch file could not be copied to tmp directory.'
  exit 1
fi

# Apply the patch.
cd $TMP_DIR || exit

if ! patch -p0 < $TMP_DIR/valgrind.patch
then
  echo 'Valgrind patch file could not be applied.'
  exit 1
fi

exit 0
