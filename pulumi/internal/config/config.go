package config

import (
	"fmt"
	"strings"

	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	pulumiconfig "github.com/pulumi/pulumi/sdk/v3/go/pulumi/config"
)

const (
	defaultCloudflareRecordType = "CNAME"
	defaultSecretNamespace      = "global-secrets"
)

type Config struct {
	PublicDNSRecords       []ServiceRecord
	CloudflareAccountID    string
	CloudflareZoneID       string
	CloudflareTarget       string
	CloudflareRecordType   string
	CloudflareTunnels      []CloudflareTunnel
	Secrets                []Secret
	CreateTailscaleAuthKey bool
}

type ServiceRecord struct {
	Name    string `json:"name"`
	Comment string `json:"comment,omitempty"`
}

type Secret struct {
	Name      string            `json:"name"`
	Namespace string            `json:"namespace,omitempty"`
	Data      map[string]string `json:"data"`
}

type CloudflareTunnel struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	TunnelName  string   `json:"tunnelName,omitempty"`
	Service     string   `json:"service"`
	NoTLSVerify bool     `json:"noTLSVerify,omitempty"`
	Hostnames   []string `json:"hostnames"`
}

func Load(ctx *pulumi.Context) (*Config, error) {
	cfg := pulumiconfig.New(ctx, "")

	var publicRecords []ServiceRecord
	if err := cfg.GetObject("publicDnsRecords", &publicRecords); err != nil {
		return nil, fmt.Errorf("read publicDnsRecords config: %w", err)
	}

	var secrets []Secret
	if _, err := cfg.GetSecretObject("secrets", &secrets); err != nil {
		return nil, fmt.Errorf("read secrets config: %w", err)
	}

	tunnels, err := loadCloudflareTunnels(cfg)
	if err != nil {
		return nil, err
	}

	stack := &Config{
		PublicDNSRecords:       publicRecords,
		CloudflareAccountID:    cfg.Get("cloudflareAccountId"),
		CloudflareRecordType:   cfg.Get("cloudflareRecordType"),
		CloudflareTunnels:      tunnels,
		Secrets:                secrets,
		CreateTailscaleAuthKey: cfg.GetBool("createTailscaleAuthKey"),
	}

	if stack.CloudflareRecordType == "" {
		stack.CloudflareRecordType = defaultCloudflareRecordType
	}

	if len(stack.PublicDNSRecords) > 0 {
		stack.CloudflareZoneID = cfg.Require("cloudflareZoneId")
		stack.CloudflareTarget = cfg.Require("cloudflareTarget")
	}

	if err := stack.validate(); err != nil {
		return nil, err
	}

	return stack, nil
}

func loadCloudflareTunnels(cfg *pulumiconfig.Config) ([]CloudflareTunnel, error) {
	var tunnels []CloudflareTunnel
	if err := cfg.GetObject("cloudflareTunnels", &tunnels); err != nil {
		return nil, fmt.Errorf("read cloudflareTunnels config: %w", err)
	}

	var legacyTunnel CloudflareTunnel
	if err := cfg.GetObject("cloudflareTunnel", &legacyTunnel); err != nil {
		return nil, fmt.Errorf("read cloudflareTunnel config: %w", err)
	}
	if legacyTunnel.configured() {
		tunnels = append(tunnels, legacyTunnel)
	}

	return tunnels, nil
}

func (cfg Config) validate() error {
	for _, record := range cfg.PublicDNSRecords {
		if strings.TrimSpace(record.Name) == "" {
			return fmt.Errorf("publicDnsRecords entries must include name")
		}
	}

	if len(cfg.CloudflareTunnels) > 0 && strings.TrimSpace(cfg.CloudflareAccountID) == "" {
		return fmt.Errorf("cloudflareAccountId is required when cloudflareTunnels is set")
	}
	if err := validateCloudflareTunnels(cfg.CloudflareTunnels); err != nil {
		return err
	}

	for _, secret := range cfg.Secrets {
		if strings.TrimSpace(secret.Name) == "" {
			return fmt.Errorf("secrets entries must include name")
		}
		if len(secret.Data) == 0 {
			return fmt.Errorf("secret %q must include at least one data key", secret.Name)
		}
		for key := range secret.Data {
			if strings.TrimSpace(key) == "" {
				return fmt.Errorf("secret %q contains an empty data key", secret.Name)
			}
		}
	}

	return nil
}

func validateCloudflareTunnels(tunnels []CloudflareTunnel) error {
	seenNames := map[string]struct{}{}

	for _, tunnel := range tunnels {
		if strings.TrimSpace(tunnel.ID) == "" {
			return fmt.Errorf("cloudflareTunnel.id is required")
		}
		if strings.TrimSpace(tunnel.Name) == "" {
			return fmt.Errorf("cloudflareTunnel.name is required")
		}
		if _, exists := seenNames[tunnel.Name]; exists {
			return fmt.Errorf("cloudflareTunnel.name %q is duplicated", tunnel.Name)
		}
		seenNames[tunnel.Name] = struct{}{}
		if len(tunnel.Hostnames) == 0 {
			return fmt.Errorf("cloudflareTunnel.hostnames requires at least one entry")
		}
		if strings.TrimSpace(tunnel.Service) == "" {
			return fmt.Errorf("cloudflareTunnel.service is required")
		}
	}

	return nil
}

func (secret Secret) TargetNamespace() string {
	if secret.Namespace != "" {
		return secret.Namespace
	}
	return defaultSecretNamespace
}

func (tunnel CloudflareTunnel) configured() bool {
	return strings.TrimSpace(tunnel.ID) != "" ||
		strings.TrimSpace(tunnel.Name) != "" ||
		len(tunnel.Hostnames) > 0 ||
		strings.TrimSpace(tunnel.Service) != ""
}
