# Infrastructure Setup & Snapshot Guide

This guide details the steps to prepare your environment and manage Debian snapshots using this Ansible project.

## 1. Remote Node Preparation

To allow Ansible to manage your servers, you should use a dedicated `ansible` user with passwordless sudo access.

### Create the Ansible User
Run these commands on **each remote server**:
```bash
# Create the user
sudo adduser ansible --gecos "" --disabled-password

# Give the user a password (temporary, for initial SSH copy)
echo "ansible:InitialPassword123" | sudo chpasswd
```

### Enable Passwordless Sudo
Allow the `ansible` user to run commands as root without a password prompt:
```bash
echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/apt/sudoers.d/ansible
sudo chmod 0440 /etc/apt/sudoers.d/ansible
```

---

## 2. Passwordless SSH Setup

From your **Ansible Control Node**, set up SSH key-based authentication.

### Generate SSH Key
If you don't already have one:
```bash
ssh-keygen -t ed25519 -C "ansible-control-node"
```

### Distribute the Key
Copy your public key to each managed server:
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub ansible@X.X.X.X
```
*Replace `X.X.X.X` with the server's IP. You will be prompted for the `ansible` user's password once.*

### Verify Connection
```bash
ssh ansible@X.X.X.X
# You should log in without a password.
```

---

## 3. How to Create a Debian Snapshot

Snapshots are created on the **Mirror Server** to provide a "frozen" set of packages for testing.

### Step 1: Sync the Mirror
Ensure your local mirror has the latest packages from Debian's official servers.
```bash
ansible-playbook playbooks/update_mirror.yml
```

### Step 2: Create the Snapshot
Run the snapshot playbook. It uses hard links to minimize disk space usage.
```bash
ansible-playbook playbooks/snapshot-mirror.yml
```
This will create a directory like `/var/www/html/snapshots/debian-2026-03-30`.

### Step 3: Promote to UAT
Update your UAT servers to point to this specific snapshot.
```bash
ansible-playbook playbooks/point-to-snapshot.yml -e "snapshot_date=2026-03-30" --limit uat
```

### Step 4: Promote to Production
After testing in UAT, promote the **same** snapshot to production.
```bash
ansible-playbook playbooks/point-to-snapshot.yml -e "snapshot_date=2026-03-30" --limit prod
```

---

## 🔒 Security Note
This project now has **Host Key Checking** enabled. If you see an "Identity has changed" error, it means the server's fingerprint does not match your `known_hosts`. Investigate this before bypassing it!
