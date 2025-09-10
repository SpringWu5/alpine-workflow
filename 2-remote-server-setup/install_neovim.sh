#!/bin/bash

# ==============================================================================
#      Neovim Full Rebuild Script for Restricted/Legacy Linux Environments
# ==============================================================================
# This script performs a complete, user-space teardown and rebuild of a
# specific Neovim version and all its C/C++ dependencies. It is designed
# for maximum portability and robustness, especially on older systems
# like CentOS 7.
#
# Features:
#   - Installs everything into ~/.local to avoid system interference.
#   - Targeted cleanup ensures other user-installed tools are not affected.
#   - Auto-detects 'cmake' vs 'cmake3'.
#   - Versions are configurable at the top of the script.
#   - Intelligently updates shell configuration files.
#
# Author: wujiacheng & AI Assistant
# Date:   2025-09-03 (Final Victorious Version)
# ==============================================================================

# --- Strict Mode: Fail on any error, and on unset variables
set -euo pipefail

# ==============================================================================
# --- Configuration & Environment Setup ---
# ==============================================================================
# --- Version Configuration (Update these to change build versions) ---
NVIM_VERSION="v0.11.4"
LIBUV_VERSION="v1.50.0"
LUAJIT_COMMIT="538a82133ad6fddfd0ca64de167c4aca3bc1a2da" # Specific commit from deps.txt
LIBTERMKEY_VERSION="libtermkey-0.22"
UNIBILIUM_VERSION="v2.1.2"
MSGPACK_C_VERSION="c-4.0.0"
UTF8PROC_VERSION="v2.10.0"
TREE_SITTER_VERSION="v0.25.6"
LUV_VERSION="1.50.0-1"
LPEG_TARBALL_URL="https://github.com/neovim/deps/raw/d495ee6f79e7962a53ad79670cb92488abe0b9b4/opt/lpeg-1.1.0.tar.gz"

# --- Path Configuration ---
export INSTALL_PREFIX="$HOME/.local"
export BUILD_ROOT="$HOME/neovim_build_root"
export DEPS_SRC_DIR="$BUILD_ROOT/deps_src"

# ==============================================================================
# --- Helpers & Utilities ---
# ==============================================================================
# --- Colored output for better logging ---
c_red="\033[1;31m"
c_green="\033[1;32m"
c_yellow="\033[1;33m"
c_blue="\033[1;34m"
c_reset="\033[0m"
log_info() { echo -e "${c_blue}==>${c_reset} ${c_yellow}$1${c_reset}"; }
log_success() { echo -e "${c_green}==> SUCCESS:${c_reset} $1"; }
log_fatal() {
  echo -e "${c_red}==> FATAL:${c_reset} $1"
  exit 1
}

# --- Helper to find the correct cmake command ---
find_cmake_cmd() {
  if command -v cmake3 &>/dev/null; then
    echo "cmake3"
  elif command -v cmake &>/dev/null; then
    echo "cmake"
  else
    log_fatal "Neither 'cmake' nor 'cmake3' found. Please install CMake."
  fi
}
CMAKE_CMD=$(find_cmake_cmd)

# ==============================================================================
# --- Phase 0: The Great Cleanup (Targeted Teardown) ---
# ==============================================================================
log_info "Phase 0: Starting Targeted Teardown"
rm -rf "$BUILD_ROOT" || true
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim || true

log_info "--> Removing binaries..."
rm -f "$INSTALL_PREFIX/bin/nvim"
rm -f "$INSTALL_PREFIX/bin/luajit"*

log_info "--> Removing shared data and docs..."
rm -rf "$INSTALL_PREFIX/share/nvim"
rm -rf "$INSTALL_PREFIX/share/lua"
rm -rf "$INSTALL_PREFIX/share/luajit"*
rm -f "$INSTALL_PREFIX/share/man/man1/nvim.1"*

log_info "--> Removing libraries and pkg-config files..."
for libdir in "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/lib64"; do
  if [ -d "$libdir" ]; then
    rm -f "$libdir/libluv"* "$libdir/libuv"* "$libdir/libluajit"* "$libdir/libtermkey"* "$libdir/libunibilium"* "$libdir/libmsgpackc"* "$libdir/libutf8proc"* "$libdir/libtree-sitter"*
    rm -rf "$libdir/lua"
    rm -f "$libdir/pkgconfig/"{luv,libuv,luajit,unibilium,msgpack-c,utf8proc}.pc
  fi
done

log_info "--> Removing header files..."
rm -rf "$INSTALL_PREFIX/include/"{luv,uv,luajit*,termkey.h,unibilium.h,msgpack,utf8proc.h,tree_sitter}

log_success "Targeted cleanup complete. Other tools (like Git) remain untouched."
echo

# ==============================================================================
# --- Phase 1: Prepare Workspace ---
# ==============================================================================
log_info "Phase 1: Preparing Workspace"
mkdir -p "$INSTALL_PREFIX/bin"
mkdir -p "$DEPS_SRC_DIR"
cd "$DEPS_SRC_DIR"
log_success "Workspace is ready at $BUILD_ROOT"
echo

# ==============================================================================
# --- Phase 2: Build All Dependencies ---
# ==============================================================================
log_info "Phase 2: Building All Core C/C++ Dependencies"

build_from_tar() {
  local name="$1"
  local url="$2"
  local build_commands="$3"
  local filename
  filename=$(basename "$url")
  log_info "Building $name from $url"
  wget -O "$filename" "$url"
  local dirname
  dirname=$(tar -tf "$filename" | head -n 1 | cut -d'/' -f1)
  log_info "--> Auto-detected directory name: $dirname"
  tar -xvf "$filename"
  log_info "--> Configuring, compiling, and installing from $dirname"
  (
    cd "$dirname"
    eval "$build_commands"
  )
  log_success "$name built and installed."
  echo
}

# 1. libuv
build_from_tar "libuv" "https://github.com/libuv/libuv/archive/${LIBUV_VERSION}.tar.gz" \
  "sh autogen.sh && ./configure --prefix=\"$INSTALL_PREFIX\" && make -j$(nproc) && make install"

# 2. LuaJIT
build_from_tar "LuaJIT" "https://github.com/luajit/luajit/archive/${LUAJIT_COMMIT}.tar.gz" \
  "make -j$(nproc) && make install PREFIX=\"$INSTALL_PREFIX\" && \
   mkdir -p \"$INSTALL_PREFIX/lib/lua/5.1\" \"$INSTALL_PREFIX/share/lua/5.1\""

# 3. libtermkey
build_from_tar "libtermkey" "http://www.leonerd.org.uk/code/libtermkey/${LIBTERMKEY_VERSION}.tar.gz" \
  "make -j$(nproc) && make install PREFIX=\"$INSTALL_PREFIX\""

# 4. unibilium
build_from_tar "unibilium" "https://github.com/neovim/unibilium/archive/${UNIBILIUM_VERSION}.tar.gz" \
  "mkdir -p build && cd build && $CMAKE_CMD .. -DCMAKE_INSTALL_PREFIX=\"$INSTALL_PREFIX\" && make -j$(nproc) && make install"

# 5. msgpack-c
build_from_tar "msgpack-c" "https://github.com/msgpack/msgpack-c/releases/download/${MSGPACK_C_VERSION}/msgpack-c-${MSGPACK_C_VERSION#c-}.tar.gz" \
  "mkdir -p build && cd build && $CMAKE_CMD .. -DCMAKE_INSTALL_PREFIX=\"$INSTALL_PREFIX\" && make -j$(nproc) && make install"

# 6. utf8proc
build_from_tar "utf8proc" "https://github.com/JuliaStrings/utf8proc/archive/${UTF8PROC_VERSION}.tar.gz" \
  "make -j$(nproc) && make install prefix=\"$INSTALL_PREFIX\""

# 7. Tree-sitter (with CentOS 7 glibc compatibility patch)
build_from_tar "Tree-sitter" "https://github.com/tree-sitter/tree-sitter/archive/${TREE_SITTER_VERSION}.tar.gz" \
  "log_info '--> Patching Makefile for potential glibc compatibility issues...' && \
   sed -i.bak \"s/-D_DEFAULT_SOURCE/-D_GNU_SOURCE -include endian.h/\" Makefile && \
   log_info '--> Makefile patched. Starting build...' && \
   make -j\$(nproc) && make install PREFIX=\"$INSTALL_PREFIX\""

# 8. luv (static build)
log_info "Building luv (static library) using git clone"
git clone https://github.com/luvit/luv.git
(
  cd luv
  git checkout "$LUV_VERSION"
  git submodule update --init --recursive
  LUV_SOURCE_DIR=$(pwd)
  mkdir -p build && cd build
  $CMAKE_CMD .. -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_MODULE=OFF
  make || log_info "Ignoring potential 'make' error, proceeding to check for libluv.a"
  if [ ! -f "libluv.a" ]; then log_fatal 'libluv.a failed to build.'; fi
  log_info "--> Manually installing libluv.a and headers"
  cp libluv.a "$INSTALL_PREFIX/lib/"
  mkdir -p "$INSTALL_PREFIX/include/luv"
  cp "$LUV_SOURCE_DIR"/src/*.h "$INSTALL_PREFIX/include/luv/"
)
log_success "luv built and installed."
echo

# 9. Lpeg
build_from_tar "Lpeg" "$LPEG_TARBALL_URL" \
  "LUAJIT_INCLUDE_DIR=\"$INSTALL_PREFIX/include/luajit-2.1\" && \
   make -j\$(nproc) CFLAGS=\"-I\$LUAJIT_INCLUDE_DIR -fPIC\" && \
   mkdir -p \"$INSTALL_PREFIX/lib/lua/5.1/\" && cp lpeg.so \"$INSTALL_PREFIX/lib/lua/5.1/\""

# ==============================================================================
# --- Phase 3: Manually Create pkg-config File for Luv ---
# ==============================================================================
log_info "Phase 3: Creating luv.pc file for CMake to find it"
mkdir -p "$INSTALL_PREFIX/lib/pkgconfig"
cat <<EOF >"$INSTALL_PREFIX/lib/pkgconfig/luv.pc"
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include
Name: luv
Description: libuv bindings for lua
Version: $LUV_VERSION
Requires: luajit libuv
Libs: -L\${libdir} -lluv
Cflags: -I\${includedir}/luv
EOF
log_success "pkg-config file for luv is ready."
echo

# ==============================================================================
# --- Phase 4: Build Neovim ---
# ==============================================================================
log_info "Phase 4: Building Neovim ${NVIM_VERSION}"
NVIM_SRC_DIR="$BUILD_ROOT/neovim"
if [ ! -d "$NVIM_SRC_DIR" ]; then git clone https://github.com/neovim/neovim.git "$NVIM_SRC_DIR"; fi
cd "$NVIM_SRC_DIR"
log_info "--> Checking out tag ${NVIM_VERSION}"
git checkout "$NVIM_VERSION"
mkdir -p build && cd build
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib/pkgconfig:$INSTALL_PREFIX/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"
log_info "--> Configuring Neovim with CMake using command: $CMAKE_CMD"
$CMAKE_CMD -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_BUILD_TYPE=Release ..
log_info "--> Compiling Neovim (this may take a while...)"
make -j$(nproc)
log_info "--> Installing Neovim"
make install

# ==============================================================================
# --- Phase 5: Finalization & Instructions ---
# ==============================================================================
update_shell_config() {
  local shell_config_file="$1" line_to_add="$2"
  if [ -f "$shell_config_file" ] && ! grep -qF -- "$line_to_add" "$shell_config_file"; then
    log_info "Adding to $shell_config_file: $line_to_add"
    printf "\n%s\n" "$line_to_add" >>"$shell_config_file"
  elif [ -f "$shell_config_file" ]; then
    log_info "Line already exists in $shell_config_file. Skipping."
  fi
}

echo
log_success "--- Neovim ${NVIM_VERSION} installation complete! ---"
echo
log_info "The script will now attempt to update your shell configuration..."

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
LD_PATH_LINE='export LD_LIBRARY_PATH="$HOME/.local/lib:$HOME/.local/lib64:$LD_LIBRARY_PATH"'
COMMENT_LINE='# Neovim Custom Build Environment (added by Alpine Workflow script)'
SHELL_CONFIG=""
if [ -n "${ZSH_VERSION:-}" ]; then
  SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ]; then
  SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
  if ! grep -qF -- "$COMMENT_LINE" "$SHELL_CONFIG"; then echo "" >>"$SHELL_CONFIG" && echo "$COMMENT_LINE" >>"$SHELL_CONFIG"; fi
  update_shell_config "$SHELL_CONFIG" "$PATH_LINE"
  update_shell_config "$SHELL_CONFIG" "$LD_PATH_LINE"
  log_info "Please run 'source $SHELL_CONFIG' or open a new terminal to apply changes."
else
  log_info "Could not auto-detect shell. Please add these lines to your startup file (e.g., ~/.profile):"
  echo -e "\n  ${c_yellow}${PATH_LINE}${c_reset}\n  ${c_yellow}${LD_PATH_LINE}${c_reset}\n"
fi
echo
log_info "Enjoy your freshly built Neovim!"
