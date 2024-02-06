#!/bin/bash
#
# This script installs and configures dudect.

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please, run with sudo or as root.'
  exit 1
fi

DUDECT_SHARE_DIR=/usr/share/dudect

# Download dudect.
if ! git clone https://github.com/oreparaz/dudect.git $DUDECT_SHARE_DIR
then
  echo 'Dudect could not be downloaded.'
  exit 1
fi


# Build dudect.
cd $DUDECT_SHARE_DIR || exit

if ! make
then
  echo 'Dudect could not be built.'
  exit 1
fi


# Replace all occurences of function randombytes in dudect.h by randombytes_dudect

if ! sed -i "s/randombytes/randombytes_dudect/g" "$DUDECT_SHARE_DIR"/src/dudect.h
then
  echo "Could not replace occurences of function randombytes by randombytes_dudect in dudect.h"
  exit 1
fi


if ! cp $DUDECT_SHARE_DIR/src/dudect.h /usr/include/dudect.h
  then
    echo "Could not find $DUDECT_SHARE_DIR/scr/dudect.h"
    exit 1
fi

exit 0
