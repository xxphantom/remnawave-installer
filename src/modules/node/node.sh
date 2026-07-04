# ===================================================================================
#                              REMNAWAVE NODE INSTALLATION (Node-Only)
# ===================================================================================

# Global variable for connection type (socket or port)
XRAY_CONNECTION_TYPE=""

# Select Xray connection type (socket or port)
select_xray_connection_type() {
    echo -e "${BOLD_BLUE}$(t node_xray_connection_type)${NC}"
    echo
    echo -e "  ${BOLD_GREEN}1)${NC} $(t node_xray_connection_socket)"
    echo -e "     ${YELLOW}$(t node_xray_connection_socket_desc)${NC}"
    echo
    echo -e "  ${BOLD_GREEN}2)${NC} $(t node_xray_connection_port)"
    echo -e "     ${YELLOW}$(t node_xray_connection_port_desc)${NC}"
    echo

    while true; do
        read -p "$(echo -e "${ORANGE}$(t main_menu_select_option) ${NC}")" choice
        case $choice in
            1)
                XRAY_CONNECTION_TYPE="socket"
                break
                ;;
            2)
                XRAY_CONNECTION_TYPE="port"
                break
                ;;
            *)
                echo -e "${BOLD_RED}$(t error_invalid_choice)${NC}"
                ;;
        esac
    done
    echo
}

# Create docker-compose for Node
create_node_docker_compose() {
    local certificate="$1"

    mkdir -p "$REMNANODE_DIR"
    cd "$REMNANODE_DIR"

    cat >docker-compose.yml <<EOF
services:
    remnanode:
        container_name: remnanode
        hostname: remnanode
        image: remnawave/node:$REMNAWAVE_NODE_TAG
        network_mode: host
        restart: always
        cap_add:
            - NET_ADMIN
        ulimits:
            nofile:
                soft: 1048576
                hard: 1048576
        environment:
            - NODE_PORT=$NODE_PORT
            - SECRET_KEY=$certificate
        volumes:
            - /dev/shm:/dev/shm
            - /var/log/remnanode:/var/log/remnanode
        logging:
            driver: 'json-file'
            options:
                max-size: '100m'
                max-file: '5'
EOF

    create_makefile "$REMNANODE_DIR"
}

collect_node_selfsteal_domain() {
    SELF_STEAL_DOMAIN=$(prompt_domain "$(t node_enter_selfsteal_domain)" "$ORANGE" true false false)
}

check_node_ports() {
    # Check required Node API port 2222
    if NODE_PORT=$(check_required_port "2222"); then
        show_info "$(t config_node_port_available)"
    else
        show_error "$(t node_port_2222_in_use)"
        show_error "$(t node_separate_port_2222)"
        show_error "$(t node_free_port_2222)"
        show_error "$(t node_cannot_continue_2222)"
        exit 1
    fi
}

# Collect SSL certificate for node
collect_node_ssl_certificate() {
    while true; do
        echo -e "${ORANGE}$(t node_enter_ssl_cert) ${NC}"
        CERTIFICATE=""
        while IFS= read -r line; do
            if [ -z "$line" ]; then
                if [ -n "$CERTIFICATE" ]; then
                    break
                fi
            else
                CERTIFICATE="${CERTIFICATE}${line}"
            fi
        done

        # Validate SSL certificate format
        if validate_ssl_certificate "$CERTIFICATE"; then
            echo -e "${BOLD_GREEN}$(t node_ssl_cert_valid)${NC}"
            echo
            break
        else
            echo -e "${BOLD_RED}$(t node_ssl_cert_invalid)${NC}"
            echo -e "${YELLOW}$(t node_ssl_cert_expected)${NC}"
            echo
        fi
    done
}

collect_panel_ip() {
    while true; do
        PANEL_IP=$(simple_read_domain_or_ip "$(t node_enter_panel_ip)" "" "ip_only")
        if [ -n "$PANEL_IP" ]; then
            break
        fi
    done
}

allow_ufw_node_port_from_panel_ip() {
    echo "$(t node_allow_connections)"
    echo
    ufw allow from "$PANEL_IP" to any port 2222 proto tcp
    echo
    ufw reload >/dev/null 2>&1
}

# Start node container and show results
start_node_and_show_results() {
    # Wait for Caddy socket before starting Node (only for socket mode)
    if [ "$XRAY_CONNECTION_TYPE" = "socket" ]; then
        if ! wait_for_caddy_socket 30; then
            show_error "$(t error_caddy_socket_timeout)"
            exit 1
        fi
    fi

    if ! start_container "$REMNANODE_DIR" "Remnawave Node"; then
        show_error "$(t services_installation_stopped)"
        exit 1
    fi

    echo -e "${LIGHT_GREEN}$(t node_port_info) ${BOLD_GREEN}$NODE_PORT${NC}"
    echo -e "${LIGHT_GREEN}$(t node_directory_info) ${BOLD_GREEN}$REMNANODE_DIR${NC}"
    echo
}

setup_node() {
    clear

    # Preparation for node-only installation
    if ! prepare_node_installation; then
        return 1
    fi

    collect_node_selfsteal_domain

    collect_panel_ip

    allow_ufw_node_port_from_panel_ip

    check_node_ports

    # Select Xray connection type (socket or port)
    select_xray_connection_type

    collect_node_ssl_certificate

    # Create node docker-compose
    create_node_docker_compose "$CERTIFICATE"

    setup_node_log_rotation

    # Setup and start Caddy (in selfsteal.sh) with selected connection type
    setup_selfsteal "$XRAY_CONNECTION_TYPE"

    # Start node (waits for Caddy socket if using socket mode)
    start_node_and_show_results

    unset CERTIFICATE
    unset NODE_PORT
    unset SELF_STEAL_DOMAIN
    unset XRAY_CONNECTION_TYPE

    echo -e "\n${BOLD_GREEN}$(t node_press_enter_return)${NC}"
    read -r
}
