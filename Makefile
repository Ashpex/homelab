.PHONY: help bootstrap-k3s pxe-nixos pxe-clean flux-bootstrap docker-services validate-host validate-cluster pulumi-test

help:
	@echo "Homelab IaC"
	@echo "  bootstrap-k3s     Configure Ubuntu host and install K3s (server/NAS)"
	@echo "  pxe-nixos         Start local PXE server for guarded NixOS install"
	@echo "  pxe-clean         Stop local PXE server and remove temporary artifacts"
	@echo "  flux-bootstrap    Install Flux source/helm controllers and apply releases"
	@echo "  docker-services   Deploy Docker services (AdGuard) on NAS"
	@echo "  validate-host     Check Ansible bootstrap syntax"
	@echo "  validate-cluster  Render Flux release manifests locally"
	@echo "  pulumi-test       Compile the Pulumi Go project"

bootstrap-k3s:
	$(MAKE) -C bootstrap bootstrap-k3s

pxe-nixos:
	$(MAKE) -C bootstrap pxe-nixos

pxe-clean:
	$(MAKE) -C bootstrap pxe-clean

docker-services:
	$(MAKE) -C bootstrap docker-services

flux-bootstrap:
	$(MAKE) -C bootstrap flux-bootstrap

validate-host:
	$(MAKE) -C bootstrap validate-host

validate-cluster:
	$(MAKE) -C bootstrap validate-cluster

pulumi-test:
	$(MAKE) -C pulumi test
