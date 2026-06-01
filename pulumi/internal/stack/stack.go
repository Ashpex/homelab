package stack

import (
	"github.com/Ashpex/homelab/pulumi/internal/cloudflare"
	stackconfig "github.com/Ashpex/homelab/pulumi/internal/config"
	"github.com/Ashpex/homelab/pulumi/internal/secrets"
	"github.com/Ashpex/homelab/pulumi/internal/tailnet"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func Run(ctx *pulumi.Context) error {
	cfg, err := stackconfig.Load(ctx)
	if err != nil {
		return err
	}

	if err := cloudflare.CreateDNSRecords(ctx, cfg); err != nil {
		return err
	}

	if err := cloudflare.CreateTunnelConfig(ctx, cfg); err != nil {
		return err
	}

	if err := secrets.Create(ctx, cfg.Secrets); err != nil {
		return err
	}

	if err := tailnet.Create(ctx, cfg); err != nil {
		return err
	}

	return nil
}
