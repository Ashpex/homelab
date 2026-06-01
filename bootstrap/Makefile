ANSIBLE_LOCAL_TEMP ?= /tmp/ansible-local
ANSIBLE_REMOTE_TEMP ?= /tmp
HELM_CONFIG_HOME ?= /tmp/homelab-helm-config
HELM_CACHE_HOME ?= /tmp/homelab-helm-cache
HELM_DATA_HOME ?= /tmp/homelab-helm-data

export HELM_CONFIG_HOME
export HELM_CACHE_HOME
export HELM_DATA_HOME

.PHONY: help bootstrap-k3s flux-bootstrap validate-host validate-cluster clean-helm-artifacts

help:
	@echo "IaC targets"
	@echo "  bootstrap-k3s     Configure Ubuntu host and install K3s"
	@echo "  flux-bootstrap    Install Flux source/helm controllers and apply HelmReleases"
	@echo "  validate-host     Check Ansible host bootstrap syntax"
	@echo "  validate-cluster  Render Flux release manifests locally"
	@echo "  clean-helm-artifacts  Remove generated Helm dependency files"

bootstrap-k3s:
	mkdir -p $(ANSIBLE_LOCAL_TEMP)
	ANSIBLE_LOCAL_TEMP=$(ANSIBLE_LOCAL_TEMP) ANSIBLE_REMOTE_TEMP=$(ANSIBLE_REMOTE_TEMP) ansible-playbook -i ansible/inventory/home.yml ansible/playbooks/k3s.yml --ask-become-pass

flux-bootstrap:
	mkdir -p $(ANSIBLE_LOCAL_TEMP)
	ANSIBLE_LOCAL_TEMP=$(ANSIBLE_LOCAL_TEMP) ANSIBLE_REMOTE_TEMP=$(ANSIBLE_REMOTE_TEMP) ansible-playbook -i ansible/inventory/home.yml ansible/playbooks/flux-helm.yml

validate-host:
	mkdir -p $(ANSIBLE_LOCAL_TEMP)
	ANSIBLE_LOCAL_TEMP=$(ANSIBLE_LOCAL_TEMP) ANSIBLE_REMOTE_TEMP=$(ANSIBLE_REMOTE_TEMP) ansible-playbook -i ansible/inventory/home.yml ansible/playbooks/k3s.yml --syntax-check
	ANSIBLE_LOCAL_TEMP=$(ANSIBLE_LOCAL_TEMP) ANSIBLE_REMOTE_TEMP=$(ANSIBLE_REMOTE_TEMP) ansible-playbook -i ansible/inventory/home.yml ansible/playbooks/flux-helm.yml --syntax-check

validate-cluster:
	$(MAKE) clean-helm-artifacts
	mkdir -p $(HELM_CONFIG_HOME) $(HELM_CACHE_HOME) $(HELM_DATA_HOME)
	set -e; for file in $$(find ../flux ../platform ../apps -path '*/templates/*' -prune -o -name '*.yaml' -print); do \
		yq e '.' "$$file" >/dev/null; \
	done
	helm repo add external-secrets https://charts.external-secrets.io --force-update
	helm repo add traefik https://traefik.github.io/charts --force-update
	helm repo add bjw-s https://bjw-s-labs.github.io/helm-charts --force-update
	helm repo update
	helm dependency build ../platform/external-secrets
	helm dependency build ../platform/traefik
	helm lint ../platform/external-secrets
	helm lint ../platform/traefik
	helm lint ../platform/local-storage
	helm lint ../platform/global-secrets
	helm template external-secrets ../platform/external-secrets --namespace external-secret >/tmp/homelab-external-secrets-rendered.yaml
	helm template traefik ../platform/traefik --namespace traefik >/tmp/homelab-traefik-rendered.yaml
	helm template local-storage ../platform/local-storage --namespace flux-system >/tmp/homelab-local-storage-rendered.yaml
	helm template global-secrets ../platform/global-secrets --namespace global-secrets >/tmp/homelab-global-secrets-rendered.yaml
	set -e; for release in ../apps/*/release.yaml; do \
		name=$$(yq e '.metadata.name' "$$release"); \
		namespace=$$(yq e '.spec.targetNamespace' "$$release"); \
		chart=$$(yq e '.spec.chart.spec.chart' "$$release"); \
		helm dependency build "../$${chart#./}"; \
		helm lint "../$${chart#./}"; \
		helm template "$$name" "../$${chart#./}" --namespace "$$namespace" > "/tmp/homelab-$${name}-rendered.yaml"; \
	done
	$(MAKE) clean-helm-artifacts
	@echo "Validated Flux release YAML and rendered Helm charts under /tmp"

clean-helm-artifacts:
	rm -rf ../apps/*/Chart.lock ../apps/*/charts ../platform/*/Chart.lock ../platform/*/charts
