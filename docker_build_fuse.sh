#! /bin/sh

set -xv # enable debug
set -e # exit on error

BUILD_DIR=/tmp/datenlord_docker_build
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cp target/release/async_fuse $BUILD_DIR
cp scripts/umount-in-container.sh $BUILD_DIR

docker build $BUILD_DIR --no-cache --file ../scripts/Dockerfile.fuse --tag datenlord/datenlord:e2e_test
# && docker push datenlord/datenlord:latest

kind load docker-image datenlord/datenlord:e2e_test --name=kind-multiple
