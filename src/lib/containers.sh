#!/bin/bash

# ===================================================================================
#                               DOCKER CONTAINER FUNCTIONS
# ===================================================================================

# Resolve the subscription page directory, honoring pre-v2.2 installs
get_subscription_page_dir() {
    if [ -f "$SUBSCRIPTION_PAGE_DIR/docker-compose.yml" ]; then
        echo "$SUBSCRIPTION_PAGE_DIR"
    elif [ -f "$LEGACY_SUBSCRIPTION_PAGE_DIR/docker-compose.yml" ]; then
        echo "$LEGACY_SUBSCRIPTION_PAGE_DIR"
    else
        echo "$SUBSCRIPTION_PAGE_DIR"
    fi
}

# Resolve the node directory: node-only installs use /opt/remnanode,
# all-in-one keeps the node in /opt/remnawave/node
get_node_dir() {
    if [ -f "$REMNANODE_DIR/docker-compose.yml" ]; then
        echo "$REMNANODE_DIR"
    elif [ -f "$LOCAL_REMNANODE_DIR/docker-compose.yml" ]; then
        echo "$LOCAL_REMNANODE_DIR"
    else
        echo "$REMNANODE_DIR"
    fi
}

# Wait for Caddy socket to be ready
wait_for_caddy_socket() {
    local max_wait=${1:-30}
    local elapsed=0

    show_info "$(t waiting_for_caddy_socket)" "$ORANGE"

    while [ ! -S "$CADDY_SOCKET_PATH" ]; do
        if [ $elapsed -ge $max_wait ]; then
            show_error "$(t error_caddy_socket_timeout)"
            return 1
        fi
        sleep 1
        ((elapsed++))
    done

    show_success "$(t caddy_socket_ready)"
    return 0
}

remove_previous_installation() {
    local from_menu=${1:-false}

    # Check if any installation directory exists (panel or node-only)
    if [ -d "$REMNAWAVE_DIR" ] || [ -d "$REMNANODE_DIR" ]; then
        # Show warning and request confirmation (keep as is)
        if [ "$from_menu" = true ]; then
            show_warning "$(t removal_installation_detected)"
            if [ "$KEEP_CADDY_DATA" = "true" ]; then
                echo -e "${BOLD_GREEN}$(t removal_keep_caddy_data)${NC}"
            fi
            if ! prompt_yes_no "$(t removal_confirm_delete)" "$ORANGE"; then
                return 1
            fi
        else
            show_warning "$(t removal_previous_detected)"
            if [ "$KEEP_CADDY_DATA" = "true" ]; then
                echo -e "${BOLD_GREEN}$(t removal_keep_caddy_data)${NC}"
            fi
            if ! prompt_yes_no "$(t removal_confirm_continue)" "$ORANGE"; then
                return 1
            fi
        fi

        # Array of compose files to process
        local compose_configs=(
            "$REMNAWAVE_DIR/caddy/docker-compose.yml"
            "$LOCAL_REMNANODE_DIR/docker-compose.yml"
            "$SUBSCRIPTION_PAGE_DIR/docker-compose.yml"
            "$LEGACY_SUBSCRIPTION_PAGE_DIR/docker-compose.yml" # Old path - for backward compatibility
            "$REMNAWAVE_DIR/docker-compose.yml"
            "$REMNANODE_DIR/docker-compose.yml"
            "$SELFSTEAL_DIR/docker-compose.yml"
            "$REMNAWAVE_DIR/panel/docker-compose.yml" # Old path - for backward compatibility
            "$REMNANODE_DIR/node/docker-compose.yml"  # Old path - for backward compatibility
        )

        # Process each compose file
        for compose_file in "${compose_configs[@]}"; do
            if [ -f "$compose_file" ]; then
                local dir_path=$(dirname "$compose_file")
                local compose_cmd="docker compose down"
                
                # Check if this is Caddy and we should keep its data
                if [[ "$dir_path" == *"/caddy"* ]] && [ "$KEEP_CADDY_DATA" = "true" ]; then
                    # Don't remove volumes for Caddy
                    compose_cmd="$compose_cmd --rmi local --remove-orphans"
                else
                    # Remove volumes for everything else (or for Caddy if not keeping data)
                    compose_cmd="$compose_cmd -v --rmi local --remove-orphans"
                fi
                
                cd "$dir_path" && eval "$compose_cmd" >/dev/null 2>&1 &
                spinner $! "$(t spinner_cleaning_services) $(basename "$dir_path")"
            fi
        done

        # Force cleanup of remaining containers (if any)
        local containers=("remnawave-subscription-page" "remnawave" "remnawave-db" "remnawave-redis" "remnanode" "caddy-remnawave" "caddy-selfsteal")
        for container in "${containers[@]}"; do
            if docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
                docker stop "$container" >/dev/null 2>&1 && docker rm "$container" >/dev/null 2>&1 &
                spinner $! "$(t spinner_force_removing) $container"
            fi
        done

        # Remove directories
        if [ -d "$REMNAWAVE_DIR" ]; then
            rm -rf "$REMNAWAVE_DIR" >/dev/null 2>&1 &
            spinner $! "$(t spinner_removing_directory) $REMNAWAVE_DIR"
        fi
        if [ -d "$REMNANODE_DIR" ]; then
            rm -rf "$REMNANODE_DIR" >/dev/null 2>&1 &
            spinner $! "$(t spinner_removing_directory) $REMNANODE_DIR"
        fi

        # Show result
        if [ "$from_menu" = true ]; then
            show_success "$(t removal_complete_success)"
            read
        else
            show_success "$(t removal_previous_success)"
        fi
    else
        if [ "$from_menu" = true ]; then
            echo
            show_info "$(t removal_no_installation)"
            echo -e "${BOLD_GREEN}$(t prompt_press_any_key)${NC}"
            read
        fi
    fi
}

# Restart panel container and service
restart_panel() {
    local no_wait=${1:-false} # Optional parameter to skip waiting for user input
    echo ''
    # Check for panel directory
    if [ ! -d /opt/remnawave ]; then
        show_error "$(t restart_panel_dir_not_found)"
        show_error "$(t restart_install_panel_first)"
    else
        # Check for docker-compose.yml in panel directory
        if [ ! -f /opt/remnawave/docker-compose.yml ]; then
            show_error "$(t restart_compose_not_found)"
            show_error "$(t restart_installation_corrupted)"
        else
            # Variable to track subscription page directory existence
            local sub_page_dir=$(get_subscription_page_dir)
            SUBSCRIPTION_PAGE_EXISTS=false

            # Check for subscription page directory
            if [ -f "$sub_page_dir/docker-compose.yml" ]; then
                SUBSCRIPTION_PAGE_EXISTS=true
            fi

            # Stop subscription page if it exists
            if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ]; then
                cd "$sub_page_dir" && docker compose down >/dev/null 2>&1 &
                spinner $! "$(t spinner_stopping_subscription)"
            fi

            # Stop panel
            cd /opt/remnawave && docker compose down >/dev/null 2>&1 &
            spinner $! "$(t spinner_restarting_panel)"

            # Start panel with error handling
            show_info "$(t restart_starting_panel)" "$ORANGE"
            if ! start_container "/opt/remnawave" "Remnawave Panel"; then
                return 1
            fi

            # Start subscription page if it exists
            if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ]; then
                show_info "$(t restart_starting_subscription)" "$ORANGE"
                if ! start_container "$sub_page_dir" "Subscription Page"; then
                    return 1
                fi
            fi

            show_success "$(t restart_success)"
        fi
    fi
    if [ "$no_wait" != "true" ]; then
        echo -e "${BOLD_GREEN}$(t prompt_enter_to_continue)${NC}"
        read
    fi
}

start_container() {
    local compose_dir="$1" display_name="$2"
    local max_wait=20 poll=1 tmp_log compose_file
    tmp_log=$(mktemp /tmp/docker-stack-XXXX.log)

    if [[ -z "$compose_dir" || -z "$display_name" ]]; then
        printf "${BOLD_RED}$(t container_error_provide_args)${NC}\n" >&2
        return 2
    fi
    if [[ ! -d "$compose_dir" ]]; then
        printf "${BOLD_RED}$(t container_error_directory_not_found)${NC}\n" "$compose_dir" >&2
        return 2
    fi
    if [[ -f "$compose_dir/docker-compose.yml" ]]; then
        compose_file="$compose_dir/docker-compose.yml"
    elif [[ -f "$compose_dir/docker-compose.yaml" ]]; then
        compose_file="$compose_dir/docker-compose.yaml"
    else
        printf "${BOLD_RED}$(t container_error_compose_not_found)${NC}\n" "$compose_dir" >&2
        return 2
    fi
    if ! command -v docker >/dev/null 2>&1; then
        printf "${BOLD_RED}$(t container_error_docker_not_installed)${NC}\n" >&2
        return 2
    fi
    if ! docker info >/dev/null 2>&1; then
        printf "${BOLD_RED}$(t container_error_docker_not_running)${NC}\n" >&2
        return 2
    fi

    (docker compose -f "$compose_file" up -d --force-recreate --remove-orphans) \
        >"$tmp_log" 2>&1 &
    spinner $! "$(t spinner_launching) $display_name"
    wait $!

    local output
    output=$(<"$tmp_log")

    if echo "$output" | grep -qiE 'toomanyrequests.*rate limit'; then
        printf "${BOLD_RED}$(t container_rate_limit_error)${NC}\n" "$display_name" >&2
        printf "${BOLD_YELLOW}$(t container_rate_limit_cause)${NC}\n" >&2
        echo -e "${ORANGE}$(t container_rate_limit_solutions)${NC}" >&2
        echo -e "${GREEN}$(t container_rate_limit_wait)${NC}" >&2
        echo -e "${GREEN}$(t container_rate_limit_login)${NC}" >&2
        echo -e "${GREEN}$(t container_rate_limit_vpn)${NC}" >&2
        echo -e "${GREEN}$(t container_rate_limit_mirror)${NC}\n" >&2
        rm -f "$tmp_log"
        return 1
    fi

    mapfile -t services < <(docker compose -f "$compose_file" config --services)

    # A crashing container is briefly "running" after each restart, so require two
    # consecutive good polls; stable=1 at the deadline still gets its confirming poll
    local all_ok=true elapsed=0 stable=0
    while [[ $elapsed -lt $max_wait || $stable -eq 1 ]]; do
        all_ok=true
        for svc in "${services[@]}"; do
            cid=$(docker compose -f "$compose_file" ps -q "$svc")
            state=$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null)
            if [[ "$state" != "running" ]]; then
                all_ok=false
                break
            fi
        done
        if $all_ok; then
            stable=$((stable + 1))
            [[ $stable -ge 2 ]] && break
        else
            stable=0
        fi
        sleep $poll
        ((elapsed += poll))
    done

    if $all_ok && [[ $stable -ge 2 ]]; then
        printf "${BOLD_GREEN}$(t container_success_up)${NC}\n" \
            "$display_name" "$(
                IFS=,
                echo "${services[*]}"
            )"
        echo
        rm -f "$tmp_log"
        return 0
    fi

    printf "${BOLD_RED}$(t container_failed_start)${NC}\n" "$display_name" >&2
    printf "${BOLD_RED}$(t container_compose_output)${NC}\n" >&2
    cat "$tmp_log" >&2
    printf "\n${BOLD_RED}$(t container_problematic_services)${NC}\n" >&2
    docker compose -f "$compose_file" ps >&2
    rm -f "$tmp_log"
    return 1
}

create_makefile() {
    local directory="$1"
    cat >"$directory/Makefile" <<'EOF'
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

start_panel() {
    echo
    show_info "$(t services_starting_containers)" "$BOLD_GREEN"

    if ! start_container "$REMNAWAVE_DIR" "Remnawave/backend"; then
        show_info "$(t services_installation_stopped)" "$BOLD_RED"
        exit 1
    fi
}

# Start subscription page after API token is created
start_subscription_page() {
    if ! start_container "$SUBSCRIPTION_PAGE_DIR" "Subscription page"; then
        show_info "$(t services_installation_stopped)" "$BOLD_RED"
        exit 1
    fi
}
