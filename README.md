# Debian Mirror & Frozen Patch Management with Ansible

[![CI](https://github.com/wazaglo/ansible-mirror-control/actions/workflows/ci.yml/badge.svg)](https://github.com/wazaglo/ansible-mirror-control/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ansible](https://img.shields.io/badge/Ansible-%23EE0000.svg?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Debian](https://img.shields.io/badge/Debian-A81D33?logo=debian&logoColor=white)](https://www.debian.org/)

Deterministic, snapshot-based patching for Debian environments using Ansible. Eliminates the "works in UAT, breaks in Prod" problem caused by non-deterministic upstream mirrors.

---

## The Problem

Running `apt upgrade` against public mirrors is non-deterministic. The same command executed today on UAT and next week on Production may install different package versions, leading to untestable, unreproducible deployments.

## The Solution

A **snapshot-based patching strategy** that freezes the package repository at a known point in time:

1. **Sync** - Mirror upstream Debian repositories to a local server
2. **Snapshot** - Create a timestamped, storage-efficient hard-link snapshot
3. **Test** - Point UAT servers to the snapshot and validate updates
4. **Promote** - Point Production servers to the *exact same* snapshot

---

## Architecture

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Ansible Control  │────▶   Mirror Server   │────▶   Target Nodes    │
│      Node         │     │  (apt-mirror +   │     │  (UAT / Prod)     │
│                   │     │   Nginx/Apache)  │     │                   │
│  Orchestrates     │     │  /var/apt-mirror │     │  /etc/apt/sources │
│  all operations   │     │  /var/www/snap   │     │  .list → snapshot │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

## Project Structure

```
ansible-mirror-control/
├── .github/workflows/ci.yml   # Automated linting & syntax checks
├── .ansible-lint               # Ansible lint rules
├── .yamllint                   # YAML lint rules
├── ansible.cfg                 # Ansible configuration
├── inventory/
│   └── hosts.ini               # Server inventory (mirror, uat, prod)
├── group_vars/
│   └── all.yml                 # Global variables (mirror_host)
├── playbooks/
│   ├── update_mirror.yml       # Sync upstream repository
│   ├── snapshot-mirror.yml     # Create frozen snapshots
│   └── point-to-snapshot.yml   # Apply snapshot to targets
├── requirements.yml            # Ansible collection dependencies
├── Makefile                    # Common task shortcuts
├── SETUP_GUIDE.md              # Step-by-step infrastructure setup
└── LICENSE                     # MIT License
```

---

## Prerequisites

- Ansible control node with SSH access to all servers
- Debian 12+ mirror server with `apt-mirror` installed
- Web server (Nginx/Apache) serving `/var/www/html/snapshots`
- Debian 12+ target nodes (UAT/Production)

## Quick Start

### 1. Configure Inventory

Edit `inventory/hosts.ini` with your server IPs:

```ini
[mirror]
mirror-01 ansible_host=10.0.0.10

[uat]
uat-01 ansible_host=10.0.0.20

[prod]
prod-01 ansible_host=10.0.0.30
```

### 2. Set Global Variables

Edit `group_vars/all.yml`:

```yaml
mirror_host: "10.0.0.10"
```

### 3. Sync the Mirror

```bash
ansible-playbook playbooks/update_mirror.yml
```

### 4. Create a Snapshot

```bash
ansible-playbook playbooks/snapshot-mirror.yml
```

### 5. Apply Snapshot to UAT

```bash
ansible-playbook playbooks/point-to-snapshot.yml -e "snapshot_date=2026-07-15" --limit uat
```

### 6. Promote to Production

```bash
ansible-playbook playbooks/point-to-snapshot.yml -e "snapshot_date=2026-07-15" --limit prod
```

---

## Development

```bash
make lint          # Run ansible-lint
make yamllint      # Run YAML linting
make syntax-check  # Validate all playbook syntax
make all           # Run all checks
```

---

## Security & Best Practices

- **Host key checking** enabled in `ansible.cfg`
- **Automatic backups** of `sources.list` before modification
- **Traceability**: each `sources.list` includes a header with the snapshot date
- **Storage efficiency**: snapshots use hard links (`cp -al`), not full copies
- **Idempotent playbooks**: safe to run multiple times

---

## License

[MIT](LICENSE) © 2026 Wisdom Azaglo
