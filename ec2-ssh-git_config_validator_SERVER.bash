#!/bin/bash
# remote_validator.sh
# Validates remote server permissions for Git over SSH

check_remote_permissions() {
    local has_errors=0
    
    echo "=== Checking Remote Server Permissions ==="
    echo

    # Check git user exists and shell
    echo "Checking git user configuration..."
    if ! id git >/dev/null 2>&1; then
        echo "❌ git user does not exist"
        has_errors=1
    else
        echo "✅ git user exists"
        
        # Check git user shell
        local git_shell=$(grep git /etc/passwd | cut -d: -f7)
        if [[ "$git_shell" != *"git-shell"* ]]; then
            echo "❌ git user should use git-shell, found: $git_shell"
            has_errors=1
        else
            echo "✅ git user shell correct (git-shell)"
        fi
    fi

    # Check git user home directory
    echo -e "\nChecking git user home directory..."
    if [ ! -d /home/git ]; then
        echo "❌ /home/git directory does not exist"
        has_errors=1
    else
        local home_perms=$(stat -c "%a" /home/git)
        local home_owner=$(stat -c "%U:%G" /home/git)
        
        if [ "$home_perms" != "755" ]; then
            echo "❌ /home/git permissions should be 755, found: $home_perms"
            has_errors=1
        else
            echo "✅ /home/git permissions correct (755)"
        fi
        
        if [ "$home_owner" != "git:git" ]; then
            echo "❌ /home/git ownership should be git:git, found: $home_owner"
            has_errors=1
        else
            echo "✅ /home/git ownership correct (git:git)"
        fi
    fi

    # Check .ssh directory
    echo -e "\nChecking .ssh directory..."
    if [ ! -d /home/git/.ssh ]; then
        echo "❌ /home/git/.ssh directory does not exist"
        has_errors=1
    else
        local ssh_perms=$(stat -c "%a" /home/git/.ssh)
        local ssh_owner=$(stat -c "%U:%G" /home/git/.ssh)
        
        if [ "$ssh_perms" != "700" ]; then
            echo "❌ /home/git/.ssh permissions should be 700, found: $ssh_perms"
            has_errors=1
        else
            echo "✅ /home/git/.ssh permissions correct (700)"
        fi
        
        if [ "$ssh_owner" != "git:git" ]; then
            echo "❌ /home/git/.ssh ownership should be git:git, found: $ssh_owner"
            has_errors=1
        else
            echo "✅ /home/git/.ssh ownership correct (git:git)"
        fi
    fi

    # Check authorized_keys
    echo -e "\nChecking authorized_keys..."
    if [ ! -f /home/git/.ssh/authorized_keys ]; then
        echo "❌ authorized_keys file does not exist"
        has_errors=1
    else
        local auth_perms=$(stat -c "%a" /home/git/.ssh/authorized_keys)
        local auth_owner=$(stat -c "%U:%G" /home/git/.ssh/authorized_keys)
        
        if [ "$auth_perms" != "600" ]; then
            echo "❌ authorized_keys permissions should be 600, found: $auth_perms"
            has_errors=1
        else
            echo "✅ authorized_keys permissions correct (600)"
        fi
        
        if [ "$auth_owner" != "git:git" ]; then
            echo "❌ authorized_keys ownership should be git:git, found: $auth_owner"
            has_errors=1
        else
            echo "✅ authorized_keys ownership correct (git:git)"
        fi
    fi

    # Check git-shell-commands directory
    echo -e "\nChecking git-shell-commands..."
    if [ ! -d /home/git/git-shell-commands ]; then
        echo "❌ git-shell-commands directory does not exist"
        has_errors=1
    else
        local cmd_perms=$(stat -c "%a" /home/git/git-shell-commands)
        local cmd_owner=$(stat -c "%U:%G" /home/git/git-shell-commands)
        
        if [ "$cmd_perms" != "755" ]; then
            echo "❌ git-shell-commands permissions should be 755, found: $cmd_perms"
            has_errors=1
        else
            echo "✅ git-shell-commands permissions correct (755)"
        fi
        
        if [ "$cmd_owner" != "git:git" ]; then
            echo "❌ git-shell-commands ownership should be git:git, found: $cmd_owner"
            has_errors=1
        else
            echo "✅ git-shell-commands ownership correct (git:git)"
        fi
    fi

    # Check /srv/git directory
    echo -e "\nChecking /srv/git directory..."
    if [ ! -d /srv/git ]; then
        echo "❌ /srv/git directory does not exist"
        has_errors=1
    else
        local srv_perms=$(stat -c "%a" /srv/git)
        local srv_owner=$(stat -c "%U:%G" /srv/git)
        
        if [ "$srv_perms" != "755" ]; then
            echo "❌ /srv/git permissions should be 755, found: $srv_perms"
            has_errors=1
        else
            echo "✅ /srv/git permissions correct (755)"
        fi
        
        if [ "$srv_owner" != "git:git" ]; then
            echo "❌ /srv/git ownership should be git:git, found: $srv_owner"
            has_errors=1
        else
            echo "✅ /srv/git ownership correct (git:git)"
        fi
    fi

    # Check EC2 Instance Connect configuration
    echo -e "\nChecking EC2 Instance Connect configuration..."
    if [ ! -f /etc/ssh/sshd_config.d/git-user.conf ]; then
        echo "❌ git user SSH config not found"
        has_errors=1
    else
        if ! grep -q "Match User git" /etc/ssh/sshd_config.d/git-user.conf; then
            echo "❌ git user SSH configuration incomplete"
            has_errors=1
        else
            echo "✅ git user SSH configuration found"
        fi
    fi

    echo
    if [ $has_errors -eq 1 ]; then
        echo "❌ Found permission issues that need to be fixed"
        return 1
    else
        echo "✅ All remote permissions are correct"
        return 0
    fi
}

# Must be run as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

check_remote_permissions


