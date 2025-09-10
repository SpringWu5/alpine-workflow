#!/bin/bash

# ==============================================================================
#      Modern Git Installer for Restricted/Legacy Linux (No Sudo)
# ==============================================================================
# This script compiles and installs a modern version of Git and its core
# dependencies into the user's home directory (~/.local).
# It is designed for environments where system tools are outdated (e.g., CentOS 7)
# and the user lacks sudo privileges.
#
# Features:
#   - Installs everything into ~/.local to avoid system interference.
#   - Targeted cleanup ensures other user-installed tools are not affected.
#   - Checks for a sufficiently modern compiler instead of hardcoding paths.
#   - Versions are configurable at the top of the script.
#   - Intelligently updates user's shell configuration for PATH.
#
# Author: Spring5 & AI Assistant
# Date:   2025-09-03 (Final Victorious Version)
# ==============================================================================

# --- Strict Mode: Fail on any error, and on unset variables ---
set -euo pipefail

# ==============================================================================
# --- Configuration & Environment Setup ---
# ==============================================================================
# --- Version Configuration (Update these to change build versions) ---
GIT_VERSION="2.39.2"
ZLIB_VERSION="1.3.1"
LIBICONV_VERSION="1.17"

# --- Path Configuration ---
export INSTALL_PREFIX="$HOME/.local"
export BUILD_ROOT="$HOME/git_build_root"

# --- Build Requirements ---
MIN_GCC_VERSION=7

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

# --- Helper function for building from tarballs ---
build_from_tar() {
  local name="$1"
  local url="$2"
  local filename
  filename=$(basename "$url")
  log_info "Building $name from $url"
  if [ ! -f "$filename" ]; then wget -O "$filename" "$url"; else log_info "--> Source tarball already exists. Skipping download."; fi
  local dirname
  dirname=$(tar -tf "$filename" | head -n 1 | cut -d'/' -f1)
  if [ -d "$dirname" ]; then log_info "--> Source directory '$dirname' already exists. Skipping extraction."; else tar -xvf "$filename"; fi
  log_info "--> Configuring, compiling, and installing from '$dirname'"
  (
    cd "$dirname"
    if [[ "$name" == "Git" ]]; then
      # Git requires special flags to find our custom-built libraries
      LDFLAGS="-L$INSTALL_PREFIX/lib" CPPFLAGS="-I$INSTALL_PREFIX/include" ./configure --prefix="$INSTALL_PREFIX"
    else
      ./configure --prefix="$INSTALL_PREFIX"
    fi
    make -j"$(nproc)"
    make install
  )
  log_success "$name has been successfully built and installed."
  echo
}

# ==============================================================================
# --- Phase 0: Targeted Cleanup ---
# ==============================================================================
log_info "Phase 0: Starting Targeted Cleanup for Git and its dependencies"
rm -rf "$BUILD_ROOT" || true

log_info "--> Removing binaries, libraries, and shared data..."
rm -rf "$INSTALL_PREFIX/bin/git"*
rm -rf "$INSTALL_PREFIX/libexec/git-core"
rm -rf "$INSTALL_PREFIX/share/git"*
rm -f "$INSTALL_PREFIX/lib/libz."*
rm -f "$INSTALL_PREFIX/lib/libiconv."*
rm -f "$INSTALL_PREFIX/include/"{zlib.h,zconf.h,iconv.h}

log_success "Targeted cleanup complete."
echo

# ==============================================================================
# --- Phase 1: Prepare Workspace & Verify Environment ---
# ==============================================================================
log_info "Phase 1: Preparing Workspace and Verifying Compiler"
mkdir -p "$INSTALL_PREFIX/bin"
mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"

if ! command -v gcc &>/dev/null; then log_fatal "GCC compiler not found. Please install a C compiler."; fi
GCC_MAJOR_VERSION=$(gcc -dumpversion | cut -f1 -d.)
if ((GCC_MAJOR_VERSION < MIN_GCC_VERSION)); then
  log_fatal "Your GCC version ($GCC_MAJOR_VERSION) is too old. A version >= ${MIN_GCC_VERSION} is required."
  log_info "On CentOS/RHEL, you can enable a newer version by running:"
  log_info "  sudo yum install centos-release-scl && sudo yum install devtoolset-9 (or newer)"
  log_info "Then run this script inside the SCL shell: 'scl enable devtoolset-9 bash'"
  exit 1
fi
log_success "Workspace is ready at $BUILD_ROOT, using GCC $(gcc --version | head -n1)"
echo

# ==============================================================================
# --- Phase 2: Build Dependencies ---
# ==============================================================================
log_info "Phase 2: Building dependencies from source"
build_from_tar "zlib" "https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
build_from_tar "libiconv" "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz"

# ==============================================================================
# --- Phase 3: Build Git ---
# ==============================================================================
log_info "Phase 3: Building Git v${GIT_VERSION} from source"
build_from_tar "Git" "https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz"

# ==============================================================================
# --- Phase 4: Finalization & Instructions ---
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
log_success "--- Modern Git v${GIT_VERSION} has been successfully installed to $INSTALL_PREFIX ---"
echo
log_info "The script will now attempt to update your shell configuration to include ~/.local/bin in your PATH."

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
COMMENT_LINE='# Custom Tools Path (added by Alpine Workflow script)'
SHELL_CONFIG=""
if [ -n "${ZSH_VERSION:-}" ]; then
  SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ]; then
  SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
  if ! grep -qF -- "$COMMENT_LINE" "$SHELL_CONFIG"; then echo "" >>"$SHELL_CONFIG" && echo "$COMMENT_LINE" >>"$SHELL_CONFIG"; fi
  update_shell_config "$SHELL_CONFIG" "$PATH_LINE"
  log_info "Please run 'source $SHELL_CONFIG' or open a new terminal to apply changes."
else
  log_info "Could not auto-detect shell. Please add this line to your startup file (e.g., ~/.profile):"
  echo -e "\n  ${c_yellow}${PATH_LINE}${c_reset}\n"
fi

echo
log_info "To verify, open a NEW terminal and run:"
echo "  which git   (should point to '$HOME/.local/bin/git')"
echo "  git --version (should show 'git version ${GIT_VERSION}')"
echo
log_info "Enjoy your modern Git!"
