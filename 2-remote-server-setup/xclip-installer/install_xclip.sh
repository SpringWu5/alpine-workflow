#!/bin/bash

# ==============================================================================
#           xclip Installer for Local User (No Sudo)
# ==============================================================================
# This script compiles and installs xclip from source into the user's
# home directory. It is a crucial component for enabling clipboard sharing
# between a remote Neovim instance and a local machine via X11 forwarding.
# ==============================================================================

# --- Strict Mode ---
set -euo pipefail

# --- Environment Setup ---
export INSTALL_PREFIX="$HOME/.local"
export BUILD_ROOT="$HOME/local_builds/xclip_build"

# --- Helper for colored output ---
c_green="\033[1;32m"
c_yellow="\033[1;33m"
c_blue="\033[1;34m"
c_reset="\033[0m"
log_info() { echo -e "${c_blue}==>${c_reset} ${c_yellow}$1${c_reset}"; }
log_success() { echo -e "${c_green}==> SUCCESS:${c_reset} $1"; }

# --- Main Logic ---
log_info "Preparing build directory at $BUILD_ROOT..."
mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"

log_info "Cloning xclip source code..."
# Clean up previous attempt if it exists
rm -rf xclip
git clone https://github.com/astrand/xclip.git
cd xclip

log_info "Configuring, compiling, and installing xclip..."
# Generate the configure script
autoreconf

# Configure to install into our local prefix
./configure --prefix="$INSTALL_PREFIX"

# Compile
make

# Install
make install

log_success "xclip has been successfully installed to $INSTALL_PREFIX/bin/"
log_info "Please ensure '$HOME/.local/bin' is in your PATH environment variable."
