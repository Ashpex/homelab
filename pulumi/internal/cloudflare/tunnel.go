package cloudflare

import (
	"github.com/Ashpex/homelab/pulumi/internal/config"
	"github.com/Ashpex/homelab/pulumi/internal/naming"
	cf "github.com/pulumi/pulumi-cloudflare/sdk/v6/go/cloudflare"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateTunnelConfig(ctx *pulumi.Context, cfg *config.Config) error {
	if len(cfg.CloudflareTunnels) == 0 {
		return nil
	}

	tunnelNames := pulumi.StringArray{}
	for _, tunnel := range cfg.CloudflareTunnels {
		tunnelName, err := createTunnelConfig(ctx, cfg, tunnel)
		if err != nil {
			return err
		}
		tunnelNames = append(tunnelNames, tunnelName)
	}

	ctx.Export("cloudflareTunnelNames", tunnelNames)
	return nil
}

func createTunnelConfig(ctx *pulumi.Context, cfg *config.Config, tunnel config.CloudflareTunnel) (pulumi.StringOutput, error) {
	cloudflaredTunnel, err := cf.NewZeroTrustTunnelCloudflared(
		ctx,
		naming.Resource("cloudflared-tunnel", tunnel.Name),
		&cf.ZeroTrustTunnelCloudflaredArgs{
			AccountId: pulumi.String(cfg.CloudflareAccountID),
			Name:      pulumi.String(tunnelDisplayName(tunnel)),
			ConfigSrc: pulumi.String("cloudflare"),
		},
		pulumi.Import(pulumi.ID(cfg.CloudflareAccountID+"/"+tunnel.ID)),
		pulumi.Protect(true),
	)
	if err != nil {
		return pulumi.StringOutput{}, err
	}

	tunnelConfig, err := cf.NewZeroTrustTunnelCloudflaredConfig(
		ctx,
		naming.Resource("tunnel", tunnel.Name),
		&cf.ZeroTrustTunnelCloudflaredConfigArgs{
			AccountId: pulumi.String(cfg.CloudflareAccountID),
			TunnelId:  pulumi.String(tunnel.ID),
			Source:    pulumi.String("cloudflare"),
			Config: &cf.ZeroTrustTunnelCloudflaredConfigConfigArgs{
				Ingresses: cloudflaredIngresses(tunnel),
			},
		},
		pulumi.Protect(true),
	)
	if err != nil {
		return pulumi.StringOutput{}, err
	}

	ctx.Export(naming.Resource("cloudflareTunnelHostnames", tunnel.Name), pulumi.ToStringArray(tunnel.Hostnames))
	ctx.Export(naming.Resource("cloudflareTunnelConfigVersion", tunnel.Name), tunnelConfig.Version)
	return cloudflaredTunnel.Name, nil
}

func tunnelDisplayName(tunnel config.CloudflareTunnel) string {
	if tunnel.TunnelName != "" {
		return tunnel.TunnelName
	}
	return tunnel.Name
}

func cloudflaredIngresses(tunnel config.CloudflareTunnel) cf.ZeroTrustTunnelCloudflaredConfigConfigIngressArray {
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

	// Cloudflare requires a catch-all rule at the end of the ingress list.
	return append(ingresses, &cf.ZeroTrustTunnelCloudflaredConfigConfigIngressArgs{
		Service: pulumi.String("http_status:404"),
	})
}
