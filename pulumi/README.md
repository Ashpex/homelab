# Pulumi IaC

- Cloudflare DNS records.
- Cloudflare Tunnel public hostname config.
- Optional Tailscale auth key generation.
- Kubernetes Secrets in `global-secrets` consumed by External Secrets Operator.

## Cloudflare

This creates proxied DNS records only for hostnames explicitly listed in
`publicDnsRecords`, and can manage the Cloudflare Tunnel public hostname route.
Public records point at one configured target, normally a Cloudflare Tunnel CNAME:

```text
<tunnel-id>.cfargotunnel.com
```

Required config:

```sh
pulumi stack init homelab
pulumi config set cloudflare:apiToken <token> --secret
pulumi config set cloudflareAccountId <account-id>
pulumi config set cloudflareZoneId <zone-id>
pulumi config set cloudflareTarget <tunnel-id>.cfargotunnel.com
pulumi config set cloudflareRecordType CNAME
```

`cloudflareAccountId` is used for account-scoped resources such as Cloudflare
Tunnel, Zero Trust, and Access policies. DNS records use `cloudflareZoneId`.

Example public records in `Pulumi.homelab.yaml`:

```yaml
config:
  homelab:publicDnsRecords:
    - name: "*.example.com"
      comment: Homelab Cloudflare Tunnel wildcard
```

With an empty `publicDnsRecords` list, Pulumi will not create any Cloudflare DNS
records.

Example Cloudflare Tunnel route:

```yaml
config:
  homelab:cloudflareTunnel:
    id: 9028a97f-35d2-4e2b-828c-fa97a446f48e
    name: nas
    hostname: "*.ashpex.net"
    service: https://localhost:443
    noTLSVerify: true
```

If you also manage the existing wildcard DNS record, import that DNS record too:

```sh
pulumi import cloudflare:index/dnsRecord:DnsRecord dns-wildcard-ashpex-net '2afa48a079be5f4e385275c44dc79dd9/<dns-record-id>'
```

The tunnel ID is the UUID before `.cfargotunnel.com`. The DNS record ID is not
shown in the DNS table; fetch it from Cloudflare API or the record detail view.

## Tailscale

Tailscale is opt-in. Configure credentials:

```sh
pulumi config set tailscale:apiKey <key> --secret
pulumi config set tailscale:tailnet <tailnet-id>
```

To create a reusable, preauthorized auth key tagged for the K3s host:

```sh
pulumi config set createTailscaleAuthKey true
pulumi preview
```

The generated auth key is exported as a Pulumi secret and stored in Pulumi state.

## App Secrets

App runtime secrets are written by Pulumi into the `global-secrets` namespace.
External Secrets Operator then syncs them into app namespaces.

Set `secrets` as a Pulumi secret config value:

```sh
pulumi config set --secret secrets '[
  {
    "name": "immich.db",
    "data": {
      "POSTGRES_PASSWORD": "<value>"
    }
  }
]'
```

That writes encrypted config into `Pulumi.<stack>.yaml`. Commit the encrypted
stack file so secret data is versioned in Git without committing plaintext.

By default, each secret is created in `global-secrets`. A different
namespace can be set per entry with `namespace`, but the app mappings expect
`global-secrets`.

Run this after the cluster exists and the `global-secrets` namespace has been
created by Flux.
