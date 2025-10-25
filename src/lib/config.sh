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

# Collect Telegram configuration
collect_telegram_config() {
    if prompt_yes_no "$(t telegram_enable_notifications)"; then
        IS_TELEGRAM_NOTIFICATIONS_ENABLED=true
        TELEGRAM_BOT_TOKEN=$(prompt_input "$(t telegram_bot_token)" "$ORANGE")

        TELEGRAM_NOTIFY_NODES_CHAT_ID=$(prompt_input "$(t telegram_nodes_chat_id)" "$ORANGE")

        # Ask about user notifications (optional since 1.6.7)
        if prompt_yes_no "$(t telegram_enable_user_notifications)"; then
            TELEGRAM_NOTIFY_USERS_CHAT_ID=$(prompt_input "$(t telegram_users_chat_id)" "$ORANGE")
        else
            # Leave empty to disable user notifications
            TELEGRAM_NOTIFY_USERS_CHAT_ID=""
        fi

        # Ask about CRM notifications (optional)
        if prompt_yes_no "$(t telegram_enable_crm_notifications)"; then
            TELEGRAM_NOTIFY_CRM_CHAT_ID=$(prompt_input "$(t telegram_crm_chat_id)" "$ORANGE")
        else
            # Leave empty to disable CRM notifications
            TELEGRAM_NOTIFY_CRM_CHAT_ID=""
        fi

        if prompt_yes_no "$(t telegram_use_topics)"; then
            # Only ask for user thread ID if user notifications are enabled
            if [ -n "$TELEGRAM_NOTIFY_USERS_CHAT_ID" ]; then
                TELEGRAM_NOTIFY_USERS_THREAD_ID=$(prompt_input "$(t telegram_users_thread_id)" "$ORANGE")
            else
                TELEGRAM_NOTIFY_USERS_THREAD_ID=""
            fi
            # Only ask for CRM thread ID if CRM notifications are enabled
            if [ -n "$TELEGRAM_NOTIFY_CRM_CHAT_ID" ]; then
                TELEGRAM_NOTIFY_CRM_THREAD_ID=$(prompt_input "$(t telegram_crm_thread_id)" "$ORANGE")
            else
                TELEGRAM_NOTIFY_CRM_THREAD_ID=""
            fi
            TELEGRAM_NOTIFY_NODES_THREAD_ID=$(prompt_input "$(t telegram_nodes_thread_id)" "$ORANGE")
        else
            # Initialize thread ID variables as empty when not using topics
            TELEGRAM_NOTIFY_USERS_THREAD_ID=""
            TELEGRAM_NOTIFY_CRM_THREAD_ID=""
            TELEGRAM_NOTIFY_NODES_THREAD_ID=""
        fi
    else
        show_warning "$(t warning_skipping_telegram)"
        IS_TELEGRAM_NOTIFICATIONS_ENABLED=false
        TELEGRAM_BOT_TOKEN="change-me"
        TELEGRAM_NOTIFY_USERS_CHAT_ID="change-me"
        TELEGRAM_NOTIFY_NODES_CHAT_ID="change-me"
        TELEGRAM_NOTIFY_CRM_CHAT_ID="change-me"
        TELEGRAM_NOTIFY_USERS_THREAD_ID=""
        TELEGRAM_NOTIFY_NODES_THREAD_ID=""
        TELEGRAM_NOTIFY_CRM_THREAD_ID=""
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
    CADDY_LOCAL_PORT=$(get_available_port "9443" "Caddy")
    NODE_PORT=$(get_available_port "2222" "Node API")
}

collect_ports_separate_installation() {
    # For separate installations, both CADDY_LOCAL_PORT and NODE_PORT must be fixed

    # Check Caddy port 9443
    if CADDY_LOCAL_PORT=$(check_required_port "9443"); then
        show_info "$(t config_caddy_port_available)"
    else
        show_error "$(t config_caddy_port_in_use)"
        show_error "$(t config_separate_installation_port_required) 9443."
        show_error "$(t config_free_port_and_retry) 9443."
        show_error "$(t config_installation_cannot_continue) 9443"
        return 1
    fi

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
        "TELEGRAM_NOTIFY_USERS_CHAT_ID" "$TELEGRAM_NOTIFY_USERS_CHAT_ID" \
        "TELEGRAM_NOTIFY_NODES_CHAT_ID" "$TELEGRAM_NOTIFY_NODES_CHAT_ID" \
        "TELEGRAM_NOTIFY_CRM_CHAT_ID" "$TELEGRAM_NOTIFY_CRM_CHAT_ID" \
        "TELEGRAM_NOTIFY_USERS_THREAD_ID" "$TELEGRAM_NOTIFY_USERS_THREAD_ID" \
        "TELEGRAM_NOTIFY_NODES_THREAD_ID" "$TELEGRAM_NOTIFY_NODES_THREAD_ID" \
        "TELEGRAM_NOTIFY_CRM_THREAD_ID" "$TELEGRAM_NOTIFY_CRM_THREAD_ID" \
        "SUB_PUBLIC_DOMAIN" "$SUB_DOMAIN" \
        "DATABASE_URL" "postgresql://$DB_USER:$DB_PASSWORD@remnawave-db:5432/$DB_NAME" \
        "POSTGRES_USER" "$DB_USER" \
        "POSTGRES_PASSWORD" "$DB_PASSWORD" \
        "POSTGRES_DB" "$DB_NAME" \
        "METRICS_PASS" "$METRICS_PASS"
}

setup_panel_docker_compose() {
    cat >>docker-compose.yml <<"EOF"
services:
  remnawave-db:
    image: postgres:17.6
    container_name: 'remnawave-db'
    hostname: remnawave-db
    restart: always
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

  remnawave:
    image: remnawave/backend:REMNAWAVE_BACKEND_TAG_PLACEHOLDER
    container_name: 'remnawave'
    hostname: remnawave
    restart: always
    ports:
      - '127.0.0.1:3000:3000'
    env_file:
      - .env
    networks:
      - remnawave-network
    depends_on:
      remnawave-db:
        condition: service_healthy
      remnawave-redis:
        condition: service_healthy
    healthcheck:
      test: ['CMD-SHELL', 'curl -f http://localhost:$${METRICS_PORT}/health || exit 1']
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  remnawave-redis:
    image: valkey/valkey:8.1-alpine
    container_name: remnawave-redis
    hostname: remnawave-redis
    restart: always
    networks:
      - remnawave-network
    volumes:
      - remnawave-redis-data:/data
    healthcheck:
      test: [ "CMD", "valkey-cli", "ping" ]
      interval: 3s
      timeout: 10s
      retries: 3

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
  remnawave-redis-data:
    driver: local
    external: false
    name: remnawave-redis-data
EOF

    # Replace Docker image tag placeholder with actual value
    sed -i "s/REMNAWAVE_BACKEND_TAG_PLACEHOLDER/$REMNAWAVE_BACKEND_TAG/g" docker-compose.yml
}
