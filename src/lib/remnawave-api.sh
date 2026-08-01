#!/bin/bash

# ===================================================================================
#                                REMNAWAVE API FUNCTIONS
# ===================================================================================

register_user() {
    local panel_url="$1"
    local panel_domain="$2"
    local username="$3"
    local password="$4"
    local api_url="http://${panel_url}/api/auth/register"

    local reg_token=""
    local reg_error=""
    local response=""
    local max_wait=180

    local temp_result=$(mktemp)

    {
        local start_time=$(date +%s)
        local end_time=$((start_time + max_wait))

        while [ $(date +%s) -lt $end_time ]; do
            response=$(make_api_request "POST" "$api_url" "" "$panel_domain" "{\"username\":\"$username\",\"password\":\"$password\"}")
            if [ -z "$response" ]; then
                reg_error="$(t api_empty_server_response)"
            elif [[ "$response" == *"accessToken"* ]]; then
                reg_token=$(echo "$response" | jq -r '.response.accessToken')
                echo "$reg_token" >"$temp_result"
                exit 0
            else
                reg_error="$response"
            fi
            sleep 1
        done
        echo "${reg_error:-$(t api_registration_failed)}" >"$temp_result"
        exit 1
    } &

    local pid=$!

    spinner "$pid" "$(t spinner_registering_user) $username..."

    wait $pid
    local status=$?

    local result=$(cat "$temp_result")
    rm -f "$temp_result"

    echo "$result"
    return $status
}

get_public_key() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"

    local temp_file=$(mktemp)

    make_api_request "GET" "http://$panel_url/api/keygen" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_public_key)"
    api_response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ -z "$api_response" ]; then
        echo -e "${BOLD_RED}$(t api_failed_get_public_key)${NC}"
        return 1
    fi

    # 2.9.0 renames the response field pubKey -> secretKey; support both
    local pubkey=$(echo "$api_response" | jq -r '.response.secretKey // .response.pubKey // empty')
    if [ -z "$pubkey" ]; then
        echo -e "${BOLD_RED}$(t api_failed_extract_public_key)${NC}"
        return 1
    fi

    # Return public key
    echo "$pubkey"
}

# Create node
create_node() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local node_host="$4"
    local node_port="$5"
    local profile_uuid="$6"
    local inbound_uuid="$7"

    local node_name="VLESS"
    local temp_file=$(mktemp)

    local new_node_data=$(
        cat <<EOF
{
    "name": "$node_name",
    "address": "$node_host",
    "port": $node_port,
    "configProfile": {
        "activeConfigProfileUuid": "$profile_uuid",
        "activeInbounds": [
            "$inbound_uuid"
        ]
    },
    "isTrafficTrackingActive": false,
    "trafficLimitBytes": 0,
    "notifyPercent": 0,
    "trafficResetDay": 31,
    "countryCode": "XX",
    "consumptionMultiplier": 1.0
}
EOF
    )

    make_api_request "POST" "http://$panel_url/api/nodes" "$token" "$panel_domain" "$new_node_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_creating_node)"
    node_response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ -z "$node_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_creating_node)${NC}"
        return 1
    fi

    if echo "$node_response" | jq -e '.response.uuid' >/dev/null; then
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_node)${NC}"
        echo
        echo "$(t api_request_body_was)"
        echo "$new_node_data"
        echo
        echo "$(t api_response):"
        echo
        echo "$node_response"
        return 1
    fi
}

# Get config profiles
get_config_profiles() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/config-profiles" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_config_profiles)"
    profiles_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$profiles_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_profiles)${NC}"
        return 1
    fi
    
    echo "$profiles_response"
}

# Delete config profile
delete_config_profile() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local profile_uuid="$4"
    
    local temp_file=$(mktemp)
    
    make_api_request "DELETE" "http://$panel_url/api/config-profiles/$profile_uuid" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_deleting_config_profile)"
    delete_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    # Check for successful deletion
    # Panel 3.0.0 answers 204 with an empty body, 2.x answered {"response":{"isDeleted":true}}
    if [ -z "$delete_response" ] || echo "$delete_response" | jq -e '.response.isDeleted == true' >/dev/null 2>&1; then
        return 0
    fi

    # Check if response indicates error
    if echo "$delete_response" | jq -e '.error // .errorCode // .message' >/dev/null 2>&1; then
        echo -e "${BOLD_RED}$(t api_failed_delete_profile)${NC}"
        echo
        echo "$(t api_response):"
        echo "$delete_response"
        return 1
    fi
    
    return 0
}

# Create config profile
create_config_profile() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local profile_name="$4"
    local xray_config="$5"
    
    local temp_file=$(mktemp)
    
    local profile_data=$(cat <<EOF
{
    "name": "$profile_name",
    "config": $xray_config
}
EOF
    )
    
    make_api_request "POST" "http://$panel_url/api/config-profiles" "$token" "$panel_domain" "$profile_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_creating_config_profile)"
    profile_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$profile_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_creating_profile)${NC}"
        return 1
    fi
    
    if echo "$profile_response" | jq -e '.response.uuid' >/dev/null; then
        # Return profile UUID and inbound UUID as colon-separated string
        local profile_uuid=$(echo "$profile_response" | jq -r '.response.uuid')
        local inbound_uuid=$(echo "$profile_response" | jq -r '.response.inbounds[0].uuid')
        echo "$profile_uuid:$inbound_uuid"
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_profile)${NC}"
        echo
        echo "$(t api_response):"
        echo "$profile_response"
        return 1
    fi
}

# Get list of squads
get_squads() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/internal-squads" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_squads)"
    squads_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$squads_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_squads)${NC}"
        return 1
    fi
    
    # Return the full response for processing
    echo "$squads_response"
}

# Update squad with new inbound
update_squad() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local squad_uuid="$4"
    local inbound_uuid="$5"
    
    local temp_file=$(mktemp)
    
    # First get current squad data
    local squad_response=$(get_squads "$panel_url" "$token" "$panel_domain")
    if [ -z "$squad_response" ] || ! echo "$squad_response" | jq -e '.response.internalSquads' >/dev/null; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_squads)${NC}"
        return 1
    fi
    
    # Extract existing inbounds for this squad
    local existing_inbounds=$(echo "$squad_response" | jq -r --arg uuid "$squad_uuid" '.response.internalSquads[] | select(.uuid == $uuid) | .inbounds[].uuid')
    if [ -z "$existing_inbounds" ]; then
        existing_inbounds="[]"
    else
        existing_inbounds=$(echo "$existing_inbounds" | jq -R . | jq -s .)
    fi
    
    # Create array with existing and new inbound
    local inbounds_array=$(jq -n --argjson existing "$existing_inbounds" --arg new "$inbound_uuid" '$existing + [$new] | unique')
    
    # Create request body
    local squad_data=$(jq -n --arg uuid "$squad_uuid" --argjson inbounds "$inbounds_array" '{
        uuid: $uuid,
        inbounds: $inbounds
    }')
    
    make_api_request "PATCH" "http://$panel_url/api/internal-squads" "$token" "$panel_domain" "$squad_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_updating_squad)"
    local update_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$update_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_updating_squad)${NC}"
        return 1
    fi
    
    if echo "$update_response" | jq -e '.response.uuid' >/dev/null; then
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_update_squad)${NC}"
        echo
        echo "$(t api_response):"
        echo "$update_response"
        return 1
    fi
}

# Get list of nodes
get_nodes() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/nodes" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_nodes)"
    local response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_nodes)${NC}"
        return 1
    fi
    
    echo "$response"
}

# Create host
create_host() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local profile_uuid="$4"
    local inbound_uuid="$5"
    local self_steal_domain="$6"

    local temp_file=$(mktemp)

    local host_data=$(
        cat <<EOF
{
    "inbound": {
        "configProfileUuid": "$profile_uuid",
        "configProfileInboundUuid": "$inbound_uuid"
    },
    "remark": "VLESS",
    "address": "$self_steal_domain",
    "port": 443,
    "path": "",
    "sni": "$self_steal_domain",
    "host": "",
    "alpn": null,
    "fingerprint": "chrome",
    "isDisabled": false,
    "securityLayer": "DEFAULT"
}
EOF
    )

    make_api_request "POST" "http://$panel_url/api/hosts" "$token" "$panel_domain" "$host_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_creating_host)..."
    host_response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ -z "$host_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_creating_host)${NC}"
        return 1
    fi

    if echo "$host_response" | jq -e '.response.uuid' >/dev/null; then
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_host)${NC}"
        return 1
    fi
}

# Create user
create_user() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local username="$4"
    local squad_uuid="$5"

    local temp_file=$(mktemp)
    local temp_headers=$(mktemp)

    local user_data=$(
        cat <<EOF
{
    "username": "$username",
    "status": "ACTIVE",
    "trafficLimitBytes": 0,
    "trafficLimitStrategy": "NO_RESET",
    "activeInternalSquads": [
        "$squad_uuid"
    ],
    "expireAt": "2099-12-31T23:59:59.000Z",
    "description": "Default user created during installation",
    "hwidDeviceLimit": 0
}
EOF
    )

    # Make request with status code check
    {
        local host_only=$(echo "http://$panel_url/api/users" | sed 's|http://||' | cut -d'/' -f1 | cut -d':' -f1)

        local headers=(
            -H "Content-Type: application/json"
            -H "Host: $panel_domain"
            -H "X-Forwarded-For: $host_only"
            -H "X-Forwarded-Proto: https"
            -H "X-Remnawave-Client-type: browser"
            -H "Authorization: Bearer $token"
        )

        curl -s -w "%{http_code}" -X "POST" "http://$panel_url/api/users" "${headers[@]}" -d "$user_data" -D "$temp_headers" >"$temp_file"
    } &

    spinner $! "$(t creating_user) $username..."

    # Read response and status code
    local full_response=$(cat "$temp_file")
    local status_code="${full_response: -3}"   # Last 3 characters
    local user_response="${full_response%???}" # Everything except last 3 characters

    rm -f "$temp_file" "$temp_headers"

    if [ -z "$user_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_creating_user)${NC}"
        return 1
    fi

    # Check for 201 status code
    if [ "$status_code" != "201" ]; then
        echo -e "${BOLD_RED}$(t api_failed_create_user_status) $status_code${NC}"
        echo
        echo "$(t api_request_body_was)"
        echo "$user_data"
        echo
        echo "$(t api_response):"
        echo "$user_response"
        return 1
    fi

    # Panel 3.0.0 dropped the user uuid in favour of a numeric id and removed subscriptionUuid
    if echo "$user_response" | jq -e '.response.id // .response.uuid' >/dev/null; then
        # Extract user data and save to global variables
        USER_ID=$(echo "$user_response" | jq -r '.response.id // .response.uuid')
        USER_SHORT_UUID=$(echo "$user_response" | jq -r '.response.shortUuid')
        USER_VLESS_UUID=$(echo "$user_response" | jq -r '.response.vlessUuid')
        USER_TROJAN_PASSWORD=$(echo "$user_response" | jq -r '.response.trojanPassword')
        USER_SS_PASSWORD=$(echo "$user_response" | jq -r '.response.ssPassword')
        USER_SUBSCRIPTION_URL=$(echo "$user_response" | jq -r '.response.subscriptionUrl')

        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_user_format)${NC}"
        echo
        echo "$(t api_request_body_was)"
        echo "$user_data"
        echo
        echo "$(t api_response):"
        echo "$user_response"
        return 1
    fi
}

# Generate x25519 keys using panel API
generate_x25519_keys_api() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/system/tools/x25519/generate" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_generating_keys)"
    local api_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$api_response" ]; then
        echo -e "${BOLD_RED}$(t api_failed_generate_keys)${NC}"
        return 1
    fi
    
    # Extract keys from response
    local private_key=$(echo "$api_response" | jq -r '.response.keypairs[0].privateKey')
    local public_key=$(echo "$api_response" | jq -r '.response.keypairs[0].publicKey')
    
    if [ -z "$private_key" ] || [ -z "$public_key" ] || [ "$private_key" = "null" ] || [ "$public_key" = "null" ]; then
        echo -e "${BOLD_RED}$(t api_failed_extract_keys)${NC}"
        return 1
    fi
    
    # Return keys via echo
    echo "$private_key:$public_key"
}

# Create API token for subscription page
create_api_token() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local token_name="${4:-subscription-page-token}"

    local temp_file=$(mktemp)
    local token_data='{"name":"'"$token_name"'","expiresInDays":3650}'

    make_api_request "POST" "http://$panel_url/api/tokens" "$token" "$panel_domain" "$token_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_creating_api_token)"
    local api_response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ -z "$api_response" ]; then
        echo -e "${BOLD_RED}$(t api_failed_create_token)${NC}"
        return 1
    fi

    if echo "$api_response" | jq -e '.response.token' >/dev/null 2>&1; then
        local api_token=$(echo "$api_response" | jq -r '.response.token')
        echo "$api_token"
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_token): $(echo "$api_response" | jq -r '.message // "Unknown error"')${NC}"
        return 1
    fi
}

# Common user registration
register_panel_user() {
    REG_TOKEN=$(register_user "127.0.0.1:3000" "$PANEL_DOMAIN" "$SUPERADMIN_USERNAME" "$SUPERADMIN_PASSWORD")

    if [ -z "$REG_TOKEN" ]; then
        show_error "$(t api_failed_register_user)"
        exit 1
    fi
}
