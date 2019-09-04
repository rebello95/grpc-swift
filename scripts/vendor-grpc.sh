#!/bin/sh

# Copyright 2019, gRPC Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script vendors the gRPC Core library into the
# CgRPC module in a form suitable for building with
# the Swift Package Manager.
#
# For usage, see `vendor-all.sh`.

source ./tmp/grpc/swift-vendoring.sh

TMP_DIR=./tmp
DSTROOT=../Sources
DSTASSETS=../Assets

#
# Remove previously-vendored code.
#
echo "REMOVING any previously-vendored gRPC code"
rm -rf $DSTROOT/CgRPC/src
rm -rf $DSTROOT/CgRPC/grpc
rm -rf $DSTROOT/CgRPC/third_party
rm -rf $DSTROOT/CgRPC/include/grpc

#
# Copy grpc headers and source files
#
echo "COPYING public gRPC headers"
for src in "${public_headers[@]}"
do
	dest="$DSTROOT/CgRPC/$src"
	dest_dir=$(dirname $dest)
	mkdir -pv $dest_dir
	cp $TMP_DIR/grpc/$src $dest
done

echo "COPYING private gRPC headers"
for src in "${private_headers[@]}"
do
	dest="$DSTROOT/CgRPC/$src"
	dest_dir=$(dirname $dest)
	mkdir -pv $dest_dir
	cp $TMP_DIR/grpc/$src $dest
done

echo "COPYING gRPC source files"
for src in "${source_files[@]}"
do
	dest="$DSTROOT/CgRPC/$src"
	dest_dir=$(dirname $dest)
	mkdir -pv $dest_dir
	cp $TMP_DIR/grpc/$src $dest
done

echo "MOVING upb headers to CgRPC/include"
mkdir -pv $DSTROOT/CgRPC/include/upb
mv $DSTROOT/CgRPC/third_party/upb/upb/*.h $DSTROOT/CgRPC/include/upb/

# echo "MOVING upb headers to CgRPC"
# cp -R $DSTROOT/CgRPC/third_party/upb/ $DSTROOT/CgRPC/
# rm -rf $DSTROOT/CgRPC/third_party/upb

# echo "MOVING upb generated headers to CgRPC/src"
# cp -R $DSTROOT/CgRPC/src/core/ext/upb-generated/ $DSTROOT/CgRPC/src/
# rm -rf $DSTROOT/CgRPC/src/core/ext/upb-generated

echo "REMOVING stray import in xds.cc"
perl -pi -e 's/#include \"include\/grpc\/support\/alloc\.h\"\n//' $DSTROOT/CgRPC/src/core/ext/filters/client_channel/lb_policy/xds/xds.cc

echo "ADDING additional compiler flags to tsi/ssl_transport_security.cc"
perl -pi -e 's/#define TSI_OPENSSL_ALPN_SUPPORT 1/#define TSI_OPENSSL_ALPN_SUPPORT 0/' $DSTROOT/CgRPC/src/core/tsi/ssl_transport_security.cc

echo "DISABLING ARES"
perl -pi -e 's/#define GRPC_ARES 1/#define GRPC_ARES 0/' $DSTROOT/CgRPC/include/grpc/impl/codegen/port_platform.h

echo "COPYING roots.pem"
echo "Please run 'swift run RootsEncoder > Sources/SwiftGRPC/Core/Roots.swift' to import the updated certificates."
cp $TMP_DIR/grpc/etc/roots.pem $DSTASSETS/roots.pem
