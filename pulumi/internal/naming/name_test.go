package naming

import "testing"

func TestResource(t *testing.T) {
	tests := map[string]string{
		"hub":           "dns-hub",
		"photos_ashpex": "dns-photos-ashpex",
		"*.ashpex.net":  "dns-wildcard-ashpex-net",
		"immich.db":     "dns-immich-db",
	}

	for input, want := range tests {
		if got := Resource("dns", input); got != want {
			t.Fatalf("Resource(%q) = %q, want %q", input, got, want)
		}
	}
}
