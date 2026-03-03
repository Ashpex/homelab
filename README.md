# Homeserver Infrastructure as Code

This repository contains an Ansible-based Infrastructure as Code (IaC) solution for deploying and managing Docker services on your homeserver.

## Features

- **Automated Deployment**: One-command deployment of all services
- **Configurable Paths**: All paths are variables, no hardcoded values
- **Secure Secrets**: Ansible Vault for sensitive data
- **Easy Updates**: Update all services with a single command
- **Service Management**: Start, stop, restart individual or all services
- **Individual Service Deployment**: Deploy single services quickly
- **Service-specific Tasks**: Backup, restore, and maintenance operations

## Quick Start

### Prerequisites Installation

```bash
# Minimal local setup (Ansible, helpers)
make init

# One-time host provisioning (Docker, utilities, optional)
make bootstrap
```

**Manual installation** (if preferred):
- **Docker & Docker Compose** on your homeserver
- **Ansible** on your local machine or homeserver
- **Git** for version control
- **community.docker** Ansible collection: `ansible-galaxy collection install -r requirements.yml`

### Initial Setup

1. **Configure your paths** in `inventory/hosts.yml`:
   ```yaml
   # Customize these paths for your setup
   root_path: "/mnt/hdd1/"
   base_data_path: "/mnt/hdd1/infra-data"  # Main data storage
   media_path: "/mnt/hdd1/media"           # Media files
   downloads_path: "/mnt/ssd/downloads"    # Download location
   nvr_path: "/mnt/hdd1/nvr"              # Security camera storage
   docker_network: "media"                 # Docker network name
   ```

   Note: `user_id` and `group_id` are resolved dynamically at runtime via `id -u` and `id -g`.

2. **Set up encrypted secrets**:
   ```bash
   # Create/edit the vault file (interactive)
   make setup-vault
   ```

3. **Configure services** in `group_vars/all/services.yml`:
   - Enable/disable services by setting `enabled: true/false`
   - Adjust ports, paths, images, and other settings

### Basic Usage

```bash
# Deploy all enabled services
make deploy

# Deploy a specific service
make deploy-service jellyfin

# Update all services to latest images
make update

# Update a specific service
make update-service jellyfin

# Stop all services
make stop

# Restart a specific service
make restart-service immich

# View logs for a specific service
make logs-service romm

# Show running containers
make status
```

## Available Services

Currently supported services:

| Service | Description | Default Port | Status |
|---------|-------------|--------------|--------|
| **AdGuard** | Network-wide ad blocking | 8081 | Enabled |
| **Alist** | File manager and sharing | 8083 | Enabled |
| **ARR Stack** | Sonarr, Radarr, Prowlarr | 8989, 7878, 9696 | Disabled |
| **Audiobookshelf** | Audiobook and podcast server | 13378 | Enabled |
| **Authelia** | Authentication and authorization | 9091 | Enabled |
| **Backrest** | Backup solution with restic | 9898 | Disabled |
| **Copyparty** | File sharing server | 3923 | Enabled |
| **Forgejo** | Self-hosted Git service | 8087 | Enabled |
| **Frigate** | NVR for security cameras | 8971 | Disabled |
| **Glance** | Dashboard and monitoring | 8090 | Enabled |
| **Gotify** | Push notification server | 8888 | Enabled |
| **Immich** | Photo management (Google Photos alternative) | 2283 | Enabled |
| **Jellyfin** | Media server | 8096 | Enabled |
| **qBittorrent** | BitTorrent client | 8084 | Enabled |
| **RomM** | ROM management with metadata | 8086 | Enabled |
| **Traefik** | Reverse proxy | 80/443/8080 | Enabled |
| **Waline** | Comment system | 8360 | Enabled |
| **Watchtower** | Auto-update containers | 8085 | Enabled |

## Configuration

### Service Configuration

Edit `group_vars/all/services.yml` to configure your services:

```yaml
services:
  jellyfin:
    enabled: true
    image: "jellyfin/jellyfin:latest"   # Centralized image reference
    port: 8096                          # Single-port services use 'port'
    config_path: "{{ base_data_path }}/jellyfin/config"
    cache_path: "{{ base_data_path }}/jellyfin/cache"
    media_path: "{{ media_path }}"

  adguard:
    enabled: true
    image: "adguard/adguardhome:latest"
    web_port: 8081                      # Multi-port services use prefixed names
    dns_port: 53
    data_path: "{{ base_data_path }}/adguard"
```

**Port naming convention:**
- `port` — for services with a single port
- `web_port`, `dns_port`, `torrent_port`, etc. — for services with multiple ports

### Path Management

All paths are variables defined in `inventory/hosts.yml`:

- `base_data_path`: Main application data storage
- `media_path`: Media files (videos, music, photos, ROMs)
- `downloads_path`: Download directory
- `nvr_path`: NVR/security camera storage

### Secrets Management

Sensitive data is encrypted using Ansible Vault in `group_vars/all/vault.yml`:

```yaml
# Example vault variables (encrypted)
vault_immich_db_password: "your_secure_password"
vault_romm_db_password: "your_secure_password"
vault_romm_auth_secret_key: "your_secret_key"
vault_romm_igdb_client_id: "your_igdb_client_id"
vault_romm_igdb_client_secret: "your_igdb_client_secret"
vault_romm_retroachievements_api_key: "your_retroachievements_api_key"
```

## Advanced Usage

### Individual Service Management

```bash
# Single-service deploys
make deploy-service immich
make deploy-service romm

# Update a single service
make update-service jellyfin

# Restart individual services
make restart-service jellyfin

# View logs for specific services
make logs-service frigate

# Stop individual services
make stop-service qbittorrent
```

### Custom Variables

Override variables at runtime:

```bash
# Use different data path temporarily
ansible-playbook playbooks/deploy.yml -e base_data_path=/tmp/test-data --ask-vault-pass --ask-become-pass

# Deploy with specific vault password file
ansible-playbook playbooks/deploy.yml --vault-password-file .vault_pass --ask-become-pass
```

## Project Structure

```
homelab/
├── ansible.cfg              # Ansible configuration
├── Makefile                 # Convenient command shortcuts
├── requirements.yml         # Ansible collection dependencies
├── inventory/
│   └── hosts.yml           # Server inventory and variables
├── group_vars/all/
│   ├── services.yml        # Service configurations (single source of truth)
│   └── vault.yml           # Encrypted secrets (Ansible Vault)
├── roles/                  # Role-based automation
│   ├── bootstrap/          # One-time host provisioning (Docker, utils)
│   ├── docker/             # Ensure Docker/Compose, network
│   ├── common/             # Base dirs, timezone, sanity checks
│   ├── service/            # Generic per-service compose/config/deploy
│   ├── health/             # System/storage diagnostics
│   ├── raid/               # RAID array management
│   └── zfs/                # ZFS pool/dataset management
├── templates/services/     # Jinja2 templates for Docker Compose
│   ├── jellyfin.yml.j2
│   ├── romm.yml.j2
│   └── ...
├── configs/               # Configuration files
│   ├── traefik/
│   │   ├── traefik.yml.j2            # Static config (Jinja2 template)
│   │   └── dynamic/middleware.yml    # Dynamic middleware
│   ├── glance/glance.yml            # Static config (copied as-is)
│   ├── backrest/excludes.txt
│   └── romm/config.yml
├── playbooks/            # Ansible playbooks
│   ├── deploy.yml        # Main logic (roles + service loop)
│   ├── update.yml        # Pull latest images and recreate
│   ├── stop.yml          # Stop services
│   ├── bootstrap.yml     # One-time host setup
│   ├── health.yml        # System diagnostics
│   ├── raid.yml          # RAID configuration
│   └── zfs.yml           # ZFS configuration
├── scripts/             # Helper scripts
│   ├── init.sh         # System setup script
│   ├── backup-romm.sh  # RomM backup script
│   └── restore-romm.sh # RomM restore script
└── build/              # Generated Docker Compose files (gitignored)
    └── services/
        ├── jellyfin/
        ├── romm/
        └── ...
```

## Migration from Docker Compose

If you're migrating from individual Docker Compose setups:

1. **Backup your current data** (important!)
2. **Stop existing containers**:
   ```bash
   cd /path/to/old/setup
   docker compose down
   ```
3. **Update paths** in `inventory/hosts.yml` to match your current data locations
4. **Configure and enable services** in `group_vars/all/services.yml`
5. **Set up vault** with your existing passwords/secrets
6. **Test with dry run**: `make dry-run`
7. **Deploy**: `make deploy`
8. **Verify services** are working correctly
9. **Clean up old directories** if desired

## Troubleshooting

### Common Issues

1. **Permission errors**:
   - `user_id` and `group_id` are resolved dynamically — verify with `id -u` and `id -g`
   - Some services (like RomM) may need to run as root for volume permissions

2. **Port conflicts**:
   - Adjust ports in `group_vars/all/services.yml`
   - Check for conflicts: `sudo netstat -tlnp | grep :PORT`

3. **Path not found**:
   - Verify all paths in `inventory/hosts.yml` exist
   - Check directory permissions: `ls -la /mnt/hdd1/`

4. **Vault password errors**:
   - Create `.vault_pass` file with your password
   - Or use `--ask-vault-pass` flag
   - Edit vault: `ansible-vault edit group_vars/all/vault.yml`

5. **Service-specific issues**:
   - **RomM**: Database migration failures usually indicate permission issues
   - **Frigate**: Requires compatible hardware for object detection
   - **Immich**: Machine learning requires significant resources

### Debugging Commands

```bash
# Check container status
make status

# View specific service logs
make logs-service romm

# Test service connectivity
curl -I http://localhost:8096  # Jellyfin
curl -I http://localhost:2283  # Immich

# Check generated compose files
ls -la build/services/

# Validate configuration
make validate

# Check Docker resources
docker system df
```

## Maintenance

### Regular Tasks

```bash
# Weekly: Update all services
make update

# Monthly: Clean up unused resources
make clean
```

### Adding New Services

For detailed instructions on adding new services, see [Adding Services Guide](docs/ADDING-SERVICES.md).

Quick overview:
1. Add configuration (with `image` field) to `group_vars/all/services.yml`
2. Create Docker Compose template in `templates/services/servicename.yml.j2`
3. Add secrets to `group_vars/all/vault.yml` (if needed)
4. Create config files in `configs/servicename/` (if needed)
5. Test deployment: `make deploy-service servicename`
6. The service URL display is generated automatically — no manual update needed

### Database Backups

For services with databases, run the backup scripts directly:

```bash
# RomM database backup
./scripts/backup-romm.sh

# RomM database restore
./scripts/restore-romm.sh backup-file.sql
```

## Traefik Reverse Proxy

This setup includes Traefik as a reverse proxy. With Cloudflare Tunnel, TLS terminates at Cloudflare; Traefik's internal ACME is disabled in this repo.

**Features:**
- HTTPS via Cloudflare Tunnel (no ACME in Traefik)
- Security headers and compression
- Rate limiting and circuit breaker patterns
- Cloudflare integration support

**Configuration:**
- Static config: `configs/traefik/traefik.yml.j2`
- Dynamic middleware: `configs/traefik/dynamic/middleware.yml`
- Service domains: Configured in `group_vars/all/services.yml`

**Documentation:**
- [Traefik Integration Guide](docs/TRAEFIK-INTEGRATION.md)
- [Traefik Best Practices](docs/TRAEFIK-BEST-PRACTICES.md)
- [Ansible Roles Guide](docs/ANSIBLE-ROLES.md)

**Access:**
- Dashboard: `http://localhost:8080` (local only)
- Services: `https://service.ashpex.net` (via domain)

## Security Considerations

- **Vault encryption**: All sensitive data is encrypted with Ansible Vault
- **Network isolation**: Services communicate through a dedicated Docker network
- **User permissions**: Most services run as your user, not root (except where required)
- **TLS via Cloudflare**: TLS terminates at Cloudflare Tunnel (Traefik ACME disabled in this setup)
- **Security headers**: OWASP-recommended headers applied via Traefik middleware
- **Firewall**: Configure your firewall to restrict external access as needed

## Performance Tips

- **SSD for databases**: Store database files on SSD when possible
- **Resource limits**: Set appropriate memory limits in service configurations
- **Monitoring**: Use Glance dashboard to monitor system resources
- **Log rotation**: Configure Docker log rotation to prevent disk filling

## Contributing

Contributions welcome! Please:

1. Test changes with `make dry-run`
2. Update documentation for new services
3. Follow existing naming conventions
4. Encrypt sensitive data in vault.yml

## License

This project is open source. Use it freely for your homeserver setup.

---

**Need help?** Check the troubleshooting section above or review the generated files in `build/services/` to debug issues.
