package config

import (
	"strings"
	"testing"
)

func TestSecretTargetNamespace(t *testing.T) {
	if got := (Secret{}).TargetNamespace(); got != defaultSecretNamespace {
		t.Fatalf("default namespace = %q, want %q", got, defaultSecretNamespace)
	}

	if got := (Secret{Namespace: "custom"}).TargetNamespace(); got != "custom" {
		t.Fatalf("custom namespace = %q, want custom", got)
	}
}

func TestConfigValidate(t *testing.T) {
	tests := map[string]struct {
		cfg  Config
		want string
	}{
		"missing public record name": {
			cfg: Config{
				PublicDNSRecords: []ServiceRecord{{Name: " "}},
			},
			want: "publicDnsRecords entries must include name",
		},
		"missing secret name": {
			cfg: Config{
				Secrets: []Secret{{Data: map[string]string{"PASSWORD": "value"}}},
			},
			want: "secrets entries must include name",
		},
		"empty secret data": {
			cfg: Config{
				Secrets: []Secret{{Name: "immich.db"}},
			},
			want: `secret "immich.db" must include at least one data key`,
		},
		"empty secret key": {
			cfg: Config{
				Secrets: []Secret{{Name: "immich.db", Data: map[string]string{" ": "value"}}},
			},
			want: `secret "immich.db" contains an empty data key`,
		},
		"tunnel missing account id": {
			cfg: Config{
				CloudflareTunnel: &CloudflareTunnel{
					ID:       "9028a97f-35d2-4e2b-828c-fa97a446f48e",
					Name:     "nas",
					Hostname: "*.ashpex.net",
					Service:  "https://localhost:443",
				},
			},
			want: "cloudflareAccountId is required when cloudflareTunnel is set",
		},
		"tunnel missing id": {
			cfg: Config{
				CloudflareAccountID: "account-id",
				CloudflareTunnel: &CloudflareTunnel{
					Name:     "nas",
					Hostname: "*.ashpex.net",
					Service:  "https://localhost:443",
				},
			},
			want: "cloudflareTunnel.id is required",
		},
		"tunnel missing name": {
			cfg: Config{
				CloudflareAccountID: "account-id",
				CloudflareTunnel: &CloudflareTunnel{
					ID:       "9028a97f-35d2-4e2b-828c-fa97a446f48e",
					Hostname: "*.ashpex.net",
					Service:  "https://localhost:443",
				},
			},
			want: "cloudflareTunnel.name is required",
		},
		"tunnel missing hostname": {
			cfg: Config{
				CloudflareAccountID: "account-id",
				CloudflareTunnel: &CloudflareTunnel{
					ID:      "9028a97f-35d2-4e2b-828c-fa97a446f48e",
					Name:    "nas",
					Service: "https://localhost:443",
				},
			},
			want: "cloudflareTunnel.hostname is required",
		},
		"tunnel missing service": {
			cfg: Config{
				CloudflareAccountID: "account-id",
				CloudflareTunnel: &CloudflareTunnel{
					ID:       "9028a97f-35d2-4e2b-828c-fa97a446f48e",
					Name:     "nas",
					Hostname: "*.ashpex.net",
				},
			},
			want: "cloudflareTunnel.service is required",
		},
		"valid": {
			cfg: Config{
				CloudflareAccountID: "account-id",
				PublicDNSRecords:    []ServiceRecord{{Name: "hub"}},
				CloudflareTunnel: &CloudflareTunnel{
					ID:       "9028a97f-35d2-4e2b-828c-fa97a446f48e",
					Name:     "nas",
					Hostname: "*.ashpex.net",
					Service:  "https://localhost:443",
				},
				Secrets: []Secret{
					{Name: "immich.db", Data: map[string]string{"POSTGRES_PASSWORD": "value"}},
				},
			},
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			err := tt.cfg.validate()
			if tt.want == "" {
				if err != nil {
					t.Fatalf("Validate() returned error: %v", err)
				}
				return
			}
			if err == nil {
				t.Fatalf("Validate() returned nil, want %q", tt.want)
			}
			if !strings.Contains(err.Error(), tt.want) {
				t.Fatalf("Validate() = %q, want substring %q", err.Error(), tt.want)
			}
		})
	}
}

func TestCloudflareTunnelConfigured(t *testing.T) {
	tests := map[string]struct {
		tunnel CloudflareTunnel
		want   bool
	}{
		"empty": {
			tunnel: CloudflareTunnel{},
		},
		"id": {
			tunnel: CloudflareTunnel{ID: "9028a97f-35d2-4e2b-828c-fa97a446f48e"},
			want:   true,
		},
		"name": {
			tunnel: CloudflareTunnel{Name: "nas"},
			want:   true,
		},
		"hostname": {
			tunnel: CloudflareTunnel{Hostname: "*.ashpex.net"},
			want:   true,
		},
		"service": {
			tunnel: CloudflareTunnel{Service: "https://localhost:443"},
			want:   true,
		},
		"bool only": {
			tunnel: CloudflareTunnel{NoTLSVerify: true},
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			if got := tt.tunnel.configured(); got != tt.want {
				t.Fatalf("configured() = %t, want %t", got, tt.want)
			}
		})
	}
}
