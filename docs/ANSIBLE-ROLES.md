# Ansible Roles in This Homelab

This homelab adopts Ansible roles for clarity, reuse, and per-service deployments.

## Why roles
- Reuse the same patterns across services
- Smaller playbooks, clearer ownership per service
- Deploy or update a single service via `single_service` variable
- Easier testing and maintenance over time

## Directory model

```
homelab/
├── roles/
│   ├── docker/             # ensure Docker/Compose, network
│   │   └── tasks/main.yml
│   ├── common/             # base dirs, timezone, sanity checks
│   │   └── tasks/main.yml
│   ├── service/            # generic compose/config/deploy logic
│   │   └── tasks/main.yml
│   ├── health/             # system/storage diagnostics
│   │   └── tasks/main.yml
│   ├── raid/               # RAID array management
│   │   └── tasks/main.yml
│   └── zfs/                # ZFS pool/dataset management
│       └── tasks/main.yml
└── playbooks/
    ├── deploy.yml          # main logic (roles + service loop)
    ├── update.yml          # pull latest images and recreate
    ├── stop.yml            # stop services
    ├── health.yml          # system diagnostics
    ├── raid.yml            # RAID configuration
    └── zfs.yml             # ZFS configuration
```

Vars remain centralized in `group_vars/all/services.yml` (service config) and `group_vars/all/vault.yml` (secrets).

## deploy.yml pattern

```yaml
- hosts: homeserver
  become: true
  vars_files:
    - ../group_vars/all/services.yml
    - ../group_vars/all/vault.yml

  tasks:
    - name: Determine target services to deploy
      set_fact:
        services_to_deploy: >-
          {{ (services | dict2items | selectattr('key','equalto', single_service) | list)
             if (single_service is defined and single_service|length > 0)
             else (services | dict2items) }}

    - name: Ensure Docker and base system are ready
      block:
        - include_role: { name: docker }
        - include_role: { name: common }

    - name: Deploy enabled services via roles
      include_role:
        name: service
      vars:
        service_key: "{{ item.key }}"
        service_cfg: "{{ item.value }}"
        service_action: "{{ desired_service_action }}"
      when: item.value.enabled | default(false)
      loop: "{{ services_to_deploy }}"
      loop_control:
        label: "{{ item.key }}"
```

Run a single service via variable:

```bash
ansible-playbook playbooks/deploy.yml -e single_service=forgejo --ask-vault-pass --ask-become-pass
# or via Makefile helper
make deploy-service forgejo
```

## Minimal service role contract (generic `service` role)
- Ensure service directories exist (data/config/build)
- Render compose to `build/services/<service>/docker-compose.yml`
- Copy/render config files from `configs/<service>/` (including subdirectories)
- Compose up/down/pull based on `service_action`
- Traefik-specific: ensure `acme.json` exists with `0600` permissions

## Migration strategy
1. Create `roles/docker`, `roles/common`, and the generic `roles/service`.
2. Use `playbooks/deploy.yml` as the main logic.
3. Move per-service compose templates to `templates/services/<service>.yml.j2` and any config files to `configs/<service>/`.
4. Deploy services via the generic `service` role loop.

## TLS note
This homelab currently uses Cloudflare Tunnel for HTTPS, so Traefik's internal ACME is disabled and router labels don't need `tls.certresolver`. If you switch to Traefik-managed certificates later, re-enable ACME in the static config and add certresolver labels per Traefik docs.
