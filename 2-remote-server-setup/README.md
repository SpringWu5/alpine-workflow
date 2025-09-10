# Part 2: Forging the Remote Server Environment

Welcome to the core of the **Alpine Workflow**. This guide contains all the necessary scripts and instructions to transform a standard, legacy Linux server (like CentOS 7) into a modern, AI-ready development powerhouse for Neovim.

## 📋 Prerequisites

Before you begin, please ensure the following prerequisite is met on your remote server:

*   **Conda is installed**: You must have a working installation of Miniconda or Anaconda. If not, please [install Miniconda](https://docs.conda.io/projects/miniconda/en/latest/index.html) first.

All scripts in this directory are designed to be run from this `2-remote-server-setup/` directory.

## 🚀 The Main Quest: Installation Workflow

Please follow these steps in the exact order listed to ensure all components are built and configured correctly.

### Part 1: Install a Modern Neovim

Our first step is to compile and install the latest stable version of Neovim from source. This bypasses the outdated versions available in system repositories and gives us access to all modern features required by the LazyVim ecosystem.

**Action:**
Activate a modern toolchain and run the Neovim installation script. It will automatically handle downloading the source code and installing it into your local `~/.local` directory.

```bash
chmod +x install_neovim.sh
scl enable devtoolset-9 bash
./install_neovim.sh
```

### Part 2: Install a Modern Git

Modern plugin managers like `lazy.nvim` use advanced Git features (like partial clones) for maximum performance. The default Git on CentOS 7 (v1.8.x) is too old and will cause errors. This script compiles and installs a modern version of Git and its dependencies (`zlib`, `libiconv`) into your local `~/.local` directory.

**Action:**
Run the Git installation script. After completion, you will need to **re-login** to the server for the new Git to become active in your `PATH`.

```bash
chmod +x install_local_git.sh
scl enable devtoolset-9 bash
./install_local_git.sh
# Verify with `git --version`, it should be 2.39.2 or newer.
```

### Part 3: Create the Unified Toolchain Environment

Modern Neovim plugins, especially for AI-assistance like Copilot(also Gemini CLI,though it's not a plugin) and language servers (Pyright), rely on a **Node.js** runtime. We use Conda to create a single, isolated environment to manage these tools, ensuring perfect compatibility and avoiding conflicts with system libraries.

**Action:**
Create the Conda environment from the provided `environment.yml` file. This file defines the exact versions of `nodejs` and other tools needed.

```bash
conda env create -f environment.yml
```
This will create a new environment named `gemini_env`.

**Daily Usage:** Remember to activate this environment every time you start a work session:
```bash
conda activate gemini_env
```

### Part 4: Enable Cross-Platform Clipboard (Xclip)

To achieve seamless copy-paste functionality between your local Windows machine and the remote Neovim, we need a command-line utility called `xclip` on the server. It acts as the bridge for Neovim's clipboard operations.

**Action:**
Navigate to the `xclip-installer` directory and follow the instructions within its `README.md` to compile and install `xclip`.

```bash
cd xclip-installer
# Follow the instructions in README.md, which will guide you to run:
# chmod +x install_xclip.sh && ./install_xclip.sh
cd ..
```

### Part 5: [Optional] Configure Network Access for AI Tools (Clash)

AI tools like Gemini CLI require stable access to Google's APIs, which may be challenging in some network environments. This setup provides a robust solution using `clash` as a local proxy on the server.

**Action:**
If you need this, navigate to the `clash-setup` directory and follow the detailed instructions in its `README.md` to configure your personal subscription and launch the service.

```bash
cd clash-setup
# Follow the detailed setup guide in README.md
cd ..
```

---

## ✅ Final Verification

Congratulations! You have successfully forged your remote development environment. To verify that all core components are correctly installed and accessible, run the following commands (you may need to activate the Conda environment first):

```bash
# Activate the environment
conda activate gemini_env

# Check versions
nvim --version         # Should show v0.11.4 or newer
git --version          # Should show v2.39.2 or newer
node --version         # Should show a modern LTS version (e.g., v18.x or v20.x)
which xclip            # Should point to ~/.local/bin/xclip
```

If all commands return the expected versions and paths, you are now ready to proceed to **Part 3: Infuse Your Style (`3-personal-config-sync/`)** to deploy your personalized Neovim configuration.
