#!/bin/bash

# ===================================================================================
#                              REMNAWAVE PANEL INSTALLATION
# ===================================================================================

generate_secrets_all_in_one() {
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

setup_caddy_all_in_one() {
    local auth_type=$1

    # Setup components
    if [ "$auth_type" = "full" ]; then
        setup_caddy_all_in_one_full_auth
    else
        if [ "$auth_type" = "cookie" ]; then
            setup_caddy_all_in_one_cookie_auth
        fi
    fi
}

save_credentials_all_in_one() {
    local auth_type=$1

    if [ "$auth_type" = "full" ]; then
        save_credentials_full_auth
    else
        if [ "$auth_type" = "cookie" ]; then
            save_credentials_cookie_auth
        fi
    fi
}

display_results_all_in_one() {
    local auth_type=$1

    if [ "$auth_type" = "full" ]; then
        display_full_auth_results "all-in-one"
    else
        if [ "$auth_type" = "cookie" ]; then
            display_cookie_auth_results "all-in-one"
        fi
    fi
}

collect_selfsteal_domain_for_all_in_one() {
    while true; do
        # 3 - true show_warning
        # 4 - false allow_cf_proxy
        # 5 - false expect_different_ip
        SELF_STEAL_DOMAIN=$(prompt_domain "$(t domain_selfsteal_prompt)" "$ORANGE" true false false)

        # Check that selfsteal domain is different from panel and subscription domains
        if check_domain_uniqueness "$SELF_STEAL_DOMAIN" "selfsteal" "$PANEL_DOMAIN" "$SUB_DOMAIN"; then
            break
        fi
        show_warning "$(t warning_enter_different_domain) selfsteal."
        echo
    done
}

install_remnawave_all_in_one() {
    local auth_type=$1

    if ! prepare_installation "qrencode"; then
        return 1
    fi

    generate_secrets_all_in_one $auth_type

    collect_telegram_config
    collect_domain_config
    collect_selfsteal_domain_for_all_in_one

    if [ "$auth_type" = "full" ]; then
        collect_full_auth_config
    fi

    collect_ports_all_in_one

    allow_ufw_node_port_from_panel

    setup_panel_docker_compose

    if ! setup_panel_environment; then
        return 1
    fi

    create_makefile "$REMNAWAVE_DIR"

    setup_caddy_all_in_one $auth_type

    start_panel

    start_caddy_all_in_one

    register_panel_user
    configure_vless_all_in_one

    # Create API token and setup subscription page
    SUBSCRIPTION_API_TOKEN=$(create_api_token "127.0.0.1:3000" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -z "$SUBSCRIPTION_API_TOKEN" ]; then
        show_error "$(t api_failed_create_token)"
        exit 1
    fi
    setup_remnawave-subscription-page "$SUBSCRIPTION_API_TOKEN"
    start_subscription_page

    setup_and_start_all_in_one_node

    save_credentials_all_in_one $auth_type

    display_results_all_in_one $auth_type
}
