#!/bin/bash
# local_checker.sh - Check all local SSH and Git configurations

check_local_setup() {
    local pem_file="$1"
    local has_errors=0
    local has_warnings=0
    
    echo "=== Local Machine Configuration Checker ==="
    echo "Checking SSH and Git configurations..."
    echo

    # Function to print status
    print_status() {
        local type="$1"
        local message="$2"
        if [ "$type" = "error" ]; then
            echo "❌ ERROR: $message"
            has_errors=1
        elif [ "$type" = "warning" ]; then
            echo "⚠️  WARNING: $message"
            has_warnings=1
        else
            echo "✅ OK: $message"
        fi
    }

    # Check SSH directory
    echo "Checking SSH Configuration:"
    echo "-------------------------"
    if [ ! -d ~/.ssh ]; then
        print_status "error" "SSH directory (~/.ssh) does not exist"
    else
        local ssh_perms=$(stat -c "%a" ~/.ssh)
        if [ "$ssh_perms" = "700" ]; then
            print_status "ok" "SSH directory permissions (700)"
        else
            print_status "error" "SSH directory has incorrect permissions: $ssh_perms (should be 700)"
        fi
    fi

    # Check SSH config
    if [ -f ~/.ssh/config ]; then
        local config_perms=$(stat -c "%a" ~/.ssh/config)
        if [ "$config_perms" = "600" ]; then
            print_status "ok" "SSH config file permissions (600)"
        else
            print_status "error" "SSH config has incorrect permissions: $config_perms (should be 600)"
        fi

        # Check Git host configuration
        if grep -q "Host.*git" ~/.ssh/config; then
            print_status "ok" "Git host configuration found in SSH config"
        else
            print_status "warning" "No Git host configuration found in SSH config"
        fi
    else
        print_status "warning" "No SSH config file found"
    fi

    # Check PEM file
    echo -e "\nChecking PEM Key File:"
    echo "---------------------"
    if [ ! -f "$pem_file" ]; then
        print_status "error" "PEM file ($pem_file) not found"
    else
        local pem_perms=$(stat -c "%a" "$pem_file")
        if [ "$pem_perms" = "600" ]; then
            print_status "ok" "PEM file permissions (600)"
        else
            print_status "error" "PEM file has incorrect permissions: $pem_perms (should be 600)"
        fi
    fi

    # Check Git configuration
    echo -e "\nChecking Git Configuration:"
    echo "-------------------------"
    if command -v git >/dev/null 2>&1; then
        print_status "ok" "Git is installed"
        
        # Check Git global configuration
        if [ -f ~/.gitconfig ]; then
            if git config --global user.name >/dev/null; then
                print_status "ok" "Git user.name is configured"
            else
                print_status "warning" "Git user.name is not configured"
            fi
            
            if git config --global user.email >/dev/null; then
                print_status "ok" "Git user.email is configured"
            else
                print_status "warning" "Git user.email is not configured"
            fi
        else
            print_status "warning" "No Git global configuration found"
        fi
    else
        print_status "error" "Git is not installed"
    fi

    # Print summary
    echo -e "\nSummary:"
    echo "--------"
    if [ $has_errors -eq 1 ]; then
        echo "❌ Found errors that need to be fixed"
    elif [ $has_warnings -eq 1 ]; then
        echo "⚠️  Found warnings that should be reviewed"
    else
        echo "✅ All checks passed successfully"
    fi
}

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/your/key.pem"
    exit 1
fi

check_local_setup "$1"

