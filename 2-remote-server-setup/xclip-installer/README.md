# Xclip Installer for Clipboard Sharing

This directory contains the necessary script to install `xclip`, a command-line utility that is essential for enabling seamless clipboard integration between your remote Neovim session and your local machine.

## 🤔 What is `xclip` and Why Do We Need It?

When you use SSH with X11 forwarding (`ssh -Y`), you create a secure tunnel that can transport graphical information. However, Neovim is a terminal application; it doesn't inherently know how to talk to a graphical server.

`xclip` acts as the **translator**. When you `yank` (copy) text in Neovim (with the correct configuration), Neovim will:
1.  Look for a clipboard provider program.
2.  Find `xclip`.
3.  Pass the copied text to the `xclip` command.
4.  `xclip` then sends this text as a clipboard request through the X11 tunnel to your local X Server (e.g., VcXsrv).
5.  Your local X Server receives the request and places the text into your Windows clipboard.

Without `xclip` on the remote server, this communication chain is broken.

## 🚀 Installation

The provided script will download the `xclip` source code, compile it, and install it into your user-local directory (`~/.local/bin`), requiring no `sudo` permissions.

1.  **Grant execution permission to the script:**
    ```bash
    chmod +x install_xclip.sh
    ```
2.  **Run the script:**
    ```bash
    ./install_xclip.sh
    ```

### ⚠️ Potential Dependencies

Compiling `xclip` requires a few X11 development libraries to be present on the system. On CentOS 7, these are typically:
*   `libX11-devel`
*   `libXmu-devel`
*   `libXt-devel`
*   `libXext-devel`

These packages are very common and are likely already installed on your server by the system administrator. If the `./configure` step in the script fails with an error message about missing headers (like `X11/Xlib.h`), you may need to contact your system administrator to request the installation of these `-devel` packages.

## ✅ Verification

After the installation is complete, you can verify that it's working correctly **after establishing an SSH connection with X11 forwarding enabled**.

1.  Ensure you have followed the local setup guide for VcXsrv and are connected with `ssh -Y`.
2.  On the remote server, check that the `DISPLAY` variable is set:
    ```bash
    echo $DISPLAY
    # Expected output: localhost:10.0 (or similar)
    ```
3.  Test `xclip` directly:
    ```bash
    echo "Clipboard test successful!" | ~/.local/bin/xclip -selection clipboard
    ```
4.  Switch to your local Windows machine and paste (`Ctrl+V`) into any text editor. If you see the message "Clipboard test successful!", then `xclip` is working perfectly.

Once verified, Neovim (with `vim.o.clipboard = "unnamedplus"`) will automatically use it.
