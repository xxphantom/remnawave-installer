#!/bin/bash

# Установка и настройка remnawave-json
setup_remnawave_json() {
    # Установка remnawave-json, если пользователь согласился
    if [ "$INSTALL_REMNAWAVE_JSON" = "y" ] || [ "$INSTALL_REMNAWAVE_JSON" = "yes" ]; then
        echo -e "${BOLD_GREEN}Установка remnawave-json...${NC}"

        # Создаем директорию для remnawave-json
        mkdir -p $REMNAWAVE_DIR/remnawave-json/templates/{v2ray,mux,subscription}

        # Скачиваем шаблоны
        curl -s -o $REMNAWAVE_DIR/remnawave-json/templates/v2ray/default.json https://raw.githubusercontent.com/Jolymmiles/remnawave-json/refs/heads/main/templates/v2ray/default.json
        curl -s -o $REMNAWAVE_DIR/remnawave-json/templates/mux/default.json https://raw.githubusercontent.com/Jolymmiles/remnawave-json/refs/heads/main/templates/mux/default.json
        curl -s -o $REMNAWAVE_DIR/remnawave-json/templates/subscription/index.html https://raw.githubusercontent.com/Jolymmiles/remnawave-json/refs/heads/main/templates/subscription/index.html

        cd $REMNAWAVE_DIR/remnawave-json

        # Устанавливаем APP_PORT по умолчанию
        APP_PORT=4000
        APP_HOST="localhost"
        REMNAWAVE_URL="https://$SCRIPT_PANEL_DOMAIN"

        # Устанавливаем стандартные пути к шаблонам
        V2RAY_TEMPLATE_HOST_PATH="$REMNAWAVE_DIR/remnawave-json/templates/v2ray/default.json"
        V2RAY_TEMPLATE_PATH_LINE="V2RAY_TEMPLATE_PATH=/app/templates/v2ray/default.json"

        # V2RAY_MUX_ENABLED
        echo ""
        echo -ne "${ORANGE}V2RAY_MUX_ENABLED - флаг для включения или отключения функции V2Ray Mux.${NC}\\n"
        echo ""
        echo -ne "${ORANGE}Включить функцию V2Ray Mux? (y/n, по умолчанию y): ${NC}"
        read ENABLE_V2RAY_MUX
        if [ "$ENABLE_V2RAY_MUX" = "n" ] || [ "$ENABLE_V2RAY_MUX" = "N" ]; then
            V2RAY_MUX_ENABLED_LINE="V2RAY_MUX_ENABLED=false"
        else
            V2RAY_MUX_ENABLED_LINE="V2RAY_MUX_ENABLED=true"
        fi

        V2RAY_MUX_TEMPLATE_HOST_PATH="$REMNAWAVE_DIR/remnawave-json/templates/mux/default.json"
        V2RAY_MUX_TEMPLATE_PATH_LINE="V2RAY_MUX_TEMPLATE_PATH=/app/templates/v2ray/mux_default.json"

        WEB_PAGE_TEMPLATE_HOST_PATH="$REMNAWAVE_DIR/remnawave-json/templates/subscription/index.html"
        WEB_PAGE_TEMPLATE_PATH_LINE="WEB_PAGE_TEMPLATE_PATH=/app/templates/subscription/index.html"

        # HAPP_ANNOUNCEMENTS
        echo -ne "${ORANGE}HAPP_ANNOUNCEMENTS - текст объявления.${NC}\\n"
        echo -e "${ORANGE}По умолчанию: По всем вопросам пишите в бот обратной связи${NC}"
        echo -ne "${ORANGE}Хотите указать текст объявления? (y/n, по умолчанию n): ${NC}"
        read ADD_HAPP_ANNOUNCEMENTS
        if [ "$ADD_HAPP_ANNOUNCEMENTS" = "y" ] || [ "$ADD_HAPP_ANNOUNCEMENTS" = "Y" ]; then
            echo -ne "${ORANGE}Введите текст объявления: ${NC}"
            read HAPP_ANNOUNCEMENTS
            HAPP_ANNOUNCEMENTS_LINE="HAPP_ANNOUNCEMENTS=$HAPP_ANNOUNCEMENTS"
        else
            HAPP_ANNOUNCEMENTS_LINE="HAPP_ANNOUNCEMENTS=По всем вопросам пишите в бот обратной связи"
        fi

        # Создание .env файла
        cat >.env <<EOF
REMNAWAVE_URL=$REMNAWAVE_URL
APP_PORT=$APP_PORT
APP_HOST=$APP_HOST
$V2RAY_TEMPLATE_PATH_LINE
$V2RAY_MUX_ENABLED_LINE
$V2RAY_MUX_TEMPLATE_PATH_LINE
$WEB_PAGE_TEMPLATE_PATH_LINE
$HAPP_ANNOUNCEMENTS_LINE
EOF

        # Создание docker-compose.yml для remnawave-json
        cat >docker-compose.yml <<EOF
services:
  remnawave-json:
    image: ghcr.io/jolymmiles/remnawave-json:latest
    network_mode: host
    env_file:
      - .env
    volumes:
      - $V2RAY_TEMPLATE_HOST_PATH:/app/templates/v2ray/default.json
      - $V2RAY_MUX_TEMPLATE_HOST_PATH:/app/templates/v2ray/mux_default.json
      - $WEB_PAGE_TEMPLATE_HOST_PATH:/app/templates/subscription/index.html
EOF

        # Создание Makefile для remnawave-json
        create_makefile "$REMNAWAVE_DIR/remnawave-json"

        echo -e "${BOLD_GREEN}Конфигурация remnawave-json завершена.${NC}"
    fi
}
