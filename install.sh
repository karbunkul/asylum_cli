#!/bin/bash

# Asylum Installer
# Downloads the pre-compiled binary from GitHub Releases
# https://github.com/karbunkul/asylum_cli

set -e

REPO="karbunkul/asylum_cli"
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎭 Installing Asylum from GitHub Releases...${NC}"

# 1. Detect OS
OS_TYPE="$(uname -s)"
case "${OS_TYPE}" in
    Linux*)     FILE_NAME="asylum-linux";;
    Darwin*)    FILE_NAME="asylum-macos";;
    CYGWIN*|MINGW*|MSYS*) FILE_NAME="asylum-windows.exe";;
    *)          echo -e "${RED}Unsupported OS: ${OS_TYPE}${NC}"; exit 1;;
esac

# 2. Get latest version/tag from GitHub API
echo -e "Fetching latest release info..."
LATEST_RELEASE_URL="https://github.com/${REPO}/releases/latest/download/${FILE_NAME}"

# 3. Define installation directory
INSTALL_DIR="/usr/local/bin"
TARGET_NAME="asylum"

# Check if we have write access to /usr/local/bin
USE_SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
    USE_SUDO="sudo"
    echo -e "Note: Installation requires sudo to write to $INSTALL_DIR"
fi

# 4. Download and Install
TEMP_FILE=$(mktemp)
echo -e "Downloading ${FILE_NAME}..."
if ! curl -fsSL "$LATEST_RELEASE_URL" -o "$TEMP_FILE"; then
    echo -e "${RED}Error: Failed to download binary.${NC}"
    echo "The release might not be published yet or the URL is incorrect."
    echo "Attempted URL: $LATEST_RELEASE_URL"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo -e "Installing to ${INSTALL_DIR}/${TARGET_NAME}..."
$USE_SUDO mv "$TEMP_FILE" "${INSTALL_DIR}/${TARGET_NAME}"
$USE_SUDO chmod +x "${INSTALL_DIR}/${TARGET_NAME}"

echo -e "${GREEN}✅ Asylum installed successfully!${NC}"
echo -e "Run ${BLUE}asylum --version${NC} to verify."
