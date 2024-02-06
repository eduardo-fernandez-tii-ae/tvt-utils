#!/bin/bash
#
# This script installs and configures flowtracker.

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please, run with sudo or as root.'
  exit 1
fi

FLOWTRACKER_TMP_DIR=/tmp/flowtracker-local-copy
NUM_PROCESSORS=8
TMP_DIR=/tmp

# Get LLVM toolchain technologies.
if ! wget -O $TMP_DIR/llvm.src.tar.xz "https://www.llvm.org/releases/3.7.1/llvm-3.7.1.src.tar.xz"    || \
   ! wget -O $TMP_DIR/cfe-3.7.1.src.tar.xz "http://www.llvm.org/releases/3.7.1/cfe-3.7.1.src.tar.xz"
then
  echo 'LLVM could not be downloaded.'
  exit 1
fi

# Extract LLVM toolchain technologies into the home directory.
if ! tar -xf $TMP_DIR/llvm.src.tar.xz -C "$HOME"                            || \
   ! tar -xf $TMP_DIR/cfe-3.7.1.src.tar.xz -C "$HOME"/llvm-3.7.1.src/tools/
then
  echo 'LLVM files could not be extracted.'
  exit 1
fi

# Move LLVM files to clang directory. 
if ! mv "$HOME"/llvm-3.7.1.src/tools/cfe-3.7.1.src "$HOME"/llvm-3.7.1.src/tools/clang
then
  echo 'LLVM files could not be moved.'
  exit 1
fi

# Create Transforms directory.
if ! mkdir -p "$HOME"/llvm-3.7.1.src/build/lib/Transforms
then
  echo 'Transforms directory could not be created.'
  exit 1
fi

# Download flowtracker.
if ! git clone https://github.com/dfaranha/FlowTracker.git $FLOWTRACKER_TMP_DIR
then
  echo 'Flowtracker could not be downloaded.'
  exit 1
fi

# Copy flowtracker libraries.
if ! cp -r $FLOWTRACKER_TMP_DIR/{AliasSets,DepGraph,bSSA2} "$HOME"/llvm-3.7.1.src/lib/Transforms       || \
   ! cp -r $FLOWTRACKER_TMP_DIR/{AliasSets,DepGraph,bSSA2} "$HOME"/llvm-3.7.1.src/build/lib/Transforms
then
  echo 'Flowtracker libraries could not be copied.'
  exit 1
fi

# Update ValueMap header file.
if ! sed -i "s#bool hasMD() const { return MDMap; }#bool hasMD() const { return bool(MDMap); }#g" "$HOME"/llvm-3.7.1.src/include/llvm/IR/ValueMap.h
then
  echo 'ValueMap header file could not be updated.'
  exit 1
fi

# Build LLVM toolchain.
cd "$HOME"/llvm-3.7.1.src/build || exit

if ! ../configure --disable-bindings || \
   ! make -j$NUM_PROCESSORS
then
  echo 'LLVM toolchain could not be built.'
  exit 1
fi

PATH="$PATH:/root/llvm-3.7.1.src/build/Release+Asserts/bin"

# Build AliasSets library.
cd "$HOME"/llvm-3.7.1.src/build/lib/Transforms/AliasSets || exit

if ! make -j$NUM_PROCESSORS
then
  echo 'AliasSets library could not be built.'
  exit 1
fi

# Build DepGraph library.
cd "$HOME"/llvm-3.7.1.src/build/lib/Transforms/DepGraph || exit

if ! make -j$NUM_PROCESSORS
then
  echo 'DepGraph library could not be built.'
  exit 1
fi

# Build bSSA2 library.
cd "$HOME"/llvm-3.7.1.src/build/lib/Transforms/bSSA2 || exit

if ! make -j$NUM_PROCESSORS                                       || \
   ! g++ -shared -o parserXML.so -fPIC parserXML.cpp tinyxml2.cpp
then
  echo 'bSSA2 library could not be built.'
  exit 1
fi

exit 0
