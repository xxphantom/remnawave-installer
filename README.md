[![Version](https://img.shields.io/badge/version-2.1.1-blue.svg)](https://github.com/xxphantom/remnawave-installer)
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

**Examples:**
```bash
# Use specific panel version
sudo bash -c "$(curl -sL ...)" @ --lang=en --panel-branch=2.0.1

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
