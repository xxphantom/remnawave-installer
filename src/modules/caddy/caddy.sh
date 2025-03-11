#!/bin/bash

# Настройка Caddy для панели Remnawave
setup_caddy_for_panel() {
    local PANEL_SECRET_KEY=$1
    
    cd $REMNAWAVE_DIR/caddy

    # Определение SUB_BACKEND_URL в зависимости от установки remnawave-json
    if [ "$INSTALL_REMNAWAVE_JSON" = "y" ] || [ "$INSTALL_REMNAWAVE_JSON" = "yes" ]; then
        SCRIPT_SUB_BACKEND_URL="127.0.0.1:$APP_PORT"
        REWRITE_RULE=""
    else
        SCRIPT_SUB_BACKEND_URL="127.0.0.1:3000"
        REWRITE_RULE="rewrite * /api/sub{uri}"
    fi

    # Создание .env файла для Caddy
    cat >.env <<EOF
PANEL_DOMAIN=$SCRIPT_PANEL_DOMAIN
PANEL_PORT=443
SUB_DOMAIN=$SCRIPT_SUB_DOMAIN
SUB_PORT=443
BACKEND_URL=127.0.0.1:3000
SUB_BACKEND_URL=$SCRIPT_SUB_BACKEND_URL
PANEL_SECRET_KEY=$PANEL_SECRET_KEY
EOF

    PANEL_DOMAIN='$PANEL_DOMAIN'
    PANEL_PORT='$PANEL_PORT'
    BACKEND_URL='$BACKEND_URL'
    PANEL_SECRET_KEY='$PANEL_SECRET_KEY'

    SUB_DOMAIN='$SUB_DOMAIN'
    SUB_PORT='$SUB_PORT'
    SUB_BACKEND_URL='$SUB_BACKEND_URL'

    # Создание Caddyfile с защитой панели
    cat >Caddyfile <<EOF
{$PANEL_DOMAIN}:{$PANEL_PORT} {
        @has_token_param {
                query caddy={$PANEL_SECRET_KEY}
        }
        handle @has_token_param {
                header +Set-Cookie "caddy={$PANEL_SECRET_KEY}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=31536000"
        }

        @subscription_info_path {
                path_regexp ^/api/sub/[^/]+
        }

        handle @subscription_info_path {
                reverse_proxy {$BACKEND_URL} {
                        @notfound status 404

                        handle_response @notfound {
                                respond 404
                        }

                        header_up X-Real-IP {remote}
                        header_up Host {host}
                }
        }
        @unauthorized {
                not header Cookie *caddy={$PANEL_SECRET_KEY}*
                not query caddy={$PANEL_SECRET_KEY}
                path /
        }
        handle @unauthorized {
                respond 200 {
                        body ""
                        close
                }
        }

        @unauthorized_non_root {
                not header Cookie *caddy={$PANEL_SECRET_KEY}*
                not query caddy={$PANEL_SECRET_KEY}
                path_regexp .+
        }
        handle @unauthorized_non_root {
                respond 404
        }

        reverse_proxy {$BACKEND_URL} {
                header_up X-Real-IP {remote}
                header_up Host {host}
        }
}

{$SUB_DOMAIN}:{$SUB_PORT} {
        handle {
                reverse_proxy {$SUB_BACKEND_URL} {
                        header_up X-Real-IP {remote}
                        header_up Host {host}

                        @error status 400 404 422 500

                        handle_response @error {
                                error "" 404
                        }
                }
        }
}
EOF

    # Создание docker-compose.yml для Caddy
    cat >docker-compose.yml <<'EOF'
services:
  caddy:
    image: caddy:2.9.1
    container_name: caddy-remnawave
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./logs:/var/log/caddy
      - caddy_data_panel:/data
      - caddy_config_panel:/config
    env_file:
      - .env
    network_mode: "host"
volumes:
  caddy_data_panel:
  caddy_config_panel:
EOF

    # Создание Makefile
    create_makefile "$REMNAWAVE_DIR/caddy"

    # Создание директории для логов
    mkdir -p $REMNAWAVE_DIR/caddy/logs
}
