package cloudflare

import (
	"github.com/Ashpex/homelab/pulumi/internal/config"
	"github.com/Ashpex/homelab/pulumi/internal/naming"
	cf "github.com/pulumi/pulumi-cloudflare/sdk/v6/go/cloudflare"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateTunnelConfig(ctx *pulumi.Context, cfg *config.Config) error {
	tunnel := cfg.CloudflareTunnel
	if tunnel == nil {
		return nil
	}

	ingresses := cf.ZeroTrustTunnelCloudflaredConfigConfigIngressArray{}
	for _, hostname := range tunnel.Hostnames {
		ingress := &cf.ZeroTrustTunnelCloudflaredConfigConfigIngressArgs{
			Hostname: pulumi.String(hostname),
			Service:  pulumi.String(tunnel.Service),
		}
		if tunnel.NoTLSVerify {
			ingress.OriginRequest = &cf.ZeroTrustTunnelCloudflaredConfigConfigIngressOriginRequestArgs{
				NoTlsVerify: pulumi.Bool(true),
			}
		}
		ingresses = append(ingresses, ingress)
	}
	// catch-all rule (required by Cloudflare)
	ingresses = append(ingresses, &cf.ZeroTrustTunnelCloudflaredConfigConfigIngressArgs{
		Service: pulumi.String("http_status:404"),
	})

	tunnelConfig, err := cf.NewZeroTrustTunnelCloudflaredConfig(
		ctx,
		naming.Resource("tunnel", tunnel.Name),
		&cf.ZeroTrustTunnelCloudflaredConfigArgs{
			AccountId: pulumi.String(cfg.CloudflareAccountID),
			TunnelId:  pulumi.String(tunnel.ID),
			Source:    pulumi.String("cloudflare"),
			Config: &cf.ZeroTrustTunnelCloudflaredConfigConfigArgs{
				Ingresses: ingresses,
			},
		},
		pulumi.Protect(true),
	)
	if err != nil {
		return err
	}

	ctx.Export("cloudflareTunnelHostnames", pulumi.ToStringArray(tunnel.Hostnames))
	ctx.Export("cloudflareTunnelConfigVersion", tunnelConfig.Version)
	return nil
}
