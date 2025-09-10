# [Optional] Clash Proxy Setup for Network Access

This module provides a robust, automated solution for running a `clash` proxy service on the remote server. It is designed for situations where AI tools like the Gemini CLI need reliable access to global APIs that might be otherwise restricted.

## ✨ Core Features

This is not just a simple proxy script; it's an intelligent service manager:

-   **Auto Start & Stop**: The Clash service starts automatically when you establish your first SSH connection and gracefully shuts down after your last connection is terminated.
-   **Single Instance Guarantee**: Ensures only one Clash instance runs per user, no matter how many concurrent terminals are open.
-   **Resilient & Clean**: Correctly handles all session termination scenarios (normal `exit`, closing the terminal window, network disconnections), ensuring no zombie processes are left behind.

## 🚀 Deployment Steps

### Step 1: Download the Clash Premium Executable

We will use a pre-compiled version of the Clash Premium core.

1.  **Navigate to the releases page:**
    Open the following link in your browser:
    [**DustinWin/proxy-tools/releases/tag/Clash-Premium**](https://github.com/DustinWin/proxy-tools/releases/tag/Clash-Premium)

2.  **Download the correct version:**
    Find the asset named `clash-linux-amd64-v3-*.gz` (or the latest available version for `linux-amd64`). Right-click on it and copy the link address.

3.  **Download and prepare the file on your server:**
    Back in your server terminal, inside this `clash-setup` directory, run the following commands. Replace `[COPIED_LINK_ADDRESS]` with the URL you just copied.

    ```bash
    # Download the file
    wget [COPIED_LINK_ADDRESS]

    # Unzip the file
    gunzip clash-linux-amd64-v3-*.gz

    # Rename it to 'clash' for simplicity and make it executable
    mv clash-linux-amd64-v3-* clash
    chmod +x clash
    ```
    After these steps, you should have an executable file named `clash` in the current directory.

### Step 2: Prepare Your Personal Configuration

The Clash service needs your personal subscription information to function, please put your personal config file under this directory.

    **⚠️ Security Notice**: Your `config.yaml` contains a private subscription link. **Never commit this file to a public repository.** This directory is already configured via the project's main `.gitignore` file to ignore `config.yaml`.

### Step 3: Configure Your Login Shell for Automation

This is the key to the "zero-touch" experience. We will add a small block of code to your shell's login configuration file (`~/.bash_profile` or `~/.zprofile` for Zsh) to manage the Clash service automatically.

**Action:**
Append the following code block to the **end** of your `~/.bash_profile` file. If you are using Zsh as your login shell, you should add this to `~/.zprofile`.

```bash
# ==================== Auto Clash Manager Start ====================
# Manages the automatic start/stop of the Clash proxy service for the Alpine Workflow.

# --- Define Paths ---
# IMPORTANT: Update this path if you place the clash-setup directory elsewhere!
CLASH_SETUP_DIR="$HOME/alpine-workflow/2-remote-server-setup/clash-setup"
LOCK_DIR="$CLASH_SETUP_DIR/.clash.lock" # The lock is a directory
MANAGER_SCRIPT="$CLASH_SETUP_DIR/clash_manager.sh"

# --- Atomic Launch of Manager ---
# The `mkdir` command is atomic, ensuring only the first session can launch the manager.
if mkdir "$LOCK_DIR" 2>/dev/null; then
    # Launch the manager in the background. It will manage its own lifecycle.
    nohup "$MANAGER_SCRIPT" &> /dev/null &
fi

# --- Set Proxy Environment for the Current Session ---
# This ensures that tools like Gemini CLI and git automatically use the proxy.
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"

# ===================== Auto Clash Manager End =====================
