#!/bin/bash

# 2048 Game CI/CD Pipeline - Cross-Platform Script Runner
# This script detects the platform and runs the appropriate scripts

echo "🎮 2048 Game CI/CD Pipeline - Script Runner"
echo "============================================"

# Detect platform
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="linux"
    SCRIPT_EXT=".sh"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
    SCRIPT_EXT=".bat"
else
    echo "❌ Unsupported platform: $OSTYPE"
    exit 1
fi

echo "🖥️ Detected platform: $PLATFORM"
echo ""

# Show available actions
echo "Available actions:"
echo "  1. deploy   - Deploy the complete infrastructure and application"
echo "  2. status   - Check the status of deployed resources"
echo "  3. destroy  - Destroy all resources and clean up"
echo ""

# Get action from user
if [ $# -eq 0 ]; then
    read -p "Select an action (1-3): " ACTION_NUM
    case $ACTION_NUM in
        1) ACTION="deploy" ;;
        2) ACTION="status" ;;
        3) ACTION="destroy" ;;
        *) echo "❌ Invalid selection"; exit 1 ;;
    esac
else
    ACTION=$1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate action
case $ACTION in
    deploy|status|destroy)
        SCRIPT_PATH="$SCRIPT_DIR/$PLATFORM/$ACTION$SCRIPT_EXT"
        ;;
    *)
        echo "❌ Invalid action: $ACTION"
        echo "Valid actions: deploy, status, destroy"
        exit 1
        ;;
esac

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Script not found: $SCRIPT_PATH"
    exit 1
fi

echo "🚀 Running: $SCRIPT_PATH"
echo ""

# Execute the appropriate script
if [ "$PLATFORM" = "linux" ]; then
    chmod +x "$SCRIPT_PATH"
    "$SCRIPT_PATH"
else
    cmd.exe /c "$SCRIPT_PATH"
fi