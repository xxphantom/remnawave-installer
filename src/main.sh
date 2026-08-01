#!/bin/bash

# Root privileges check
if [ "$(id -u)" -ne 0 ]; then
    echo "$(t error_root_required)"
    exit 1
fi

clear

# ===================================================================================
# This file is intended ONLY for building the final script.
# To run, use ONLY the built script dist/install_remnawave.sh
# ===================================================================================

# Check if all-in-one installation (panel + local node)
is_all_in_one_installation() {
    [ -d "$REMNAWAVE_DIR" ] && [ -d "$LOCAL_REMNANODE_DIR" ]
}

# Build main menu items array
# Sets MENU_ITEMS array and MENU_ACTIONS associative array
build_main_menu() {
    MENU_ITEMS=()
    declare -gA MENU_ACTIONS

    local n=1

    MENU_ITEMS+=("$n:$(t main_menu_install_components)")
    MENU_ACTIONS[$n]="install"
    ((n++))

    MENU_ITEMS+=("separator")

    MENU_ITEMS+=("$n:$(t main_menu_update_components)")
    MENU_ACTIONS[$n]="update"
    ((n++))

    MENU_ITEMS+=("$n:$(t main_menu_restart_panel)")
    MENU_ACTIONS[$n]="restart"
    ((n++))

    MENU_ITEMS+=("$n:$(t main_menu_remove_panel)")
    MENU_ACTIONS[$n]="remove"
    ((n++))

    MENU_ITEMS+=("$n:$(t main_menu_rescue_cli)")
    MENU_ACTIONS[$n]="cli"
    ((n++))

    MENU_ITEMS+=("$n:$(t main_menu_show_credentials)")
    MENU_ACTIONS[$n]="credentials"
    ((n++))

    MENU_ITEMS+=("$n:$(t main_menu_view_logs)")
    MENU_ACTIONS[$n]="logs"
    ((n++))

    # Show emergency panel access only for all-in-one installation
    if is_all_in_one_installation; then
        MENU_ITEMS+=("$n:$(t main_menu_panel_access)")
        MENU_ACTIONS[$n]="panel_access"
        ((n++))
    fi

    MENU_ITEMS+=("separator")

    MENU_ITEMS+=("$n:$(get_bbr_menu_text)")
    MENU_ACTIONS[$n]="bbr"
    ((n++))

    MENU_ITEMS+=("$n:$(t main_menu_warp_integration)")
    MENU_ACTIONS[$n]="warp"
    ((n++))
}

# Show main menu
show_main_menu() {
    build_main_menu

    clear
    echo -e "${BOLD_GREEN}$(t main_menu_title)${VERSION}${NC}"
    echo -e "${GREEN}$(t main_menu_script_branch)${NC} ${BLUE}$INSTALLER_BRANCH${NC} | ${GREEN}$(t main_menu_panel_branch)${NC} ${BLUE}$REMNAWAVE_BRANCH${NC}"
    echo

    for item in "${MENU_ITEMS[@]}"; do
        if [ "$item" = "separator" ]; then
            echo
        else
            local num="${item%%:*}"
            local text="${item#*:}"
            echo -e "${GREEN}${num}.${NC} ${text}"
        fi
    done

    echo
    echo -e "${GREEN}0.${NC} $(t main_menu_exit)"
    echo
    echo -ne "${BOLD_BLUE_MENU}$(t main_menu_select_option) ${NC}"
}

# Show installation submenu
show_installation_menu() {
    clear
    echo -e "${BOLD_GREEN}$(t install_menu_title)${NC}"
    echo
    echo -e "${YELLOW}$(t install_menu_panel_only)${NC}"
    echo -e "${GREEN}1.${NC} $(t install_menu_panel_full_security)"
    echo -e "${GREEN}2.${NC} $(t install_menu_panel_simple_security)"
    echo
    echo -e "${YELLOW}$(t install_menu_node_only)${NC}"
    echo -e "${GREEN}3.${NC} $(t install_menu_node_separate)"
    echo
    echo -e "${YELLOW}$(t install_menu_all_in_one)${NC}"
    echo -e "${GREEN}4.${NC} $(t install_menu_panel_node_full)"
    echo -e "${GREEN}5.${NC} $(t install_menu_panel_node_simple)"
    echo
    echo -e "${GREEN}0.${NC} $(t install_menu_back)"
    echo
    echo -ne "${BOLD_BLUE_MENU}$(t main_menu_select_option) ${NC}"
}

# Handle installation menu
handle_installation_menu() {
    while true; do
        show_installation_menu
        read choice

        case $choice in
        1)
            install_panel_only "full"
            ;;
        2)
            install_panel_only "cookie"
            ;;
        3)
            setup_node
            ;;
        4)
            install_remnawave_all_in_one "full"
            ;;
        5)
            install_remnawave_all_in_one "cookie"
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

main() {
    while true; do
        show_main_menu
        read -r choice

        if [ "$choice" = "0" ]; then
            echo "$(t exiting)"
            break
        fi

        if [[ -z "$choice" || ! "$choice" =~ ^[0-9]+$ ]]; then
            clear
            echo -e "${BOLD_RED}$(t error_invalid_choice)${NC}"
            sleep 1
            continue
        fi

        local action="${MENU_ACTIONS[$choice]:-}"

        case "$action" in
        install)
            handle_installation_menu
            ;;
        update)
            handle_update_menu
            ;;
        restart)
            restart_panel
            ;;
        remove)
            remove_previous_installation true
            ;;
        cli)
            run_remnawave_cli
            ;;
        credentials)
            show_panel_credentials
            ;;
        logs)
            view_logs
            ;;
        panel_access)
            manage_panel_access
            ;;
        bbr)
            toggle_bbr
            ;;
        warp)
            add_warp_docker_integration
            ;;
        *)
            clear
            echo -e "${BOLD_RED}$(t error_invalid_choice)${NC}"
            sleep 1
            ;;
        esac
    done
}

# Run main function
main
