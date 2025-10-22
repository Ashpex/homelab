# Traefik Integration Guide

This document explains how Traefik configuration works in your homelab setup.

## Configuration Flow

```
Deployment Flow:
1. deploy.yml runs
2. Creates service directories
3. Generates docker-compose files from templates
4. process_service_configs.yml copies config files
   ├─ Copies configs/traefik/dynamic/* → {data_path}/traefik/config/dynamic/
   └─ Handles subdirectories recursively
5. Special Traefik tasks run
   ├─ Renders configs/traefik/traefik.yml → {data_path}/traefik/config/traefik.yml
   └─ Creates acme.json with proper permissions
6. Services start
```

## Directory Structure

```
configs/traefik/                          # Source configs (in repo)
├── traefik.yml                          # Static config (Jinja2 template)
├── dynamic.yml.example                  # Example dynamic config
└── dynamic/                             # Dynamic configs
    ├── middleware.yml                   # Shared middleware (auto-loaded)
    └── [your-custom-configs].yml       # Add more as needed

{base_data_path}/traefik/               # Runtime configs (on server)
├── acme.json                           # SSL certificates (auto-generated)
└── config/
    ├── traefik.yml                     # Rendered static config
    └── dynamic/                        # Dynamic configs (watched by Traefik)
        └── middleware.yml              # Copied from source
```

## Two Configuration Methods

### Method 1: Docker Labels (Recommended)

**Use for:** All your Docker containers (Forgejo, Jellyfin, etc.)

**Location:** Service templates (`templates/services/*.yml.j2`)

**Example:** `templates/services/forgejo.yml.j2`
```yaml
services:
  forgejo:
    image: codeberg.org/forgejo/forgejo:13
    labels:
      # Enable Traefik
      - "traefik.enable=true"
      
      # Router configuration
      - "traefik.http.routers.forgejo.rule=Host(`git.ashpex.net`)"
      - "traefik.http.routers.forgejo.entrypoints=websecure"
      - "traefik.http.routers.forgejo.tls.certresolver=letsencrypt"
      
      # Use shared middleware from dynamic config
      - "traefik.http.routers.forgejo.middlewares=secure-chain@file"
      
      # Service port
      - "traefik.http.services.forgejo.loadbalancer.server.port=3000"
```

**Advantages:**
- Self-contained - routing config lives with service
- Version controlled with service
- Auto-discovery - Traefik finds it automatically
- Perfect for Ansible templating

### Method 2: Dynamic Config Files

**Use for:** 
- Shared middleware (already created in `dynamic/middleware.yml`)
- External/non-Docker services
- Complex routing rules
- Global configurations

**Location:** `configs/traefik/dynamic/*.yml`

**Example:** `configs/traefik/dynamic/external-services.yml`
```yaml
http:
  routers:
    router-admin:
      rule: "Host(`router.ashpex.net`)"
      entryPoints:
        - websecure
      service: router-admin
      tls:
        certResolver: letsencrypt
  
  services:
    router-admin:
      loadBalancer:
        servers:
          - url: "http://192.168.1.1"
```

**Advantages:**
- Live reload - changes apply without restart
- Centralized management
- Can route to non-Docker services
- Complex middleware chains

## Using Shared Middleware

The file `configs/traefik/dynamic/middleware.yml` provides reusable middleware:

### Available Middleware

1. **secure-headers** - Security headers (HSTS, XSS protection, etc.)
2. **secure-chain** - Compression + Security headers
3. **resilient-chain** - Compression + Security headers + Retry + Circuit breaker
4. **api-chain** - Compression + Security headers + API rate limits + Retry
5. **rate-limit-moderate** - 100 req/min with 50 burst
6. **rate-limit-strict** - 30 req/min with 10 burst
7. **rate-limit-api** - 300 req/min with 100 burst
8. **compress** - GZIP compression

### Using in Docker Labels

```yaml
labels:
  # Use a single middleware
  - "traefik.http.routers.myservice.middlewares=secure-headers@file"
  
  # Use multiple middleware (comma-separated)
  - "traefik.http.routers.myservice.middlewares=compress@file,secure-headers@file"
  
  # Use the predefined chain
  - "traefik.http.routers.myservice.middlewares=secure-chain@file"
```

Note: `@file` tells Traefik the middleware comes from a file, not a label.

### Using in Dynamic Config

```yaml
http:
  routers:
    myservice:
      middlewares:
        - secure-chain@file
```

## Complete Examples

### Example 1: Forgejo with Traefik

**File:** `templates/services/forgejo.yml.j2`

```yaml
services:
  forgejo:
    container_name: forgejo
    image: codeberg.org/forgejo/forgejo:13
    volumes:
      - "{{ services.forgejo.data_path }}:/data"
    restart: always
    environment:
      - FORGEJO__server__ROOT_URL=https://git.ashpex.net/
    networks:
      - {{ docker_network }}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.forgejo.rule=Host(`git.ashpex.net`)"
      - "traefik.http.routers.forgejo.entrypoints=websecure"
      - "traefik.http.routers.forgejo.tls.certresolver=letsencrypt"
      - "traefik.http.routers.forgejo.middlewares=secure-chain@file"
      - "traefik.http.services.forgejo.loadbalancer.server.port=3000"

networks:
  {{ docker_network }}:
    external: true
```

**Access:** `https://git.ashpex.net`

### Example 2: Service with Basic Auth

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.private-service.rule=Host(`private.ashpex.net`)"
  - "traefik.http.routers.private-service.entrypoints=websecure"
  - "traefik.http.routers.private-service.tls.certresolver=letsencrypt"
  - "traefik.http.routers.private-service.middlewares=auth"
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wj/"
  - "traefik.http.services.private-service.loadbalancer.server.port=8080"
```

**Generate password hash:**
```bash
htpasswd -nb admin yourpassword
# Output: admin:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/
# In YAML, escape $ as $$
```

### Example 3: External Service via Dynamic Config

**File:** `configs/traefik/dynamic/nas.yml`

```yaml
http:
  routers:
    nas:
      rule: "Host(`nas.ashpex.net`)"
      entryPoints:
        - websecure
      service: nas
      middlewares:
        - secure-headers@file
      tls:
        certResolver: letsencrypt
  
  services:
    nas:
      loadBalancer:
        servers:
          - url: "http://192.168.1.50:5000"
```

## Adding Traefik to Existing Services

### Step-by-Step Process

1. **Update service template** (e.g., `templates/services/jellyfin.yml.j2`)
   ```yaml
   # Optional: Remove or comment out port mapping
   # ports:
   #   - "8096:8096"
   
   # Add Traefik labels
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.ashpex.net`)"
     - "traefik.http.routers.jellyfin.entrypoints=websecure"
     - "traefik.http.routers.jellyfin.tls.certresolver=letsencrypt"
     - "traefik.http.routers.jellyfin.middlewares=secure-chain@file"
     - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
   ```

2. **Redeploy service**
   ```bash
   ansible-playbook playbooks/deploy.yml --tags jellyfin
   ```

3. **Update DNS**
   - Add A record: `jellyfin.ashpex.net` pointing to your server IP

4. **Test**
   - Visit: `https://jellyfin.ashpex.net`
   - Check Traefik dashboard: `http://localhost:8080`

## Troubleshooting

### Check if Traefik sees the service

```bash
# List all routers
curl http://localhost:8080/api/http/routers | jq

# List all services
curl http://localhost:8080/api/http/services | jq

# Check Traefik logs
docker logs traefik
```

### Service not appearing in Traefik

1. Check container has label: `traefik.enable=true`
2. Verify container is on correct network: `{{ docker_network }}`
3. Check container is running: `docker ps`
4. View Traefik logs: `docker logs traefik`

### SSL Certificate issues

```bash
# Check certificate status
docker exec traefik cat /acme.json | jq

# If stuck, remove and regenerate
docker stop traefik
rm {base_data_path}/traefik/acme.json
ansible-playbook playbooks/deploy.yml --tags traefik
```

### Dynamic config not loading

1. Check file syntax: `yamllint configs/traefik/dynamic/*.yml`
2. Check file is being copied: `ls {base_data_path}/traefik/config/dynamic/`
3. Check Traefik logs for errors: `docker logs traefik | grep dynamic`

## Best Practices

### 1. Use Labels for Docker Services
```yaml
# Good - Config with service
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.app.rule=Host(`app.ashpex.net`)"
```

### 2. Use Dynamic Config for Shared Middleware
```yaml
# Good - Reusable across services
# configs/traefik/dynamic/middleware.yml
middlewares:
  secure-chain:
    chain:
      middlewares:
        - compress
        - secure-headers
```

### 3. Reference Shared Middleware
```yaml
# Good - Use shared middleware
labels:
  - "traefik.http.routers.app.middlewares=secure-chain@file"
```

### 4. Keep Sensitive Data in Vault
```yaml
# Bad - Hardcoded password
- "traefik.http.middlewares.auth.basicauth.users=admin:password123"

# Good - Use vault variables
- "traefik.http.middlewares.auth.basicauth.users={{ vault_traefik_basic_auth }}"
```

## Migration Checklist

When moving a service behind Traefik:

- [ ] Add Traefik labels to service template
- [ ] Remove/comment port mapping (or keep for direct access)
- [ ] Update ROOT_URL/BASE_URL in service config if needed
- [ ] Redeploy service
- [ ] Add DNS record
- [ ] Test HTTPS access
- [ ] Verify certificate in browser
- [ ] Check Traefik dashboard for route

## Resources

- [Traefik Docker Labels Reference](https://doc.traefik.io/traefik/routing/providers/docker/)
- [Middleware Documentation](https://doc.traefik.io/traefik/middlewares/overview/)
- [Let's Encrypt](https://doc.traefik.io/traefik/https/acme/)

## Summary

| Configuration Type | Method | Location | When to Use |
|-------------------|--------|----------|-------------|
| Service routing | Docker labels | `templates/services/*.yml.j2` | All Docker services |
| Shared middleware | Dynamic config | `configs/traefik/dynamic/middleware.yml` | Reusable middleware |
| External services | Dynamic config | `configs/traefik/dynamic/*.yml` | Non-Docker services |
| Static settings | Template | `configs/traefik/traefik.yml` | Traefik core config |

Your setup is configured to use Docker labels as the primary method, with dynamic config for shared middleware and external services.
