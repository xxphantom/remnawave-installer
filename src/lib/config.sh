#!/bin/bash

# ===================================================================================
#                                CONFIG FUNCTIONS
# ===================================================================================

# Function for safely updating .env file with multiple keys
update_file() {
    local env_file="$1"
    shift

    # Check for parameters
    if [ "$#" -eq 0 ] || [ $(($# % 2)) -ne 0 ]; then
        echo "$(t config_invalid_arguments)" >&2
        return 1
    fi

    # Convert arguments to key and value arrays
    local keys=()
    local values=()

    while [ "$#" -gt 0 ]; do
        keys+=("$1")
        values+=("$2")
        shift 2
    done

    # Create a temporary file
    local temp_file=$(mktemp)

    # Process file line by line and replace needed lines
    while IFS= read -r line || [[ -n "$line" ]]; do
        local key_found=false
        for i in "${!keys[@]}"; do
            if [[ "$line" =~ ^${keys[$i]}= ]]; then
                echo "${keys[$i]}=${values[$i]}" >>"$temp_file"
                key_found=true
                break
            fi
        done

        if [ "$key_found" = false ]; then
            echo "$line" >>"$temp_file"
        fi
    done <"$env_file"

    # Replace original file
    mv "$temp_file" "$env_file"
}

# Build telegram notify value in "chat_id:thread_id" format
# If thread_id is empty, returns just chat_id
build_telegram_notify_value() {
    local chat_id="$1"
    local thread_id="$2"

    if [ -n "$thread_id" ]; then
        echo "${chat_id}:${thread_id}"
    else
        echo "$chat_id"
    fi
}

# Collect chat_id and optional thread_id for a telegram notification channel
collect_telegram_channel() {
    local chat_id_prompt="$1"
    local chat_id
    local thread_id

    chat_id=$(prompt_input "$chat_id_prompt" "$ORANGE")

    if prompt_yes_no "$(t telegram_use_topics)"; then
        thread_id=$(prompt_input "$(t telegram_thread_id)" "$ORANGE")
    else
        thread_id=""
    fi

    build_telegram_notify_value "$chat_id" "$thread_id"
}

# Collect Telegram configuration
collect_telegram_config() {
    if prompt_yes_no "$(t telegram_enable_notifications)"; then
        IS_TELEGRAM_NOTIFICATIONS_ENABLED=true
        TELEGRAM_BOT_TOKEN=$(prompt_input "$(t telegram_bot_token)" "$ORANGE")

        TELEGRAM_NOTIFY_NODES=$(collect_telegram_channel "$(t telegram_nodes_chat_id)")

        # Ask about user notifications (optional)
        if prompt_yes_no "$(t telegram_enable_user_notifications)"; then
            TELEGRAM_NOTIFY_USERS=$(collect_telegram_channel "$(t telegram_users_chat_id)")
        else
            TELEGRAM_NOTIFY_USERS=""
        fi

        # Ask about CRM notifications (optional)
        if prompt_yes_no "$(t telegram_enable_crm_notifications)"; then
            TELEGRAM_NOTIFY_CRM=$(collect_telegram_channel "$(t telegram_crm_chat_id)")
        else
            TELEGRAM_NOTIFY_CRM=""
        fi

        # Ask about service notifications (optional)
        if prompt_yes_no "$(t telegram_enable_service_notifications)"; then
            TELEGRAM_NOTIFY_SERVICE=$(collect_telegram_channel "$(t telegram_service_chat_id)")
        else
            TELEGRAM_NOTIFY_SERVICE=""
        fi

        # Ask about TBLOCKER notifications (optional)
        if prompt_yes_no "$(t telegram_enable_tblocker_notifications)"; then
            TELEGRAM_NOTIFY_TBLOCKER=$(collect_telegram_channel "$(t telegram_tblocker_chat_id)")
        else
            TELEGRAM_NOTIFY_TBLOCKER=""
        fi
    else
        show_warning "$(t warning_skipping_telegram)"
        IS_TELEGRAM_NOTIFICATIONS_ENABLED=false
        TELEGRAM_BOT_TOKEN=""
        TELEGRAM_NOTIFY_NODES=""
        TELEGRAM_NOTIFY_USERS=""
        TELEGRAM_NOTIFY_CRM=""
        TELEGRAM_NOTIFY_SERVICE=""
        TELEGRAM_NOTIFY_TBLOCKER=""
    fi
}

# Check if domain is unique among already collected domains
check_domain_uniqueness() {
    local new_domain="$1"
    local domain_type="$2"
    local existing_domains=("${@:3}")

    for existing_domain in "${existing_domains[@]}"; do
        if [ -n "$existing_domain" ] && [ "$new_domain" = "$existing_domain" ]; then
            show_error "$(t config_domain_already_used) '$new_domain'"
            show_error "$(t config_domains_must_be_unique)"
            return 1
        fi
    done
    return 0
}

# Collect domain configuration (panel and subscription domains only)
collect_domain_config() {
    # First, collect panel domain
    PANEL_DOMAIN=$(prompt_domain "$(t domain_panel_prompt)")

    # Then collect subscription domain with uniqueness check
    while true; do
        SUB_DOMAIN=$(prompt_domain "$(t domain_subscription_prompt)")

        # Check that subscription domain is different from panel domain
        if check_domain_uniqueness "$SUB_DOMAIN" "subscription" "$PANEL_DOMAIN"; then
            break
        fi
        show_warning "$(t warning_enter_different_domain) subscription."
    done
}

collect_ports_all_in_one() {
    NODE_PORT=$(get_available_port "2222" "Node API")
}

collect_ports_separate_installation() {
    # Check Node API port 2222
    if NODE_PORT=$(check_required_port "2222"); then
        show_info "$(t config_node_port_available)"
    else
        show_error "$(t config_node_port_in_use)"
        show_error "$(t config_separate_installation_port_required) 2222."
        show_error "$(t config_free_port_and_retry) 2222."
        show_error "$(t config_installation_cannot_continue) 2222"
        return 1
    fi
}

# Setup common environment
setup_panel_environment() {
    # Download environment template
    # For alpha branch, use dev branch's .env file
    # For numeric versions, use main branch's .env file
    local env_branch="$REMNAWAVE_BRANCH"
    if [ "$REMNAWAVE_BRANCH" = "alpha" ]; then
        env_branch="dev"
    elif [[ "$REMNAWAVE_BRANCH" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        env_branch="main"
    fi
    curl -s -o .env "$REMNAWAVE_BACKEND_REPO/$env_branch/.env.sample"

    # Update environment file
    update_file ".env" \
        "JWT_AUTH_SECRET" "$JWT_AUTH_SECRET" \
        "JWT_API_TOKENS_SECRET" "$JWT_API_TOKENS_SECRET" \
        "IS_TELEGRAM_NOTIFICATIONS_ENABLED" "$IS_TELEGRAM_NOTIFICATIONS_ENABLED" \
        "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN" \
        "TELEGRAM_NOTIFY_NODES" "$TELEGRAM_NOTIFY_NODES" \
        "TELEGRAM_NOTIFY_USERS" "$TELEGRAM_NOTIFY_USERS" \
        "TELEGRAM_NOTIFY_CRM" "$TELEGRAM_NOTIFY_CRM" \
        "TELEGRAM_NOTIFY_SERVICE" "$TELEGRAM_NOTIFY_SERVICE" \
        "TELEGRAM_NOTIFY_TBLOCKER" "$TELEGRAM_NOTIFY_TBLOCKER" \
        "SUB_PUBLIC_DOMAIN" "$SUB_DOMAIN" \
        "DATABASE_URL" "postgresql://$DB_USER:$DB_PASSWORD@remnawave-db:5432/$DB_NAME" \
        "POSTGRES_USER" "$DB_USER" \
        "POSTGRES_PASSWORD" "$DB_PASSWORD" \
        "POSTGRES_DB" "$DB_NAME" \
        "METRICS_PASS" "$METRICS_PASS" \
        "REDIS_SOCKET" "/var/run/valkey/valkey.sock"
}

setup_panel_docker_compose() {
    cat >>docker-compose.yml <<"EOF"
services:
  remnawave-db:
    image: postgres:17.6
    container_name: 'remnawave-db'
    hostname: remnawave-db
    restart: always
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    env_file:
      - .env
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - TZ=UTC
    ports:
      - '127.0.0.1:6767:5432'
    volumes:
      - remnawave-db-data:/var/lib/postgresql/data
    networks:
      - remnawave-network
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}']
      interval: 3s
      timeout: 10s
      retries: 3
    logging:
      driver: 'json-file'
      options:
        max-size: '30m'
        max-file: '5'

  remnawave:
    image: remnawave/backend:REMNAWAVE_BACKEND_TAG_PLACEHOLDER
    container_name: 'remnawave'
    hostname: remnawave
    restart: always
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    ports:
      - '127.0.0.1:3000:3000'
      - '127.0.0.1:3001:3001'
    env_file:
      - .env
    volumes:
      - valkey-socket:/var/run/valkey
    networks:
      - remnawave-network
    depends_on:
      remnawave-db:
        condition: service_healthy
      remnawave-redis:
        condition: service_healthy
    healthcheck:
      test: ['CMD-SHELL', 'curl -f http://localhost:3001/health']
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s
    logging:
      driver: 'json-file'
      options:
        max-size: '30m'
        max-file: '5'

  remnawave-redis:
    image: valkey/valkey:9-alpine
    container_name: remnawave-redis
    hostname: remnawave-redis
    restart: always
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    networks:
      - remnawave-network
    volumes:
      - valkey-socket:/var/run/valkey
    command: >
      valkey-server
      --save ""
      --appendonly no
      --maxmemory-policy noeviction
      --loglevel warning
      --unixsocket /var/run/valkey/valkey.sock
      --unixsocketperm 777
      --port 0
    healthcheck:
      test: ['CMD', 'valkey-cli', '-s', '/var/run/valkey/valkey.sock', 'ping']
      interval: 3s
      timeout: 3s
      retries: 3
    logging:
      driver: 'json-file'
      options:
        max-size: '30m'
        max-file: '5'

networks:
  remnawave-network:
    name: remnawave-network
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.0.0/16
    external: false

volumes:
  remnawave-db-data:
    driver: local
    external: false
    name: remnawave-db-data
  valkey-socket:
    name: valkey-socket
    driver: local
    external: false
EOF

    # Replace Docker image tag placeholder with actual value
    sed -i "s/REMNAWAVE_BACKEND_TAG_PLACEHOLDER/$REMNAWAVE_BACKEND_TAG/g" docker-compose.yml
}
