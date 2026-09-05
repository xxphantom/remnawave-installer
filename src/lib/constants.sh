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
VERSION="2.4.0"

# Default stable versions.
# Node and subscription page use exact versions; Docker Hub has no major-only tags.
PINNED_BACKEND_TAG="3.4.3"
PINNED_NODE_TAG="3.4.1"
PINNED_SUBPAGE_TAG="8.0.0"
# Last releases compatible with panel 2.x
LEGACY_NODE_TAG="2.8.0"
LEGACY_SUBPAGE_TAG="7.2.6"

# Docker image tags based on branch
# Check if branch is a version number (e.g., 1.65, 2.0.1)
if [[ "$REMNAWAVE_BRANCH" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    # Use the version number as tag directly
    REMNAWAVE_BACKEND_TAG="$REMNAWAVE_BRANCH"
    # Node and subscription page are versioned independently of the panel
    if [[ "$REMNAWAVE_BRANCH" =~ ^2\. ]]; then
        REMNAWAVE_NODE_TAG="$LEGACY_NODE_TAG"
        REMNAWAVE_SUBPAGE_TAG="$LEGACY_SUBPAGE_TAG"
    else
        REMNAWAVE_NODE_TAG="$PINNED_NODE_TAG"
        REMNAWAVE_SUBPAGE_TAG="$PINNED_SUBPAGE_TAG"
    fi
elif [ "$REMNAWAVE_BRANCH" = "dev" ]; then
    REMNAWAVE_BACKEND_TAG="dev"
    REMNAWAVE_NODE_TAG="dev"
    REMNAWAVE_SUBPAGE_TAG="dev"
elif [ "$REMNAWAVE_BRANCH" = "alpha" ]; then
    REMNAWAVE_BACKEND_TAG="alpha"
    REMNAWAVE_NODE_TAG="dev"  # Node doesn't have alpha tag, use dev
    REMNAWAVE_SUBPAGE_TAG="dev"
else
    # Stable versions for main
    REMNAWAVE_BACKEND_TAG="$PINNED_BACKEND_TAG"
    REMNAWAVE_NODE_TAG="$PINNED_NODE_TAG"
    REMNAWAVE_SUBPAGE_TAG="$PINNED_SUBPAGE_TAG"
fi

# Keep the environment template on the same release as the Docker image.
if [[ "$REMNAWAVE_BACKEND_TAG" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    REMNAWAVE_BACKEND_ENV_REF="refs/tags/$REMNAWAVE_BACKEND_TAG"
elif [ "$REMNAWAVE_BRANCH" = "alpha" ]; then
    REMNAWAVE_BACKEND_ENV_REF="refs/heads/dev"
else
    REMNAWAVE_BACKEND_ENV_REF="refs/heads/$REMNAWAVE_BRANCH"
fi

# GitHub repository URLs
REMNAWAVE_BACKEND_RAW="https://raw.githubusercontent.com/remnawave/backend"
REMNAWAVE_ENV_SAMPLE_URL="$REMNAWAVE_BACKEND_RAW/$REMNAWAVE_BACKEND_ENV_REF/.env.sample"
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
