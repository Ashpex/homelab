# Ansible Roles in This Homelab

This homelab adopts Ansible roles for clarity, reuse, and per‑service deployments.

## Why roles
- Reuse the same patterns across services
- Smaller playbooks, clearer ownership per service
- Deploy or update a single service via tags
- Easier testing and maintenance over time

## Directory model

```
homelab/
├── roles/
│   ├── bootstrap/          # one-time host provisioning (Docker, utils)
│   │   └── tasks/main.yml
│   ├── docker/             # ensure Docker/Compose, network
│   │   └── tasks/main.yml
│   ├── common/             # base dirs, timezone, sanity checks
│   │   └── tasks/main.yml
│   └── service/            # generic compose/config/deploy logic
│       └── tasks/main.yml
└── playbooks/
    ├── deploy.yml          # main logic (roles + service loop)
    └── site.yml            # thin entrypoint importing deploy.yml
```

Vars remain centralized in `group_vars/all/services.yml` (service config) and `group_vars/all/vault.yml` (secrets).

## site.yml pattern

```yaml
- hosts: homeserver
  become: true
tasks:
  - name: Docker setup
    include_role: { name: docker }
  - name: Common setup
    include_role: { name: common }
  - name: Deploy enabled services via roles
    include_role: { name: service }
    loop: "{{ services | dict2items }}"
    loop_control:
      label: "{{ item.key }}"
    when: item.value.enabled | default(false)
```

Run a single service via variable:

```bash
ansible-playbook playbooks/deploy.yml -e single_service=forgejo
# or via Makefile helper
make deploy-service forgejo
```

## Minimal service role contract (generic `service` role)
- Ensure service directories exist (data/config/build)
- Render compose to `build/services/<service>/docker-compose.yml`
- Copy/render config files from `configs/<service>/`
- Compose up/down/pull based on `service_action`

## Migration strategy
1. Create `roles/bootstrap`, `roles/docker`, `roles/common`, and the generic `roles/service`.
2. Use `playbooks/deploy.yml` as the main logic and keep `playbooks/site.yml` as a thin importer.
3. Move per-service compose templates to `templates/services/<service>.yml.j2` and any config files to `configs/<service>/`.
4. Deploy services via the generic `service` role loop.

## TLS note
This homelab currently uses Cloudflare Tunnel for HTTPS, so Traefik’s internal ACME is disabled and router labels don’t need `tls.certresolver`. If you switch to Traefik-managed certificates later, re-enable ACME in the static config and add certresolver labels per Traefik docs.
