#!/bin/bash

# ===================================================================================
#                              REMNAWAVE PANEL INSTALLATION
# ===================================================================================

# Generate secrets for panel installation
generate_secrets_panel_only() {
    local auth_type=$1

    generate_secrets
    if [ "$auth_type" = "full" ]; then
        generate_full_auth_secrets
    else
        if [ "$auth_type" = "cookie" ]; then
            generate_cookie_auth_secrets
        fi
    fi
}

collect_selfsteal_domain_for_panel() {
    while true; do
        # 3 - true show_warning
        # 4 - false allow_cf_proxy
        # 5 - true expect_different_ip
        SELF_STEAL_DOMAIN=$(prompt_domain "$(t domain_selfsteal_prompt)" "$ORANGE" true false true)

        # Check that selfsteal domain is different from panel and subscription domains
        if check_domain_uniqueness "$SELF_STEAL_DOMAIN" "selfsteal" "$PANEL_DOMAIN" "$SUB_DOMAIN"; then
            break
        fi
        show_warning "$(t warning_enter_different_domain) selfsteal."
        echo
    done
}

# Collect configuration for panel installation
collect_config_panel_only() {
    local auth_type=$1

    collect_telegram_config
    collect_domain_config
    collect_selfsteal_domain_for_panel

    # Use separate installation port collection
    if ! collect_ports_separate_installation; then
        return 1
    fi

    if [ "$auth_type" = "full" ]; then
        collect_full_auth_config
    fi
}

# Setup Caddy for panel installation
setup_caddy_panel_only() {
    local auth_type=$1

    if [ "$auth_type" = "cookie" ]; then
        setup_caddy_for_panel "$PANEL_SECRET_KEY"
    else
        if [ "$auth_type" = "full" ]; then
            setup_caddy_panel_only_full_auth
        fi
    fi
}

# Start Caddy for panel installation
start_caddy_panel_only() {
    local auth_type=$1

    if [ "$auth_type" = "cookie" ]; then
        start_caddy_cookie_auth
    else
        if [ "$auth_type" = "full" ]; then
            start_caddy_full_auth
        fi
    fi
}

# Save credentials and display results for panel installation
save_and_display_panel_only() {
    local auth_type=$1

    if [ "$auth_type" = "cookie" ]; then
        save_credentials_cookie_auth
        display_cookie_auth_results "panel"
    else
        if [ "$auth_type" = "full" ]; then
            save_credentials_full_auth
            display_full_auth_results "panel"
        fi
    fi
}

# Main panel installation function using composition
install_panel_only() {
    local auth_type=$1

    # Validate auth type
    if [[ "$auth_type" != "cookie" && "$auth_type" != "full" ]]; then
        show_error "$(t panel_invalid_auth_type): $auth_type. $(t panel_auth_type_options)"
        return 1
    fi

    # Preparation
    if ! prepare_installation; then
        return 1
    fi

    # Generate secrets
    generate_secrets_panel_only $auth_type

    # Collect configuration
    if ! collect_config_panel_only $auth_type; then
        return 1
    fi

    setup_panel_docker_compose

    if ! setup_panel_environment; then
        return 1
    fi

    create_makefile "$REMNAWAVE_DIR"

    # Setup Caddy
    setup_caddy_panel_only $auth_type

    start_panel
    start_caddy_panel_only $auth_type

    # Register user and configure VLESS
    register_panel_user
    configure_vless_panel_only

    # Create API token and setup subscription page
    SUBSCRIPTION_API_TOKEN=$(create_api_token "127.0.0.1:3000" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -z "$SUBSCRIPTION_API_TOKEN" ]; then
        show_error "$(t api_failed_create_token)"
        exit 1
    fi
    setup_remnawave-subscription-page "$SUBSCRIPTION_API_TOKEN"
    start_subscription_page

    # Save credentials and display results
    save_and_display_panel_only $auth_type
}
