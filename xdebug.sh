#!/bin/bash

# Display help function
show_help() {
    echo "Usage: xdebug [OPTIONS]"
    echo ""
    echo "A script to toggle Xdebug configuration for different PHP versions and settings."
    echo ""
    echo "Options:"
    echo "  --php <version>             Specify the PHP version (e.g., 7.4, 8.0, 8.3)"
    echo "  --enable                    Enable Xdebug for the specified PHP version"
    echo "  --disable                   Disable Xdebug for the specified PHP version"
    echo "  --mode <mode>               Set the Xdebug mode (e.g., debug, coverage)"
    echo "  --port <port>               Set the Xdebug port (e.g., 9003)"
    echo "  --start-with-request <yes|no> Set whether Xdebug should start with the request"
    echo "  --help                      Show this help message"
    echo ""
    echo "Examples:"
    echo "  xdebug --enable --php 8.3 --mode debug"
    echo "  xdebug --disable --php 7.4"
    echo "  xdebug --php 8.3 --start-with-request no"
    echo "  xdebug --php 8.3 --port 9003"
    exit 0
}

# Check for the presence of Xdebug config files
get_xdebug_config_file() {
    local php_version=$1
    local ini_file
    if [ -f "/etc/php/${php_version}/mods-available/xdebug.ini" ]; then
        ini_file="/etc/php/${php_version}/mods-available/xdebug.ini"
    elif [ -f "/etc/php/${php_version}/mods-available/20-xdebug.ini" ]; then
        ini_file="/etc/php/${php_version}/mods-available/20-xdebug.ini"
    else
        echo "Xdebug is not installed or configuration file not found for PHP ${php_version}"
        exit 1
    fi
    echo $ini_file
}

# Enable Xdebug
enable_xdebug() {
    local php_version=$1
    local mode=$2
    local ini_file=$(get_xdebug_config_file $php_version)

    # Check if Xdebug is already enabled
    if grep -q "^;zend_extension=xdebug.so" "$ini_file"; then
        sed -i 's/^;zend_extension/zend_extension/' "$ini_file"
    else
        echo "Xdebug is already enabled for PHP ${php_version}"
    fi

    if [ ! -z "$mode" ]; then
        if grep -q "^xdebug.mode=" "$ini_file"; then
            sed -i "s/^xdebug.mode=.*/xdebug.mode=${mode}/" "$ini_file"
        else
            echo "xdebug.mode=${mode}" >> "$ini_file"
        fi
    fi
}

# Disable Xdebug
disable_xdebug() {
    local php_version=$1
    local ini_file=$(get_xdebug_config_file $php_version)

    # Check if Xdebug is already disabled
    if grep -q "^zend_extension=xdebug.so" "$ini_file"; then
        sed -i 's/^zend_extension/;zend_extension/' "$ini_file"
    else
        echo "Xdebug is already disabled for PHP ${php_version}"
    fi
}

# Change the Xdebug mode
change_mode() {
    local php_version=$1
    local mode=$2
    local ini_file=$(get_xdebug_config_file $php_version)

    if grep -q "^xdebug.mode=" "$ini_file"; then
        sed -i "s/^xdebug.mode=.*/xdebug.mode=${mode}/" "$ini_file"
    else
        echo "xdebug.mode=${mode}" >> "$ini_file"
    fi
}

# Set the Xdebug port
set_port() {
    local php_version=$1
    local port=$2
    local ini_file=$(get_xdebug_config_file $php_version)

    if grep -q "^xdebug.client_port=" "$ini_file"; then
        sed -i "s/^xdebug.client_port=.*/xdebug.client_port=${port}/" "$ini_file"
    else
        echo "xdebug.client_port=${port}" >> "$ini_file"
    fi
}

# Set the Xdebug start_with_request option
set_start_with_request() {
    local php_version=$1
    local value=$2
    local ini_file=$(get_xdebug_config_file $php_version)

    if grep -q "^xdebug.start_with_request=" "$ini_file"; then
        sed -i "s/^xdebug.start_with_request=.*/xdebug.start_with_request=${value}/" "$ini_file"
    else
        echo "xdebug.start_with_request=${value}" >> "$ini_file"
    fi
}

# Restart PHP-FPM service
restart_fpm() {
    local php_version=$1
    sudo systemctl restart php${php_version}-fpm
}

# Parse command-line arguments
php_version=""
mode=""
port=""
start_with_request=""
action=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --php) php_version="$2"; shift ;;
        --mode) mode="$2"; shift ;;
        --enable) action="enable";;
        --disable) action="disable";;
        --port) port="$2"; shift ;;
        --start-with-request) start_with_request="$2"; shift ;;
        --help) show_help ;;
        *) echo "Unknown parameter: $1"; show_help ;;
    esac
    shift
done

if [ -z "$php_version" ]; then
    echo "Please specify a PHP version with --php"
    exit 1
fi

case $action in
    enable) enable_xdebug $php_version $mode ;;
    disable) disable_xdebug $php_version ;;
    *) if [ ! -z "$mode" ]; then change_mode $php_version $mode; fi
       if [ ! -z "$port" ]; then set_port $php_version $port; fi
       if [ ! -z "$start_with_request" ]; then set_start_with_request $php_version $start_with_request; fi ;;
esac

# Restart PHP-FPM service
restart_fpm $php_version
