#!/bin/bash

# Remnawave Installer (модульная версия)
# Собрано: Wed Mar 12 07:58:56 UTC 2025

# Включение модуля: common.sh

# Определение цветов для вывода
BOLD_BLUE=$(tput setaf 4)
BOLD_GREEN=$(tput setaf 2)
LIGHT_GREEN=$(tput setaf 10)
BOLD_BLUE_MENU=$(tput setaf 6)
ORANGE=$(tput setaf 3)
BOLD_RED=$(tput setaf 1)
BLUE=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

# Версия скрипта
VERSION="V1.0"

# Основные директории
REMNAWAVE_DIR="$HOME/remnawave"
REMNANODE_ROOT_DIR="$HOME/remnanode"
REMNANODE_DIR="$HOME/remnanode/node"
SELFSTEAL_DIR="$HOME/remnanode/selfsteal"

# Отрисовка информационного блока
draw_info_box() {
    local title="$1"
    local subtitle="$2"
    
    # Фиксированная ширина блока для идеального выравнивания
    local width=54
    
    echo -e "${BOLD_GREEN}"
    # Верхняя граница
    printf "┌%s┐\n" "$(printf '─%.0s' $(seq 1 $width))"
    
    # Центрирование заголовка
    local title_padding_left=$(( (width - ${#title}) / 2 ))
    local title_padding_right=$(( width - title_padding_left - ${#title} ))
    printf "│%*s%s%*s│\n" "$title_padding_left" "" "$title" "$title_padding_right" ""
    
    # Центрирование подзаголовка
    local subtitle_padding_left=$(( (width - ${#subtitle}) / 2 ))
    local subtitle_padding_right=$(( width - subtitle_padding_left - ${#subtitle} ))
    printf "│%*s%s%*s│\n" "$subtitle_padding_left" "" "$subtitle" "$subtitle_padding_right" ""
    
    # Пустая строка
    printf "│%*s│\n" "$width" ""
    
    # Строка версии - аккуратная обработка цветов
    local version_text="  • Версия: "
    local version_value="$VERSION (Бета)"
    local version_value_colored="${ORANGE}${version_value}${BOLD_GREEN}"
    local version_value_length=${#version_value}
    local remaining_space=$(( width - ${#version_text} - version_value_length ))
    printf "│%s%s%*s│\n" "$version_text" "$version_value_colored" "$remaining_space" ""
    
    # Пустая строка
    printf "│%*s│\n" "$width" ""
    
    # Нижняя граница
    printf "└%s┘\n" "$(printf '─%.0s' $(seq 1 $width))"
    echo -e "${NC}"
}

generate_secure_password() {
    local length="${1:-16}"
    local password=""
    local special_chars='!%^&*_+.,'
    local uppercase_chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local lowercase_chars='abcdefghijklmnopqrstuvwxyz'
    local number_chars='0123456789'
    local alphanumeric_chars="${uppercase_chars}${lowercase_chars}${number_chars}"
    
    # Генерируем начальный пароль только из букв и цифр
    if command -v openssl &>/dev/null; then
        password="$(openssl rand -base64 48 \
            | tr -dc "$alphanumeric_chars" \
            | head -c "$length")"
    else
        # Если openssl недоступен, fallback на /dev/urandom
        password="$(head -c 100 /dev/urandom \
            | tr -dc "$alphanumeric_chars" \
            | head -c "$length")"
    fi
    
    # Проверяем наличие символов каждого типа и добавляем недостающие
    # Если нет символа верхнего регистра, добавляем его
    if ! [[ "$password" =~ [$uppercase_chars] ]]; then
        local position=$((RANDOM % length))
        local one_uppercase="$(echo "$uppercase_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_uppercase}${password:$((position+1))}"
    fi
    
    # Если нет символа нижнего регистра, добавляем его
    if ! [[ "$password" =~ [$lowercase_chars] ]]; then
        local position=$((RANDOM % length))
        local one_lowercase="$(echo "$lowercase_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_lowercase}${password:$((position+1))}"
    fi
    
    # Если нет цифры, добавляем её
    if ! [[ "$password" =~ [$number_chars] ]]; then
        local position=$((RANDOM % length))
        local one_number="$(echo "$number_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_number}${password:$((position+1))}"
    fi
    
    # Добавляем от 1 до 3 специальных символов (в зависимости от длины пароля)
    # но не более 25% длины пароля
    local special_count=$((length / 4))
    special_count=$((special_count > 0 ? special_count : 1))
    special_count=$((special_count < 3 ? special_count : 3))
    
    for ((i=0; i<special_count; i++)); do
        # Выбираем случайную позицию, избегая первого и последнего символа
        local position=$((RANDOM % (length - 2) + 1))
        local one_special="$(echo "$special_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_special}${password:$((position+1))}"
    done

    echo "$password"
}

# Создание общего Makefile для управления сервисами
create_makefile() {
    local directory="$1"
    cat > "$directory/Makefile" << 'EOF'
.PHONY: start stop restart logs

start:
	docker compose up -d && docker compose logs -f -t
stop:
	docker compose down
restart:
	docker compose down && docker compose up -d
logs:
	docker compose logs -f -t
EOF
}

register_user() {
    local panel_url="$1"
    local panel_domain="$2"
    local username="$3"
    local password="$4"
    local api_url="http://${panel_url}/api/auth/register"
    
    local response=$(curl -s "$api_url" \
    -H "Host: $panel_domain" \
    -H "X-Forwarded-For: $panel_url" \
    -H "X-Forwarded-Proto: https" \
    -H "Content-Type: application/json" \
    --data-raw '{"username":"'"$username"'","password":"'"$password"'"}')
    
	if [ -z "$response" ]; then
		echo "Ошибка при регистрации - пустой ответ сервера"
        return 1
	fi

    if [[ "$response" == *"accessToken"* ]]; then
    	local token=$(echo "$response" | jq -r '.response.accessToken')
        
        echo "$token"
        return 0
    else
        echo "$response"
        return 1
    fi
}

# ===================================================================================
#                                ФУНКЦИИ ВАЛИДАЦИИ
# ===================================================================================

# Функция для валидации и очистки доменного имени или IP-адреса
# Оставляет только допустимые символы: буквы, цифры, точки и дефисы
# Использование:
#   validate_domain "example.com"
validate_domain() {
    local input="$1"
    local max_length="${2:-253}"  # Максимальная длина домена по стандарту
    
    # Проверка на IP-адрес
    if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # Проверка каждого октета IP-адреса
        local valid_ip=true
        IFS='.' read -r -a octets <<< "$input"
        for octet in "${octets[@]}"; do
            if [[ ! "$octet" =~ ^[0-9]+$ ]] || [ "$octet" -gt 255 ]; then
                valid_ip=false
                break
            fi
        done
        
        if [ "$valid_ip" = true ]; then
            echo "$input"
            return 0
        fi
    fi
    
    # Удаляем все символы, кроме букв, цифр, точек и дефисов
    local cleaned_domain=$(echo "$input" | tr -cd 'a-zA-Z0-9.-')
    
    # Проверка на пустую строку после очистки
    if [ -z "$cleaned_domain" ]; then
        echo ""
        return 1
    fi
    
    # Проверка на максимальную длину
    if [ ${#cleaned_domain} -gt $max_length ]; then
        cleaned_domain=${cleaned_domain:0:$max_length}
    fi
    
    # Проверка формата домена (простая базовая проверка)
    # Домен должен содержать хотя бы одну точку и не начинаться/заканчиваться точкой или дефисом
    if [[ ! "$cleaned_domain" =~ \. ]] || \
       [[ "$cleaned_domain" =~ ^[\.-] ]] || \
       [[ "$cleaned_domain" =~ [\.-]$ ]]; then
        echo "$cleaned_domain"
        return 1
    fi
    
    echo "$cleaned_domain"
    return 0
}

# Функция для валидации и очистки порта
# Оставляет только числовые символы и проверяет, что значение в диапазоне 1-65535
# Использование:
#   validate_port "8080"
validate_port() {
    local input="$1"
    local default_port="$2"
    
    # Удаляем все символы, кроме цифр
    local cleaned_port=$(echo "$input" | tr -cd '0-9')
    
    # Проверка на пустую строку после очистки
    if [ -z "$cleaned_port" ] && [ -n "$default_port" ]; then
        echo "$default_port"
        return 0
    elif [ -z "$cleaned_port" ]; then
        echo ""
        return 1
    fi
    
    # Проверка на диапазон портов
    if [ "$cleaned_port" -lt 1 ] || [ "$cleaned_port" -gt 65535 ]; then
        if [ -n "$default_port" ]; then
            echo "$default_port"
            return 0
        else
            echo ""
            return 1
        fi
    fi
    
    echo "$cleaned_port"
    return 0
}

# Безопасное чтение пользовательского ввода с валидацией
# Использование:
#   read_domain "Введите домен:" "example.com"
read_domain() {
    local prompt="$1"
    local default_value="$2"
    local max_attempts="${3:-3}"
    local result=""
    local attempts=0
    
    while [ $attempts -lt $max_attempts ]; do
        # Показываем подсказку с дефолтным значением, если оно есть
        if [ -n "$default_value" ]; then
            echo -e "${ORANGE}${prompt} [$default_value]:${NC}" >&2
        else
            echo -e "${ORANGE}${prompt}:${NC}" >&2
        fi
        
        read -p "> " input
        
        # Если ввод пустой и есть дефолтное значение, используем его
        if [ -z "$input" ] && [ -n "$default_value" ]; then
            result="$default_value"
            break
        fi
        
        # Валидируем ввод
        result=$(validate_domain "$input")
        local status=$?
        
        if [ $status -eq 0 ]; then
            break
        else
            echo -e "${BOLD_RED}Некорректный формат домена или IP-адреса. Пожалуйста, используйте только буквы, цифры, точки и дефисы.${NC}" >&2
            echo -e "${BOLD_RED}Домен должен содержать как минимум одну точку и не начинаться/заканчиваться точкой или дефисом.${NC}" >&2
            echo -e "${BOLD_RED}IP-адрес должен быть в формате X.X.X.X, где X - число от 0 до 255.${NC}" >&2
            ((attempts++))
        fi
    done
    
    if [ $attempts -eq $max_attempts ]; then
        echo -e "${BOLD_RED}Превышено максимальное количество попыток. Используется значение по умолчанию: $default_value${NC}" >&2
        result="$default_value"
    fi
    
    echo "$result"
}

# Безопасное чтение порта с валидацией
# Использование:
#   read_port "Введите порт:" "8080"
read_port() {
    local prompt="$1"
    local default_value="$2"
    local max_attempts="${3:-3}"
    local result=""
    local attempts=0
    
    while [ $attempts -lt $max_attempts ]; do
        # Показываем подсказку с дефолтным значением, если оно есть
        if [ -n "$default_value" ]; then
            echo -e "${ORANGE}${prompt} [$default_value]:${NC}" >&2
        else
            echo -e "${ORANGE}${prompt}:${NC}" >&2
        fi
        
        read -p "> " input
        
        # Если ввод пустой и есть дефолтное значение, используем его
        if [ -z "$input" ] && [ -n "$default_value" ]; then
            result="$default_value"
            break
        fi
        
        # Валидируем ввод
        result=$(validate_port "$input" "$default_value")
        local status=$?
        
        if [ $status -eq 0 ]; then
            break
        else
            echo -e "${BOLD_RED}Некорректный порт. Пожалуйста, введите число от 1 до 65535.${NC}" >&2
            ((attempts++))
        fi
    done
    
    if [ $attempts -eq $max_attempts ]; then
        echo -e "${BOLD_RED}Превышено максимальное количество попыток. Используется значение по умолчанию: $default_value${NC}" >&2
        result="$default_value"
    fi
    
    echo "$result"
}

# Включение модуля: ui.sh
draw_info_box() {
    local title="$1"
    local subtitle="$2"

    # Фиксированная ширина блока для идеального выравнивания
    local width=54

    echo -e "${BOLD_GREEN}"
    # Верхняя граница
    printf "┌%s┐\n" "$(printf '─%.0s' $(seq 1 $width))"

    # Центрирование заголовка
    local title_padding_left=$(((width - ${#title}) / 2))
    local title_padding_right=$((width - title_padding_left - ${#title}))
    printf "│%*s%s%*s│\n" "$title_padding_left" "" "$title" "$title_padding_right" ""

    # Центрирование подзаголовка
    local subtitle_padding_left=$(((width - ${#subtitle}) / 2))
    local subtitle_padding_right=$((width - subtitle_padding_left - ${#subtitle}))
    printf "│%*s%s%*s│\n" "$subtitle_padding_left" "" "$subtitle" "$subtitle_padding_right" ""

    # Пустая строка
    printf "│%*s│\n" "$width" ""

    # Строка версии - аккуратная обработка цветов
    local version_text="  • Версия: "
    local version_value="$VERSION (Бета)"
    local version_value_colored="${ORANGE}${version_value}${BOLD_GREEN}"
    local version_value_length=${#version_value}
    local remaining_space=$((width - ${#version_text} - version_value_length))
    printf "│%s%s%*s│\n" "$version_text" "$version_value_colored" "$remaining_space" ""

    # Пустая строка
    printf "│%*s│\n" "$width" ""

    # Нижняя граница
    printf "└%s┘\n" "$(printf '─%.0s' $(seq 1 $width))"
    echo -e "${NC}"
}

# Включение модуля: dependencies.sh

# Функция для проверки и установки зависимостей
check_and_install_dependency() {
    local packages=("$@")
    local failed=false
    
    for package_name in "${packages[@]}"; do
        if ! command -v $package_name &>/dev/null; then
            echo -e "${GREEN}Установка пакета $package_name...${NC}"
            sudo apt install -y $package_name >/dev/null 2>&1
            if ! command -v $package_name &>/dev/null; then
                echo -e "${BOLD_RED}Ошибка: Не удалось установить $package_name. Пожалуйста, установите его вручную.${NC}"
                echo -e "${BOLD_RED}Для работы скрипта требуется пакет $package_name.${NC}"
                sleep 2
                failed=true
            else
                echo -e "${GREEN}Пакет $package_name успешно установлен.${NC}"
            fi
        fi
    done
    
    if [ "$failed" = true ]; then
        return 1
    fi
    return 0
}

# Установка общих зависимостей для всех компонентов
install_dependencies() {
    echo -e "${GREEN}Проверка зависимостей...${NC}"
    sudo apt update >/dev/null 2>&1

    # Проверка и установка необходимых пакетов
    check_and_install_dependency "curl" "jq" "make" || {
        echo -e "${BOLD_RED}Ошибка: Не все необходимые зависимости были установлены.${NC}"
        return 1
    }

    # Проверка, установлен ли Docker
    if command -v docker &>/dev/null && docker --version &>/dev/null; then
        echo -e "${GREEN}Docker уже установлен. Пропускаем установку Docker.${NC}"
    else
        echo ""
        echo -e "${GREEN}Установка Docker и других необходимых пакетов...${NC}"

        # Установка предварительных зависимостей
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common make >/dev/null 2>&1

        # Создание директории для хранения ключей
        sudo mkdir -p /etc/apt/keyrings

        # Добавление официального GPG-ключа Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null || {
            # Если не удалось, пробуем удалить файл и добавить ключ снова
            sudo rm -f /etc/apt/keyrings/docker.gpg
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
        }

        # Настройка прав доступа к ключу
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Определение кодового имени дистрибутива
        CODENAME=$(lsb_release -cs)

        # Добавление репозитория Docker
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

        # Установка Docker Engine и Docker Compose plugin
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1

        # Проверка наличия группы docker и создание, если она не существует
        if ! getent group docker >/dev/null; then
            echo -e "${GREEN}Создание группы docker...${NC}"
            sudo groupadd docker
        fi

        # Добавление текущего пользователя в группу docker (чтобы использовать Docker без sudo)
        sudo usermod -aG docker $USER

        # Проверка успешности установки
        if command -v docker &>/dev/null; then
            echo -e "${GREEN}Docker успешно установлен$(docker --version)${NC}"
        else
            echo -e "${RED}Ошибка установки Docker${NC}"
            exit 1
        fi
    fi
}

# Включение модуля: remnawave_json.sh

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

# Включение модуля: caddy.sh

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

# Включение модуля: ui.sh

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
    
    echo -e "\033[1m└${border_line}┘\033[0m"
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

# Включение модуля: vless-configuration.sh

vless_configuration() {
    local panel_url="$1"
    local panel_domain="$2"
    local token="$3"
    local api_url="http://${panel_url}/api/auth/register"

    # Запрос домена Selfsteal с валидацией
    SELF_STEAL_DOMAIN=$(read_domain "Введите Selfsteal домен, например domain.example.com")
    if [ -z "$SELF_STEAL_DOMAIN" ]; then
        return 1
    fi

    # Запрос порта Selfsteal с валидацией и дефолтным значением 9443
    SELF_STEAL_PORT=$(read_port "Введите Selfsteal порт (можно оставить по умолчанию)" "9443")

    # Запрос IP адреса или домена сервера с нодой с валидацией и дефолтным значением Selfsteal домена
    NODE_HOST=$(read_domain "Введите IP адрес или домен сервера с нодой (если отличается от Selfsteal домена)" "$SELF_STEAL_DOMAIN")

    # Запрос порта API ноды с валидацией и дефолтным значением 3000
    NODE_PORT=$(read_port "Введите порт API ноды (можно оставить по умолчанию)" "3000")

    local config_file="$REMNAWAVE_DIR/panel/config.json"
    local node_name="VLESS-NODE"

    # Генерация ключей x25519 с помощью Docker
    echo -e "${BOLD_GREEN}Генерация ключей x25519...${NC}"
    sleep 1
    keys=$(docker run --rm ghcr.io/xtls/xray-core x25519)
    private_key=$(echo "$keys" | grep "Private key:" | awk '{print $3}')
    public_key=$(echo "$keys" | grep "Public key:" | awk '{print $3}')

    if [ -z "$private_key" ] || [ -z "$public_key" ]; then
        echo -e "${BOLD_RED}Ошибка: Не удалось сгенерировать ключи.${NC}"
    fi

    short_id=$(openssl rand -hex 8)
    cat > "$config_file" <<EOL
{
  "log": {
    "loglevel": "debug"
  },
  "inbounds": [
    {
      "tag": "VLESS TCP REALITY",
      "port": 443,
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "dest": "127.0.0.1:$SELF_STEAL_PORT",
          "show": false,
          "xver": 1,
          "shortIds": [
            "$short_id"
          ],
          "publicKey": "$public_key",
          "privateKey": "$private_key",
          "serverNames": [
              "$SELF_STEAL_DOMAIN"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      "tag": "BLOCK",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "rules": [
      {
        "ip": [
          "geoip:private"
        ],
        "type": "field",
        "outboundTag": "BLOCK"
      },
      {
        "type": "field",
        "domain": [
          "geosite:private"
        ],
        "outboundTag": "BLOCK"
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "BLOCK"
      }
    ]
  }
}
EOL

    echo -e "${BOLD_GREEN}Обновление конфигурации Xray...${NC}"
    sleep 1
    local new_config=$(cat "$config_file")
    local update_response=$(curl -s -X POST "http://$panel_url/api/xray/update-config" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https" \
        -d "$new_config")

    if [ -z "$update_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Пустой ответ от сервера при обновлении Xray конфига.${NC}"
    fi

    if echo "$update_response" | jq -e '.response.config' > /dev/null; then
        echo -e "${BOLD_GREEN}Конфигурация Xray успешно обновлена.${NC}"
        sleep 1
    else
        echo -e "${BOLD_RED}Ошибка: Не удалось обновить конфигурацию Xray.${NC}"
    fi

    local new_node_data=$(cat <<EOF
{
    "name": "$node_name",
    "address": "$NODE_HOST",
    "port": $NODE_PORT,
    "isTrafficTrackingActive": false,
    "trafficLimitBytes": 0,
    "notifyPercent": 0,
    "trafficResetDay": 31,
    "excludedInbounds": [],
    "countryCode": "XX",
    "consumptionMultiplier": 1.0
}
EOF
)
    # Создание ноды
    echo -e "${BOLD_GREEN}Создание ноды...${NC}"
    sleep 1
    node_response=$(curl -s -X POST "http://$panel_url/api/nodes/create" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https" \
        -d "$new_node_data")

    if [ -z "$node_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Пустой ответ от сервера при создании узла.${NC}"
    fi

    if echo "$node_response" | jq -e '.response.uuid' > /dev/null; then
        echo -e "${BOLD_GREEN}Узел успешно создан.${NC}"
    else
        echo -e "${BOLD_RED}Ошибка: Не удалось создать узел, ответ:${NC}"
        echo
        echo "Был направлен запрос с телом:"
        echo "$new_node_data"
        echo
        echo "Ответ:"
        echo
        echo "$node_response"
    fi

    # Получение inbounds
    inbounds_response=$(curl -s -X GET "http://$panel_url/api/inbounds" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https")

    if [ -z "$inbounds_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Пустой ответ от сервера при получении inbounds.${NC}"
    fi

    inbound_uuid=$(echo "$inbounds_response" | jq -r '.response[0].uuid')
    if [ -z "$inbound_uuid" ]; then
        echo -e "${BOLD_RED}Ошибка: Не удалось извлечь UUID из ответа.${NC}"
    fi
    echo -e "${BOLD_GREEN}Создаем хост с UUID: $inbound_uuid...${NC}"
    host_data=$(cat <<EOF
{
    "inboundUuid": "$inbound_uuid",
    "remark": "$node_name-HOST",
    "address": "$SELF_STEAL_DOMAIN",
    "port": 443,
    "path": "",
    "sni": "$SELF_STEAL_DOMAIN",
    "host": "$SELF_STEAL_DOMAIN",
    "alpn": "h2",
    "fingerprint": "chrome",
    "allowInsecure": false,
    "isDisabled": false
}
EOF
)

    host_response=$(curl -s -X POST "http://$panel_url/api/hosts/create" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https" \
        -d "$host_data")

    if [ -z "$host_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Пустой ответ от сервера при создании хоста.${NC}"
    fi

    if echo "$host_response" | jq -e '.response.uuid' > /dev/null; then
        echo -e "${BOLD_GREEN}Хост успешно создан.${NC}"
    else
        echo -e "${BOLD_RED}Ошибка: Не удалось создать хост.${NC}"
    fi

    api_response=$(curl -s -X GET "http://$panel_url/api/keygen/get" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https")

    if [ -z "$api_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Не удалось получить публичный ключ.${NC}"
    fi

    pubkey=$(echo "$api_response" | jq -r '.response.pubKey')
    if [ -z "$pubkey" ]; then
        echo -e "${BOLD_RED}Ошибка: Не удалось извлечь публичный ключ из ответа.${NC}"
    fi

    echo -e "${GREEN}Публичный ключ (нужен для установки ноды):${NC}"
    echo
    echo -e "SSL_CERT=\"$pubkey\""
    echo
}

# Включение модуля: panel.sh

# ===================================================================================
#                              УСТАНОВКА ПАНЕЛИ REMNAWAVE
# ===================================================================================

install_panel() {
    clear

    # Проверка наличия предыдущей установки
    if [ -d "$REMNAWAVE_DIR" ]; then
        echo -e "${BOLD_YELLOW}Обнаружена предыдущая установка RemnaWave.${NC}"
        echo -ne "${ORANGE}Хотите удалить предыдущую установку перед продолжением? (y/n): ${NC}"
        read REMOVE_PREVIOUS
        REMOVE_PREVIOUS=$(echo "$REMOVE_PREVIOUS" | tr '[:upper:]' '[:lower:]')
        echo

        if [ "$REMOVE_PREVIOUS" = "y" ] || [ "$REMOVE_PREVIOUS" = "yes" ]; then
            echo -e "${BOLD_YELLOW}Удаление предыдущей установки...${NC}"

            cd $REMNAWAVE_DIR && \
            docker compose -f panel/docker-compose.yml down 2>/dev/null || true
            docker compose -f caddy/docker-compose.yml down 2>/dev/null || true
            docker compose -f remnawave-json/docker-compose.yml down 2>/dev/null || true
            rm -rf $REMNAWAVE_DIR
            docker volume rm remnawave-db-data remnawave-redis-data 2>/dev/null || true

            echo -e "${BOLD_GREEN}Предыдущая установка успешно удалена.${NC}"
        else
            echo -e "${BOLD_YELLOW}Продолжаем установку без удаления предыдущей.${NC}"
        fi
    fi

    # Установка общих зависимостей
    install_dependencies

    # Создаем базовую директорию для всего проекта
    mkdir -p $REMNAWAVE_DIR/{panel,caddy}

    # Переходим в директорию панели
    cd $REMNAWAVE_DIR/panel

    # Генерация JWT секретов с помощью openssl
    JWT_AUTH_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    JWT_API_TOKENS_SECRET=$(openssl rand -hex 32 | tr -d '\n')

    # Генерация безопасных учетных данных
    DB_USER="remnawave_$(openssl rand -hex 4 | tr -d '\n')"
    DB_PASSWORD=$(generate_secure_password 16)
    DB_NAME="remnawave_db"
    METRICS_PASS=$(generate_secure_password 16)

    curl -s -o .env https://raw.githubusercontent.com/remnawave/backend/refs/heads/dev/.env.sample

    # Спрашиваем, нужна ли интеграция с Telegram
    echo -ne "${GREEN}Хотите включить интеграцию с Telegram? (y/n): ${NC}"
    read IS_TELEGRAM_ENABLED
    IS_TELEGRAM_ENABLED=$(echo "$IS_TELEGRAM_ENABLED" | tr '[:upper:]' '[:lower:]')
    echo

    # Преобразование y/n в true/false для файла .env
    if [ "$IS_TELEGRAM_ENABLED" = "y" ] || [ "$IS_TELEGRAM_ENABLED" = "yes" ]; then
        IS_TELEGRAM_ENV_VALUE="true"
        # Если интеграция с Telegram включена, запрашиваем параметры
        echo -ne "${ORANGE}Введите токен вашего Telegram бота: ${NC}"
        read TELEGRAM_BOT_TOKEN
        echo

        echo -ne "${ORANGE}Введите ID администратора Telegram: ${NC}"
        read TELEGRAM_ADMIN_ID
        echo

        echo -ne "${ORANGE}Введите ID чата для уведомлений: ${NC}"
        read NODES_NOTIFY_CHAT_ID
        echo
    else
        # Если интеграция с Telegram не включена, устанавливаем параметры в "change-me"
        IS_TELEGRAM_ENV_VALUE="false"
        echo -e "${BOLD_YELLOW}Пропуск интеграции с Telegram.${NC}"
        TELEGRAM_BOT_TOKEN="change-me"
        TELEGRAM_ADMIN_ID="change-me"
        NODES_NOTIFY_CHAT_ID="change-me"
    fi

    # Запрашиваем основной домен для панели с валидацией
    SCRIPT_PANEL_DOMAIN=$(read_domain "Введите основной домен для вашей панели (например, panel.example.com)")
    echo

    # Запрашиваем домен для подписок с валидацией
    SCRIPT_SUB_DOMAIN=$(read_domain "Введите домен для подписок (например, subs.example.com)")
    echo

    # Запрос на установку remnawave-json
    echo -ne "${GREEN}Установить remnawave-json https://github.com/Jolymmiles/remnawave-json ? (y/n): ${NC}"
    read INSTALL_REMNAWAVE_JSON
    INSTALL_REMNAWAVE_JSON=$(echo "$INSTALL_REMNAWAVE_JSON" | tr '[:upper:]' '[:lower:]')
    echo

    echo -e "${BOLD_RED}\033[1m┌────────────────────────────────────────────┐\033[0m${NC}"
    echo -e "${BOLD_RED}\033[1m│     Выберите способ создания пароля:       │\033[0m${NC}"
    echo -e "${BOLD_RED}\033[1m└────────────────────────────────────────────┘\033[0m${NC}"
    echo
    echo -e "${ORANGE}1. Ввести пароль вручную${NC}"
    echo -e "${ORANGE}2. Автоматически сгенерировать надежный пароль${NC}"
    echo
    echo -ne "${GREEN}Выберите опцию (1-2): ${NC}"
    read password_option
    echo

    echo -ne "${ORANGE}Пожалуйста, введите имя пользователя SuperAdmin: ${NC}"
    read SUPERADMIN_USERNAME
    echo

    if [ "$password_option" = "1" ]; then
        # Ручной ввод пароля
        while true; do
            echo -ne "${ORANGE}Введите пароль SuperAdmin (минимум 24 символа, должен содержать буквы разного регистра и цифры): ${NC}"
            stty -echo
            read PASSWORD1
            stty echo
            echo

            # Проверка длины пароля
            if [ ${#PASSWORD1} -lt 24 ]; then
                echo -e "${BOLD_RED}Пароль должен содержать не менее 24 символов. Пожалуйста, попробуйте снова.${NC}"
                continue
            fi

            echo -ne "${BOLD_RED}Повторно введите пароль SuperAdmin для подтверждения: ${NC}"
            stty -echo
            read PASSWORD2
            stty echo
            echo

            if [ "$PASSWORD1" = "$PASSWORD2" ]; then
                SUPERADMIN_PASSWORD=$PASSWORD1
                break
            else
                echo -e "${BOLD_RED}Пароли не совпадают. Пожалуйста, попробуйте снова.${NC}"
            fi
        done
    else
        # Автоматическая генерация пароля
        SUPERADMIN_PASSWORD=$(generate_secure_password 25)
        echo -e "${BOLD_GREEN}Сгенерирован надежный пароль: ${BOLD_RED}$SUPERADMIN_PASSWORD${NC}"
        echo -e "${ORANGE}Обязательно сохраните этот пароль в надежном месте!${NC}"
        echo
    fi

    sed -i "s|JWT_AUTH_SECRET=change_me|JWT_AUTH_SECRET=$JWT_AUTH_SECRET|" .env
    sed -i "s|JWT_API_TOKENS_SECRET=change_me|JWT_API_TOKENS_SECRET=$JWT_API_TOKENS_SECRET|" .env
    sed -i "s|IS_TELEGRAM_ENABLED=false|IS_TELEGRAM_ENABLED=$IS_TELEGRAM_ENV_VALUE|" .env
    sed -i "s|TELEGRAM_BOT_TOKEN=change_me|TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN|" .env
    sed -i "s|TELEGRAM_ADMIN_ID=change_me|TELEGRAM_ADMIN_ID=$TELEGRAM_ADMIN_ID|" .env
    sed -i "s|NODES_NOTIFY_CHAT_ID=change_me|NODES_NOTIFY_CHAT_ID=$NODES_NOTIFY_CHAT_ID|" .env
    sed -i "s|SUB_PUBLIC_DOMAIN=example.com|SUB_PUBLIC_DOMAIN=$SCRIPT_SUB_DOMAIN|" .env
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@remnawave-db:5432/$DB_NAME|" .env
    sed -i "s|POSTGRES_USER=.*|POSTGRES_USER=$DB_USER|" .env
    sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$DB_PASSWORD|" .env
    sed -i "s|POSTGRES_DB=.*|POSTGRES_DB=$DB_NAME|" .env
    sed -i "s|METRICS_PASS=.*|METRICS_PASS=$METRICS_PASS|" .env

    # Обрабатываем superadmin username и password - добавляем или обновляем переменные
    if grep -q "^SUPERADMIN_USERNAME=" .env; then
        sed -i "s|^SUPERADMIN_USERNAME=.*|SUPERADMIN_USERNAME=$SUPERADMIN_USERNAME|" .env
    else
        echo "SUPERADMIN_USERNAME=$SUPERADMIN_USERNAME" >>.env
    fi

    if grep -q "^SUPERADMIN_PASSWORD=" .env; then
        sed -i "s|^SUPERADMIN_PASSWORD=.*|SUPERADMIN_PASSWORD=$SUPERADMIN_PASSWORD|" .env
    else
        echo "SUPERADMIN_PASSWORD=$SUPERADMIN_PASSWORD" >>.env
    fi

    sleep 3

    # Создаем docker-compose.yml для панели
    curl -s -o docker-compose.yml https://raw.githubusercontent.com/remnawave/backend/refs/heads/dev/docker-compose-prod.yml

    # Меняем образ на dev
    sed -i "s|image: remnawave/backend:latest|image: remnawave/backend:dev|" docker-compose.yml

    # Создаем Makefile
    create_makefile "$REMNAWAVE_DIR/panel"

    # ===================================================================================
    # Установка и настройка remnawave-json
    # ===================================================================================

    setup_remnawave_json

    # ===================================================================================
    # Установка и настройка Caddy для панели и подписок
    # ===================================================================================

    # Генерация секретного ключа для защиты панели управления
    PANEL_SECRET_KEY=$(openssl rand -hex 16)
    
    # Передаем секретный ключ в функцию настройки Caddy
    setup_caddy_for_panel "$PANEL_SECRET_KEY"

    # Запуск всех контейнеров
    echo -e "${BOLD_GREEN}Запуск контейнеров...${NC}"

    # Запуск панели RemnaWave
    cd $REMNAWAVE_DIR/panel
    docker compose up -d

    # Запуск Caddy
    cd $REMNAWAVE_DIR/caddy
    docker compose up -d

    # Ждем инициализации Caddy
    sleep 5
    if ! docker ps | grep -q "caddy-remnawave"; then
        echo -e "${BOLD_RED}Caddy контейнер не запустился. Проверьте вашу конфигурацию домена.${NC}"
        echo -e "${ORANGE}Вы можете проверить логи позже с помощью 'make logs' в директории $REMNAWAVE_DIR/caddy.${NC}"
    else
        echo -e "${BOLD_GREEN}Caddy reverse proxy успешно запущен.${NC}"
    fi

    # Ждем инициализации панели
    sleep 5
    if ! docker ps | grep -q "remnawave/backend"; then
        echo -e "${BOLD_RED}RemaWave контейнер не запустился.${NC}"
        echo -e "${ORANGE}Вы можете проверить логи позже с помощью 'make logs' в директории $REMNAWAVE_DIR/panel.${NC}"
    else
        echo -e "${BOLD_GREEN}Контейнеры панели RemnaWave запущены.${NC}"
    fi

    # Запуск remnawave-json (если был выбран)
    if [ "$INSTALL_REMNAWAVE_JSON" = "y" ] || [ "$INSTALL_REMNAWAVE_JSON" = "yes" ]; then
        cd $REMNAWAVE_DIR/remnawave-json
        docker compose up -d

        # Ждем инициализации контейнера
        sleep 5
        if ! docker ps | grep -q "remnawave-json"; then
            echo -e "${BOLD_RED}Контейнер remnawave-json не запустился. Проверьте конфигурацию.${NC}"
            echo -e "${ORANGE}Вы можете проверить логи позже с помощью 'make logs' в директории $REMNAWAVE_DIR/remnawave-json.${NC}"
        else
            echo -e "${BOLD_GREEN}remnawave-json успешно запущен.${NC}"
        fi
    fi

    sleep 5
    # Регистрация пользователя и получение токена
    local reg_token=$(register_user "127.0.0.1:3000" "$SCRIPT_PANEL_DOMAIN" "$SUPERADMIN_USERNAME" "$SUPERADMIN_PASSWORD")
    local reg_status=$?

    if [ $reg_status -eq 0 ]; then
        echo -e "${GREEN}✓ Регистрация пользователя выполнена успешно${NC}"
        echo
        echo -e "${GREEN} Получен токен: $reg_token${NC}"
        echo
        vless_configuration "127.0.0.1:3000" "$SCRIPT_PANEL_DOMAIN" "$reg_token"
    else
        echo -e "${RED}✗ Ошибка при регистрации пользователя, конфигурация не выполнена.${NC}"
        echo -e "${GRAY}Ответ сервера: $reg_token${NC}"
    fi

    display_panel_installation_complete_message "$PANEL_SECRET_KEY"
}

# Включение модуля: selfsteal.sh

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

# Включение модуля: node.sh

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

    cd $REMNANODE_DIR
    docker compose up -d && docker compose logs -f > /tmp/node_logs 2>&1 & LOGS_PID=$!
    sleep 1
    tail -f /tmp/node_logs & TAIL_PID=$!
    sleep 5
    kill $LOGS_PID $TAIL_PID 2>/dev/null
    wait $LOGS_PID $TAIL_PID 2>/dev/null
    rm -f /tmp/node_logs
    
    # Проверяем, запущена ли нода
    NODE_STATUS=$(docker compose ps --services --filter "status=running" | grep -q "node" && echo "running" || echo "stopped")
    
    unset CERTIFICATE
    
    if [ "$NODE_STATUS" = "running" ]; then
        echo -e "${BOLD_GREEN}✓ Нода Remnawave успешно установлена и запущена!${NC}"
        echo -e "${LIGHT_GREEN}• Порт ноды: ${BOLD_GREEN}$NODE_PORT${NC}"
        echo -e "${LIGHT_GREEN}• Директория ноды: ${BOLD_GREEN}$REMNANODE_DIR${NC}"
        echo -e "\n${LIGHT_GREEN}Для управления нодой используйте следующие команды:${NC}"
        echo -e "${ORANGE}   cd $REMNANODE_DIR${NC}"
        echo -e "${ORANGE}   make start   ${NC}- Запуск ноды и просмотр логов"
        echo -e "${ORANGE}   make stop    ${NC}- Остановка ноды"
        echo -e "${ORANGE}   make restart ${NC}- Перезапуск ноды"
        echo -e "${ORANGE}   make logs    ${NC}- Просмотр логов ноды"
    else
        echo -e "${BOLD_RED}⚠ Нода Remnawave была установлена, но не запущена автоматически.${NC}"
        echo -e "${LIGHT_RED}Для запуска ноды вручную выполните:${NC}"
        echo -e "${ORANGE}   cd $REMNANODE_DIR${NC}"
        echo -e "${ORANGE}   make start${NC}"
        echo -e "\n${LIGHT_RED}Если ошибка сохраняется, проверьте логи:${NC}"
        echo -e "${ORANGE}   make logs${NC}"
    fi
    
    unset NODE_PORT
    
    echo -e "\n${BOLD_GREEN}Нажмите Enter, чтобы вернуться в главное меню...${NC}"
    read -r

}


# Проверка на root права
if [ "$(id -u)" -ne 0 ]; then
    echo "Ошибка: Этот скрипт должен быть запущен от имени root (sudo)"
    exit 1
fi

clear


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
        echo -e "  ${GREEN}1. ${NC}Установить панель Remnawave"
        echo -e "  ${GREEN}2. ${NC}Установить ноду Remnawave"
        echo -e "  ${GREEN}3. ${NC}Выход"
        echo
        echo -ne "${BOLD_BLUE_MENU}Выберите опцию (1-3): ${NC}"
        read choice

        case $choice in
        1)
            install_panel
            ;;
        2)
            setup_node
            ;;
        3)
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
