[![Version](https://img.shields.io/badge/version-2.4.0-blue.svg)](https://github.com/xxphantom/remnawave-installer)
[![Language](https://img.shields.io/badge/language-Bash-green.svg)]()
[![OS Support](https://img.shields.io/badge/OS-Ubuntu-orange.svg)]()

[Читать на русском](README.ru.md)

Automated installer for [Remnawave Panel](https://docs.rw/) — VPN/proxy management system with Docker and Caddy.

> [!CAUTION]
> This script is provided as an **educational example**. It is not intended for production use without full understanding of Remnawave configurations. **USE AT YOUR OWN RISK!**

## Quick Start

```bash
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/xxphantom/remnawave-installer/main/install.sh)" @ --lang=en
```

## Features

- **Installation modes**: Panel Only, Node Only, All-in-One
- **Access protection**: Cookie security or Full Caddy authentication (2FA)
- **Auto-setup**: Docker, Caddy, UFW, PostgreSQL, Redis
- **Management**: Updates, restart, removal, credentials backup
- **Tools**: WARP integration, BBR control, Rescue CLI, Logs viewer
- **Emergency access**: Direct panel access on port 8443 (All-in-One)

## Requirements

- **OS**: Ubuntu 22.04+ or Debian
- **Access**: Root privileges
- **Domains**: 3 unique domains with DNS A-records pointing to your server
- **Ports**: 80, 443, SSH must be available

## Installation Modes

| Mode | Use Case |
|------|----------|
| **Panel Only** | Management panel on dedicated server |
| **Node Only** | Proxy node on separate server |
| **All-in-One** | Panel + Node on single server |

## Command Line Options

```bash
--lang=en|ru              # Interface language
--panel-branch=VERSION    # Panel version: main, dev, alpha, or X.Y.Z
--installer-branch=BRANCH # Installer branch: main or dev
--keep-caddy-data         # Preserve certificates during reinstall
```

The `main` mode installs [backend 3.4.3](https://github.com/remnawave/backend/releases/tag/3.4.3), [node 3.4.1](https://github.com/remnawave/node/releases/tag/3.4.1), and [subscription-page 8.0.0](https://github.com/remnawave/subscription-page/tree/8.0.0). The `.env` template comes from the same release as the panel image.

The update menu uses the versions listed in the installer and keeps newer numeric tags. Download the current installer before updating your components.

If you keep the panel on 2.x, node and subscription-page tags set to `latest` change to 2.8.0 and 7.2.6. Upgrading to 3.x also updates the node and subscription page on the same server. Before upgrading a separate node, the script asks you to confirm that its remote panel already runs 3.x.

New REALITY configurations use `minClientVer: "0.0.0"` to allow mihomo, sing-box, and older Xray clients to connect. During a panel update, the script offers to add this setting to profiles without a minimum version. Existing version settings stay unchanged. [Xray warns](https://github.com/XTLS/Xray-core/blob/v26.7.28/infra/conf/transport_security.go) that removing this restriction increases the risk of the server IP being blocked by the GFW.

**Examples:**
```bash
# Use specific panel version
sudo bash -c "$(curl -sL ...)" @ --lang=en --panel-branch=3.4.3

# Dev version
sudo bash -c "$(curl -sL ...)" @ --lang=en --panel-branch=dev
```

## After Installation

**Credentials:** `/opt/remnawave/credentials.txt`

**Service management:**
```bash
cd /opt/remnawave
make start    # Start and show logs
make stop     # Stop services
make restart  # Restart services
make logs     # View logs
```

## Documentation

- [Architecture & Installation Scenarios](docs/ARCHITECTURE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Links

- [Remnawave Documentation](https://docs.rw/)
- [Telegram Channel](https://t.me/remnawave)
- [Telegram Group](https://t.me/+xQs17zMzwCY1NzYy)
- [Updates](https://t.me/remnalog)

---

Script questions: [@xxphantom](https://t.me/uphantom)
