package tailnet

import (
	"github.com/Ashpex/homelab/pulumi/internal/config"
	"github.com/pulumi/pulumi-tailscale/sdk/go/tailscale"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func Create(ctx *pulumi.Context, cfg *config.Config) error {
	if !cfg.CreateTailscaleAuthKey {
		return nil
	}

	key, err := tailscale.NewTailnetKey(ctx, "homelab-k3s-auth-key", &tailscale.TailnetKeyArgs{
		Description:       pulumi.String("homelab-k3s"),
		Reusable:          pulumi.Bool(true),
		Ephemeral:         pulumi.Bool(false),
		Preauthorized:     pulumi.Bool(true),
		Expiry:            pulumi.Int(7776000),
		RecreateIfInvalid: pulumi.String("always"),
		Tags: pulumi.StringArray{
			pulumi.String("tag:homelab"),
			pulumi.String("tag:k3s"),
		},
	})
	if err != nil {
		return err
	}

	ctx.Export("tailscaleAuthKeyId", key.ID())
	ctx.Export("tailscaleAuthKey", pulumi.ToSecret(key.Key))
	return nil
}
