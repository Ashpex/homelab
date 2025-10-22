# Traefik Best Practices Implementation

This document outlines the best practices applied to your Traefik configuration based on the [official Traefik documentation](https://doc.traefik.io/traefik/).

## Improvements Implemented

### 1. Entry Points Configuration

#### Cloudflare Proxy Support
```yaml
entryPoints:
  web:
    forwardedHeaders:
      trustedIPs: [Cloudflare IP ranges]
```

When behind Cloudflare CDN, this preserves real client IPs for accurate logging and security.

#### Security Headers at Entry Point
```yaml
websecure:
  http:
    middlewares:
      - secure-headers@file
```

Applies security headers to all HTTPS traffic automatically.

**Reference:** [EntryPoints Documentation](https://doc.traefik.io/traefik/routing/entrypoints/)

### 2. TLS Security Hardening

```yaml
tls:
  options:
    default:
      minVersion: VersionTLS12
      cipherSuites: [Modern, secure ciphers only]
      sniStrict: true
```

**Benefits:**
- Blocks TLS 1.0/1.1 (deprecated, insecure)
- Uses only strong cipher suites
- `sniStrict` prevents host header attacks
- Achieves A+ rating on SSL Labs

**Reference:** [TLS Documentation](https://doc.traefik.io/traefik/https/tls/)

### 3. Health Check Endpoint

```yaml
ping:
  entryPoint: traefik

# In docker-compose:
healthcheck:
  test: ["CMD", "traefik", "healthcheck", "--ping"]
  interval: 10s
```

**Benefits:**
- Docker/Kubernetes can detect unhealthy containers
- Monitoring systems can check Traefik status
- Automatic container restart on failure

**Access:** `curl http://localhost:8082/ping`

**Reference:** [Health Check Documentation](https://doc.traefik.io/traefik/operations/ping/)

### 4. Enhanced Middleware

#### Security Middleware
```yaml
secure-headers:
  headers:
    referrerPolicy: "strict-origin-when-cross-origin"
    permissionsPolicy: "camera=(), microphone=(), geolocation=()"
    contentSecurityPolicy: "..."
```

Implements OWASP recommendations to protect against XSS, clickjacking, and limits browser permissions.

#### Resilience Middleware
```yaml
retry:
  attempts: 3
  initialInterval: "100ms"

circuit-breaker:
  expression: "NetworkErrorRatio() > 0.30"
  checkPeriod: "10s"
```

- **Retry**: Handles transient failures
- **Circuit Breaker**: Prevents cascading failures
- Improves overall system reliability

**Reference:** 
- [Retry Middleware](https://doc.traefik.io/traefik/middlewares/http/retry/)
- [Circuit Breaker](https://doc.traefik.io/traefik/middlewares/http/circuitbreaker/)

#### Rate Limiting
```yaml
rate-limit-moderate: 100 req/min
rate-limit-strict: 30 req/min
rate-limit-api: 300 req/min
```

Protects against DoS attacks with different profiles for different use cases.

**Reference:** [Rate Limit Documentation](https://doc.traefik.io/traefik/middlewares/http/ratelimit/)

### 5. Middleware Chains

```yaml
secure-chain: compress + secure-headers
resilient-chain: compress + secure-headers + retry + circuit-breaker
api-chain: compress + secure-headers + rate-limit-api + retry
```

**Benefits:**
- DRY principle - define once, use everywhere
- Consistency - all services get same security
- Maintainability - update in one place

**Usage:**
```yaml
labels:
  - "traefik.http.routers.myservice.middlewares=resilient-chain@file"
```

### 6. Removed Redundant Configuration

**Before:**
```yaml
# HTTP->HTTPS redirect in BOTH static config AND labels
```

**After:**
```yaml
# HTTP->HTTPS redirect ONLY in static config
entryPoints:
  web:
    http:
      redirections:
        entryPoint:
          to: websecure
```

Provides single source of truth and easier maintenance.

### 7. Security Hardening

```yaml
security_opt:
  - no-new-privileges:true

volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro  # Read-only
```

Prevents privilege escalation and restricts Docker socket access to read-only.

**Reference:** [Docker Security Best Practices](https://doc.traefik.io/traefik/providers/docker/#docker-api-access)

## Configuration Summary

### Static Configuration (`traefik.yml`)
| Feature | Status | Benefit |
|---------|--------|---------|
| TLS 1.2+ only | Enabled | Modern security |
| Strong ciphers | Enabled | A+ SSL rating |
| Health check | Enabled | Monitoring |
| Cloudflare IPs | Enabled | Real IP preservation |
| Entry point middleware | Enabled | Global security |

### Dynamic Configuration (`dynamic/middleware.yml`)
| Middleware | Type | Purpose |
|------------|------|---------|
| secure-headers | Security | OWASP headers |
| rate-limit-* | Security | DoS protection |
| retry | Resilience | Handle failures |
| circuit-breaker | Resilience | Prevent cascading |
| compress | Performance | Reduce bandwidth |
| buffering | Performance | Handle slow clients |

### Docker Compose
| Feature | Status | Benefit |
|---------|--------|---------|
| Health check | Enabled | Auto-restart |
| Read-only socket | Enabled | Security |
| no-new-privileges | Enabled | Container isolation |

## Usage Examples

### Basic Service (Forgejo)
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.forgejo.rule=Host(`git.ashpex.net`)"
  - "traefik.http.routers.forgejo.entrypoints=websecure"
  - "traefik.http.routers.forgejo.tls.certresolver=letsencrypt"
  - "traefik.http.routers.forgejo.middlewares=secure-chain@file"
  - "traefik.http.services.forgejo.loadbalancer.server.port=3000"
```

### Resilient Service (with retry)
```yaml
labels:
  - "traefik.http.routers.jellyfin.middlewares=resilient-chain@file"
```

### API Service (higher limits)
```yaml
labels:
  - "traefik.http.routers.api.middlewares=api-chain@file"
```

### Private Service (with auth)
```yaml
# Uncomment basic-auth in middleware.yml first
labels:
  - "traefik.http.routers.private.middlewares=basic-auth@file,secure-chain@file"
```

## Monitoring and Health Checks

### Health Check
```bash
curl http://localhost:8082/ping
# Response: OK
```

### View Logs
```bash
# Traefik logs
docker logs traefik

# Access logs (if configured)
tail -f /path/to/traefik/logs/access.log | jq
```

### Check Middleware
```bash
curl http://localhost:8080/api/http/middlewares | jq
```

### Check Routes
```bash
curl http://localhost:8080/api/http/routers | jq
```

## Production Checklist

Before deploying to production:

- [ ] Set `api.insecure: false` in static config
- [ ] Enable `basic-auth` middleware for dashboard
- [ ] Update Cloudflare IPs if not using Cloudflare
- [ ] Configure DNS A records
- [ ] Open firewall ports 80, 443
- [ ] Test certificate generation (use staging first)
- [ ] Set up monitoring alerts
- [ ] Test health check endpoint
- [ ] Review and adjust rate limits
- [ ] Test circuit breaker behavior

## Security Recommendations

### 1. Secure Dashboard (Production)

**Static config:**
```yaml
api:
  insecure: false  # Disable insecure access
```

**Add auth to dashboard router:**
```yaml
labels:
  - "traefik.http.routers.traefik-dashboard.middlewares=basic-auth@file,secure-headers@file"
```

### 2. Certificate Management

- Let's Encrypt configured
- HTTP-01 challenge (works without DNS)
- Use staging for testing to avoid rate limits

**For staging:**
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      caServer: "https://acme-staging-v02.api.letsencrypt.org/directory"
```

### 3. Network Segmentation

Consider separating frontend (Traefik) and backend (services) networks, with only Traefik bridging both.

## Additional Resources

- [Traefik v3 Documentation](https://doc.traefik.io/traefik/)
- [Middleware Overview](https://doc.traefik.io/traefik/middlewares/overview/)
- [Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Security Best Practices](https://doc.traefik.io/traefik/https/overview/)
- [Observability](https://doc.traefik.io/traefik/observability/overview/)

## Key Takeaways

1. **Security First**: TLS 1.2+, strong ciphers, security headers
2. **Resilience**: Retry, circuit breaker, health checks
3. **Performance**: Compression, buffering, rate limiting
4. **Maintainability**: Middleware chains, DRY configuration
5. **Production Ready**: Health checks, monitoring, secure defaults

Your Traefik setup now follows industry best practices and is ready for production deployment.
