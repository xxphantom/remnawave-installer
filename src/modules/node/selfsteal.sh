#!/bin/bash

# ===================================================================================
#                              INSTALLATION OF STEAL ONESELF SITE (Node-Only)
# ===================================================================================

# SELFSTEAL_PORT is defined in constants.sh

# Create Caddyfile for socket mode
create_caddyfile_socket() {
    cat >Caddyfile <<'EOF'
{
    admin   off
    servers {
        listener_wrappers {
            proxy_protocol
            tls
        }
    }
    auto_https disable_redirects
}

http://{$SELF_STEAL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$SELF_STEAL_DOMAIN}{uri} permanent
}

https://{$SELF_STEAL_DOMAIN} {
    bind unix/{$CADDY_SOCKET_PATH}|0666
    root * /var/www/html
    try_files {path} /index.html
    file_server
}

:80 {
    bind 0.0.0.0
    respond 204
}
EOF
}

# Create Caddyfile for port mode
create_caddyfile_port() {
    cat >Caddyfile <<'EOF'
{
    admin   off
    https_port {$SELFSTEAL_PORT}
    default_bind 127.0.0.1
    servers {
        listener_wrappers {
            proxy_protocol {
                allow 127.0.0.1/32
            }
            tls
        }
    }
    auto_https disable_redirects
}

http://{$SELF_STEAL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$SELF_STEAL_DOMAIN}{uri} permanent
}

https://{$SELF_STEAL_DOMAIN} {
    root * /var/www/html
    try_files {path} /index.html
    file_server
}

:{$SELFSTEAL_PORT} {
    tls internal
    respond 204
}

:80 {
    bind 0.0.0.0
    respond 204
}
EOF
}

# Create docker-compose for socket mode
create_docker_compose_socket() {
    cat >docker-compose.yml <<EOF
services:
    caddy:
        image: caddy:2.11.4
        container_name: caddy-selfsteal
        restart: unless-stopped
        command: sh -c 'rm -f /dev/shm/caddy.sock && caddy run --config /etc/caddy/Caddyfile --adapter caddyfile'
        environment:
            - CADDY_SOCKET_PATH=$CADDY_SOCKET_PATH
            - SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
        volumes:
            - ./Caddyfile:/etc/caddy/Caddyfile
            - ./html:/var/www/html
            - /dev/shm:/dev/shm
            - remnawave-caddy-ssl-data:/data
        network_mode: host
        healthcheck:
            test: ["CMD", "test", "-S", "/dev/shm/caddy.sock"]
            interval: 2s
            timeout: 5s
            retries: 15
            start_period: 5s
        logging:
            driver: 'json-file'
            options:
                max-size: '100m'
                max-file: '5'

volumes:
    remnawave-caddy-ssl-data:
        driver: local
        external: false
        name: remnawave-caddy-ssl-data
EOF
}

# Create docker-compose for port mode
create_docker_compose_port() {
    cat >docker-compose.yml <<EOF
services:
    caddy:
        image: caddy:2.11.4
        container_name: caddy-selfsteal
        restart: unless-stopped
        environment:
            - SELFSTEAL_PORT=$SELFSTEAL_PORT
            - SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
        volumes:
            - ./Caddyfile:/etc/caddy/Caddyfile
            - ./html:/var/www/html
            - remnawave-caddy-ssl-data:/data
        network_mode: host
        healthcheck:
            test: ["CMD", "wget", "-q", "--spider", "http://localhost:80"]
            interval: 2s
            timeout: 5s
            retries: 15
            start_period: 5s
        logging:
            driver: 'json-file'
            options:
                max-size: '100m'
                max-file: '5'

volumes:
    remnawave-caddy-ssl-data:
        driver: local
        external: false
        name: remnawave-caddy-ssl-data
EOF
}

setup_selfsteal() {
    local connection_type="${1:-socket}"

    mkdir -p "$SELFSTEAL_DIR/html"
    cd "$SELFSTEAL_DIR"

    if [ "$connection_type" = "port" ]; then
        create_caddyfile_port
        create_docker_compose_port
    else
        create_caddyfile_socket
        create_docker_compose_socket
    fi

    create_makefile "$SELFSTEAL_DIR"
    create_static_site "$SELFSTEAL_DIR"

    mkdir -p logs

    if ! start_container "$SELFSTEAL_DIR" "Caddy"; then
        show_error "$(t selfsteal_installation_stopped)"
        exit 1
    fi

    CADDY_STATUS=$(docker compose ps --services --filter "status=running" | grep -q "caddy" && echo "running" || echo "stopped")

    if [ "$CADDY_STATUS" = "running" ]; then
        echo -e "${LIGHT_GREEN}$(t selfsteal_domain_info) ${BOLD_GREEN}$SELF_STEAL_DOMAIN${NC}"
        if [ "$connection_type" = "port" ]; then
            echo -e "${LIGHT_GREEN}$(t selfsteal_port_info) ${BOLD_GREEN}$SELFSTEAL_PORT${NC}"
        fi
        echo -e "${LIGHT_GREEN}$(t selfsteal_directory_info) ${BOLD_GREEN}$SELFSTEAL_DIR${NC}"
        echo
    fi
}
