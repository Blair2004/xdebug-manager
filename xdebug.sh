#!/bin/bash

# Function to get available PHP versions
get_php_versions() {
    update-alternatives --list php | grep -oP '\d\.\d+' | sort -u
}

# Function to toggle Xdebug for a specific PHP version
toggle_xdebug_for_version() {
    PHP_VERSION=$1
    ACTION=$2
    XDEBUG_MODE=$3
    CLIENT_PORT=$4

    INI_FILE="/etc/php/${PHP_VERSION}/mods-available/xdebug.ini"
    
    if [ ! -f "$INI_FILE" ]; then
        echo "Xdebug is not installed for PHP version $PHP_VERSION"
        return
    fi

    if [[ "$ACTION" == "enable" ]]; then
        echo "Enabling Xdebug for PHP $PHP_VERSION..."
        sudo sed -i '/;zend_extension=xdebug/s/^;//g' "$INI_FILE"
    elif [[ "$ACTION" == "disable" ]]; then
        # Check if Xdebug is already disabled
        if grep -q '^;zend_extension=xdebug' "$INI_FILE"; then
            echo "Xdebug is already disabled for PHP $PHP_VERSION."
        else
            echo "Disabling Xdebug for PHP $PHP_VERSION..."
            sudo sed -i '/zend_extension=xdebug/s/^/;/g' "$INI_FILE"
        fi
    fi

    if [ -n "$XDEBUG_MODE" ]; then
        echo "Setting Xdebug mode to $XDEBUG_MODE for PHP $PHP_VERSION..."
        sudo sed -i "s/^xdebug.mode=.*/xdebug.mode=$XDEBUG_MODE/" "$INI_FILE"
    fi

    if [ -n "$CLIENT_PORT" ]; then
        echo "Setting Xdebug client_port to $CLIENT_PORT for PHP $PHP_VERSION..."
        if grep -q '^xdebug.client_port=' "$INI_FILE"; then
            sudo sed -i "s/^xdebug.client_port=.*/xdebug.client_port=$CLIENT_PORT/" "$INI_FILE"
        else
            echo "xdebug.client_port=$CLIENT_PORT" | sudo tee -a "$INI_FILE" > /dev/null
        fi
    fi

    echo "Restarting PHP $PHP_VERSION-FPM service..."
    sudo service php${PHP_VERSION}-fpm restart
}

# Function to show help message
show_help() {
    echo "Usage: xdebug [options]"
    echo ""
    echo "Options:"
    echo "  --enable                 Enable Xdebug"
    echo "  --disable                Disable Xdebug"
    echo "  --mode <mode>            Set the Xdebug mode (e.g., debug, coverage)"
    echo "  --php <version>          Specify the PHP version (e.g., 7.4, 8.3)"
    echo "  --port <client_port>     Set the Xdebug client port (e.g., 9003)"
    echo ""
    echo "Examples:"
    echo "  xdebug --enable --php 7.4"
    echo "  xdebug --disable --php 8.3"
    echo "  xdebug --mode debug"
    echo "  xdebug --enable --mode coverage --php 8.3"
    echo "  xdebug --port 9003 --php 7.4"
    echo ""
}

# Function to parse command line arguments
main() {
    ACTION=""
    XDEBUG_MODE=""
    PHP_VERSION=""
    CLIENT_PORT=""

    if [[ "$#" -eq 0 ]]; then
        show_help
        exit 1
    fi

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --enable) ACTION="enable" ;;
            --disable) ACTION="disable" ;;
            --mode) XDEBUG_MODE="$2"; shift ;;
            --php) PHP_VERSION="$2"; shift ;;
            --port) CLIENT_PORT="$2"; shift ;;
            *) echo "Unknown parameter: $1"; show_help; exit 1 ;;
        esac
        shift
    done

    if [ -z "$PHP_VERSION" ]; then
        echo "No PHP version specified. Toggling Xdebug for all PHP versions."
        for VERSION in $(get_php_versions); do
            toggle_xdebug_for_version "$VERSION" "$ACTION" "$XDEBUG_MODE" "$CLIENT_PORT"
        done
    else
        toggle_xdebug_for_version "$PHP_VERSION" "$ACTION" "$XDEBUG_MODE" "$CLIENT_PORT"
    fi
}

# Execute the main function
main "$@"
