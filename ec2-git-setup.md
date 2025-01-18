# Complete Guide: Setting up Git Repository on AWS EC2

This comprehensive guide walks through setting up a git repository on an EC2 instance, including SSH access configuration, proper permissions setup, and troubleshooting common issues.

## Prerequisites

- An EC2 instance running Ubuntu
- SSH access to the instance using a .pem key file
- Basic understanding of Git and SSH

## Understanding EC2 SSH Authentication

AWS EC2 instances use a special authentication mechanism called EC2 Instance Connect that can interfere with standard SSH authentication. Here's what you need to know:

1. EC2 Instance Connect:
   - AWS injects authorized SSH keys via `/usr/share/ec2-instance-connect/eic_run_authorized_keys`
   - Works for ubuntu user but interferes with other users like git
   - Shows in logs as: `AuthorizedKeysCommand failed, status 22`

2. Standard SSH Auth:
   - Looks for keys in `~/.ssh/authorized_keys`
   - Required for git user functionality
   - Needs specific configuration to override EC2 Instance Connect

## Initial Setup

### 1. Connect to EC2
```bash
ssh -i /path/to/your-key.pem ubuntu@your-ec2-ip
```

### 2. Set Up Git User
```bash
# Create git user
sudo useradd -m git
sudo chsh git -s $(which git-shell)

# Set up SSH directory structure
sudo mkdir -p /home/git/.ssh
sudo mkdir -p /home/git/git-shell-commands

# Set proper ownership
sudo chown -R git:git /home/git
sudo chown -R git:git /home/git/.ssh
sudo chown -R git:git /home/git/git-shell-commands

# Set proper permissions
sudo chmod 755 /home/git
sudo chmod 700 /home/git/.ssh
sudo chmod 755 /home/git/git-shell-commands
```

### 3. Configure SSH Access for Git User

#### Critical: Override EC2 Instance Connect
```bash
# Create git user SSH config
sudo mkdir -p /etc/ssh/sshd_config.d
sudo nano /etc/ssh/sshd_config.d/git-user.conf
```

Add these lines:
```
Match User git
    AuthorizedKeysCommand none
    AuthorizedKeysFile %h/.ssh/authorized_keys
```

```bash
# Set proper permissions
sudo chmod 644 /etc/ssh/sshd_config.d/git-user.conf

# Restart SSH service
sudo service ssh restart
```

#### Set Up Authentication Keys
```bash
# Copy authorized_keys from ubuntu user
sudo cp /home/ubuntu/.ssh/authorized_keys /home/git/.ssh/authorized_keys
sudo chown git:git /home/git/.ssh/authorized_keys
sudo chmod 600 /home/git/.ssh/authorized_keys
```

### 4. Set Up Git Repository
```bash
# Create repository directory
sudo mkdir -p /srv/git
sudo chown -R git:git /srv/git
sudo chmod 755 /srv/git

# Create bare repository
cd /srv/git
sudo git init --bare your-repo-name.git
sudo chown -R git:git /srv/git/your-repo-name.git
```

## Local Machine Configuration

### 1. SSH Config Setup
Create or edit `~/.ssh/config`:
```bash
Host ec2-git
    HostName your-ec2-ip
    User git
    IdentityFile /path/to/your-key.pem
    Port 22
```

### 2. Test Connectivity
```bash
# Test SSH (will fail with "Connection closed" - this is normal)
ssh -v git@your-ec2-ip

# Test Git connectivity
GIT_SSH_COMMAND="ssh -i /path/to/your-key.pem" git ls-remote git@your-ec2-ip:/srv/git/your-repo-name.git
```

### 3. Initialize Local Repository
```bash
# Configure Git
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

# Create and initialize repository
mkdir project-name
cd project-name
git init
echo "# Project Name" > README.md
git add README.md
git commit -m "Initial commit"

# Add remote
git remote add origin git@your-ec2-ip:/srv/git/your-repo-name.git

# Push (using master branch)
GIT_SSH_COMMAND="ssh -i /path/to/your-key.pem" git push -u origin master

# Or if you prefer main branch
git branch -M main
GIT_SSH_COMMAND="ssh -i /path/to/your-key.pem" git push -u origin main
```

## Troubleshooting

### 1. Permission Issues
Check these permissions:
```bash
# On EC2 server
ls -la /home/git/.ssh  # Should be 700
ls -la /home/git/.ssh/authorized_keys  # Should be 600
ls -la /srv/git  # Should be 755
ls -la /srv/git/your-repo-name.git  # Should be owned by git:git
```

### 2. SSH Authentication Issues
Monitor SSH logs:
```bash
sudo tail -f /var/log/auth.log
```

Common error messages and solutions:

1. "Connection closed by authenticating user git [preauth]"
   - Check /etc/ssh/sshd_config.d/git-user.conf exists
   - Verify git-user.conf syntax
   - Restart SSH service

2. "AuthorizedKeysCommand failed, status 22"
   - EC2 Instance Connect interference
   - Check git-user.conf configuration
   - Verify SSH configuration

3. "Permission denied (publickey)"
   - Check key permissions
   - Verify authorized_keys content
   - Check SSH config syntax

### 3. Git Push Issues

1. "src refspec main does not match any"
   - Check current branch name: `git branch`
   - Ensure you have commits: `git log`
   - Use correct branch name (main or master)

2. "error: failed to push some refs"
   - Verify repository exists on server
   - Check repository permissions
   - Ensure correct remote URL

### 4. Debug Commands
```bash
# Test SSH with verbose output
ssh -vvv git@your-ec2-ip

# Test Git with SSH debugging
GIT_SSH_COMMAND="ssh -vvv" git ls-remote git@your-ec2-ip:/srv/git/your-repo-name.git

# Check SSH process
ps aux | grep sshd

# Verify git shell
grep git /etc/passwd
```

## Maintenance

### Monitor Access
```bash
# Check SSH logs
sudo journalctl -u ssh
sudo tail -f /var/log/auth.log
```

### Repository Maintenance
```bash
# On EC2 server
cd /srv/git/your-repo-name.git
git gc --aggressive
git fsck
```

### Backup Repository
```bash
cd /srv/git
tar -czf backup-repos.tar.gz *.git
```

## Security Best Practices

1. Keep .pem file secure (chmod 600)
2. Use specific IP ranges in EC2 security groups
3. Regularly update Ubuntu packages
4. Monitor SSH access logs
5. Keep git-shell-commands directory properly configured
6. Use SSH key rotation
7. Maintain proper file permissions

## Reference Commands

### Permission Verification
```bash
# Check all key permissions
ls -la ~/.ssh/
ls -la /path/to/your-key.pem  # Should be 600

# Check repository permissions
ls -la /srv/git/
ls -la /srv/git/your-repo-name.git/
```

### SSH Configuration
```bash
# Check SSH configurations
sudo cat /etc/ssh/sshd_config
sudo ls -la /etc/ssh/sshd_config.d/

# Restart SSH service
sudo service ssh restart
```
