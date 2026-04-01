# Debian Mirror & Frozen Patch Management (Ansible)

This repository provides an industry-standard Ansible-based solution for managing a local Debian mirror with **Frozen Patch Set** capabilities. It enables a controlled, predictable patching workflow by snapshotting the Debian repository at specific points in time, allowing you to test updates in UAT before promoting them to Production.

## 🚀 The Problem
Standard `apt upgrade` against public mirrors is non-deterministic. Running it today on UAT and next week on Production might install different package versions, leading to "works in UAT, breaks in Prod" scenarios.

## ✅ The Solution
This project implements a **Snapshot-based Patching Strategy**:
1. **Sync:** Sync a local mirror with upstream Debian repositories.
2. **Snapshot:** Create a time-stamped "Frozen" snapshot using hard links (storage efficient).
3. **UAT Test:** Point UAT servers to the new snapshot and run updates.
4. **Production Promotion:** Once validated, point Production servers to the *exact same* snapshot.

## 🏗️ Architecture
- **Ansible Control Node:** Orchestrates all operations.
- **Local Mirror Server:** Runs `apt-mirror` and hosts snapshots via Web Server (Nginx/Apache).
- **Target Nodes:** Debian servers categorized into `uat` and `prod` groups.

## 📁 Project Structure
```text
ansible-mirror-control/
├── ansible.cfg             # Ansible configuration
├── inventory/
│   └── hosts.ini           # Define mirror and target servers
├── playbooks/
│   ├── update_mirror.yml   # Sync local mirror with upstream
│   ├── snapshot-mirror.yml # Create storage-efficient snapshots
│   └── point-to-snapshot.yml # Update target nodes to use a snapshot
└── roles/                  # (Placeholder for future role extraction)
```

## ⚙️ Configuration

Before running any playbooks, you **must** update the following files with your server IP addresses:

1.  **`inventory/hosts.ini`**: Update `ansible_host` for each server group.
2.  **`group_vars/all.yml`**: Update `mirror_host` with the IP of your Debian mirror server.

## 🛠️ Usage

### 1. Sync the Local Mirror
Updates the base mirror files from upstream Debian.
```bash
ansible-playbook playbooks/update_mirror.yml
```

### 2. Create a Frozen Snapshot
Creates a hard-link copy of the current mirror. This is nearly instantaneous and consumes minimal additional disk space.
```bash
ansible-playbook playbooks/snapshot-mirror.yml
```
*Output will provide the snapshot date, e.g., `debian-2026-03-30`.*

### 3. Point Servers to Snapshot
Updates `/etc/apt/sources.list` on target nodes to use the specific local snapshot.
```bash
ansible-playbook playbooks/point-to-snapshot.yml -e "snapshot_date=2026-03-30"
```

## ⚙️ Prerequisites
- **Ansible** installed on the control node.
- **apt-mirror** installed and configured on the Mirror Server.
- A web server (Nginx/Apache) serving `/var/www/html/snapshots` on the Mirror Server.
- SSH access to all managed nodes.

## 🔒 Security & Best Practices
- **Backups:** `point-to-snapshot.yml` automatically creates backups of `sources.list`.
- **Traceability:** Adds a header comment to `sources.list` indicating the frozen patch set date.
- **Efficiency:** Uses `cp -al` for hard-link snapshots to avoid duplicating GBs of data.

---
*Created with Gemini CLI for professional DevOps workflows.*
