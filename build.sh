#!/bin/bash

if [ "x$1" == "x" ]; then
  echo "Missing node version"
  exit 1
fi

ndkver=
if [ "x$2" == "x" ]; then
  ndkver="23.0.7599858"
else
  ndkver="$2"
fi

arch=
if [ "x$3" == "x" ]; then
  arch="arm64"
else
  arch="$3"
fi

sdkver=
if [ "x$4" == "x" ]; then
  sdkver="23"
else
  sdkver="$4"
fi

nodever="$1"
tarfile="v$nodever.zip"

if [ ! -f "$tarfile" ]; then
  curl -OL "https://github.com/nodejs/node/archive/refs/tags/$tarfile"
  # curl -OL "https://hub.fastgit.org/nodejs/node/archive/refs/tags/$tarfile"
fi

unzip -d . "$tarfile" >/dev/null

dir="node-$nodever"
cd "$dir"
patch -p0 < ../android-configure.patch
chmod +x ./android-configure
cat ./android-configure
./android-configure "$ANDROID_HOME/ndk/$ndkver" "$arch" "$sdkver"
make

outdir="build"
mkdir -p "../$outdir/lib"
HEADERS_ONLY=1 python3 ./tools/install.py install "../$outdir" /
cp -rpf "./out/Release/libnode.so" "../$outdir/lib/libnode.so"
cd ..

zipname="build-$nodever.zip"

rm -rf "$zipname"

type zip >/dev/null 2>&1
if [ "x$?" == "x0" ]; then
  cd "$outdir"
  zip -r -y "../$zipname" .
  cd ..
else
  powershell.exe -nologo -noprofile -command \
    '& { param([String]$sourceDirectoryName, [String]$destinationArchiveFileName, [Boolean]$includeBaseDirectory); Add-Type -A "System.IO.Compression.FileSystem"; Add-Type -A "System.Text.Encoding"; [IO.Compression.ZipFile]::CreateFromDirectory($sourceDirectoryName, $destinationArchiveFileName, [IO.Compression.CompressionLevel]::Fastest, $includeBaseDirectory, [System.Text.Encoding]::UTF8); exit !$?;}' \
    -sourceDirectoryName "\"$outdir\"" \
    -destinationArchiveFileName "$zipname" \
    -includeBaseDirectory '$false'
  if [ $? -ne 0 ]; then
    echo "Zip failed"
    exit $?
  fi
fi

# rm -rf "$outdir"
# rm -rf "$dir"
# # rm -rf "$tarfile"
