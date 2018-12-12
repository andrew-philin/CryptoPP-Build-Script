#!/bin/bash

XCODE_ROOT=`xcode-select -print-path`
ARCHS="x86_64 i386 armv7 armv7s arm64"
SDK_VERSION="12.0"
FRAMEWORK_NAME="CryptoPP"
LIBRARY_FILE="libcryptopp.a"
STATIC_ARCHIVES=""

for ARCH in ${ARCHS}
do
    PLATFORM=""
    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi

    export DEV_ROOT="${XCODE_ROOT}/Platforms/${PLATFORM}.platform/Developer"
    export SDK_ROOT="${DEV_ROOT}/SDKs/${PLATFORM}${SDK_VERSION}.sdk"
    export TOOLCHAIN_ROOT="${XCODE_ROOT}/Toolchains/XcodeDefault.xctoolchain/usr/bin/"
    export CC=clang
    export CXX=clang++
    export AR=${TOOLCHAIN_ROOT}libtool
    export RANLIB=${TOOLCHAIN_ROOT}ranlib
    export ARFLAGS="-static -o"
    export LDFLAGS="-arch ${ARCH} -isysroot ${SDK_ROOT}"
    export BUILD_PATH="BUILD_${ARCH}"
    export CXXFLAGS="-x c++ -arch ${ARCH} -isysroot ${SDK_ROOT} -I${BUILD_PATH}"
    mkdir -p ${BUILD_PATH}

    make -f Makefile

    mv *.o ${BUILD_PATH}
    mv *.d ${BUILD_PATH}
    mv  ${LIBRARY_FILE} ${BUILD_PATH}

    STATIC_ARCHIVES="${STATIC_ARCHIVES} ${BUILD_PATH}/${LIBRARY_FILE}"

done

echo "Creating static library..."
mkdir -p release
lipo -create ${STATIC_ARCHIVES} -output release/${LIBRARY_FILE}
echo "Creating static library done!"

echo "Copying headers..."
cp *.h release/
echo "Copying headers done!"

echo "Making framework..."
mkdir -p ${FRAMEWORK_NAME}.framework/Versions/A
cp release/${LIBRARY_FILE} ${FRAMEWORK_NAME}.framework/Versions/A/${FRAMEWORK_NAME}
mkdir -p ${FRAMEWORK_NAME}.framework/Versions/A/Headers
cp release/*.h ${FRAMEWORK_NAME}.framework/Versions/A/Headers
ln -sfh A ${FRAMEWORK_NAME}.framework/Versions/Current
ln -sfh Versions/Current/${FRAMEWORK_NAME} ${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}
ln -sfh Versions/Current/Headers ${FRAMEWORK_NAME}.framework/Headers
echo "Making framework done!"

echo "BUILD SUCCESSFUL!"
