# Adding New Services Guide

This guide explains how to add a new service to your homelab infrastructure.

## Prerequisites

Before adding a new service, ensure you have:
- Basic understanding of Docker and Docker Compose
- Familiarity with Jinja2 templating
- Access to the service's official Docker image documentation

## Step-by-Step Process

### 1. Add Service Configuration

**File:** `group_vars/all/services.yml`

Add a new entry under the `services:` key with all required configuration:

```yaml
services:
  # ... existing services ...

  myservice:
    enabled: true                                    # Enable/disable service
    image: "namespace/myservice:latest"              # Docker image (centralized)
    port: 8888                                       # External port (if single port)
    data_path: "{{ base_data_path }}/myservice"     # Main data directory
    config_path: "{{ base_data_path }}/myservice/config"  # Config directory (optional)
    domain: "myservice.ashpex.net"                   # Domain for Traefik (if using Traefik)
```

**Port naming convention:**
- `port` — for services with a single port
- `web_port`, `api_port`, `dns_port`, etc. — for services with multiple ports

**Common variables to include:**
- `enabled`: Boolean to enable/disable the service
- `image`: Docker image reference (centralized in services.yml, referenced in templates)
- Port variables: `port` (single-port), or `web_port`, `api_port`, etc. (multi-port)
- Path variables: `data_path`, `config_path`, `cache_path`, etc.
- Domain: `domain` (for Traefik integration)
- Database credentials: `db_name`, `db_user`, `db_password` (use vault for passwords)

### 2. Add Vault Variables (if needed)

**File:** `group_vars/all/vault.yml`

For sensitive data like passwords, API keys, or tokens:

```bash
# Edit the vault file
ansible-vault edit group_vars/all/vault.yml
```

Add your sensitive variables:

```yaml
---
# MyService credentials
vault_myservice_password: "secure_password_here"
vault_myservice_api_key: "api_key_here"
vault_myservice_secret: "secret_token_here"
```

Reference these in `services.yml`:

```yaml
myservice:
  enabled: true
  image: "namespace/myservice:latest"
  password: "{{ vault_myservice_password }}"
  api_key: "{{ vault_myservice_api_key }}"
```

### 3. Create Docker Compose Template

**File:** `templates/services/myservice.yml.j2`

Create a new Jinja2 template for your service's Docker Compose file:

```yaml
services:
  myservice:
    container_name: myservice
    image: {{ services.myservice.image }}
    restart: unless-stopped

    # Port mappings (optional if using Traefik)
    ports:
      - "{{ services.myservice.port }}:8080"

    # Volume mounts
    volumes:
      - "{{ services.myservice.data_path }}:/data"
      - "{{ services.myservice.config_path }}:/config"
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro

    # Environment variables
    environment:
      - PUID={{ user_id }}
      - PGID={{ group_id }}
      - TZ={{ timezone }}
      - PASSWORD={{ services.myservice.password }}

    # Networks
    networks:
      - {{ docker_network }}

    # Traefik labels (if using Traefik)
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`{{ services.myservice.domain }}`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls=true"
      - "traefik.http.routers.myservice.middlewares=secure-chain@file"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"  # Internal port

networks:
  {{ docker_network }}:
    external: true
```

**Important considerations:**

1. **Image Reference:**
   - Always use `{{ services.myservice.image }}` — the image is centralized in `services.yml`
   - Never hardcode image names in templates

2. **Container Port vs Host Port:**
   - Use `{{ services.myservice.port }}` for the host/external port
   - Hardcode the container's internal port (e.g., `8080`)
   - Example: `- "{{ services.myservice.port }}:8080"` (host:container)

3. **Traefik Integration:**
   - Always use the container's internal port in `loadbalancer.server.port`
   - Use domain from `services.myservice.domain`
   - Use `tls=true` (TLS terminates at Cloudflare Tunnel; no certresolver needed)
   - Choose appropriate middleware chain: `secure-chain@file`, `resilient-chain@file`, or `api-chain@file`

4. **Health Checks (optional but recommended):**
   ```yaml
   healthcheck:
     test: ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
     interval: 30s
     timeout: 10s
     retries: 3
     start_period: 40s
   ```

### 4. Add Configuration Files (if needed)

If the service requires static configuration files:

**Directory:** `configs/myservice/`

Create the directory and add configuration files:

```bash
mkdir -p configs/myservice
```

Example configuration file:

**File:** `configs/myservice/config.yml`

```yaml
# Static configuration for MyService
server:
  port: 8080
  host: 0.0.0.0

database:
  type: sqlite
  path: /data/myservice.db
```

For templated configurations, use `.j2` extension:

**File:** `configs/myservice/config.yml.j2`

```yaml
server:
  port: 8080
  host: 0.0.0.0
  api_key: "{{ services.myservice.api_key }}"

database:
  type: sqlite
  path: {{ services.myservice.data_path }}/myservice.db
```

The service role will automatically:
- Render `.j2` files with variables substituted (stripping the `.j2` extension)
- Copy all other files as-is
- Create subdirectories as needed (e.g., `configs/myservice/subdir/file.yml`)

### 5. No playbook changes needed

The generic `service` role discovers and creates service directories, processes templates/configs, and manages compose lifecycle automatically. You do not need to modify `playbooks/deploy.yml`.

The service URL display is also generated dynamically — no manual update needed.

### 6. Update README

**File:** `README.md`

Add your service to the Available Services table:

```markdown
| **MyService** | Description of what it does | 8888 | Enabled |
```

## Testing Your New Service

### 1. Validate Configuration

```bash
# Check if configuration is valid
make validate
```

### 2. Deploy Single Service

```bash
# Deploy only your new service
make deploy-service myservice
# or
ansible-playbook playbooks/deploy.yml -e single_service=myservice --ask-vault-pass --ask-become-pass
```

### 3. Verify Deployment

```bash
# Check if container is running
docker ps | grep myservice

# Check logs
make logs-service myservice

# Test HTTP access
curl http://localhost:8888
```

### 4. Verify Traefik Integration (if applicable)

```bash
# Check if Traefik sees the service
curl http://localhost:8080/api/http/routers | jq '.[] | select(.name | contains("myservice"))'

# Test HTTPS access
curl -I https://myservice.ashpex.net
```

## Common Patterns

### Pattern 1: Simple Web Service

Single container with web UI, no database:

```yaml
# services.yml
myservice:
  enabled: true
  image: "myservice/myservice:latest"
  port: 8080
  data_path: "{{ base_data_path }}/myservice"
  domain: "myservice.ashpex.net"

# myservice.yml.j2
services:
  myservice:
    image: {{ services.myservice.image }}
    volumes:
      - "{{ services.myservice.data_path }}:/data"
    ports:
      - "{{ services.myservice.port }}:8080"
    networks:
      - {{ docker_network }}
```

### Pattern 2: Service with Database

Application with separate database container:

```yaml
# services.yml
myservice:
  enabled: true
  image: "myservice/app:latest"
  db_image: "postgres:15"
  web_port: 8080
  data_path: "{{ base_data_path }}/myservice"
  db_name: "myservice"
  db_user: "myservice-user"
  db_password: "{{ vault_myservice_db_password }}"
  domain: "myservice.ashpex.net"

# myservice.yml.j2
services:
  myservice-app:
    image: {{ services.myservice.image }}
    depends_on:
      - myservice-db
    environment:
      - DB_HOST=myservice-db
      - DB_NAME={{ services.myservice.db_name }}
      - DB_USER={{ services.myservice.db_user }}
      - DB_PASSWORD={{ services.myservice.db_password }}
    networks:
      - {{ docker_network }}

  myservice-db:
    image: {{ services.myservice.db_image }}
    environment:
      - POSTGRES_DB={{ services.myservice.db_name }}
      - POSTGRES_USER={{ services.myservice.db_user }}
      - POSTGRES_PASSWORD={{ services.myservice.db_password }}
    volumes:
      - "{{ services.myservice.data_path }}/db:/var/lib/postgresql/data"
    networks:
      - {{ docker_network }}
```

### Pattern 3: Service with Multiple Ports

Service requiring multiple port mappings (e.g., web UI + API):

```yaml
# services.yml
myservice:
  enabled: true
  image: "myservice/myservice:latest"
  web_port: 8080
  api_port: 9090
  data_path: "{{ base_data_path }}/myservice"
  domain: "myservice.ashpex.net"

# myservice.yml.j2
services:
  myservice:
    image: {{ services.myservice.image }}
    ports:
      - "{{ services.myservice.web_port }}:8080"
      - "{{ services.myservice.api_port }}:9090"
    # Use Traefik for web UI only
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`{{ services.myservice.domain }}`)"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

### Pattern 4: Service Requiring Root

Some services need root permissions:

```yaml
services:
  myservice:
    image: {{ services.myservice.image }}
    user: root  # or "0:0"
    # ... rest of configuration
```

### Pattern 5: Service with Conditional Configuration

Enable features based on configuration:

```yaml
services:
  myservice:
    image: {{ services.myservice.image }}
    {% if services.myservice.enable_feature_x %}
    environment:
      - FEATURE_X_ENABLED=true
    {% endif %}
```

## Troubleshooting

### Service Won't Start

1. Check logs: `make logs-service myservice`
2. Verify container exists: `docker ps -a | grep myservice`
3. Check compose file: `cat build/services/myservice/docker-compose.yml`
4. Test manually: `cd build/services/myservice && docker compose up`

### Permission Errors

1. `user_id` and `group_id` are resolved dynamically at runtime via `id -u` and `id -g`
2. Check directory ownership: `ls -la /mnt/hdd1/infra-data/myservice`
3. Fix ownership: `sudo chown -R $USER:$USER /mnt/hdd1/infra-data/myservice`

### Configuration Not Applied

1. Check if config file was copied: `ls -la /mnt/hdd1/infra-data/myservice/config/`
2. Verify template syntax: Look for Jinja2 errors in deployment output
3. Redeploy service: `make deploy-service myservice`

### Port Already in Use

1. Find what's using the port: `sudo netstat -tlnp | grep :8080`
2. Change port in `services.yml`
3. Redeploy service

### Traefik Not Routing

1. Verify labels are correct: `docker inspect myservice | jq '.[0].Config.Labels'`
2. Check Traefik sees the router: `curl http://localhost:8080/api/http/routers | jq`
3. Verify DNS record exists: `dig myservice.ashpex.net`
4. Check Traefik logs: `docker logs traefik`

## Best Practices

1. **Use Variables:** Never hardcode paths or ports in templates
2. **Centralize Images:** Define the `image` field in `services.yml`, reference via `{{ services.<name>.image }}` in templates
3. **Vault for Secrets:** Always use Ansible Vault for passwords and API keys
4. **Health Checks:** Add health checks for better container management
5. **Resource Limits:** Consider adding memory/CPU limits for resource-intensive services
6. **Consistent Naming:** Follow existing naming conventions (snake_case for variables)
7. **Test Incrementally:** Test each step before moving to the next

## Example: Complete Service Addition

Here's a complete example adding a fictional "NotesApp" service:

### 1. services.yml
```yaml
notesapp:
  enabled: true
  image: "notesapp/notesapp:latest"
  port: 8200
  data_path: "{{ base_data_path }}/notesapp"
  config_path: "{{ base_data_path }}/notesapp/config"
  domain: "notes.ashpex.net"
  db_name: "notesapp"
  db_user: "notesapp-user"
  # Password in vault
```

### 2. vault.yml
```yaml
vault_notesapp_db_password: "secure_random_password_here"
vault_notesapp_admin_password: "admin_password_here"
```

### 3. templates/services/notesapp.yml.j2
```yaml
services:
  notesapp:
    container_name: notesapp
    image: {{ services.notesapp.image }}
    restart: unless-stopped
    ports:
      - "{{ services.notesapp.port }}:3000"
    volumes:
      - "{{ services.notesapp.data_path }}:/app/data"
      - "{{ services.notesapp.config_path }}:/app/config"
    environment:
      - PUID={{ user_id }}
      - PGID={{ group_id }}
      - TZ={{ timezone }}
      - DB_NAME={{ services.notesapp.db_name }}
      - DB_USER={{ services.notesapp.db_user }}
      - DB_PASSWORD={{ services.notesapp.db_password }}
      - ADMIN_PASSWORD={{ vault_notesapp_admin_password }}
    networks:
      - {{ docker_network }}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.notesapp.rule=Host(`{{ services.notesapp.domain }}`)"
      - "traefik.http.routers.notesapp.entrypoints=websecure"
      - "traefik.http.routers.notesapp.tls=true"
      - "traefik.http.routers.notesapp.middlewares=secure-chain@file"
      - "traefik.http.services.notesapp.loadbalancer.server.port=3000"

networks:
  {{ docker_network }}:
    external: true
```

### 4. Deploy and Test
```bash
# Deploy the service
make deploy-service notesapp

# Check status
docker ps | grep notesapp

# View logs
make logs-service notesapp

# Test access
curl http://localhost:8200
curl -I https://notes.ashpex.net
```

## Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Jinja2 Template Designer Documentation](https://jinja.palletsprojects.com/)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Traefik Integration Guide](TRAEFIK-INTEGRATION.md)
- [Traefik Best Practices](TRAEFIK-BEST-PRACTICES.md)

## Need Help?

If you encounter issues:
1. Check service-specific documentation for Docker setup requirements
2. Review logs: `make logs-service servicename`
3. Test Docker Compose file manually: `cd build/services/servicename && docker compose up`
4. Verify all paths and ports are correctly configured
5. Check for port conflicts: `sudo netstat -tlnp | grep :PORT`
