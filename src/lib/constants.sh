#!/bin/bash

# Parse command line arguments for language and version configuration
LANG_CODE="${LANG_CODE:-en}"
REMNAWAVE_BRANCH="${REMNAWAVE_BRANCH:-main}"
INSTALLER_BRANCH="${INSTALLER_BRANCH:-main}"
KEEP_CADDY_DATA="${KEEP_CADDY_DATA:-false}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --lang=*)
            LANG_CODE="${1#*=}"
            shift
            ;;
        --lang)
            LANG_CODE="$2"
            shift 2
            ;;
        --panel-branch=*)
            REMNAWAVE_BRANCH="${1#*=}"
            shift
            ;;
        --panel-branch)
            REMNAWAVE_BRANCH="$2"
            shift 2
            ;;
        --installer-branch=*)
            INSTALLER_BRANCH="${1#*=}"
            shift
            ;;
        --installer-branch)
            INSTALLER_BRANCH="$2"
            shift 2
            ;;
        --keep-caddy-data)
            KEEP_CADDY_DATA="true"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Color definitions for output
BOLD_BLUE=$(tput setaf 4)
BOLD_GREEN=$(tput setaf 2)
BOLD_YELLOW=$(tput setaf 11)
LIGHT_GREEN=$(tput setaf 10)
BOLD_BLUE_MENU=$(tput setaf 6)
ORANGE=$(tput setaf 3)
BOLD_RED=$(tput setaf 1)
BLUE=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

# Script version
VERSION="2.1.1"

# Docker image tags based on branch
# Check if branch is a version number (e.g., 1.65, 2.0.1)
if [[ "$REMNAWAVE_BRANCH" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    # Use the version number as tag directly
    REMNAWAVE_BACKEND_TAG="$REMNAWAVE_BRANCH"
    REMNAWAVE_NODE_TAG="$REMNAWAVE_BRANCH"
elif [ "$REMNAWAVE_BRANCH" = "dev" ]; then
    REMNAWAVE_BACKEND_TAG="dev"
    REMNAWAVE_NODE_TAG="dev"
elif [ "$REMNAWAVE_BRANCH" = "alpha" ]; then
    REMNAWAVE_BACKEND_TAG="alpha"
    REMNAWAVE_NODE_TAG="dev"  # Node doesn't have alpha tag, use dev
else
    # Default to major version 2 for main branch (stable)
    REMNAWAVE_BACKEND_TAG="2"
    REMNAWAVE_NODE_TAG="latest"
fi

# GitHub repository URLs
REMNAWAVE_BACKEND_REPO="https://raw.githubusercontent.com/remnawave/backend/refs/heads"
INSTALLER_REPO="https://raw.githubusercontent.com/xxphantom/remnawave-installer/refs/heads"

# Main directories
REMNAWAVE_DIR="/opt/remnawave"
REMNANODE_DIR="/opt/remnanode"
# docs.rw path; installs before v2.2 used /opt/remnawave/subscription-page
SUBSCRIPTION_PAGE_DIR="$REMNAWAVE_DIR/subscription"
LEGACY_SUBSCRIPTION_PAGE_DIR="$REMNAWAVE_DIR/subscription-page"

CADDY_SOCKET_PATH="/dev/shm/caddy.sock"
SELFSTEAL_PORT="9443"

# Legacy directories (will be removed after refactoring)
SELFSTEAL_DIR="/opt/remnanode/selfsteal"
LOCAL_REMNANODE_DIR="$REMNAWAVE_DIR/node"
