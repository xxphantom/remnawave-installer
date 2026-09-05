#!/bin/bash

# Setting up Caddy for the Remnawave panel (All-in-One with full auth)
setup_caddy_all_in_one_full_auth() {
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
    order authenticate before respond
    order authorize before respond

    security {
        local identity store localdb {
            realm local
            path /data/.local/caddy/users.json
        }

        authentication portal remnawaveportal {
            crypto default token lifetime {$AUTH_TOKEN_LIFETIME}
            enable identity store localdb
            cookie domain {$REMNAWAVE_PANEL_DOMAIN}
            ui {
                links {
                    "Remnawave" "/dashboard/home" icon "las la-tachometer-alt"
                    "My Identity" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/whoami" icon "las la-user"
                    "API Keys" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/settings/apikeys" icon "las la-key"
                    "MFA" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/settings/mfa" icon "lab la-keycdn"
                }
            }
            transform user {
                match origin local
                require mfa
                action add role authp/admin
            }
        }

        authorization policy panelpolicy {
            set auth url /restricted
            disable auth redirect
            allow roles authp/admin
            with api key auth portal remnawaveportal realm local

            acl rule {
                comment "Accept"
                match role authp/admin
                allow stop log info
            }
            acl rule {
                comment "Deny"
                match any
                deny log warn
            }
        }
    }
}

http://{$REMNAWAVE_PANEL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$REMNAWAVE_PANEL_DOMAIN}{uri} permanent
}

https://{$REMNAWAVE_PANEL_DOMAIN} {
    bind unix/{$CADDY_SOCKET_PATH}|0666
    encode zstd gzip

    @login_path {
        path /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE} /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/ /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/auth
    }
    handle @login_path {
        rewrite * /auth
        request_header +X-Forwarded-Prefix /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}
        authenticate with remnawaveportal
    }

    handle_path /restricted* {
        abort
    }

    route /api/* {
        authorize with panelpolicy
        reverse_proxy http://127.0.0.1:3000
    }

    route /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}* {
        authenticate with remnawaveportal
    }

    route /* {
        authorize with panelpolicy
        reverse_proxy http://127.0.0.1:3000
    }

    handle_errors {
        @unauth {
            expression {http.error.status_code} == 401
        }
        handle @unauth {
            respond * 204
        }
    }
}

http://{$CADDY_SELF_STEAL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$CADDY_SELF_STEAL_DOMAIN}{uri} permanent
}

https://{$CADDY_SELF_STEAL_DOMAIN} {
    bind unix/{$CADDY_SOCKET_PATH}|0666
    root * /var/www/html
    try_files {path} /index.html
    file_server
}

http://{$CADDY_SUB_DOMAIN} {
    bind 0.0.0.0
    redir https://{$CADDY_SUB_DOMAIN}{uri} permanent
}

https://{$CADDY_SUB_DOMAIN} {
    bind unix/{$CADDY_SOCKET_PATH}|0666
    encode zstd gzip

    handle {
        reverse_proxy http://127.0.0.1:3010 {
            header_up X-Real-IP {remote}
            header_up Host {host}
        }
    }
    handle_errors {
        handle {
            respond * 204
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
    remnawave-caddy:
        image: remnawave/caddy-with-auth:latest
        container_name: remnawave-caddy
        hostname: remnawave-caddy
        restart: always
        command: sh -c 'rm -f /dev/shm/caddy.sock && caddy run --config /etc/caddy/Caddyfile --adapter caddyfile'
        environment:
            - AUTH_TOKEN_LIFETIME=3600
            - REMNAWAVE_PANEL_DOMAIN=$PANEL_DOMAIN
            - REMNAWAVE_CUSTOM_LOGIN_ROUTE=$CUSTOM_LOGIN_ROUTE
            - AUTHP_ADMIN_USER=$AUTHP_ADMIN_USER
            - AUTHP_ADMIN_EMAIL=$AUTHP_ADMIN_EMAIL
            - AUTHP_ADMIN_SECRET=$AUTHP_ADMIN_SECRET
            - CADDY_SOCKET_PATH=$CADDY_SOCKET_PATH
            - CADDY_SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
            - CADDY_SUB_DOMAIN=$SUB_DOMAIN
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

    create_makefile "$REMNAWAVE_DIR/caddy"
    create_static_site "$REMNAWAVE_DIR/caddy"
}
