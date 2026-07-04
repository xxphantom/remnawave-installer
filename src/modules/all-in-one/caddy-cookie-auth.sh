#!/bin/bash

# Setting up Caddy for the Remnawave panel (All-in-One with cookie auth)
setup_caddy_all_in_one_cookie_auth() {
    local BACKEND_URL=127.0.0.1:3000
    local SUB_BACKEND_URL=127.0.0.1:3010

    mkdir -p "$REMNAWAVE_DIR/caddy"
    cd "$REMNAWAVE_DIR/caddy"

    # Creating the Caddyfile
    cat >Caddyfile <<"EOF"
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

http://{$PANEL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$PANEL_DOMAIN}{uri} permanent
}

https://{$PANEL_DOMAIN} {
    bind unix/{$CADDY_SOCKET_PATH}|0666

    @has_token_param {
        query caddy={$PANEL_SECRET_KEY}
    }

    handle @has_token_param {
        header +Set-Cookie "caddy={$PANEL_SECRET_KEY}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000"
    }

    @unauthorized {
        not header Cookie *caddy={$PANEL_SECRET_KEY}*
        not query caddy={$PANEL_SECRET_KEY}
    }

    handle @unauthorized {
        root * /var/www/html
        try_files {path} /index.html
        file_server
    }

    reverse_proxy {$BACKEND_URL} {
        header_up X-Real-IP {remote}
        header_up Host {host}
    }
}

http://{$SUB_DOMAIN} {
    bind 0.0.0.0
    redir https://{$SUB_DOMAIN}{uri} permanent
}

https://{$SUB_DOMAIN} {
    bind unix/{$CADDY_SOCKET_PATH}|0666
    handle {
        reverse_proxy {$SUB_BACKEND_URL} {
            header_up X-Real-IP {remote}
            header_up Host {host}
        }
    }
}

:80 {
    bind 0.0.0.0
    respond 204
}
EOF

    cat >docker-compose.yml <<EOF
services:
    caddy:
        image: caddy:2.11.4
        container_name: caddy-remnawave
        restart: unless-stopped
        command: sh -c 'rm -f /dev/shm/caddy.sock && caddy run --config /etc/caddy/Caddyfile --adapter caddyfile'
        environment:
            - CADDY_SOCKET_PATH=$CADDY_SOCKET_PATH
            - SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
            - PANEL_DOMAIN=$PANEL_DOMAIN
            - SUB_DOMAIN=$SUB_DOMAIN
            - BACKEND_URL=$BACKEND_URL
            - SUB_BACKEND_URL=$SUB_BACKEND_URL
            - PANEL_SECRET_KEY=$PANEL_SECRET_KEY
        volumes:
            - ./Caddyfile:/etc/caddy/Caddyfile
            - ./html:/var/www/html
            - ./logs:/var/log/caddy
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

    create_makefile "$REMNAWAVE_DIR/caddy"
    create_static_site "$REMNAWAVE_DIR/caddy"
}
