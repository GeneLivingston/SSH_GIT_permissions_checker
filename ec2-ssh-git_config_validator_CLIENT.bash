#!/bin/bash
# local_validator.sh
# Validates local machine permissions for Git over SSH

check_local_permissions() {
    local pem_file="$1"
    local has_errors=0
    
    echo "=== Checking Local Machine Permissions ==="
    echo

    # Check SSH config directory
    echo "Checking ~/.ssh directory..."
    if [ ! -d ~/.ssh ]; then
        echo "❌ ~/.ssh directory does not exist"
        has_errors=1
    else
        local ssh_perms=$(stat -c "%a" ~/.ssh)
        if [ "$ssh_perms" != "700" ]; then
            echo "❌ ~/.ssh permissions should be 700, found: $ssh_perms"
            has_errors=1
        else
            echo "✅ ~/.ssh permissions correct (700)"
        fi
    fi

    # Check SSH config file
    echo -e "\nChecking ~/.ssh/config..."
    if [ ! -f ~/.ssh/config ]; then
        echo "❌ ~/.ssh/config does not exist"
        has_errors=1
    else
        local config_perms=$(stat -c "%a" ~/.ssh/config)
        if [ "$config_perms" != "600" ]; then
            echo "❌ ~/.ssh/config permissions should be 600, found: $config_perms"
            has_errors=1
        else
            echo "✅ ~/.ssh/config permissions correct (600)"
        fi

        # Check if git host is configured
        if ! grep -q "Host.*git" ~/.ssh/config; then
            echo "❌ No git host configuration found in ~/.ssh/config"
            has_errors=1
        else
            echo "✅ Git host configuration found in ~/.ssh/config"
        fi
    fi

    # Check PEM file if provided
    if [ ! -z "$pem_file" ]; then
        echo -e "\nChecking PEM file ($pem_file)..."
        if [ ! -f "$pem_file" ]; then
            echo "❌ PEM file does not exist"
            has_errors=1
        else
            local pem_perms=$(stat -c "%a" "$pem_file")
            if [ "$pem_perms" != "600" ]; then
                echo "❌ PEM file permissions should be 600, found: $pem_perms"
                has_errors=1
            else
                echo "✅ PEM file permissions correct (600)"
            fi
        fi
    fi

    echo
    if [ $has_errors -eq 1 ]; then
        echo "❌ Found permission issues that need to be fixed"
        return 1
    else
        echo "✅ All local permissions are correct"
        return 0
    fi
}

# Usage
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/your/key.pem"
    exit 1
fi

check_local_permissions "$1"

