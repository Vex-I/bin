#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/vpanel"
CONFIG_FILE="$CONFIG_DIR/main.cfg"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

print_help() {
    cat << EOF
Usage:
    vpanel [METHOD] [OPTIONS]

Description:
    A CLI tool to interact with a VPanel API.

Methods:
    set-origin          Set the target URL of the API.
    set-token           Set the read token to access the API.
    login               Login with a username and a password.
    get                 Get entries with the specified attributes.
    edit                Edit an entry.
    create              Create a new entry.
    delete              Delete an entry.
    generate-token      Generate a read token.
    invalidate-token    Invalidate a read token. 
    start               Initialize some settings.

Run vpanel [METHOD] -h|--help to view all the options.
EOF
}

export VPANEL_URL
export VPANEL_READ_TOKEN
export VPANEL_JSON_TOKEN

refrechFields() {
    cat > "$CONFIG_FILE" <<EOF
VPANEL_URL="$VPANEL_URL"
VPANEL_READ_TOKEN="$VPANEL_READ_TOKEN"
VPANEL_JSON_TOKEN="$VPANEL_JSON_TOKEN"
EOF
}


initialize() {
    mkdir -p "$CONFIG_DIR"

    echo "Let's initialize some settings."

    read -r -p "Enter the API URL: " VPANEL_URL
    read -r -p "Enter your read token (optional): " VPANEL_READ_TOKEN

    cat > "$CONFIG_FILE" <<EOF
VPANEL_URL="$VPANEL_URL"
VPANEL_READ_TOKEN="$VPANEL_READ_TOKEN"
VPANEL_JSON_TOKEN="$VPANEL_JSON_TOKEN"
EOF
    echo
    echo "Configuration saved to $CONFIG_FILE"
}

print_login_help() {
    cat << EOF
Usage: 
    vpanel login [OPTIONS]
    
Description: 
    Login using the specified credentials.

Options: 
    -u [USERNAME]           The username of the User
    -p [PASSWORD]           The password of the User
EOF
}

login() {
    local USERNAME
    local PASSWORD
    while [[ $# -gt 0 ]]; do
        case "$1" in 
            -h|--help)
                print_login_help
                exit 0 
                ;; 
            -u) 
                USERNAME="$2"
                shift 2
                ;;
            -p) 
                PASSWORD="$2"
                shift 2
                ;;
            *)
                print_login_help
                exit 0 
                ;;
        esac
    done

    if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
        echo "Error: username and password required"
        print_login_help
        return 1
    fi

    VPANEL_JSON_TOKEN=$(curl -X POST -H "Content-Type: application/json" \
        -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" \
        "$VPANEL_URL/api/auth/login" | jq -r .token)

    echo $VPANEL_JSON_TOKEN

    refrechFields
}

print_get_help() {
    cat << EOF 
Usage: 
    vpanel get [OPTIONS]

Description:
    Submit a query with the specified parameters. Case-sensitive

Options: 
    -s | --slug         Specify a slug.
    [slug]
    -t | --title        Specify a title.
    [title]
    -p | --type         Specify the type.
    [type]

EOF
}

get() {
    local TYPE 
    local SLUG
    local TITLE

    while [[ $# -gt 0 ]]; do
        case "$1" in 
            -h|--help)
                print_get_help
                exit 0 
                ;; 
            -p) 
                TYPE="$2"
                shift 2
                ;;
            -t) 
                TITLE="$2"
                shift 2
                ;;
            -s) 
                SLUG="$2"
                shift 2 
                ;;
            *)
                print_get_help
                exit 0 
                ;;
        esac
    done

    args=() 
    [ -n "$TYPE" ] && args+=(-d "type=$TYPE")
    [ -n "$TITLE" ] && args+=(-d "title=$TITLE")
    [ -n "$SLUG" ] && args+=(-d "slug=$SLUG")

    local response 
    response=$(mktemp)

    local status
    status=$(curl -sS -G \
        -H "Authorization:bearer $VPANEL_JSON_TOKEN" \
        "${args[@]}" \
        -o "$response" \
        -w "%{http_code}" \
        "$VPANEL_URL/api/content")

    if [[ "$status" == "200" ]]; then
        jq . "$response"
    else
        echo "Error: request failed (HTTP $status)."
        cat "$response"
    fi

    rm "$response"
}

print_edit_help() {
    cat << EOF 
Usage: 
    vpanel edit [SLUG] [DATA]

Description:
    Edit an entry with the specified slug. 

Options: 
    -s | --slug         Specify a slug.
    [slug]
    -d | --data         Specify the fields to edit.
    [fields] [value]

Fields:
    title 
    type 
    slug 
    hasAPage 
    link 
    excerpt 
    shortExcerpt 
    tags 
    image 
    markdown 

For a complete list of all the fields and their possible values,
refer to the API documentation.
EOF
}

edit() {
    
    local SLUG
    fields=()
    while [[ $# -gt 0 ]]; do
        case "$1" in 
            -h|--help)
                print_edit_help
                exit 0 
                ;; 
            -s|--slug) 
                fields+=(-F "slug=$2")
                shift 2
                ;;
            -d|--data) 
                fields+=(-F "$2=$3")
                shift 3 
                ;;
            *)
                print_edit_help
                exit 0 
                ;;
        esac
    done

    if [[-z "$SLUG"]]; then 
        echo "Slug unspecified."
        return 1
    fi

    local response 
    response=$(mktemp)

    local status
    status=$(curl -Ss -X PUT -H "Authorization:bearer $VPANEL_JSON_TOKEN" \
        "${fields[@]}" \
        -o "$response" \
        -w "%{http_code}" \
        "$VPANEL_URL/api/auth/content")

    if [[ "$status" == "200" ]]; then
        jq . "$response"
    else
        echo "Error: request failed (HTTP $status)."
        cat "$response"
    fi

    rm "$response"
}

print_create_help() {
    cat << EOF 
Usage: 
    vpanel create [DATA]

Description:
    Create an entry with the specified slug. 

Options: 
    -d | --data         Specify the fields and their values.
    [fields] [value]

Fields:
    title 
    type 
    slug 
    hasAPage 
    link 
    excerpt 
    shortExcerpt 
    tags 
    image 
    markdown 

For a complete list of all the fields and their possible values,
refer to the API documentation.
EOF
}

create() {
    fields=()
    while [[ $# -gt 0 ]]; do
        case "$1" in 
            -h|--help)
                print_create_help
                exit 0 
                ;; 
            -d) 
                fields+=(-F "$2=$3")
                shift 3 
                ;;
            *)
                print_create_help
                exit 0 
                ;;
        esac
    done

    local response 
    response=$(mktemp)

    local status
    status=$(curl -Ss -X POST -H "Authorization:bearer $VPANEL_JSON_TOKEN" \
        "${fields[@]}" \
        -o "$response" \
        -w "%{http_code}" \
        "$VPANEL_URL/api/auth/content")
    if [[ "$status" == "200" ]]; then
        jq . "$response"
    else
        echo "Error: request failed (HTTP $status)."
        cat "$response"
    fi

    rm "$response"
}

print_delete_help() {
    cat << EOF 
Usage: 
    vpanel delete [DATA]

Description:
    Delete an entry with the specified slug. 

Options: 
    -s | --slug Specify the fields and their values.
    [fields] [value]

EOF
}

delete() {
    local SLUG
    while [[ $# -gt 0 ]]; do
        case "$1" in 
            -h|--help)
                print_delete_help
                exit 0 
                ;; 
            -s) 
                SLUG = $2
                shift 2
                ;;
            *)
                print_delete_help
                exit 0 
                ;;
        esac
    done

    if [[-z "$SLUG" ]]; then 
        echo "Slug not specified."
        exit 1
    fi

    local response 
    response=$(mktemp)

    local status
    status=$(curl -Ss -X DELETE -H "Authorization:bearer $VPANEL_JSON_TOKEN" \
        -o "$response" \
        -w "%{http_code}" \
        "$VPANEL_URL/api/auth/content?slug=$SLUG")

    if [[ "$status" == "200" ]]; then
        jq . "$response"
    else
        echo "Error: request failed (HTTP $status)."
        cat "$response"
    fi

    rm "$response"

}

gen_token() {
    local response 
    response=$(mktemp)

    local status
    status=$(curl -Ss -X GET -H "Authorization:bearer $VPANEL_JSON_TOKEN" \
        -H "Content-Type: application/json" \
        -o "$response" \
        -w "%{http_code}" \
        "$VPANEL_URL/api/auth/token)")

    if [[ "$status" == "200" ]]; then
        jq . "$response"
    else
        echo "Error: request failed (HTTP $status)."
        cat "$response"
    fi

    rm "$response"
}

del_token() {
    local response 
    response=$(mktemp)

    local status
    status=$(curl -Ss -X DELETE -H "Authorization:bearer $VPANEL_JSON_TOKEN" \
        -o "$response" \
        -w "%{http_code}" \
        "$VPANEL_URL/api/auth/token")

    if [[ "$status" == "200" ]]; then
        jq . "$response"
    else
        echo "Error: request failed (HTTP $status)."
        cat "$response"
    fi

    rm "$response"

}

case "$1" in 
    start)
        initialize
        exit 0 
        ;;
    set-origin)
        VPANEL_URL="$2"
        exit 0
        ;;
    set-token) 
        VPANEL_READ_TOKEN="$2"
        exit 0 
        ;;
    login)
        shift 
        login "$@"
        exit 0 
        ;;
    get) 
        shift 
        get "$@"
        exit 0; 
        ;;
    edit) 
        shift 
        edit "$@"
        exit 0
        ;;
    create) 
        shift 
        create "$@"
        exit 0
        ;;
    delete)
        shift 
        delete "$@"
        exit 0
        ;;
    generate-token) 
        gen_token "$@"
        exit 0 
        ;;
    invalidate-token)
        del_token "$@"
        exit 0 
        ;;
    *)
        print_help
        exit 0 
        ;;
esac
