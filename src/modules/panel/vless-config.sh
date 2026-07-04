#!/bin/bash

# ===================================================================================
#                           PANEL-ONLY SHARED FUNCTIONS
# ===================================================================================

# VLESS configuration for panel-only installations
configure_vless_panel_only() {
    local panel_url="127.0.0.1:3000"
    local config_file="$REMNAWAVE_DIR/config.json"

    # Collect node host info
    NODE_HOST=$(simple_read_domain_or_ip "$(t vless_enter_node_host)" "$SELF_STEAL_DOMAIN")

    # Generate VLESS keys
    local keys_result=$(generate_vless_keys "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ $? -ne 0 ]; then
        return 1
    fi

    local private_key=$(echo "$keys_result" | cut -d':' -f1)

    generate_xray_config "$config_file" "$SELF_STEAL_DOMAIN" "$CADDY_SOCKET_PATH" "$private_key"

    # Read the generated config
    local xray_config=$(cat "$config_file")

    # Delete the first (default) profile before creating new one
    local profiles_response=$(get_config_profiles "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -n "$profiles_response" ]; then
        # Get first profile UUID
        local default_profile_uuid=$(echo "$profiles_response" | jq -r '.response.configProfiles[0].uuid // empty' 2>/dev/null)
        
        if [ -n "$default_profile_uuid" ] && [ "$default_profile_uuid" != "null" ]; then
            # Delete the first profile
            delete_config_profile "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$default_profile_uuid"
        fi
    fi

    # Create config profile
    local profile_result=$(create_config_profile "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "StealConfig" "$xray_config")
    if [ -z "$profile_result" ]; then
        return 1
    fi

    local profile_uuid=$(echo "$profile_result" | cut -d':' -f1)
    local inbound_uuid=$(echo "$profile_result" | cut -d':' -f2)

    # Create node entry in panel with config profile
    if ! create_node "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$NODE_HOST" "$NODE_PORT" "$profile_uuid" "$inbound_uuid"; then
        return 1
    fi

    # Create host entry with new structure
    if ! create_host "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$profile_uuid" "$inbound_uuid" "$SELF_STEAL_DOMAIN"; then
        return 1
    fi

    # Get squads and update with new inbound
    local squads_response=$(get_squads "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -z "$squads_response" ]; then
        return 1
    fi

    # Get first squad UUID (в alpha версии может не быть squad'а с именем Default)
    local squad_uuid=$(echo "$squads_response" | jq -r '.response.internalSquads[0].uuid' 2>/dev/null)
    
    # Check if we found any squad
    if [ -z "$squad_uuid" ] || [ "$squad_uuid" = "null" ]; then
        echo -e "${BOLD_RED}Error: No squads found${NC}"
        echo "Squads response:"
        echo "$squads_response" | jq '.'
        return 1
    fi

    # Update squad with new inbound
    if ! update_squad "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$squad_uuid" "$inbound_uuid"; then
        return 1
    fi

    # Create default user
    if ! create_user "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "remnawave" "$squad_uuid"; then
        return 1
    fi

    # Display public key for manual node setup
    local pubkey=$(get_public_key "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -n "$pubkey" ]; then
        echo
        echo -e "${GREEN}$(t vless_public_key_required)${NC}"
        echo -e "${YELLOW}$(t vless_public_key_instruction)${NC}"
        echo
        echo -e "${BOLD_GREEN}$pubkey${NC}"
        echo
    fi
}
