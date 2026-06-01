package cloudflare

import (
	"github.com/Ashpex/homelab/pulumi/internal/config"
	"github.com/Ashpex/homelab/pulumi/internal/naming"
	cf "github.com/pulumi/pulumi-cloudflare/sdk/v6/go/cloudflare"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateDNSRecords(ctx *pulumi.Context, cfg *config.Config) error {
	for _, record := range cfg.PublicDNSRecords {
		dnsRecord, err := cf.NewDnsRecord(ctx, naming.Resource("dns", record.Name), &cf.DnsRecordArgs{
			ZoneId:  pulumi.String(cfg.CloudflareZoneID),
			Name:    pulumi.String(record.Name),
			Type:    pulumi.String(cfg.CloudflareRecordType),
			Content: pulumi.String(cfg.CloudflareTarget),
			Ttl:     pulumi.Float64(1),
			Proxied: pulumi.Bool(true),
			Comment: pulumi.String(record.Comment),
			Tags: pulumi.StringArray{
				pulumi.String("managed-by:pulumi"),
				pulumi.String("homelab"),
			},
		})
		if err != nil {
			return err
		}

		ctx.Export(naming.Resource("dnsRecord", record.Name), dnsRecord.Name)
	}

	ctx.Export("publicDnsRecordCount", pulumi.Int(len(cfg.PublicDNSRecords)))
	return nil
}
