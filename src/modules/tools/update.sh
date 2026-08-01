#!/bin/bash

# ===================================================================================
#                              UPDATE FUNCTIONS
# ===================================================================================

# Check if Docker images were actually updated
# Prints the result to stdout: "updated", "no_updates" or "error".
# Callers run it in the background, so the result must go through
# stdout (a variable assigned via eval would be lost in the subshell).
check_images_updated() {
    local compose_dir="$1"

    cd "$compose_dir" || {
        echo "error"
        return
    }

    # Get list of images from compose file
    local images_list=$(docker compose config --images 2>/dev/null)
    if [ -z "$images_list" ]; then
        echo "error"
        return
    fi

    local updates_found=false

    # Check each image individually
    while IFS= read -r image; do
        if [ -n "$image" ]; then
            local output=$(docker pull "$image" 2>&1)
            if echo "$output" | grep -q "Downloaded newer image"; then
                updates_found=true
                break
            fi
        fi
    done <<< "$images_list"

    if [ "$updates_found" = true ]; then
        echo "updated"
    else
        echo "no_updates"
    fi
}

# Verify a container stays up: a crash-looping panel briefly shows "running" too
verify_container_running() {
    local container="$1"
    local checks="${2:-5}"
    local i state

    for ((i = 0; i < checks; i++)); do
        state=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)
        if [ "$state" != "running" ]; then
            return 1
        fi
        sleep 1
    done

    return 0
}

# Panel 3.0.0 renamed JWT_AUTH_SECRET to APP_SECRET and bumped the image major tag.
# Installs pinned to :2 would never see 3.x — offer the migration on update.
migrate_panel_to_v3() {
    local panel_dir="$1"
    local compose_file="$panel_dir/docker-compose.yml"
    local env_file="$panel_dir/.env"

    PANEL_V3_MIGRATED=false

    if ! grep -qE '^[[:space:]]*image:[[:space:]]*remnawave/backend:2([.][0-9]+)*[[:space:]]*$' "$compose_file"; then
        return 0
    fi

    echo
    echo -e "${YELLOW}$(t update_major_v3_title)${NC}"
    echo -e "${YELLOW}$(t update_major_v3_details)${NC}"
    echo -e "${BLUE}$(t update_warning_panel_releases)${NC}"
    echo

    if ! prompt_yes_no "$(t update_major_v3_confirm)" "$YELLOW"; then
        show_info "$(t update_major_v3_skipped)"
        return 0
    fi

    local stamp=$(date +%Y%m%d-%H%M%S)
    cp "$compose_file" "$compose_file.bak-$stamp"

    if [ -f "$env_file" ]; then
        cp "$env_file" "$env_file.bak-$stamp"

        # Keep the JWT_AUTH_SECRET value — it signs the admin session and the
        # subscription page API token
        if ! grep -q '^APP_SECRET=' "$env_file"; then
            if grep -q '^JWT_AUTH_SECRET=' "$env_file"; then
                sed -i 's/^JWT_AUTH_SECRET=/APP_SECRET=/' "$env_file"
            else
                echo "APP_SECRET=$(openssl rand -hex 32 | tr -d '\n')" >>"$env_file"
                show_warning "$(t update_major_v3_new_secret)"
            fi
        fi

        # Gone in 3.0.0, dropped only to keep .env tidy
        sed -i '/^JWT_API_TOKENS_SECRET=/d' "$env_file"
    fi

    sed -i -E 's|^([[:space:]]*image:[[:space:]]*)remnawave/backend:2([.][0-9]+)*[[:space:]]*$|\1remnawave/backend:3|' "$compose_file"

    PANEL_V3_MIGRATED=true
    show_success "$(t update_major_v3_done) $env_file.bak-$stamp"
    return 0
}

# Show update warning and get confirmation
show_update_warning() {
    local component_type="$1"  # "panel", "node", or "all"

    echo
    echo -e "${YELLOW}$(t update_warning_title)${NC}"
    echo
    echo -e "${YELLOW}$(t update_warning_backup)${NC}"
    echo -e "${YELLOW}$(t update_warning_changelog)${NC}"

    # Show relevant changelog links based on component type
    if [[ "$component_type" == "panel" || "$component_type" == "all" ]]; then
        echo -e "${BLUE}$(t update_warning_panel_releases)${NC}"
    fi
    if [[ "$component_type" == "node" || "$component_type" == "all" ]]; then
        echo -e "${BLUE}$(t update_warning_node_releases)${NC}"
    fi

    echo -e "${YELLOW}$(t update_warning_downtime)${NC}"
    echo

    # Ask for confirmation
    if ! prompt_yes_no "$(t update_warning_confirm)" "$YELLOW"; then
        show_info "$(t update_cancelled)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    return 0
}

# Update panel only (will also update node if on same server)
update_panel_only() {
    echo

    # Check if panel directory exists
    if [ ! -d /opt/remnawave ]; then
        show_error "$(t update_panel_dir_not_found)"
        show_error "$(t update_install_first)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    # Check for docker-compose.yml in panel directory
    if [ ! -f /opt/remnawave/docker-compose.yml ]; then
        show_error "$(t update_compose_not_found)"
        show_error "$(t update_installation_corrupted)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    # Check if node exists on same server (node-only or all-in-one path)
    local node_dir=$(get_node_dir)
    NODE_EXISTS=false
    if [ -f "$node_dir/docker-compose.yml" ]; then
        NODE_EXISTS=true
    fi

    # Show warning and get confirmation
    if [ "$NODE_EXISTS" = true ]; then
        if ! show_update_warning "all"; then
            return 0
        fi
    else
        if ! show_update_warning "panel"; then
            return 0
        fi
    fi
    
    # Check if subscription page exists (new or legacy path)
    local sub_page_dir=$(get_subscription_page_dir)
    SUBSCRIPTION_PAGE_EXISTS=false
    if [ -f "$sub_page_dir/docker-compose.yml" ]; then
        SUBSCRIPTION_PAGE_EXISTS=true
    fi

    # Offer the 2.x -> 3.x migration before pulling anything
    migrate_panel_to_v3 "/opt/remnawave"

    # Check for updates and track what needs restart
    local panel_updated=false
    local subscription_updated=false
    local node_updated=false
    local any_updates=false

    # The migration rewrote the image tag, so the panel must be recreated even if
    # the new image happens to be present locally already
    if [ "$PANEL_V3_MIGRATED" = true ]; then
        panel_updated=true
        any_updates=true
    fi

    # Check panel updates
    show_info "$(t update_checking_images)" "$ORANGE"
    local result_file=$(mktemp)
    check_images_updated "/opt/remnawave" >"$result_file" &
    local check_pid=$!
    spinner $check_pid "$(t update_checking_images)"
    wait $check_pid
    local panel_result=$(<"$result_file")
    rm -f "$result_file"

    if [ "$panel_result" = "updated" ]; then
        panel_updated=true
        any_updates=true
    elif [ "$panel_result" = "error" ]; then
        show_error "$(t update_pull_failed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    # Check subscription page updates if exists
    if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ]; then
        result_file=$(mktemp)
        check_images_updated "$sub_page_dir" >"$result_file" &
        local check_pid=$!
        spinner $check_pid "$(t update_checking_images)"
        wait $check_pid
        local subscription_result=$(<"$result_file")
        rm -f "$result_file"

        if [ "$subscription_result" = "updated" ]; then
            subscription_updated=true
            any_updates=true
        elif [ "$subscription_result" = "error" ]; then
            show_error "$(t update_pull_failed)"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    # Check node updates if exists on same server
    if [ "$NODE_EXISTS" = true ]; then
        result_file=$(mktemp)
        check_images_updated "$node_dir" >"$result_file" &
        local check_pid=$!
        spinner $check_pid "$(t update_checking_images)"
        wait $check_pid
        local node_result=$(<"$result_file")
        rm -f "$result_file"

        if [ "$node_result" = "updated" ]; then
            node_updated=true
            any_updates=true
        elif [ "$node_result" = "error" ]; then
            show_error "$(t update_pull_failed)"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    # If no updates available, exit early
    if [ "$any_updates" = false ]; then
        show_success "$(t update_no_updates_available)"
        show_info "$(t update_no_restart_needed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    # Show what will be updated
    show_info "$(t update_images_updated)"

    # Recreate updated services with new images
    show_info "$(t update_starting_services)" "$ORANGE"

    # Recreate panel if it was updated
    if [ "$panel_updated" = true ]; then
        cd /opt/remnawave && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
        local recreate_pid=$!
        spinner $recreate_pid "$(t update_starting_services)"
        if ! wait $recreate_pid; then
            show_error "$(t update_recreate_panel_failed)"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi

        # A broken .env makes the panel exit right after start
        if ! verify_container_running "remnawave"; then
            show_error "$(t update_panel_not_running)"
            show_error "$(t update_check_logs)"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    # Recreate subscription page if it was updated
    if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ] && [ "$subscription_updated" = true ]; then
        cd "$sub_page_dir" && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
        local recreate_pid=$!
        spinner $recreate_pid "$(t update_starting_services)"
        if ! wait $recreate_pid; then
            show_error "$(t update_recreate_subscription_failed)"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    # Recreate node if it was updated
    if [ "$NODE_EXISTS" = true ] && [ "$node_updated" = true ]; then
        cd "$node_dir" && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
        local recreate_pid=$!
        spinner $recreate_pid "$(t update_starting_services)"
        if ! wait $recreate_pid; then
            show_error "$(t update_recreate_node_failed)"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi
    
    # Clean unused images
    show_info "$(t update_cleaning_images)" "$ORANGE"
    docker image prune -f >/dev/null 2>&1 &
    spinner $! "$(t update_cleaning_images)"
    
    # Show success message
    if [ "$NODE_EXISTS" = true ]; then
        show_success "$(t update_all_success)"
    else
        show_success "$(t update_panel_success)"
    fi
    
    show_info "$(t update_cleanup_complete)"
    
    echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
    read -r
}

# Update node only (for separate server)
update_node_only() {
    echo

    local node_dir=$(get_node_dir)

    # Check if node directory exists
    if [ ! -d "$node_dir" ]; then
        show_error "$(t update_node_dir_not_found)"
        show_error "$(t update_install_first)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    # Check for docker-compose.yml in node directory
    if [ ! -f "$node_dir/docker-compose.yml" ]; then
        show_error "$(t update_compose_not_found)"
        show_error "$(t update_installation_corrupted)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    # Show warning and get confirmation
    if ! show_update_warning "node"; then
        return 0
    fi

    # Check for updates
    show_info "$(t update_checking_images)" "$ORANGE"
    local result_file=$(mktemp)
    check_images_updated "$node_dir" >"$result_file" &
    local check_pid=$!
    spinner $check_pid "$(t update_checking_images)"
    wait $check_pid
    local node_result=$(<"$result_file")
    rm -f "$result_file"

    if [ "$node_result" = "updated" ]; then
        show_info "$(t update_images_updated)"
    elif [ "$node_result" = "no_updates" ]; then
        show_success "$(t update_no_updates_available)"
        show_info "$(t update_no_restart_needed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    else
        show_error "$(t update_pull_failed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    # Recreate services with new images
    show_info "$(t update_starting_services)" "$ORANGE"
    cd "$node_dir" && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
    local recreate_pid=$!
    spinner $recreate_pid "$(t update_starting_services)"
    if ! wait $recreate_pid; then
        show_error "$(t update_recreate_node_failed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi
    
    # Clean unused images
    show_info "$(t update_cleaning_images)" "$ORANGE"
    docker image prune -f >/dev/null 2>&1 &
    spinner $! "$(t update_cleaning_images)"
    
    show_success "$(t update_node_success)"
    show_info "$(t update_cleanup_complete)"
    
    echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
    read -r
}

# Show update menu
show_update_menu() {
    clear
    echo -e "${BOLD_GREEN}$(t update_menu_title)${NC}"
    echo
    echo -e "${YELLOW}$(t update_menu_panel_only)${NC}"
    echo -e "${GREEN}1.${NC} $(t update_menu_panel_update)"
    echo
    echo -e "${YELLOW}$(t update_menu_node_only)${NC}"
    echo -e "${GREEN}2.${NC} $(t update_menu_node_separate)"
    echo
    echo -e "${GREEN}0.${NC} $(t update_menu_back)"
    echo
    echo -ne "${BOLD_BLUE_MENU}$(t main_menu_select_option) ${NC}"
}

# Handle update menu
handle_update_menu() {
    while true; do
        show_update_menu
        read choice

        case $choice in
        1)
            update_panel_only
            ;;
        2)
            update_node_only
            ;;
        0)
            return
            ;;
        *)
            clear
            echo -e "${BOLD_RED}$(t error_invalid_choice)${NC}"
            sleep 1
            ;;
        esac
    done
}
