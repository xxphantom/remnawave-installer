#!/bin/bash

# Функции отображения сообщений и пользовательского интерфейса

# Отображение сообщения об успешной установке панели
display_panel_installation_complete_message() {
    echo -e "${GREEN}Панель Remnawave успешно установлена${NC}"
    echo
    echo -e "\033[1m┌──────────────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1m│     Ваш домен для панели:                            │\033[0m"

    local panel_domain_text="https://$SCRIPT_PANEL_DOMAIN"
    local panel_padding_right=$((54 - 2 - ${#panel_domain_text}))
    echo -e "\033[1m│ $panel_domain_text$(printf '%*s' $panel_padding_right) │\033[0m"

    echo -e "\033[1m│                                                      │\033[0m"
    echo -e "\033[1m│ Ваш домен для подписок:                              │\033[0m"

    local sub_domain_text="https://$SCRIPT_SUB_DOMAIN"
    local sub_padding_right=$((54 - 2 - ${#sub_domain_text}))
    echo -e "\033[1m│ $sub_domain_text$(printf '%*s' $sub_padding_right) │\033[0m"

    echo -e "\033[1m│                                                      │\033[0m"
    echo -e "\033[1m│ Логин администратора: $SUPERADMIN_USERNAME$(printf '%*s' $((54 - 24 - ${#SUPERADMIN_USERNAME}))) │\033[0m"

    echo -e "\033[1m│ Пароль администратора: $SUPERADMIN_PASSWORD$(printf '%*s' $((54 - 25 - ${#SUPERADMIN_PASSWORD}))) │\033[0m"

    echo -e "\033[1m└──────────────────────────────────────────────────────┘\033[0m"
    echo
    echo -e "${BOLD_BLUE}Директория панели: ${NC}$REMNAWAVE_DIR/panel"
    echo -e "${BOLD_BLUE}Директория Caddy: ${NC}$REMNAWAVE_DIR/caddy"
    echo
    echo -e "${BOLD_GREEN}Вы можете управлять обеими службами с помощью команды 'make' в соответствующих директориях:${NC}"
    echo -e "  ${ORANGE}make start   ${NC}- Запуск службы и просмотр логов"
    echo -e "  ${ORANGE}make stop    ${NC}- Остановка службы"
    echo -e "  ${ORANGE}make restart ${NC}- Перезапуск службы"
    echo -e "  ${ORANGE}make logs    ${NC}- Просмотр логов"
    echo

    cd ~
    draw_info_box "Панель Remnawave" "Расширенная настройка $VERSION"

    echo -e "${BOLD_GREEN}Установка завершена. Нажмите Enter, чтобы продолжить...${NC}"
    read -r
}
