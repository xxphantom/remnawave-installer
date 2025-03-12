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

# Очистка экрана
clear_screen() {
    clear
}

# Отображение заголовка раздела
draw_section_header() {
    local title="$1"
    local width=${2:-50}
    
    echo -e "${BOLD_RED}\033[1m┌$(printf '─%.0s' $(seq 1 $width))┐\033[0m${NC}"
    
    # Центрирование заголовка
    local padding_left=$(((width - ${#title}) / 2))
    local padding_right=$((width - padding_left - ${#title}))
    echo -e "${BOLD_RED}\033[1m│$(printf ' %.0s' $(seq 1 $padding_left))$title$(printf ' %.0s' $(seq 1 $padding_right))│\033[0m${NC}"
    
    echo -e "${BOLD_RED}\033[1m└$(printf '─%.0s' $(seq 1 $width))┘\033[0m${NC}"
    echo
}

# Отображение опций меню с нумерацией
draw_menu_options() {
    local options=("$@")
    local idx=1
    
    for option in "${options[@]}"; do
        echo -e "${ORANGE}$idx. $option${NC}"
        ((idx++))
    done
    echo
}

# Запрос ввода с предустановленным текстом и цветом
prompt_input() {
    local prompt_text="$1"
    local prompt_color="${2:-$GREEN}"
    
    echo -ne "${prompt_color}${prompt_text}${NC}" >&2
    read input_value
    echo >&2
    
    echo "$input_value"
}

# Запрос ввода пароля (с отключением эхо)
prompt_password() {
    local prompt_text="$1"
    local prompt_color="${2:-$ORANGE}"
    
    echo -ne "${prompt_color}${prompt_text}${NC}" >&2
    stty -echo
    read password_value
    stty echo
    echo >&2
    
    echo "$password_value"
}

# Запрос выбора опции (y/n)
prompt_yes_no() {
    local prompt_text="$1"
    local prompt_color="${2:-$GREEN}"
    local default="${3:-}"
    
    local prompt_suffix=" (y/n): "
    [ -n "$default" ] && prompt_suffix=" (y/n) [$default]: "
    
    echo -ne "${prompt_color}${prompt_text}${prompt_suffix}${NC}" >&2
    read answer
    echo >&2
    
    # Преобразование в нижний регистр
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    
    # Если пусто, используем значение по умолчанию
    [ -z "$answer" ] && answer="$default"
    
    if [ "$answer" = "y" ] || [ "$answer" = "yes" ]; then
        return 0
    else
        return 1
    fi
}

# Выбор опции из нумерованного меню
prompt_menu_option() {
    local prompt_text="$1"
    local prompt_color="${2:-$GREEN}"
    local min="${3:-1}"
    local max="$4"
    
    local selected_option
    while true; do
        echo -ne "${prompt_color}${prompt_text} (${min}-${max}): ${NC}" >&2
        read selected_option
        echo >&2
        
        # Валидация выбора
        if [[ "$selected_option" =~ ^[0-9]+$ ]] && \
           [ "$selected_option" -ge "$min" ] && \
           [ "$selected_option" -le "$max" ]; then
            break
        else
            echo -e "${BOLD_RED}Пожалуйста, введите число от ${min} до ${max}.${NC}" >&2
        fi
    done
    
    echo "$selected_option"
}

# Отображение сообщения об успехе
show_success() {
    local message="$1"
    echo -e "${BOLD_GREEN}✓ ${message}${NC}"
    echo ""
}

# Отображение сообщения об ошибке
show_error() {
    local message="$1"
    echo -e "${BOLD_RED}✗ ${message}${NC}"
    echo ""
}

# Отображение предупреждения
show_warning() {
    local message="$1"
    echo -e "${BOLD_YELLOW}⚠  ${message}${NC}"
    echo ""
}

# Отображение информационного сообщения
show_info() {
    local message="$1"
    local color="${2:-$ORANGE}"
    echo -e "${color}${message}${NC}"
    echo ""
}

# Отображение разделителя
draw_separator() {
    local width=${1:-50}
    local char=${2:-"-"}
    
    printf "%s\n" "$(printf "$char%.0s" $(seq 1 $width))"
}

# Отображение прогресса операции
show_progress() {
    local message="$1"
    local progress_char=${2:-"."}
    local count=${3:-3}
    
    echo -ne "${message}"
    for ((i=0; i<count; i++)); do
        echo -ne "${progress_char}"
        sleep 0.5
    done
    echo ""
}

# Запрос домена с валидацией
prompt_domain() {
    local prompt_text="$1"
    local prompt_color="${2:-$ORANGE}"
    
    local domain
    while true; do
        echo -ne "${prompt_color}${prompt_text}: ${NC}" >&2
        read domain
        echo >&2
        
        # Базовая валидация домена (может быть расширена)
        if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
            break
        else
            echo -e "${BOLD_RED}Неверный формат домена. Пожалуйста, попробуйте снова.${NC}" >&2
        fi
    done
    
    echo "$domain"
    echo ""
}

# Запрос числового значения с валидацией
prompt_number() {
    local prompt_text="$1"
    local prompt_color="${2:-$ORANGE}"
    local min="${3:-1}"
    local max="${4:-}"
    
    local number
    while true; do
        echo -ne "${prompt_color}${prompt_text}: ${NC}" >&2
        read number
        echo >&2
        
        # Валидация числа
        if [[ "$number" =~ ^[0-9]+$ ]]; then
            if [ -n "$min" ] && [ "$number" -lt "$min" ]; then
                echo -e "${BOLD_RED}Значение должно быть не меньше ${min}.${NC}" >&2
                continue
            fi
            
            if [ -n "$max" ] && [ "$number" -gt "$max" ]; then
                echo -e "${BOLD_RED}Значение должно быть не больше ${max}.${NC}" >&2
                continue
            fi
            
            break
        else
            echo -e "${BOLD_RED}Пожалуйста, введите корректное числовое значение.${NC}" >&2
        fi
    done
    
    echo "$number"
}

# Отображение ряда с заголовком и значением
draw_info_row() {
    local label="$1"
    local value="$2"
    local label_color="${3:-$ORANGE}"
    local value_color="${4:-$GREEN}"
    local width=${5:-50}
    
    local label_display="${label_color}${label}:${NC}"
    local value_display="${value_color}${value}${NC}"
    
    echo -e "${label_display} ${value_display}"
}

# Центрирование текста
center_text() {
    local text="$1"
    local width=${2:-$(tput cols)}
    local padding_left=$(((width - ${#text}) / 2))
    
    printf "%${padding_left}s%s\n" "" "$text"
}

# Отображение блока с завершающим сообщением
draw_completion_message() {
    local title="$1"
    local message="$2"
    local width=${3:-70}
    
    draw_separator "$width" "="
    center_text "$title" "$width"
    echo
    echo -e "$message"
    draw_separator "$width" "="
}

# Валидация пароля на сложность
validate_password_strength() {
    local password="$1"
    local min_length=${2:-8}
    
    local length=${#password}
    
    # Проверка длины
    if [ "$length" -lt "$min_length" ]; then
        echo "Пароль должен содержать не менее $min_length символов."
        return 1
    fi
    
    # Проверка наличия цифр
    if ! [[ "$password" =~ [0-9] ]]; then
        echo "Пароль должен содержать хотя бы одну цифру."
        return 1
    fi
    
    # Проверка наличия букв нижнего регистра
    if ! [[ "$password" =~ [a-z] ]]; then
        echo "Пароль должен содержать хотя бы одну букву нижнего регистра."
        return 1
    fi
    
    # Проверка наличия букв верхнего регистра
    if ! [[ "$password" =~ [A-Z] ]]; then
        echo "Пароль должен содержать хотя бы одну букву верхнего регистра."
        return 1
    fi
    
    # Пароль прошел все проверки
    return 0
}

# Запрос пароля с подтверждением и проверкой сложности
prompt_secure_password() {
    local prompt_text="$1"
    local confirm_text="${2:-Повторно введите пароль для подтверждения}"
    local min_length=${3:-8}
    
    local password1 password2 error_message
    
    while true; do
        # Запрашиваем пароль
        password1=$(prompt_password "$prompt_text")
        
        # Проверяем сложность пароля
        error_message=$(validate_password_strength "$password1" "$min_length")
        if [ $? -ne 0 ]; then
            echo -e "${BOLD_RED}${error_message} Пожалуйста, попробуйте снова.${NC}" >&2
            continue
        fi
        
        # Запрашиваем подтверждение пароля
        password2=$(prompt_password "$confirm_text")
        
        # Проверяем совпадение паролей
        if [ "$password1" = "$password2" ]; then
            break
        else
            echo -e "${BOLD_RED}Пароли не совпадают. Пожалуйста, попробуйте снова.${NC}" >&2
        fi
    done
    
    echo "$password1"
}
