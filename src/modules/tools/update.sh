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
    local images_list containers
    if ! images_list=$(docker compose config --images 2>/dev/null) || [ -z "$images_list" ]; then
        echo "error"
        return
    fi
    if ! containers=$(docker compose ps -aq 2>/dev/null); then
        echo "error"
        return
    fi

    local updates_found=false

    # Check each image individually
    local image before after container running_image running_id
    while IFS= read -r image; do
        if [ -n "$image" ]; then
            before=$(docker image inspect -f '{{.Id}}' "$image" 2>/dev/null) || before=""
            if ! docker pull "$image" >/dev/null 2>&1; then
                echo "error"
                return
            fi
            if ! after=$(docker image inspect -f '{{.Id}}' "$image" 2>/dev/null); then
                echo "error"
                return
            fi
            if [ "$before" != "$after" ]; then
                updates_found=true
            fi
            # An earlier pull may have left containers using the old image.
            # Check every service, including the database and cache.
            while IFS= read -r container; do
                [ -n "$container" ] || continue
                running_image=$(docker inspect -f '{{.Config.Image}}' "$container" 2>/dev/null) || continue
                running_id=$(docker inspect -f '{{.Image}}' "$container" 2>/dev/null) || continue
                if [ "$running_image" = "$image" ] && [ "$running_id" != "$after" ]; then
                    updates_found=true
                fi
            done <<< "$containers"
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
    local i state restarts baseline

    baseline=$(docker inspect -f '{{.RestartCount}}' "$container" 2>/dev/null) || return 1

    for ((i = 0; i < checks; i++)); do
        state=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)
        if [ "$state" != "running" ]; then
            return 1
        fi
        # A grown RestartCount means a crash between polls
        restarts=$(docker inspect -f '{{.RestartCount}}' "$container" 2>/dev/null)
        if [ "$restarts" != "$baseline" ]; then
            return 1
        fi
        sleep 1
    done

    return 0
}

# Panel 3.0.0 renamed JWT_AUTH_SECRET to APP_SECRET and bumped the image major tag.
# Covers installs pinned to :2 and to the pre-2.1.0 :latest default (now resolves to 3.x).
migrate_panel_to_v3() {
    local panel_dir="$1"
    local compose_file="$panel_dir/docker-compose.yml"
    local env_file="$panel_dir/.env"

    # APP_SECRET identifies a 3.x install using :latest.
    # Offering to stay on 2.x here would downgrade its database.
    if grep -qE 'image:[[:space:]]*remnawave/backend:latest[[:space:]]*$' "$compose_file" &&
        grep -q '^APP_SECRET=' "$env_file" 2>/dev/null; then
        sed -i -E "s#^([[:space:]]*image:[[:space:]]*)remnawave/backend:latest[[:space:]]*\$#\1remnawave/backend:${PINNED_BACKEND_TAG}#" "$compose_file"
        return 0
    fi

    # Keep 2.x when the user selects it explicitly.
    if [[ "$REMNAWAVE_BRANCH" =~ ^2\. ]]; then
        sed -i -E 's#^([[:space:]]*image:[[:space:]]*)remnawave/backend:latest[[:space:]]*$#\1remnawave/backend:2#' "$compose_file"
        return 0
    fi

    if ! grep -qE '^[[:space:]]*image:[[:space:]]*remnawave/backend:(2([.][0-9]+)*|latest)[[:space:]]*$' "$compose_file"; then
        return 0
    fi

    echo
    echo -e "${YELLOW}$(t update_major_v3_title)${NC}"
    echo -e "${YELLOW}$(t update_major_v3_details)${NC}"
    echo -e "${BLUE}$(t update_warning_panel_releases)${NC}"
    echo

    if ! prompt_yes_no "$(t update_major_v3_confirm)" "$YELLOW"; then
        # :latest would still pull 3.x — pin declined installs to the 2.x major
        sed -i -E 's#^([[:space:]]*image:[[:space:]]*)remnawave/backend:latest[[:space:]]*$#\1remnawave/backend:2#' "$compose_file"
        show_info "$(t update_major_v3_skipped)"
        return 0
    fi

    local stamp=$(date +%Y%m%d-%H%M%S)
    local env_backup=""
    cp "$compose_file" "$compose_file.bak-$stamp"

    if [ -f "$env_file" ]; then
        cp "$env_file" "$env_file.bak-$stamp"
        env_backup="$env_file.bak-$stamp"

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

    sed -i -E 's#^([[:space:]]*image:[[:space:]]*)remnawave/backend:(2([.][0-9]+)*|latest)[[:space:]]*$#\1remnawave/backend:3#' "$compose_file"

    show_success "$(t update_major_v3_done) ${env_backup:-$compose_file.bak-$stamp}"
    return 0
}

# Compare the container's image reference with its compose file.
container_image_outdated() {
    local compose_file="$1"
    local image_prefix="$2"
    local container="$3"

    [ -f "$compose_file" ] || return 1

    local compose_image running_image
    compose_image=$(sed -nE "s#^[[:space:]]*image:[[:space:]]*(${image_prefix}:[^[:space:]]+)[[:space:]]*\$#\1#p" "$compose_file" | head -n1) || compose_image=""
    running_image=$(docker inspect -f '{{.Config.Image}}' "$container" 2>/dev/null) || running_image=""

    [ -n "$compose_image" ] && [ -n "$running_image" ] && [ "$running_image" != "$compose_image" ]
}

# Update the image tag without downgrading numeric versions.
# A nonempty $4 allows replacing :latest. $5 allows upgrading from that major
# version once the panel migration is accepted.
sync_pinned_image() {
    local compose_file="$1"
    local image_prefix="$2"
    local target_tag="$3"
    local latest_alias_major="$4"
    local previous_major="${5:-}"

    [ -f "$compose_file" ] || return 0

    # Keep dev/alpha on their rolling tags.
    case "$REMNAWAVE_BRANCH" in
    dev | alpha) return 0 ;;
    esac

    local current
    current=$(sed -nE "s#^[[:space:]]*image:[[:space:]]*${image_prefix}:([^[:space:]]+)[[:space:]]*\$#\1#p" "$compose_file" | head -n1) || return 0
    [ -n "$current" ] || return 0
    [ "$current" != "$target_tag" ] || return 0

    local target_major="${target_tag%%.*}"
    local allowed="^(${target_major}|${target_major}\.[0-9.]+)\$"
    if [ -n "$previous_major" ]; then
        allowed="^(${target_major}|${target_major}\.[0-9.]+|${previous_major}|${previous_major}\.[0-9.]+)\$"
    fi
    if [ "$current" != latest ] || [ -z "$latest_alias_major" ]; then
        [[ "$current" =~ $allowed ]] || return 0
        # Keep newer versions installed manually.
        if [ "$(printf '%s\n' "$current" "$target_tag" | sort -V | tail -n1)" = "$current" ]; then
            return 0
        fi
    fi

    sed -i -E "s#^([[:space:]]*image:[[:space:]]*)${image_prefix}:[^[:space:]]+[[:space:]]*\$#\1${image_prefix}:${target_tag}#" "$compose_file"
}

# Match node and subscription-page versions to the panel's compose file.
sync_panel_companion_images() {
    local panel_file="$1" sub_file="$2" node_file="$3"
    local node_tag sub_tag previous_node="" previous_sub=""

    if grep -qE 'image:[[:space:]]*remnawave/backend:2([.][0-9]+)*[[:space:]]*$' "$panel_file"; then
        node_tag="$LEGACY_NODE_TAG"
        sub_tag="$LEGACY_SUBPAGE_TAG"
    elif grep -qE 'image:[[:space:]]*remnawave/backend:3([.][0-9]+)*[[:space:]]*$' "$panel_file"; then
        node_tag="$PINNED_NODE_TAG"
        sub_tag="$PINNED_SUBPAGE_TAG"
        previous_node=2
        previous_sub=7
    else
        return 0
    fi

    sync_pinned_image "$sub_file" "remnawave/subscription-page" "$sub_tag" "8" "$previous_sub"
    sync_pinned_image "$node_file" "remnawave/node" "$node_tag" "3" "$previous_node"
}

# Ask for the remote panel's version before upgrading a separate node.
sync_standalone_node_image() {
    local compose_file="$1"
    local target_tag="$REMNAWAVE_NODE_TAG" previous_major=""

    if [[ "$target_tag" == 3.* ]] &&
        grep -qE 'image:[[:space:]]*remnawave/node:(2([.][0-9]+)*|latest)[[:space:]]*$' "$compose_file"; then
        if prompt_yes_no "$(t update_node_v3_confirm)" "$YELLOW"; then
            previous_major=2
        else
            target_tag="$LEGACY_NODE_TAG"
        fi
    fi

    sync_pinned_image "$compose_file" "remnawave/node" "$target_tag" "3" "$previous_major"
}

# Xray-core >= v26.7.11 defaults minClientVer to 26.3.27.
# Clients reporting 1.8.2, including mihomo/sing-box, go to the REALITY fallback
# without an error in the node logs.
fix_reality_min_client_ver() {
    local panel_url="127.0.0.1:3000"
    local panel_dir="${REMNAWAVE_DIR:-/opt/remnawave}"
    local PANEL_USERNAME PANEL_PASSWORD PANEL_DOMAIN PANEL_TOKEN

    [ -d "$panel_dir" ] || return 0
    docker ps --format '{{.Names}}' | grep -q '^remnawave$' || return 0
    [ -f "$panel_dir/credentials.txt" ] || return 0

    # Skip profile repair if panel login fails.
    extract_panel_credentials_docker >/dev/null 2>&1 || return 0
    authenticate_panel_docker >/dev/null 2>&1 || return 0

    local temp_file=$(mktemp)
    make_api_request "GET" "http://$panel_url/api/config-profiles" "$PANEL_TOKEN" "$PANEL_DOMAIN" "" >"$temp_file" 2>&1 &
    spinner $! "$(t update_reality_fix_checking)"
    local profiles_response=$(cat "$temp_file")
    rm -f "$temp_file"

    [ -n "$profiles_response" ] || return 0

    local affected
    affected=$(echo "$profiles_response" | jq -c '
        [ .response.configProfiles[]?
          | select(.config | type == "object")
          | select([ .config.inbounds[]?
                     | select(type == "object")
                     | select(.streamSettings.security == "reality")
                     | select((.streamSettings.realitySettings.minClientVer // "") == "") ] | length > 0)
          | {uuid, name} ]' 2>/dev/null) || return 0

    local total
    total=$(echo "$affected" | jq 'length' 2>/dev/null) || return 0
    [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null || return 0

    echo
    echo -e "${YELLOW}$(t update_reality_fix_title)${NC}"
    echo -e "${YELLOW}$(t update_reality_fix_details)${NC}"
    echo -e "${BLUE}$(t update_reality_fix_profiles): $(echo "$affected" | jq -r 'map(.name) | join(", ")')${NC}"
    echo

    if ! prompt_yes_no "$(t update_reality_fix_confirm)" "$YELLOW"; then
        show_info "$(t update_reality_fix_skipped)"
        return 0
    fi

    local fixed=0
    local profile profile_uuid profile_name current_config updated_config update_data update_response update_temp

    # Process substitution keeps the counter in this shell
    while IFS= read -r profile; do
        [ -n "$profile" ] || continue
        profile_uuid=$(echo "$profile" | jq -r '.uuid')
        profile_name=$(echo "$profile" | jq -r '.name // .uuid')

        # Re-read the profile to keep edits made during the confirmation prompt.
        current_config=$(make_api_request "GET" "http://$panel_url/api/config-profiles/$profile_uuid" "$PANEL_TOKEN" "$PANEL_DOMAIN" "" |
            jq -ce '.response.config | select(type == "object")') || {
            show_warning "$(t update_reality_fix_failed): $profile_name"
            continue
        }
        [ -n "$current_config" ] && [ "$current_config" != "null" ] || continue

        # An empty string uses Xray's default minimum. Keep explicit versions.
        updated_config=$(echo "$current_config" | jq -c '
            (.inbounds[]?
             | select(type == "object")
             | select(.streamSettings.security == "reality")
             | select((.streamSettings.realitySettings.minClientVer // "") == "")
             | .streamSettings.realitySettings.minClientVer) = "0.0.0"') || {
            show_warning "$(t update_reality_fix_failed): $profile_name"
            continue
        }

        update_data=$(jq -n --arg uuid "$profile_uuid" --argjson config "$updated_config" '{uuid: $uuid, config: $config}')

        update_temp=$(mktemp)
        make_api_request "PATCH" "http://$panel_url/api/config-profiles" "$PANEL_TOKEN" "$PANEL_DOMAIN" "$update_data" >"$update_temp" 2>&1 &
        spinner $! "$(t update_reality_fix_updating) ($profile_name)"
        update_response=$(cat "$update_temp")
        rm -f "$update_temp"

        if echo "$update_response" | jq -e '.response.uuid' >/dev/null 2>&1; then
            fixed=$((fixed + 1))
        else
            show_warning "$(t update_reality_fix_failed): $profile_name"
        fi
    done < <(echo "$affected" | jq -c '.[]')

    if [ "$fixed" -gt 0 ]; then
        show_success "$(t update_reality_fix_done): $fixed"
    fi

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

    # Offer profile repair even when there are no image updates.
    fix_reality_min_client_ver

    # Update compose tags to the versions listed in the installer.
    sync_pinned_image "/opt/remnawave/docker-compose.yml" "remnawave/backend" "$REMNAWAVE_BACKEND_TAG" ""
    sync_panel_companion_images "/opt/remnawave/docker-compose.yml" \
        "$sub_page_dir/docker-compose.yml" "$node_dir/docker-compose.yml"

    # Check for updates and track what needs restart
    local panel_updated=false
    local subscription_updated=false
    local node_updated=false
    local any_updates=false

    # Changed tags need a recreate even if the image is already downloaded.
    # This also handles an interrupted migration.
    if container_image_outdated "/opt/remnawave/docker-compose.yml" "remnawave/backend" "remnawave"; then
        panel_updated=true
        any_updates=true
    fi
    if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ] &&
        container_image_outdated "$sub_page_dir/docker-compose.yml" "remnawave/subscription-page" "remnawave-subscription-page"; then
        subscription_updated=true
        any_updates=true
    fi
    if [ "$NODE_EXISTS" = true ] &&
        container_image_outdated "$node_dir/docker-compose.yml" "remnawave/node" "remnanode"; then
        node_updated=true
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

        # A broken .env makes the panel exit right after start; the first 3.x boot
        # also runs DB migrations, hence the long window
        show_info "$(t update_verifying_panel)" "$ORANGE"
        if ! verify_container_running "remnawave" 15; then
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

    # Select the node version before pulling its image.
    sync_standalone_node_image "$node_dir/docker-compose.yml"

    # Check for updates
    show_info "$(t update_checking_images)" "$ORANGE"
    local result_file=$(mktemp)
    check_images_updated "$node_dir" >"$result_file" &
    local check_pid=$!
    spinner $check_pid "$(t update_checking_images)"
    wait $check_pid
    local node_result=$(<"$result_file")
    rm -f "$result_file"

    # A changed tag still needs a recreate when its image is already downloaded.
    if [ "$node_result" != "error" ] && container_image_outdated "$node_dir/docker-compose.yml" "remnawave/node" "remnanode"; then
        node_result="updated"
    fi

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
