#!/bin/bash

# ===================================================================================
#                              УСТАНОВКА НОДЫ REMNAWAVE
# ===================================================================================

setup_node() {
    clear
   
       # Проверка наличия предыдущей установки
    if [ -d "$REMNANODE_ROOT_DIR" ]; then
        echo -e "${BOLD_YELLOW}Обнаружена предыдущая установка RemnaWave Node.${NC}"
        echo -ne "${ORANGE}Хотите удалить предыдущую установку перед продолжением? (y/n): ${NC}"
        read REMOVE_PREVIOUS
        REMOVE_PREVIOUS=$(echo "$REMOVE_PREVIOUS" | tr '[:upper:]' '[:lower:]')
        echo

        if [ "$REMOVE_PREVIOUS" = "y" ] || [ "$REMOVE_PREVIOUS" = "yes" ]; then
            echo -e "${BOLD_YELLOW}Удаление предыдущей установки...${NC}"
            
            cd $REMNANODE_DIR && \
            docker compose -f docker-compose.yml down 2>/dev/null || true
            cd $SELFSTEAL_DIR && \
            docker compose -f docker-compose.yml down 2>/dev/null || true

            rm -rf $REMNANODE_ROOT_DIR
            
            echo -e "${BOLD_GREEN}Предыдущая установка успешно удалена.${NC}"
        else
            echo -e "${BOLD_YELLOW}Продолжаем установку без удаления предыдущей.${NC}"
        fi
    fi

    # Установка общих зависимостей
    install_dependencies
    
    mkdir -p $REMNANODE_DIR && cd $REMNANODE_DIR
    curl -sS https://raw.githubusercontent.com/remnawave/node/refs/heads/main/docker-compose-prod.yml > docker-compose.yml
    
    # Создание Makefile для ноды
    create_makefile "$REMNANODE_DIR"
    
    # Запрос домена Selfsteal с валидацией
    SELF_STEAL_DOMAIN=$(read_domain "Введите Selfsteal домен, например domain.example.com")
    if [ -z "$SELF_STEAL_DOMAIN" ]; then
        return 1
    fi

    # Запрос порта Selfsteal с валидацией и дефолтным значением 9443
    SELF_STEAL_PORT=$(read_port "Введите Selfsteal порт (можно оставить по умолчанию)" "9443")

    # Запрос порта API ноды с валидацией и дефолтным значением 3000
    NODE_PORT=$(read_port "Введите порт API ноды (можно оставить по умолчанию)" "3000")

    echo -e "${ORANGE}Введите сертификат сервера (вставьте содержимое и 2 раза нажмите Enter): ${NC}"
    CERTIFICATE=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            if [ -n "$CERTIFICATE" ]; then
                break
            fi
        else
            CERTIFICATE="$CERTIFICATE$line\n"
        fi
    done
    
    echo -ne "${BOLD_RED}Вы уверены, что сертификат правильный? (y/n): ${NC}"
    read confirm
    echo
    
    echo -e "### APP ###\nAPP_PORT=$NODE_PORT\n$CERTIFICATE" > .env
    
    setup_selfsteal

    start_container "$REMNANODE_DIR" "remnawave/node" "Remnawave Node"

    unset CERTIFICATE

    # Проверяем, запущена ли нода
    NODE_STATUS=$(docker compose ps --services --filter "status=running" | grep -q "node" && echo "running" || echo "stopped")
    
    if [ "$NODE_STATUS" = "running" ]; then
        echo -e "${LIGHT_GREEN}• Порт ноды: ${BOLD_GREEN}$NODE_PORT${NC}"
        echo -e "${LIGHT_GREEN}• Директория ноды: ${BOLD_GREEN}$REMNANODE_DIR${NC}"
        echo ""
    fi
    
    unset NODE_PORT
    
    echo -e "\n${BOLD_GREEN}Нажмите Enter, чтобы вернуться в главное меню...${NC}"
    read -r

}
