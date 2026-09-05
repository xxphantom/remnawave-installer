#!/bin/bash

# Installation and setup of remnawave-subscription-page
setup_remnawave-subscription-page() {
    local api_token="$1"

    mkdir -p "$SUBSCRIPTION_PAGE_DIR"

    cd "$SUBSCRIPTION_PAGE_DIR"

    cat >docker-compose.yml <<EOF
services:
    remnawave-subscription-page:
        image: remnawave/subscription-page:$REMNAWAVE_SUBPAGE_TAG
        container_name: remnawave-subscription-page
        hostname: remnawave-subscription-page
        restart: always
        environment:
            - REMNAWAVE_PANEL_URL=http://remnawave:3000
            - REMNAWAVE_API_TOKEN=$api_token
            - APP_PORT=3010
            - TRUST_PROXY=1
        ports:
            - '127.0.0.1:3010:3010'
        networks:
            - remnawave-network
        logging:
            driver: 'json-file'
            options:
                max-size: '100m'
                max-file: '5'

networks:
    remnawave-network:
        driver: bridge
        external: true
EOF

    create_makefile "$SUBSCRIPTION_PAGE_DIR"
}
