#!/bin/bash

# Asylum Uninstaller
# https://github.com/karbunkul/asylum_cli

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎭 Uninstalling Asylum...${NC}"

# Check multiple possible installation paths
PATHS=(
    "/usr/local/bin/asylum"
    "$HOME/.local/bin/asylum"
)

FOUND=false

for TARGET in "${PATHS[@]}"; do
    if [ -f "$TARGET" ]; then
        echo -e "Found Asylum at $TARGET"

        USE_SUDO=""
        if [ ! -w "$(dirname "$TARGET")" ] || [ ! -w "$TARGET" ]; then
            USE_SUDO="sudo"
            echo -e "Note: Removing $TARGET requires sudo."
        fi

        $USE_SUDO rm -f "$TARGET"
        echo -e "${GREEN}Removed $TARGET${NC}"
        FOUND=true
    fi
done

if [ "$FOUND" = true ]; then
    echo -e "${GREEN}✅ Asylum has been successfully uninstalled.${NC}"
else
    echo -e "${RED}Asylum was not found in standard installation paths.${NC}"
    exit 1
fi
