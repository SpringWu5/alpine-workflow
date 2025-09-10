# Gemini CLI Setup Guide

This guide provides instructions for installing, configuring, and running the **Gemini CLI**, a powerful AI agent, within our custom remote development environment.

## 🤔 What is Gemini CLI?

Gemini CLI brings the power of Google's Gemini models directly into your terminal. It's a revolutionary tool for code understanding, generation, automation, and much more. In our workflow, it serves as a key component for AI-assisted programming, working alongside GitHub Copilot.

## 🚀 Installation

The Gemini CLI is a Node.js application. We will install it into our unified Conda environment (`gemini_env`), which already provides the required Node.js v20+ runtime.

1.  **Activate the Conda Environment:**
    Before installing or running Gemini, you must always activate our shared toolchain environment.
    ```bash
    conda activate gemini_env
    ```

2.  **Install via npm:**
    We will use `npm` (Node Package Manager), which is included in our Conda environment, to install the Gemini CLI globally *within that environment*.
    ```bash
    npm install -g @google/gemini-cli
    ```

## 🔐 Authentication & API Key Setup

To use Gemini, you need to authenticate with a Google account. The recommended method for individual developers is using a Gemini API Key.

1.  **Obtain Your API Key:**
    *   Navigate to [Google AI Studio](https://aistudio.google.com/apikey) in your web browser.
    *   Sign in with your Google account.
    *   Click "Create API key" to generate a new key.

2.  **Configure the API Key on the Server:**
    The CLI reads the API key from an environment variable. To make this setting permanent, you should add it to your shell's configuration file (`.zshrc` or `.bashrc`).

    **Action:**
    Open your shell configuration file:
    ```bash
    vim ~/.zshrc
    ```
    Add the following line, replacing `YOUR_API_KEY` with the key you just generated:
    ```bash
    export GEMINI_API_KEY="YOUR_API_KEY"
    ```
    Save the file and reload your shell configuration (`source ~/.zshrc`) or open a new terminal for the change to take effect.

## 🌐 Ensuring Network Connectivity (Using Clash)

The Gemini API is hosted on Google's servers. To ensure reliable access from the remote server, you may need to route its traffic through a proxy.

Our workflow includes an optional but highly recommended setup for `clash`. If you have not configured it yet, please follow the guide in the `../clash-setup/` directory.

Once `clash` is running, it will automatically set the necessary proxy environment variables (`http_proxy`, `https-proxy`), and the Gemini CLI will use it automatically.

## ✅ Verification & Basic Usage

With everything set up, you can now test the Gemini CLI.

1.  **Activate the environment:**
    ```bash
    conda activate gemini_env
    ```

2.  **Run a simple, non-interactive prompt:**
    This is a great way to test authentication and connectivity.
    ```bash
    gemini -p "Hello! Who are you?"
    ```
    If successful, you should receive a response from the Gemini model.

3.  **Start an interactive session:**
    This is the primary way to use the CLI.
    ```bash
    gemini
    ```
    You can now chat with the AI, ask it to read files, generate code, and much more!

For a full list of features and advanced usage, please refer to the [official Gemini CLI documentation](https://github.com/google-gemini/gemini-cli).
