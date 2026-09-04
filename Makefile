NIXIE ?= github:Ashpex/nixie
NIXIE_INSTALL_SSH_KEY ?= $(HOME)/.ssh/ashpex
NIXIE_DEPLOYMENT_SSH_KEY ?= $(HOME)/.ssh/ashpex
NIXIE_DEPLOYMENT_SSH_USER ?= ashpex
NIXIE_EXTRA_ARGS ?=

.PHONY: help bootstrap-k3s nixos-rebuild nixos-clean pxe-nixos nixie-install pxe-clean flux-bootstrap docker-services validate-host validate-cluster pulumi-test

help:
	@echo "Homelab IaC"
	@echo "  bootstrap-k3s     Configure Ubuntu host and install K3s (server/NAS)"
	@echo "  nixos-rebuild     Sync repo and rebuild existing NixOS nodes"
	@echo "  nixos-clean       Remove temporary NixOS rebuild artifacts"
	@echo "  pxe-nixos         Install NixOS nodes with Nixie"
	@echo "  nixie-install     Install NixOS nodes with Nixie"
	@echo "  pxe-clean         Stop local PXE server and remove temporary artifacts"
	@echo "  flux-bootstrap    Install Flux source/helm controllers and apply releases"
	@echo "  docker-services   Deploy Docker services (AdGuard) on NAS"
	@echo "  validate-host     Check Ansible bootstrap syntax"
	@echo "  validate-cluster  Render Flux release manifests locally"
	@echo "  pulumi-test       Compile the Pulumi Go project"

bootstrap-k3s:
	$(MAKE) -C bootstrap bootstrap-k3s

nixos-rebuild:
	$(MAKE) -C bootstrap nixos-rebuild

nixos-clean:
	$(MAKE) -C bootstrap nixos-clean

pxe-nixos:
	$(MAKE) nixie-install

nixie-install:
	sudo --preserve-env=SSH_AUTH_SOCK nix run $(NIXIE) -- \
		--installer ./nixie-installer#nixosConfigurations.installer \
		--flake ./nixos \
		--hosts ./nixos/nixie-hosts.json \
		--install-ssh-key $(NIXIE_INSTALL_SSH_KEY) \
		--deployment-ssh-user $(NIXIE_DEPLOYMENT_SSH_USER) \
		--deployment-ssh-key $(NIXIE_DEPLOYMENT_SSH_KEY) \
		$(NIXIE_EXTRA_ARGS)

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
