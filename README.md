# Homeserver Infrastructure as Code

This repository contains an Ansible-based Infrastructure as Code (IaC) solution for deploying and managing Docker services on your homeserver.

## Features

- 🚀 **Automated Deployment**: One-command deployment of all services
- 🔧 **Configurable Paths**: No more hardcoded `/mnt/hdd1/` paths
- 🔐 **Secure Secrets**: Ansible Vault for sensitive data
- 🔄 **Easy Updates**: Update all services with a single command
- 📊 **Service Management**: Start, stop, restart individual or all services
- 🎯 **Individual Service Deployment**: Deploy single services quickly
- 🛠️ **Service-specific Tasks**: Backup, restore, and maintenance operations

## Quick Start

### Prerequisites Installation

Use the automated installation script to set up all required tools:

```bash
# Install Docker, Ansible, Git, Tailscale, and utilities
make init

# Set up project structure and configuration
make setup
```

**Manual installation** (if preferred):
- **Docker & Docker Compose** on your homeserver
- **Ansible** on your local machine or homeserver
- **Git** for version control

### Initial Setup

1. **Configure your paths** in `inventory/hosts.yml`:
   ```yaml
   # Customize these paths for your setup
   base_data_path: "/mnt/hdd1/infra-data"  # Main data storage
   media_path: "/mnt/hdd1/media"           # Media files
   downloads_path: "/mnt/ssd/downloads"    # Download location
   nvr_path: "/mnt/hdd1/nvr"              # Security camera storage
   user_id: 1000                          # Your user ID
   group_id: 1000                         # Your group ID
   docker_network: "homelab"              # Docker network name
   ```

2. **Set up encrypted secrets**:
   ```bash
   # The setup script will guide you through vault creation
   make setup
   ```

3. **Configure services** in `group_vars/all/services.yml`:
   - Enable/disable services by setting `enabled: true/false`
   - Adjust ports, paths, and other settings

### Basic Usage

```bash
# Deploy all enabled services
make deploy

# Deploy a specific service
make deploy-service jellyfin

# Update all services to latest versions
make update

# Stop all services
make stop

# Restart a specific service
make restart-service immich

# View logs for all services
make logs

# View logs for a specific service
make logs-service romm

# Show running containers
make status

# Access service-specific tasks (backup, restore, etc.)
make tasks
```

## Available Services

Currently supported services:

| Service | Description | Default Port | Status |
|---------|-------------|--------------|--------|
| **AdGuard** | Network-wide ad blocking | 3000 | ✅ |
| **Alist** | File manager and sharing | 5244 | ✅ |
| **ARR Stack** | Sonarr, Radarr, etc. | 8989, 7878 | ✅ |
| **Audiobookshelf** | Audiobook and podcast server | 13378 | ✅ |
| **Backrest** | Backup solution with restic | 9898 | ✅ |
| **Copyparty** | File sharing server | 3923 | ✅ |
| **Frigate** | NVR for security cameras | 8971 | ✅ |
| **Glance** | Dashboard and monitoring | 8083 | ✅ |
| **Gotify** | Push notification server | 8080 | ✅ |
| **Immich** | Photo management (Google Photos alternative) | 2283 | ✅ |
| **Jellyfin** | Media server | 8096 | ✅ |
| **Owncast** | Live streaming server | 8085 | ✅ |
| **qBittorrent** | BitTorrent client | 8084 | ✅ |
| **RomM** | ROM management with metadata | 8086 | ✅ |
| **Samba** | File sharing | 445 | ✅ |
| **Waline** | Comment system | 8360 | ✅ |
| **Watchtower** | Auto-update containers | N/A | ✅ |

## Configuration

### Service Configuration

Edit `group_vars/all/services.yml` to configure your services:

```yaml
services:
  jellyfin:
    enabled: true                    # Enable/disable service
    web_port: 8096                  # Port mapping
    config_path: "{{ base_data_path }}/jellyfin/config"
    cache_path: "{{ base_data_path }}/jellyfin/cache"
    media_path: "{{ media_path }}"  # Uses variable from inventory
    
  romm:
    enabled: true
    web_port: 8086
    library_path: "{{ media_path }}/roms"    # Your ROM collection
    assets_path: "{{ base_data_path }}/romm/assets"     # Saves, states
    config_path: "{{ base_data_path }}/romm/config"     # Configuration
    db_name: "romm"
    db_user: "romm-user"
```

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
vault_samba_username: "your_username"  
vault_samba_password: "your_secure_password"
```

## Advanced Usage

### Individual Service Management

```bash
# Deploy only specific services
make deploy-service immich
make deploy-service romm

# Restart individual services
make restart-service jellyfin

# View logs for specific services
make logs-service frigate

# Stop individual services
make stop-service qbittorrent
```

### Service-specific Tasks

Access additional operations through the interactive tasks menu:

```bash
make tasks
# Choose from:
# 1. Backup RomM database
# 2. Restore RomM database
# (More tasks added as services require them)
```

### Custom Variables

Override variables at runtime:

```bash
# Use different data path temporarily
ansible-playbook playbooks/deploy.yml -e base_data_path=/tmp/test-data

# Deploy with specific vault password file
ansible-playbook playbooks/deploy.yml --vault-password-file .vault_pass
```

## Project Structure

```
stacks/
├── ansible.cfg              # Ansible configuration
├── Makefile                 # Convenient command shortcuts
├── inventory/
│   └── hosts.yml           # Server inventory and variables
├── group_vars/all/
│   ├── services.yml        # Service configurations
│   └── vault.yml           # Encrypted secrets (Ansible Vault)
├── templates/services/     # Jinja2 templates for Docker Compose
│   ├── jellyfin.yml.j2
│   ├── romm.yml.j2
│   └── ...
├── configs/               # Static configuration files
│   ├── glance/glance.yml
│   ├── backrest/excludes.txt
│   └── romm/config.yml
├── playbooks/            # Ansible playbooks
│   ├── deploy.yml
│   ├── update.yml
│   └── stop.yml
├── scripts/             # Helper scripts
│   ├── init.sh         # System setup script
│   ├── tasks.sh        # Interactive tasks menu
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
   - Check `user_id` and `group_id` in `inventory/hosts.yml`
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

1. Add service configuration to `group_vars/all/services.yml`
2. Create Docker Compose template in `templates/services/servicename.yml.j2`
3. Add any required vault variables to `group_vars/all/vault.yml`
4. Update service directories list in `playbooks/deploy.yml` if needed
5. Test: `make deploy-service servicename`
6. Update this README

### Database Backups

For services with databases, use the interactive tasks menu (`make tasks`) or run backup scripts manually:

```bash
# RomM database backup
./scripts/backup-romm.sh

# RomM database restore
./scripts/restore-romm.sh backup-file.sql
```

## Security Considerations

- **Vault encryption**: All sensitive data is encrypted with Ansible Vault
- **Network isolation**: Services communicate through a dedicated Docker network
- **User permissions**: Most services run as your user, not root (except where required)
- **Reverse proxy**: Consider adding Traefik or Nginx Proxy Manager for HTTPS
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