#!/bin/bash

# ===================================================================================
#                          EMERGENCY PANEL ACCESS (PORT 8443)
# ===================================================================================

# Check if panel is installed
check_panel_for_access() {
    if [ ! -d "$REMNAWAVE_DIR" ]; then
        show_error "$(t panel_access_dir_not_found)"
        return 1
    fi
    return 0
}

# Check if UFW is available and active
is_ufw_active() {
    if ! command -v ufw >/dev/null 2>&1; then
        return 1
    fi
    if ! ufw status | grep -q "Status: active"; then
        return 1
    fi
    return 0
}

# Open port 8443 in firewall
open_firewall_port() {
    if is_ufw_active; then
        ufw allow 8443/tcp >/dev/null 2>&1
        ufw reload >/dev/null 2>&1
    fi
}

# Close port 8443 in firewall
close_firewall_port() {
    if is_ufw_active; then
        if ufw status | grep -q "8443.*ALLOW"; then
            ufw delete allow 8443/tcp >/dev/null 2>&1
            ufw reload >/dev/null 2>&1
            return 0
        fi
    fi
    return 1
}

# Check if port 8443 is open in firewall
is_firewall_port_open() {
    if is_ufw_active; then
        ufw status | grep -q "8443.*ALLOW"
        return $?
    fi
    # If UFW is not active, consider port as open (no firewall blocking)
    return 0
}

# Get authentication type (cookie or full)
get_auth_type() {
    local caddyfile=""

    # Check all-in-one installation first
    if [ -f "$REMNAWAVE_DIR/Caddyfile" ]; then
        caddyfile="$REMNAWAVE_DIR/Caddyfile"
    elif [ -f "$REMNAWAVE_DIR/caddy/Caddyfile" ]; then
        caddyfile="$REMNAWAVE_DIR/caddy/Caddyfile"
    else
        echo "unknown"
        return 1
    fi

    if grep -q "PANEL_SECRET_KEY" "$caddyfile"; then
        echo "cookie"
    elif grep -q "remnawaveportal" "$caddyfile"; then
        echo "full"
    else
        echo "unknown"
    fi
}

# Get Caddyfile path
get_caddyfile_path() {
    if [ -f "$REMNAWAVE_DIR/Caddyfile" ]; then
        echo "$REMNAWAVE_DIR/Caddyfile"
    elif [ -f "$REMNAWAVE_DIR/caddy/Caddyfile" ]; then
        echo "$REMNAWAVE_DIR/caddy/Caddyfile"
    else
        echo ""
    fi
}

# Get docker-compose directory for Caddy
get_caddy_compose_dir() {
    if [ -f "$REMNAWAVE_DIR/docker-compose.caddy.yml" ]; then
        echo "$REMNAWAVE_DIR"
    elif [ -f "$REMNAWAVE_DIR/caddy/docker-compose.yml" ]; then
        echo "$REMNAWAVE_DIR/caddy"
    else
        echo ""
    fi
}

# Get panel access link with secret key
get_panel_access_link() {
    local auth_type=$(get_auth_type)
    local credentials_file="$REMNAWAVE_DIR/credentials.txt"

    if [ ! -f "$credentials_file" ]; then
        echo ""
        return 1
    fi

    # Extract domain from credentials
    local panel_domain=$(grep "PANEL URL:" "$credentials_file" | sed 's|PANEL URL: https://||' | cut -d'/' -f1 | cut -d'?' -f1)

    if [ "$auth_type" = "cookie" ]; then
        # For cookie-auth extract secret key from credentials URL
        local secret_key=$(grep "PANEL URL:" "$credentials_file" | grep -oP 'caddy=\K[^&\s]+')
        echo "https://${panel_domain}:8443/auth/login?caddy=${secret_key}"
    else
        # For full-auth need custom login route
        local login_route=$(grep "PANEL URL:" "$credentials_file" | sed 's|.*https://[^/]*/||' | cut -d'/' -f1)
        echo "https://${panel_domain}:8443/${login_route}"
    fi
}

# Check if 8443 section exists in Caddyfile
has_8443_section() {
    local caddyfile=$(get_caddyfile_path)
    if [ -z "$caddyfile" ]; then
        return 1
    fi
    grep -q ":8443" "$caddyfile"
}

# Add 8443 section to Caddyfile
add_8443_section() {
    local caddyfile=$(get_caddyfile_path)
    local auth_type=$(get_auth_type)

    if [ -z "$caddyfile" ]; then
        show_error "$(t panel_access_dir_not_found)"
        return 1
    fi

    # Find the line with ":80 {" and insert before it
    local temp_file=$(mktemp)

    if [ "$auth_type" = "cookie" ]; then
        # Insert 8443 section before ":80 {" block
        awk '/:80 \{/ {
            print ""
            print "# Emergency access port (direct, without Xray)"
            print "https://{$PANEL_DOMAIN}:8443 {"
            print "    encode zstd gzip"
            print ""
            print "    @has_token_param {"
            print "        query caddy={$PANEL_SECRET_KEY}"
            print "    }"
            print ""
            print "    handle @has_token_param {"
            print "        header +Set-Cookie \"caddy={$PANEL_SECRET_KEY}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000\""
            print "    }"
            print ""
            print "    @unauthorized {"
            print "        not header Cookie *caddy={$PANEL_SECRET_KEY}*"
            print "        not query caddy={$PANEL_SECRET_KEY}"
            print "    }"
            print ""
            print "    handle @unauthorized {"
            print "        root * /var/www/html"
            print "        try_files {path} /index.html"
            print "        file_server"
            print "    }"
            print ""
            print "    reverse_proxy {$BACKEND_URL} {"
            print "        header_up X-Real-IP {remote}"
            print "        header_up Host {host}"
            print "    }"
            print "}"
            print ""
        } {print}' "$caddyfile" > "$temp_file"
    else
        # Full auth - insert before ":80 {"
        awk '/:80 \{/ {
            print ""
            print "# Emergency access port (direct, without Xray)"
            print "https://{$REMNAWAVE_PANEL_DOMAIN}:8443 {"
            print "    encode zstd gzip"
            print ""
            print "    @login_path {"
            print "        path /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE} /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/ /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/auth"
            print "    }"
            print "    handle @login_path {"
            print "        rewrite * /auth"
            print "        request_header +X-Forwarded-Prefix /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}"
            print "        authenticate with remnawaveportal"
            print "    }"
            print ""
            print "    handle_path /restricted* {"
            print "        abort"
            print "    }"
            print ""
            print "    route /api/* {"
            print "        authorize with panelpolicy"
            print "        reverse_proxy http://127.0.0.1:3000"
            print "    }"
            print ""
            print "    route /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}* {"
            print "        authenticate with remnawaveportal"
            print "    }"
            print ""
            print "    route /* {"
            print "        authorize with panelpolicy"
            print "        reverse_proxy http://127.0.0.1:3000"
            print "    }"
            print ""
            print "    handle_errors {"
            print "        @unauth {"
            print "            expression {http.error.status_code} == 401"
            print "        }"
            print "        handle @unauth {"
            print "            respond * 204"
            print "        }"
            print "    }"
            print "}"
            print ""
        } {print}' "$caddyfile" > "$temp_file"
    fi

    mv "$temp_file" "$caddyfile"
}

# Remove 8443 section from Caddyfile
remove_8443_section() {
    local caddyfile=$(get_caddyfile_path)

    if [ -z "$caddyfile" ]; then
        return 1
    fi

    local temp_file=$(mktemp)

    # Remove the 8443 section including the comment
    awk '
        /^# Emergency access port/ { skip = 1; next }
        /^https:\/\/.*:8443/ { skip = 1; next }
        skip && /^\}$/ { skip = 0; next }
        skip { next }
        { print }
    ' "$caddyfile" > "$temp_file"

    mv "$temp_file" "$caddyfile"
}

# Restart Caddy container
restart_caddy() {
    local compose_dir=$(get_caddy_compose_dir)

    if [ -z "$compose_dir" ]; then
        show_error "$(t panel_access_dir_not_found)"
        return 1
    fi

    cd "$compose_dir"

    # Determine compose file name
    local compose_file="docker-compose.yml"
    if [ -f "docker-compose.caddy.yml" ]; then
        compose_file="docker-compose.caddy.yml"
    fi

    # Restart only caddy service
    if [ "$compose_file" = "docker-compose.caddy.yml" ]; then
        docker compose -f "$compose_file" restart caddy >/dev/null 2>&1 || \
        docker compose -f "$compose_file" restart remnawave-caddy >/dev/null 2>&1
    else
        docker compose restart caddy >/dev/null 2>&1 || \
        docker compose restart remnawave-caddy >/dev/null 2>&1
    fi
}

# Open panel access via port 8443
open_panel_access() {
    if ! check_panel_for_access; then
        return 1
    fi

    # Check if already fully open (section exists and firewall allows)
    if has_8443_section && is_firewall_port_open; then
        show_warning "$(t panel_access_already_open)"
        local access_link=$(get_panel_access_link)
        if [ -n "$access_link" ]; then
            echo
            echo -e "${BOLD_GREEN}$(t panel_access_link)${NC}"
            echo -e "${access_link}"
            echo
        fi
        return 0
    fi

    # Run enabling with spinner
    (
        # Add 8443 section to Caddyfile if not exists
        if ! has_8443_section; then
            add_8443_section
            restart_caddy
            sleep 2
        fi

        # Open port in firewall
        open_firewall_port
    ) &
    spinner $! "$(t panel_access_enabling)"

    local access_link=$(get_panel_access_link)

    echo
    show_success "$(t panel_access_port_opened)"
    echo
    if [ -n "$access_link" ]; then
        echo -e "${BOLD_GREEN}$(t panel_access_link)${NC}"
        echo -e "${access_link}"
        echo
    fi
    show_warning "$(t panel_access_warning)"
    echo
}

# Close panel access via port 8443
close_panel_access() {
    if ! check_panel_for_access; then
        return 1
    fi

    # Check if already closed
    if ! has_8443_section && ! is_firewall_port_open; then
        show_info "$(t panel_access_already_closed)"
        return 0
    fi

    # Run disabling with spinner
    (
        # Remove 8443 section from Caddyfile if exists
        if has_8443_section; then
            remove_8443_section
            restart_caddy
        fi

        # Close port in firewall
        close_firewall_port
    ) &
    spinner $! "$(t panel_access_disabling)"

    echo
    show_success "$(t panel_access_port_closed)"
}

# Show panel access menu
show_panel_access_menu() {
    clear
    echo -e "${BOLD_GREEN}$(t panel_access_menu_title)${NC}"
    echo
    echo -e "${GREEN}1.${NC} $(t panel_access_open)"
    echo -e "${GREEN}2.${NC} $(t panel_access_close)"
    echo
    echo -e "${GREEN}0.${NC} $(t panel_access_back)"
    echo
    echo -ne "${BOLD_BLUE_MENU}$(t main_menu_select_option) ${NC}"
}

# Handle panel access menu
manage_panel_access() {
    # Check if panel is installed first
    if ! check_panel_for_access; then
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return
    fi

    while true; do
        show_panel_access_menu
        read choice

        case $choice in
        1)
            open_panel_access
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            ;;
        2)
            close_panel_access
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            ;;
        0)
            return
            ;;
        *)
            show_error "$(t error_invalid_choice)"
            sleep 1
            ;;
        esac
    done
}
