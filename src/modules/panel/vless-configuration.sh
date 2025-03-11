#!/bin/bash

vless_configuration() {
    local panel_url="$1"
    local panel_domain="$2"
    local token="$3"
    local api_url="http://${panel_url}/api/auth/register"

    # Запрос домена Selfsteal с валидацией
    SELF_STEAL_DOMAIN=$(read_domain "Введите Selfsteal домен, например domain.example.com")
    if [ -z "$SELF_STEAL_DOMAIN" ]; then
        return 1
    fi

    # Запрос порта Selfsteal с валидацией и дефолтным значением 9443
    SELF_STEAL_PORT=$(read_port "Введите Selfsteal порт (можно оставить по умолчанию)" "9443")

    # Запрос IP адреса или домена сервера с нодой с валидацией и дефолтным значением Selfsteal домена
    NODE_HOST=$(read_domain "Введите IP адрес или домен сервера с нодой (если отличается от Selfsteal домена)" "$SELF_STEAL_DOMAIN")

    # Запрос порта API ноды с валидацией и дефолтным значением 3000
    NODE_PORT=$(read_port "Введите порт API ноды (можно оставить по умолчанию)" "3000")

    local config_file="$REMNAWAVE_DIR/panel/config.json"
    local node_name="VLESS-NODE"

    # Генерация ключей x25519 с помощью Docker
    echo -e "${BOLD_GREEN}Генерация ключей x25519...${NC}"
    sleep 1
    keys=$(docker run --rm ghcr.io/xtls/xray-core x25519)
    private_key=$(echo "$keys" | grep "Private key:" | awk '{print $3}')
    public_key=$(echo "$keys" | grep "Public key:" | awk '{print $3}')

    if [ -z "$private_key" ] || [ -z "$public_key" ]; then
        echo -e "${BOLD_RED}Ошибка: Не удалось сгенерировать ключи.${NC}"
    fi

    short_id=$(openssl rand -hex 8)
    cat > "$config_file" <<EOL
{
  "log": {
    "loglevel": "debug"
  },
  "inbounds": [
    {
      "tag": "VLESS TCP REALITY",
      "port": 443,
      "listen": "0.0.0.0",
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
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "dest": "127.0.0.1:$SELF_STEAL_PORT",
          "show": false,
          "xver": 1,
          "shortIds": [
            "$short_id"
          ],
          "publicKey": "$public_key",
          "privateKey": "$private_key",
          "serverNames": [
              "$SELF_STEAL_DOMAIN"
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
        "domain": [
          "geosite:private"
        ],
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

    echo -e "${BOLD_GREEN}Обновление конфигурации Xray...${NC}"
    sleep 1
    local new_config=$(cat "$config_file")
    local update_response=$(curl -s -X POST "http://$panel_url/api/xray/update-config" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https" \
        -d "$new_config")

    if [ -z "$update_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Пустой ответ от сервера при обновлении Xray конфига.${NC}"
    fi

    if echo "$update_response" | jq -e '.response.config' > /dev/null; then
        echo -e "${BOLD_GREEN}Конфигурация Xray успешно обновлена.${NC}"
        sleep 1
    else
        echo -e "${BOLD_RED}Ошибка: Не удалось обновить конфигурацию Xray.${NC}"
    fi

    local new_node_data=$(cat <<EOF
{
    "name": "$node_name",
    "address": "$NODE_HOST",
    "port": $NODE_PORT,
    "isTrafficTrackingActive": false,
    "trafficLimitBytes": 0,
    "notifyPercent": 0,
    "trafficResetDay": 31,
    "excludedInbounds": [],
    "countryCode": "XX",
    "consumptionMultiplier": 1.0
}
EOF
)
    # Создание ноды
    echo -e "${BOLD_GREEN}Создание ноды...${NC}"
    sleep 1
    node_response=$(curl -s -X POST "http://$panel_url/api/nodes/create" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https" \
        -d "$new_node_data")

    if [ -z "$node_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Пустой ответ от сервера при создании узла.${NC}"
    fi

    if echo "$node_response" | jq -e '.response.uuid' > /dev/null; then
        echo -e "${BOLD_GREEN}Узел успешно создан.${NC}"
    else
        echo -e "${BOLD_RED}Ошибка: Не удалось создать узел, ответ:${NC}"
        echo
        echo "Был направлен запрос с телом:"
        echo "$new_node_data"
        echo
        echo "Ответ:"
        echo
        echo "$node_response"
    fi

    # Получение inbounds
    inbounds_response=$(curl -s -X GET "http://$panel_url/api/inbounds" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https")

    if [ -z "$inbounds_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Пустой ответ от сервера при получении inbounds.${NC}"
    fi

    inbound_uuid=$(echo "$inbounds_response" | jq -r '.response[0].uuid')
    if [ -z "$inbound_uuid" ]; then
        echo -e "${BOLD_RED}Ошибка: Не удалось извлечь UUID из ответа.${NC}"
    fi
    echo -e "${BOLD_GREEN}Создаем хост с UUID: $inbound_uuid...${NC}"
    host_data=$(cat <<EOF
{
    "inboundUuid": "$inbound_uuid",
    "remark": "$node_name-HOST",
    "address": "$SELF_STEAL_DOMAIN",
    "port": 443,
    "path": "",
    "sni": "$SELF_STEAL_DOMAIN",
    "host": "$SELF_STEAL_DOMAIN",
    "alpn": "h2",
    "fingerprint": "chrome",
    "allowInsecure": false,
    "isDisabled": false
}
EOF
)

    host_response=$(curl -s -X POST "http://$panel_url/api/hosts/create" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https" \
        -d "$host_data")

    if [ -z "$host_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Пустой ответ от сервера при создании хоста.${NC}"
    fi

    if echo "$host_response" | jq -e '.response.uuid' > /dev/null; then
        echo -e "${BOLD_GREEN}Хост успешно создан.${NC}"
    else
        echo -e "${BOLD_RED}Ошибка: Не удалось создать хост.${NC}"
    fi

    api_response=$(curl -s -X GET "http://$panel_url/api/keygen/get" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "Host: $panel_domain" \
        -H "X-Forwarded-For: $panel_url" \
        -H "X-Forwarded-Proto: https")

    if [ -z "$api_response" ]; then
        echo -e "${BOLD_RED}Ошибка: Не удалось получить публичный ключ.${NC}"
    fi

    pubkey=$(echo "$api_response" | jq -r '.response.pubKey')
    if [ -z "$pubkey" ]; then
        echo -e "${BOLD_RED}Ошибка: Не удалось извлечь публичный ключ из ответа.${NC}"
    fi

    echo -e "${GREEN}Публичный ключ (нужен для установки ноды):${NC}"
    echo
    echo -e "SSL_CERT=\"$pubkey\""
    echo
}
