#!/bin/bash

# ===================================================================================
#                              УСТАНОВКА STEAL ONESELF САЙТА
# ===================================================================================

setup_selfsteal() {
    mkdir -p $SELFSTEAL_DIR/html && cd $SELFSTEAL_DIR
    
    # Создаем .env файл
    cat > .env << EOF
# Домены
SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
SELF_STEAL_PORT=$SELF_STEAL_PORT
EOF
    
    # Создаем Caddyfile
    cat > Caddyfile << 'EOF'
{
    https_port {$SELF_STEAL_PORT}
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


:{$SELF_STEAL_PORT} {
    tls internal
    respond 204
}

:80 {
    bind 0.0.0.0
    respond 204
}
EOF
    
    # Создаем docker-compose.yml
    cat > docker-compose.yml << EOF
services:
  caddy:
    image: caddy:2.9.1
    container_name: caddy-selfsteal
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./html:/var/www/html
      - ./logs:/var/log/caddy
      - caddy_data_selfsteal:/data
      - caddy_config_selfsteal:/config
    env_file:
      - .env
    network_mode: "host"

volumes:
  caddy_data_selfsteal:
  caddy_config_selfsteal:
EOF
    
    # Создание Makefile для управления
    create_makefile "$SELFSTEAL_DIR"
    
    # Создание директорий и скачивание файлов с GitHub
    echo -e "${GREEN}Скачивание статических файлов для сайта-заглушки...${NC}"
    
    mkdir -p ./html/assets
    
    # Скачивание index.html
    curl -s -o ./html/index.html https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/index.html
    
    # Скачивание файлов assets
    curl -s -o ./html/assets/index-BilmB03J.css https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/index-BilmB03J.css
    curl -s -o ./html/assets/index-CRT2NuFx.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/index-CRT2NuFx.js
    curl -s -o ./html/assets/index-legacy-D44yECni.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/index-legacy-D44yECni.js
    curl -s -o ./html/assets/polyfills-legacy-B97CwC2N.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/polyfills-legacy-B97CwC2N.js
    curl -s -o ./html/assets/vendor-DHVSyNSs.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/vendor-DHVSyNSs.js
    curl -s -o ./html/assets/vendor-legacy-Cq-AagHX.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/vendor-legacy-Cq-AagHX.js
    
    # Запуск сервиса
    mkdir -p logs
    docker compose up -d
    
    # Проверяем, запущен ли сервис
    CADDY_STATUS=$(docker compose ps --services --filter "status=running" | grep -q "caddy" && echo "running" || echo "stopped")
    
    if [ "$CADDY_STATUS" = "running" ]; then
        echo -e "${BOLD_GREEN}✓ Caddy для сайта-заглушки успешно установлен и запущен!${NC}"
        echo -e "${LIGHT_GREEN}• Домен: ${BOLD_GREEN}$SELF_STEAL_DOMAIN${NC}"
        echo -e "${LIGHT_GREEN}• Порт: ${BOLD_GREEN}$SELF_STEAL_PORT${NC}"
        echo -e "${LIGHT_GREEN}• Директория: ${BOLD_GREEN}$SELFSTEAL_DIR${NC}"
        echo -e "\n${LIGHT_GREEN}Для управления сервисом используйте следующие команды:${NC}"
        echo -e "${ORANGE}   cd $SELFSTEAL_DIR${NC}"
        echo -e "${ORANGE}   make start   ${NC}- Запуск сервиса и просмотр логов"
        echo -e "${ORANGE}   make stop    ${NC}- Остановка сервиса"
        echo -e "${ORANGE}   make restart ${NC}- Перезапуск сервиса"
        echo -e "${ORANGE}   make logs    ${NC}- Просмотр логов сервиса"
    else
        echo -e "${BOLD_RED}⚠ Caddy для сайта-заглушки был установлен, но не запущен автоматически.${NC}"
        echo -e "${LIGHT_RED}Для запуска сервиса вручную выполните:${NC}"
        echo -e "${ORANGE}   cd $SELFSTEAL_DIR${NC}"
        echo -e "${ORANGE}   make start${NC}"
        echo -e "\n${LIGHT_RED}Если ошибка сохраняется, проверьте логи:${NC}"
        echo -e "${ORANGE}   make logs${NC}"
    fi
    
    unset SELF_STEAL_DOMAIN
    unset SELF_STEAL_PORT
}
