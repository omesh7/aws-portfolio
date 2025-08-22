#!/bin/bash

echo "Multi-Cloud Weather Tracker - Script Runner"
echo "============================================"
echo "Platform: Linux"
echo

echo "Available actions:"
echo "  1. deploy       - Deploy the complete infrastructure and application"
echo "  2. status       - Check the status of deployed resources"
echo "  3. destroy      - Destroy all resources and clean up"
echo "  4. test-failover - Test failover capabilities"
echo

if [ -z "$1" ]; then
    read -p "Select an action (1-4): " ACTION_NUM
    case $ACTION_NUM in
        1) ACTION="deploy" ;;
        2) ACTION="status" ;;
        3) ACTION="destroy" ;;
        4) ACTION="test-failover" ;;
        *) echo "Invalid selection"; exit 1 ;;
    esac
else
    ACTION="$1"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case $ACTION in
    "deploy")
        SCRIPT_PATH="$SCRIPT_DIR/linux/deploy.sh"
        ;;
    "status")
        SCRIPT_PATH="$SCRIPT_DIR/linux/status.sh"
        ;;
    "destroy")
        SCRIPT_PATH="$SCRIPT_DIR/linux/destroy.sh"
        ;;
    "test-failover")
        SCRIPT_PATH="$SCRIPT_DIR/linux/test-failover.sh"
        ;;
    *)
        echo "Invalid action: $ACTION"
        echo "Valid actions: deploy, status, destroy, test-failover"
        exit 1
        ;;
esac

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Script not found: $SCRIPT_PATH"
    exit 1
fi

echo "Running: $SCRIPT_PATH"
echo

chmod +x "$SCRIPT_PATH"
"$SCRIPT_PATH"