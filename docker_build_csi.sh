#! /bin/sh

set -xv # enable debug
set -e # exit on error

BUILD_DIR=/tmp/datenlord_docker_build
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cp target/release/csi $BUILD_DIR

docker build $BUILD_DIR --no-cache --file ./Dockerfile --tag datenlord/csiplugin:e2e_test
# && docker push datenlord/csiplugin:latest

kind load docker-image datenlord/csiplugin:e2e_test --name=kind-multiple
