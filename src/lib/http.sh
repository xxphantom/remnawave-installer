#!/bin/bash

# ===================================================================================
#                                HTTP CLIENT FUNCTIONS
# ===================================================================================

make_api_request() {
    local method=$1
    local url=$2
    local token=$3
    local panel_domain=$4
    local data=$5
    local cookie=${6:-""}

    # Extract only the host from the URL (X-Forwarded-For must not contain a port)
    local host_only=$(echo "${url#http://}" | cut -d'/' -f1 | cut -d':' -f1)

    local headers=(
        -H "Content-Type: application/json"
        -H "Host: $panel_domain"
        -H "X-Forwarded-For: $host_only"
        -H "X-Forwarded-Proto: https"
        -H "X-Remnawave-Client-type: browser"
    )

    if [ -n "$token" ]; then
        headers+=(-H "Authorization: Bearer $token")
    fi

    if [ -n "$cookie" ]; then
        headers+=(-H "Cookie: $cookie")
    fi

    if [ "$method" = "GET" ]; then
        curl -s -X "$method" "$url" "${headers[@]}"
    else
        if [ -n "$data" ]; then
            curl -s -X "$method" "$url" "${headers[@]}" -d "$data"
        else
            curl -s -X "$method" "$url" "${headers[@]}"
        fi
    fi
}
