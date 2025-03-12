#!/bin/bash

# Функции отображения сообщений и пользовательского интерфейса

# Отображение сообщения об успешной установке панели
display_panel_installation_complete_message() {
    local PANEL_SECRET_KEY=$1
    
    echo ""
    echo -e "${BOLD_GREEN}Панель Remnawave успешно установлена!${NC}"
    echo ""
    
    local secure_panel_url="https://$SCRIPT_PANEL_DOMAIN/auth/login?caddy=$PANEL_SECRET_KEY"
    local effective_width=$((${#secure_panel_url} + 3))
    local border_line=$(printf '─%.0s' $(seq 1 $effective_width))
    
    print_text_line() {
        local text="$1"
        local padding=$((effective_width - ${#text} - 1))
        echo -e "\033[1m│ $text$(printf '%*s' $padding)│\033[0m"
    }
    
    print_empty_line() {
        echo -e "\033[1m│$(printf '%*s' $effective_width)│\033[0m"
    }
    
    echo -e "\033[1m┌${border_line}┐\033[0m"
    
    print_text_line "Ваш домен для панели:"
    print_text_line "https://$SCRIPT_PANEL_DOMAIN"
    print_empty_line
    print_text_line "Ссылка для безопасного входа (c секретным ключом):"
    print_text_line "$secure_panel_url"
    print_empty_line
    print_text_line "Ваш домен для подписок:"
    print_text_line "https://$SCRIPT_SUB_DOMAIN"
    print_empty_line
    print_text_line "Логин администратора: $SUPERADMIN_USERNAME"
    print_text_line "Пароль администратора: $SUPERADMIN_PASSWORD"
    print_empty_line
    echo -e "\033[1m└${border_line}┘\033[0m"

    echo
    show_success "Данные сохранены в файле: $CREDENTIALS_FILE"
    echo
    echo -e "${BOLD_BLUE}Директория панели: ${NC}$REMNAWAVE_DIR/panel"
    echo -e "${BOLD_BLUE}Директория Caddy: ${NC}$REMNAWAVE_DIR/caddy"
    echo
    echo -e "${BOLD_GREEN}Вы можете управлять обеими службами с помощью команды 'make' в соответствующих директориях:${NC}"
    echo
    echo -e "  ${ORANGE}make start   ${NC}- Запуск службы и просмотр логов"
    echo -e "  ${ORANGE}make stop    ${NC}- Остановка службы"
    echo -e "  ${ORANGE}make restart ${NC}- Перезапуск службы"
    echo -e "  ${ORANGE}make logs    ${NC}- Просмотр логов"
    echo

    cd ~

    echo -e "${BOLD_GREEN}Установка завершена. Нажмите Enter, чтобы продолжить...${NC}"
    read -r
}
