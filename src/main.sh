#!/bin/bash

# Проверка на root права
if [ "$(id -u)" -ne 0 ]; then
    echo "Ошибка: Этот скрипт должен быть запущен от имени root (sudo)"
    exit 1
fi

clear

# ===================================================================================
#                              ИМПОРТ МОДУЛЕЙ
# ===================================================================================
# Примечание: В финальной версии скрипта при сборке через Makefile
# эта секция будет заменена содержимым модулей

# Получение директории текущего скрипта для относительных импортов
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# В режиме разработки каждый модуль загружается отдельно
# В режиме сборки все модули уже будут включены в скрипт

# Включение функций из модулей с проверками
source "$SCRIPT_DIR/modules/shared/common.sh" || {
    echo "Ошибка загрузки модуля common.sh"
    exit 1
}
source "$SCRIPT_DIR/modules/shared/ui.sh" || {
    echo "Ошибка загрузки модуля ui.sh"
    exit 1
}
source "$SCRIPT_DIR/modules/dependencies/dependencies.sh" || {
    echo "Ошибка загрузки модуля dependencies.sh"
    exit 1
}

# Эти модули зависят от функций из shared модулей, поэтому загружаем их после
source "$SCRIPT_DIR/modules/remnawave_json/remnawave_json.sh" || {
    echo "Ошибка загрузки модуля remnawave_json.sh"
    exit 1
}
source "$SCRIPT_DIR/modules/caddy/caddy.sh" || {
    echo "Ошибка загрузки модуля caddy.sh"
    exit 1
}

# Модули для панели управления
source "$SCRIPT_DIR/modules/panel/ui.sh" || {
    echo "Ошибка загрузки модуля panel/ui.sh"
    exit 1
}
source "$SCRIPT_DIR/modules/panel/vless-configuration.sh" || {
    echo "Ошибка загрузки модуля vless-configuration.sh"
    exit 1
}
source "$SCRIPT_DIR/modules/panel/panel.sh" || {
    echo "Ошибка загрузки модуля panel.sh"
    exit 1
}

# Остальные модули установки компонентов
source "$SCRIPT_DIR/modules/selfsteal/selfsteal.sh" || {
    echo "Ошибка загрузки модуля selfsteal.sh"
    exit 1
}
source "$SCRIPT_DIR/modules/node/node.sh" || {
    echo "Ошибка загрузки модуля node.sh"
    exit 1
}

# ===================================================================================
#                              ГЛАВНОЕ МЕНЮ
# ===================================================================================

main() {

    while true; do
    draw_info_box "Панель Remnawave" "Автоматическая установка $VERSION"

        echo -e "${BOLD_BLUE_MENU}Пожалуйста, выберите компонент для установки:${NC}"
        echo
        echo -e "  ${GREEN}1. ${NC}Установить панель"
        echo -e "  ${GREEN}2. ${NC}Установить ноду"
        echo -e "  ${GREEN}3. ${NC}Перезапустить панель"
        echo -e "  ${GREEN}4. ${NC}Выход"
        echo
        echo -ne "${BOLD_BLUE_MENU}Выберите опцию (1-4): ${NC}"
        read choice

        case $choice in
        1)
            install_panel
            ;;
        2)
            setup_node
            ;;
        3)
            restart_panel
            ;;
        4)
            echo "Готово."
            break
            ;;
        *)
            clear
            draw_info_box "Панель Remnawave" "Расширенная настройка $VERSION"
            echo -e "${BOLD_RED}Неверный выбор, пожалуйста, попробуйте снова.${NC}"
            sleep 1
            ;;
        esac
    done
}

# Запуск основной функции
main
