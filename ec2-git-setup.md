# Setting up a Git Repository on AWS EC2

This guide walks through setting up a git repository on an EC2 instance, including SSH access configuration and proper permissions setup.

## Prerequisites

- An EC2 instance running Ubuntu
- SSH access to the instance using a .pem key file
- Basic understanding of Git and SSH

## Understanding EC2 SSH Authentication

AWS EC2 instances use a special authentication mechanism called EC2 Instance Connect that can interfere with standard SSH authentication. Here's what you need to know:

1. EC2 Instance Connect:
   - AWS injects authorized SSH keys via a special command: `/usr/share/ec2-instance-connect/eic_run_authorized_keys`
   - This works for the default ubuntu user but can interfere with other users like git
   - The interference shows up in logs as: `AuthorizedKeysCommand failed, status 22`

2. Standard SSH Auth:
   - Normally looks for keys in `~/.ssh/authorized_keys`
   - Works well for git user requirements
   - Needs to be specifically configured to override EC2 Instance Connect

3. Solution:
   - Create a specific SSH config for git user
   - Disable EC2 Instance Connect for git user only
   - Keep EC2 Instance Connect working for ubuntu user

## 1. Initial EC2 Access

Connect to your EC2 instance using your .pem key:
```bash
ssh -i /path/to/your-key.pem ubuntu@your-ec2-ip
```

## 2. Setting up the Git User

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

## 3. Configure SSH Access

### Critical: Override EC2 Instance Connect for Git User

This is the most important step for making git user SSH access work:

```bash
# Create specific SSH config for git user
sudo nano /etc/ssh/sshd_config.d/git-user.conf
```

Add these lines:
```
Match User git
    AuthorizedKeysCommand none
    AuthorizedKeysFile %h/.ssh/authorized_keys
```

This configuration:
- Only applies to the git user
- Disables EC2 Instance Connect's key injection
- Uses standard SSH key authentication
- Preserves EC2 Instance Connect for ubuntu user

Restart SSH service:
```bash
sudo service ssh restart
```

### Set Up Authentication Keys

```bash
# Copy authorized_keys from ubuntu user to git user
sudo cp /home/ubuntu/.ssh/authorized_keys /home/git/.ssh/authorized_keys
sudo chown git:git /home/git/.ssh/authorized_keys
sudo chmod 600 /home/git/.ssh/authorized_keys
```

### On Local Machine

Create or edit `~/.ssh/config`:
```bash
Host ec2-git
    HostName your-ec2-ip
    User git
    IdentityFile /path/to/your-key.pem
    Port 22
```

## 4. Setting up the Git Repository

```bash
# Create repository directory
sudo mkdir -p /srv/git
sudo chown -R git:git /srv/git
sudo chmod 755 /srv/git

# Create the bare repository
cd /srv/git
sudo git init --bare your-repo-name.git
sudo chown -R git:git /srv/git/your-repo-name.git
```

## 5. Testing the Setup

From your local machine:
```bash
# Test SSH connection (will fail with "Connection closed" - this is normal)
ssh ec2-git

# Test Git access
git ls-remote git@your-ec2-ip:/srv/git/your-repo-name.git
```

## 6. Using the Repository

### Clone the Repository
```bash
git clone git@your-ec2-ip:/srv/git/your-repo-name.git
```

### Add Remote to Existing Repository
```bash
git remote add origin git@your-ec2-ip:/srv/git/your-repo-name.git
```

## 7. Troubleshooting

### Common EC2-Specific Issues

1. "AuthorizedKeysCommand failed, status 22"
   - EC2 Instance Connect is still enabled for git user
   - Check /etc/ssh/sshd_config.d/git-user.conf exists
   - Verify config syntax is correct

2. "Connection closed by authenticating user git [preauth]"
   - Normal for direct SSH attempts due to git-shell
   - Should still allow git commands

3. "Permission denied (publickey)"
   - Check key permissions
   - Verify authorized_keys content matches your .pem public key
   - Ensure git-user.conf is properly configured

### Permission Issues
Check these permissions if you encounter issues:
```bash
# On EC2 server
ls -la /home/git/.ssh  # Should be 700
ls -la /home/git/.ssh/authorized_keys  # Should be 600
ls -la /srv/git  # Should be 755
ls -la /srv/git/your-repo-name.git  # Should be owned by git:git
```

### Connection Issues
- Verify your local .pem file perm