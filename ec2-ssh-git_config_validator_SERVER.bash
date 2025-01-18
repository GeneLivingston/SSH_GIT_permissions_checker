#!/bin/bash
# remote_checker.sh - Check all remote SSH and Git configurations

check_remote_setup() {
    local has_errors=0
    local has_warnings=0
    
    echo "=== Remote Server Configuration Checker ==="
    echo "Checking SSH, Git, and permissions configurations..."
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

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or with sudo"
        exit 1
    fi

    # Check Git installation
    echo "Checking Git Installation:"
    echo "-----------------------"
    if command -v git >/dev/null 2>&1; then
        print_status "ok" "Git is installed"
    else
        print_status "error" "Git is not installed"
    fi

    # Check git-shell installation
    if command -v git-shell >/dev/null 2>&1; then
        print_status "ok" "git-shell is installed"
    else
        print_status "error" "git-shell is not installed"
    fi

    # Check git user setup
    echo -e "\nChecking Git User Configuration:"
    echo "------------------------------"
    if id git >/dev/null 2>&1; then
        print_status "ok" "git user exists"
        
        # Check git user shell
        local git_shell=$(grep git /etc/passwd | cut -d: -f7)
        if [[ "$git_shell" == *"git-shell"* ]]; then
            print_status "ok" "git user shell is git-shell"
        else
            print_status "error" "git user shell is not git-shell: $git_shell"
        fi
    else
        print_status "error" "git user does not exist"
    fi

    # Check git user home directory structure
    echo -e "\nChecking Git User Home Directory:"
    echo "--------------------------------"
    check_directory() {
        local dir="$1"
        local expected_perm="$2"
        local expected_owner="$3"
        
        if [ -d "$dir" ]; then
            local perms=$(stat -c "%a" "$dir")
            local owner=$(stat -c "%U:%G" "$dir")
            
            if [ "$perms" = "$expected_perm" ]; then
                print_status "ok" "$dir has correct permissions ($expected_perm)"
            else
                print_status "error" "$dir has incorrect permissions: $perms (should be $expected_perm)"
            fi
            
            if [ "$owner" = "$expected_owner" ]; then
                print_status "ok" "$dir has correct ownership ($expected_owner)"
            else
                print_status "error" "$dir has incorrect ownership: $owner (should be $expected_owner)"
            fi
        else
            print_status "error" "$dir does not exist"
        fi
    }

    check_directory "/home/git" "755" "git:git"
    check_directory "/home/git/.ssh" "700" "git:git"
    check_directory "/home/git/git-shell-commands" "755" "git:git"

    # Check SSH key configuration
    echo -e "\nChecking SSH Configuration:"
    echo "-------------------------"
    if [ -f "/home/git/.ssh/authorized_keys" ]; then
        local auth_perms=$(stat -c "%a" "/home/git/.ssh/authorized_keys")
        local auth_owner=$(stat -c "%U:%G" "/home/git/.ssh/authorized_keys")
        
        if [ "$auth_perms" = "600" ]; then
            print_status "ok" "authorized_keys has correct permissions (600)"
        else
            print_status "error" "authorized_keys has incorrect permissions: $auth_perms (should be 600)"
        fi
        
        if [ "$auth_owner" = "git:git" ]; then
            print_status "ok" "authorized_keys has correct ownership (git:git)"
        else
            print_status "error" "authorized_keys has incorrect ownership: $auth_owner (should be git:git)"
        fi
    else
        print_status "error" "authorized_keys file does not exist"
    fi

    # Check EC2 Instance Connect configuration
    echo -e "\nChecking EC2 Instance Connect Configuration:"
    echo "-----------------------------------------"
    if [ -f "/etc/ssh/sshd_config.d/git-user.conf" ]; then
        if grep -q "Match User git" "/etc/ssh/sshd_config.d/git-user.conf"; then
            print_status "ok" "git user SSH configuration exists"
            
            if grep -q "AuthorizedKeysCommand none" "/etc/ssh/sshd_config.d/git-user.conf"; then
                print_status "ok" "AuthorizedKeysCommand is properly configured"
            else
                print_status "error" "AuthorizedKeysCommand configuration is missing or incorrect"
            fi
            
            if grep -q "AuthorizedKeysFile %h/.ssh/authorized_keys" "/etc/ssh/sshd_config.d/git-user.conf"; then
                print_status "ok" "AuthorizedKeysFile is properly configured"
            else
                print_status "error" "AuthorizedKeysFile configuration is missing or incorrect"
            fi
        else
            print_status "error" "git user SSH configuration is incomplete"
        fi
    else
        print_status "error" "git user SSH configuration file does not exist"
    fi

    # Check repository directory
    echo -e "\nChecking Git Repository Directory:"
    echo "--------------------------------"
    if [ -d "/srv/git" ]; then
        check_directory "/srv/git" "755" "git:git"
        
        # Check for any bare repositories
        local repos=$(find /srv/git -name "*.git" -type d)
        if [ -n "$repos" ]; then
            print_status "ok" "Found Git repositories"
            for repo in $repos; do
                check_directory "$repo" "755" "git:git"
            done
        else
            print_status "warning" "No Git repositories found in /srv/git"
        fi
    else
        print_status "error" "Repository directory /srv/git does not exist"
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

