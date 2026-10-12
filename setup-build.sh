#!/bin/bash
set -e

chmod +x ./load-emsdk.sh
source ./load-emsdk.sh

chmod +x ./build-wasm.sh
./build-wasm.sh