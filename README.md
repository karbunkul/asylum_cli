# 🎭 Asylum CLI

A lightweight, project-specific shell environment manager built with Dart. Asylum allows you to isolate your environment variables and aliases on a per-project basis, making it easy to manage complex development workflows without polluting your global shell configuration.

## ✨ Features

*   **Project-Specific Environments:** Automatically discovers `asylum.yaml` in your project or parent directories.
*   **Dynamic Configuration:** Support for shell command execution within your config using `{exec: command}`.
*   **Sequential Interpolation:** Variables and aliases are resolved in order, allowing them to reference previously defined values.
*   **Multi-Shell Support:** Native support for **Zsh** and **Bash**.
*   **Custom Aliases:** Define project-specific aliases that are only available while in the Asylum session.
*   **Graceful Exit:** Cleanly leave the session by typing `exit` or pressing `Ctrl+C`.
*   **Dotenv Support:** Automatically loads variables from a `.env` file in the same directory as your configuration.

## 🛠️ Installation

### Quick Install (macOS/Linux)
You can install Asylum using the following one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/karbunkul/asylum_cli/main/install.sh | bash
```

### Manual Installation
1.  Download the latest binary for your platform from the [GitHub Releases](https://github.com/karbunkul/asylum_cli/releases).
2.  Move it to your local bin directory (e.g., `/usr/local/bin/asylum`).
3.  Ensure it has execution permissions: `chmod +x /usr/local/bin/asylum`.

## ⚙️ Configuration

Create an `asylum.yaml` file in your project root:

```yaml
environment:
  # Static values
  APP_ENV: development
  
  # Variable interpolation
  LOG_PATH: "$ASYLUM_ROOT/logs"
  
  # Dynamic values from shell commands
  GIT_BRANCH: 
    exec: git rev-parse --abbrev-ref HEAD
  
  # Platform-specific commands
  PWD:
    exec:
      unix: pwd
      windows: cd

aliases:
  bs: "flutter pub get"
  clean: "flutter clean"
```

## 🚀 Usage

Simply run the command in your project directory:

```bash
asylum
```

To use a specific configuration file:

```bash
asylum --config path/to/asylum.yaml
```

To exit and return to your host shell:
- Type `exit`
- Press `Ctrl+C`

## 🧠 How it Works

Asylum starts a new sub-shell and injects a temporary configuration file (`.zshrc` or `.bashrc`) that sources your original shell settings and then applies the project-specific environment and aliases. When you exit the sub-shell, Asylum cleans up all temporary files.
