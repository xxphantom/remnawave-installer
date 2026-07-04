#!/bin/bash

# ===================================================================================
#                               SECURITY FUNCTIONS
# ===================================================================================

# Generate secure password with proper complexity
generate_secure_password() {
    local length="${1:-16}"
    local password=""
    local special_chars='!%^&*_+.,'
    local uppercase_chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local lowercase_chars='abcdefghijklmnopqrstuvwxyz'
    local number_chars='0123456789'
    local alphanumeric_chars="${uppercase_chars}${lowercase_chars}${number_chars}"

    # Generate the initial password from letters and digits only
    if command -v openssl &>/dev/null; then
        password="$(openssl rand -base64 48 | tr -dc "$alphanumeric_chars" | head -c "$length")"
    else
        # If openssl is unavailable, fallback to /dev/urandom
        password="$(head -c 100 /dev/urandom | tr -dc "$alphanumeric_chars" | head -c "$length")"
    fi

    # Check for presence of each character type and add missing ones
    # If no uppercase character, add one
    if ! [[ "$password" =~ [$uppercase_chars] ]]; then
        local position=$((RANDOM % length))
        local one_uppercase="$(echo "$uppercase_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_uppercase}${password:$((position + 1))}"
    fi

    # If no lowercase character, add one
    if ! [[ "$password" =~ [$lowercase_chars] ]]; then
        local position=$((RANDOM % length))
        local one_lowercase="$(echo "$lowercase_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_lowercase}${password:$((position + 1))}"
    fi

    # If no digit, add one
    if ! [[ "$password" =~ [$number_chars] ]]; then
        local position=$((RANDOM % length))
        local one_number="$(echo "$number_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_number}${password:$((position + 1))}"
    fi

    # Add 1 to 3 special characters (depending on password length), but no more than 25% of password length
    local special_count=$((length / 4))
    special_count=$((special_count > 0 ? special_count : 1))
    special_count=$((special_count < 3 ? special_count : 3))

    for ((i = 0; i < special_count; i++)); do
        # Choose a random position, avoiding first and last character
        local position=$((RANDOM % (length - 2) + 1))
        local one_special="$(echo "$special_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_special}${password:$((position + 1))}"
    done

    echo "$password"
}

# Generate readable login name
generate_readable_login() {
    local length="${1:-8}"
    local consonants=('b' 'c' 'd' 'f' 'g' 'h' 'j' 'k' 'l' 'm' 'n' 'p' 'r' 's' 't' 'v' 'w' 'x' 'z')
    local vowels=('a' 'e' 'i' 'o' 'u' 'y')
    local login=""
    local type="consonant"

    # Start with a consonant (easier to pronounce)
    while [ ${#login} -lt $length ]; do
        if [ "$type" = "consonant" ]; then
            # Add consonant
            login+=${consonants[$RANDOM % ${#consonants[@]}]}
            type="vowel"
        else
            # Add vowel
            login+=${vowels[$RANDOM % ${#vowels[@]}]}
            type="consonant"
        fi
    done

    # Add random number at the end (optional)
    local add_number=$((RANDOM % 2))
    if [ $add_number -eq 1 ]; then
        login+=$((RANDOM % 100))
    fi

    echo "$login"
}

# Generate nonce
# Nonce – aAzZ0-9, min 6, max 64
generate_nonce() {
    local length="${1:-64}"
    local nonce=""
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    while [ ${#nonce} -lt $length ]; do
        nonce+="${chars:$((RANDOM % ${#chars})):1}"
    done

    echo "$nonce"
}

# Generate custom path
# Path – a-zA-Z0-9-
generate_custom_path() {
    local length="${1:-36}"
    local path=""
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"

    while [ ${#path} -lt $length ]; do
        path+="${chars:$((RANDOM % ${#chars})):1}"
    done

    echo "$path"
}

# Generate common secrets
generate_secrets() {
    JWT_AUTH_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    JWT_API_TOKENS_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    DB_USER="remnawave_$(openssl rand -hex 4 | tr -d '\n')"
    # Hex only: the password is embedded in DATABASE_URL and must stay URI-safe
    DB_PASSWORD=$(openssl rand -hex 24 | tr -d '\n')
    DB_NAME="remnawave_db"
    METRICS_PASS=$(generate_secure_password 16)
    SUPERADMIN_USERNAME=$(generate_readable_login)
    SUPERADMIN_PASSWORD=$(generate_secure_password 28)
}
