#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/load-emsdk.sh"

ROOT_DIR=$SCRIPT_DIR

# rm -rf "$ROOT_DIR/build-wasm"
mkdir -p "$ROOT_DIR/build-wasm"
cd "$ROOT_DIR/build-wasm"

# Use host pkg-config to locate native host GLib headers and libs
export PKG_CONFIG="$(which pkg-config)"
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"

# Set up clean Emscripten toolchain flags
export CC="ccache emcc"
export CXX="ccache em++"
export AR=emar
export NM=emnm
export RANLIB=emranlib

export CFLAGS="-mbulk-memory -DEMSCRIPTEN -sASYNCIFY -sUSE_SDL=2 -sUSE_ZLIB=1 -flto -msimd128"
export CXXFLAGS="-mbulk-memory -DEMSCRIPTEN -sASYNCIFY -sUSE_SDL=2 -sUSE_ZLIB=1 -O3 -flto -msimd128"
export LDFLAGS="-mbulk-memory -DEMSCRIPTEN -sASYNCIFY -sUSE_SDL=2 -sUSE_ZLIB=1 -O3 -msimd128 -flto \
  -sINITIAL_MEMORY=268435456 -sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=2147483648 \
  -sWASM_BIGINT -sSTACK_SIZE=5242880 \
  -sEXPORTED_FUNCTIONS=[\"_main\",\"_free\",\"_malloc\"] \
  -sEXPORTED_RUNTIME_METHODS=[\"ccall\",\"cwrap\",\"UTF8ToString\",\"stringToUTF8\",\"FS\",\"callMain\",\"HEAPU8\"] \
  -sENVIRONMENT=web,node -lidbfs.js"

# 1. Run QEMU configure
"$ROOT_DIR/configure" \
  --target-list=aarch64-softmmu \
  --cpu=wasm32 \
  --cross-prefix=wasm32-unknown-emscripten- \
  --host-cc=gcc \
  --cc=emcc \
  --cxx=em++ \
  --enable-tcg-interpreter \
  --enable-sdl \
  --enable-fdt=internal \
  --enable-pixman \
  --disable-linux-user \
  --disable-linux-aio \
  --disable-linux-io-uring \
  --disable-kvm \
  --disable-xen \
  --disable-libiscsi \
  --disable-tools \
  --disable-docs \
  --disable-gcrypt \
  --disable-gnutls \
  --disable-gtk \
  --disable-nettle \
  --disable-curl \
  --disable-oss \
  --disable-zstd \
  --disable-vnc \
  --disable-kvm \
  --disable-xen \
  --disable-werror \
  --disable-safe-stack \
  --disable-stack-protector \
  --disable-vhost-user \
  --disable-vhost-user-blk-server \
  --disable-vhost-net \
  --disable-vhost-crypto \
  --disable-vhost-kernel \
  --disable-vhost-vdpa

# 2. Disable subprojects directly in Meson build cache
meson configure -Dlibvduse=disabled .

# 3. Launch Ninja
ninja -C .