#!/bin/bash

# ===================================================================================
#                                VLESS CONFIGURATION
# ===================================================================================

# Generate keys for VLESS Reality
generate_vless_keys() {
  local panel_url="$1"
  local token="$2"
  local panel_domain="$3"
  
  # Try to generate keys using panel API first
  if [ -n "$panel_url" ] && [ -n "$token" ] && [ -n "$panel_domain" ]; then
    local api_keys=$(generate_x25519_keys_api "$panel_url" "$token" "$panel_domain")
    if [ $? -eq 0 ] && [ -n "$api_keys" ]; then
      echo "$api_keys"
      return 0
    fi
  fi
  
  # Fallback to Docker method if API fails or parameters not provided
  local temp_file=$(mktemp)

  # Generate x25519 keys using Docker
  docker run --rm ghcr.io/xtls/xray-core x25519 >"$temp_file" 2>&1 &
  spinner $! "$(t spinner_generating_keys)"
  keys=$(cat "$temp_file")

  local private_key=$(echo "$keys" | grep "PrivateKey:" | awk '{print $2}')
  local public_key=$(echo "$keys" | grep "Password:" | awk '{print $2}')
  rm -f "$temp_file"

  if [ -z "$private_key" ] || [ -z "$public_key" ]; then
    echo -e "${BOLD_RED}$(t vless_failed_generate_keys)${NC}"
    return 1
  fi

  # Return keys via echo
  echo "$private_key:$public_key"
}

# Create VLESS Xray configuration
generate_xray_config() {
  local config_file="$1"
  local self_steal_domain="$2"
  local CADDY_LOCAL_PORT="$3"
  local private_key="$4"

  local short_id=$(openssl rand -hex 8)

  cat >"$config_file" <<EOL
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      {
        "address": "https://dns.google/dns-query",
        "skipFallback": false
      }
    ],
    "queryStrategy": "UseIPv4"
  },
  "inbounds": [
    {
      "tag": "VLESS",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "127.0.0.1:$CADDY_LOCAL_PORT",
          "show": false,
          "xver": 1,
          "shortIds": [
            "$short_id"
          ],
          "privateKey": "$private_key",
          "serverNames": [
            "$self_steal_domain"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      "tag": "BLOCK",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "rules": [
      {
        "ip": [
          "geoip:private"
        ],
        "type": "field",
        "outboundTag": "BLOCK"
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "BLOCK"
      }
    ]
  }
}
EOL
}

# Update Xray configuration
update_xray_config() {
  local panel_url="$1"
  local token="$2"
  local panel_domain="$3"
  local config_file="$4"

  local temp_file=$(mktemp)
  local new_config=$(cat "$config_file")

  make_api_request "PUT" "http://$panel_url/api/xray" "$token" "$panel_domain" "$new_config" >"$temp_file" 2>&1 &
  spinner $! "$(t spinner_updating_xray)"
  local update_response=$(cat "$temp_file")
  rm -f "$temp_file"

  if [ -z "$update_response" ]; then
    echo -e "${BOLD_RED}$(t vless_empty_response_xray)${NC}"
    return 1
  fi

  if echo "$update_response" | jq -e '.response.config' >/dev/null; then
    return 0
  else
    echo -e "${BOLD_RED}$(t vless_failed_update_xray)${NC}"
    return 1
  fi
}
