#!/bin/sh

# Copy this file to the root of your boost directory and run it there.
# Run this script to build boost. Copy the static libraries from the `arm64` and `x86_64` directories into Source/boost-<version/lib

rm -rf arm64 x86_64 universal stage bin.v2
rm -f b2 project-config*
./bootstrap.sh --with-libraries=iostreams,serialization,thread cxxflags="-arch x86_64 -arch arm64" cflags="-arch x86_64 -arch arm64" linkflags="-arch x86_64 -arch arm64"

./b2 toolset=clang-darwin target-os=darwin architecture=arm abi=aapcs cxxflags="-arch arm64 -target arm64-apple-macos12.0 -std=c++11" cflags="-arch arm64 -target arm64-apple-macos12.0" linkflags="-arch arm64" -a
mkdir -p arm64 && cp stage/lib/*.dylib arm64 cp stage/lib/*.a arm64

./b2 toolset=clang-darwin target-os=darwin architecture=x86 cxxflags="-arch x86_64 -target arm64-apple-macos12.0 -std=c++11" cflags="-arch x86_64 -target arm64-apple-macos12.0" linkflags="-arch x86_64" abi=sysv binary-format=mach-o -a
mkdir x86_64 && cp stage/lib/*.dylib x86_64 && cp stage/lib/*.a x86_64

mkdir universal
for dylib in arm64/*.dylib; do 
  lipo -create -arch arm64 $dylib -arch x86_64 x86_64/$(basename $dylib) -output universal/$(basename $dylib); 
done
for dylib in universal/*.dylib; do
  lipo $dylib -info;
done
