# Conda Unified Toolchain Environment

This directory contains the `environment.yml` file used to create a unified, isolated Conda environment for all our development tools.

This environment provides:
- A modern, binary-compatible **Node.js** runtime required by Neovim plugins (Copilot, Mason) and the Gemini CLI.
- The Mason server for language support in neovim.

## Installation

To create this environment, run the following command from the `2-remote-server-setup/` parent directory:

```bash
conda env create -f conda-env/environment.yml
