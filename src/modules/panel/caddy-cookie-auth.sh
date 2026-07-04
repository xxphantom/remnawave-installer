#!/bin/bash

setup_caddy_for_panel() {
    local BACKEND_URL=127.0.0.1:3000
    local SUB_BACKEND_URL=127.0.0.1:3010
    cd $REMNAWAVE_DIR/caddy

    cat >docker-compose.yml <<EOF
services:
  caddy:
    image: caddy:2.11.4
    container_name: caddy-remnawave
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./html:/var/www/html
      - ./logs:/var/log/caddy
      - remnawave-caddy-ssl-data:/data
    environment:
      - SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
      - PANEL_DOMAIN=$PANEL_DOMAIN
      - SUB_DOMAIN=$SUB_DOMAIN
      - BACKEND_URL=$BACKEND_URL
      - SUB_BACKEND_URL=$SUB_BACKEND_URL
      - PANEL_SECRET_KEY=$PANEL_SECRET_KEY
    network_mode: "host"
    logging:
      driver: 'json-file'
      options:
        max-size: '30m'
        max-file: '5'

volumes:
  remnawave-caddy-ssl-data:
    driver: local
    external: false
    name: remnawave-caddy-ssl-data
EOF

    # Creating the Caddyfile
    cat >Caddyfile <<"EOF"
{
    admin   off
}

https://{$SELF_STEAL_DOMAIN} {
    root * /var/www/html
    try_files {path} /index.html
    file_server
}

https://{$PANEL_DOMAIN} {
    @has_token_param {
        query caddy={$PANEL_SECRET_KEY}
    }

    handle @has_token_param {
        header +Set-Cookie "caddy={$PANEL_SECRET_KEY}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=31536000"
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

https://{$SUB_DOMAIN} {
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

    # Creating Makefile
    create_makefile "$REMNAWAVE_DIR/caddy"

    # Creating stub site
    create_static_site "$REMNAWAVE_DIR/caddy"
}
