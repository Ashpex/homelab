.PHONY: help bootstrap-k3s bootstrap-worker flux-bootstrap validate-host validate-cluster pulumi-test

help:
	@echo "Homelab IaC"
	@echo "  bootstrap-k3s     Configure Ubuntu host and install K3s (server/NAS)"
	@echo "  bootstrap-worker  Join a new Ubuntu node as K3s agent (worker)"
	@echo "  flux-bootstrap    Install Flux source/helm controllers and apply releases"
	@echo "  validate-host     Check Ansible bootstrap syntax"
	@echo "  validate-cluster  Render Flux release manifests locally"
	@echo "  pulumi-test       Compile the Pulumi Go project"

bootstrap-k3s:
	$(MAKE) -C bootstrap bootstrap-k3s

bootstrap-worker:
	$(MAKE) -C bootstrap bootstrap-worker

flux-bootstrap:
	$(MAKE) -C bootstrap flux-bootstrap

validate-host:
	$(MAKE) -C bootstrap validate-host

validate-cluster:
	$(MAKE) -C bootstrap validate-cluster

pulumi-test:
	$(MAKE) -C pulumi test
