#!/bin/bash

# ===================================================================================
#                              REMNAWAVE NODE INSTALLATION (All-in-One)
# ===================================================================================

# Create docker-compose for Node in LOCAL_REMNANODE_DIR
setup_node_all_in_one() {
    local panel_url=$1
    local token=$2
    local node_port=$3

    mkdir -p "$LOCAL_REMNANODE_DIR"
    cd "$LOCAL_REMNANODE_DIR"

    local pubkey=$(get_public_key "$panel_url" "$token" "$PANEL_DOMAIN")

    if [ -z "$pubkey" ]; then
        return 1
    fi

    cat >docker-compose.yml <<EOF
services:
    remnanode:
        image: remnawave/node:$REMNAWAVE_NODE_TAG
        container_name: remnanode
        hostname: remnanode
        restart: always
        cap_add:
            - NET_ADMIN
        ulimits:
            nofile:
                soft: 1048576
                hard: 1048576
        environment:
            - NODE_PORT=$node_port
            - SECRET_KEY=$pubkey
        volumes:
            - /dev/shm:/dev/shm
            - /var/log/remnanode:/var/log/remnanode
        network_mode: host
        logging:
            driver: 'json-file'
            options:
                max-size: '100m'
                max-file: '5'
EOF

    create_makefile "$LOCAL_REMNANODE_DIR"

    setup_node_log_rotation
}

# Start Caddy container
start_caddy_all_in_one() {
    if ! start_container "$REMNAWAVE_DIR/caddy" "Caddy"; then
        show_error "$(t services_installation_stopped)"
        exit 1
    fi
}

# Start Node container (waits for Caddy socket)
start_node_all_in_one() {
    if ! wait_for_caddy_socket 30; then
        show_error "$(t error_caddy_socket_timeout)"
        exit 1
    fi

    if ! start_container "$LOCAL_REMNANODE_DIR" "Remnawave Node"; then
        show_error "$(t services_installation_stopped)"
        exit 1
    fi
}

setup_and_start_all_in_one_node() {
    setup_node_all_in_one "127.0.0.1:3000" "$REG_TOKEN" "$NODE_PORT"
    start_node_all_in_one
}
