#!/bin/bash

# ===================================================================================
#                              UPDATE FUNCTIONS
# ===================================================================================

# Check if Docker images were actually updated
check_images_updated() {
    local compose_dir="$1"
    local result_var="$2"

    cd "$compose_dir"

    # Get list of images from compose file
    local images_list=$(docker compose config --images 2>/dev/null)
    if [ -z "$images_list" ]; then
        eval "$result_var=error"
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
        eval "$result_var=updated"
    else
        eval "$result_var=no_updates"
    fi
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

    # Check if node exists on same server to determine warning type
    NODE_EXISTS=false
    if [ -d /opt/remnanode ] && [ -f /opt/remnanode/docker-compose.yml ]; then
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

    # Check for updates and track what needs restart
    local panel_updated=false
    local subscription_updated=false
    local node_updated=false
    local any_updates=false

    # Check for updates and track what needs restart
    local panel_updated=false
    local subscription_updated=false
    local node_updated=false
    local any_updates=false

    # Check panel updates
    show_info "$(t update_checking_images)" "$ORANGE"
    local panel_result=""
    check_images_updated "/opt/remnawave" panel_result &
    local check_pid=$!
    spinner $check_pid "$(t update_checking_images)"
    wait $check_pid

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
        local subscription_result=""
        check_images_updated "$sub_page_dir" subscription_result &
        local check_pid=$!
        spinner $check_pid "$(t update_checking_images)"
        wait $check_pid

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
        local node_result=""
        check_images_updated "/opt/remnanode" node_result &
        local check_pid=$!
        spinner $check_pid "$(t update_checking_images)"
        wait $check_pid

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
        spinner $! "$(t update_starting_services)"
        if [ $? -ne 0 ]; then
            show_error "Failed to recreate panel services"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    # Recreate subscription page if it was updated
    if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ] && [ "$subscription_updated" = true ]; then
        cd "$sub_page_dir" && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
        spinner $! "$(t update_starting_services)"
        if [ $? -ne 0 ]; then
            show_error "Failed to recreate subscription page services"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    # Recreate node if it was updated
    if [ "$NODE_EXISTS" = true ] && [ "$node_updated" = true ]; then
        cd /opt/remnanode && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
        spinner $! "$(t update_starting_services)"
        if [ $? -ne 0 ]; then
            show_error "Failed to recreate node services"
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

    # Check if node directory exists
    if [ ! -d /opt/remnanode ]; then
        show_error "$(t update_node_dir_not_found)"
        show_error "$(t update_install_first)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    # Check for docker-compose.yml in node directory
    if [ ! -f /opt/remnanode/docker-compose.yml ]; then
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
    local node_result=""
    check_images_updated "/opt/remnanode" node_result &
    local check_pid=$!
    spinner $check_pid "$(t update_checking_images)"
    wait $check_pid

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
    cd /opt/remnanode && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
    spinner $! "$(t update_starting_services)"
    if [ $? -ne 0 ]; then
        show_error "Failed to recreate node services"
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
