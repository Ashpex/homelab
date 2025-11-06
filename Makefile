# Homeserver Infrastructure as Code
.PHONY: help init bootstrap deploy update stop status clean setup-vault edit-vault encrypt-vault decrypt-vault raid zfs health

# Default target
help: ## Show this help message
	@echo "Homeserver Infrastructure as Code"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Install required tools (Docker, Ansible, Git, Tailscale) and utilities
	./scripts/init.sh

bootstrap: ## Bootstrap host (install Docker, Compose, utilities)
	ansible-playbook playbooks/bootstrap.yml --ask-become-pass

deploy: ## Deploy all enabled services
	ansible-playbook playbooks/deploy.yml --ask-vault-pass --ask-become-pass

update: ## Update all services to latest images  
	ansible-playbook playbooks/update.yml --ask-vault-pass --ask-become-pass

stop: ## Stop all services
	ansible-playbook playbooks/stop.yml --ask-vault-pass --ask-become-pass


status: ## Show status of all containers
	@find ./build/services -name "docker-compose.yml" -execdir sh -c 'echo "=== $$(basename $$(pwd)) ===" && docker compose ps' \;

clean: ## Clean up unused Docker resources
	docker system prune -f
	docker volume prune -f

# Service-specific commands (use: make deploy-service glance)
deploy-service: ## Deploy specific service
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then echo "Usage: make deploy-service <servicename>"; echo "Example: make deploy-service glance"; exit 1; fi
	ansible-playbook playbooks/deploy.yml -e "single_service=$(word 2,$(MAKECMDGOALS))" --ask-vault-pass --ask-become-pass

restart-service: ## Restart specific service  
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then echo "Usage: make restart-service <servicename>"; echo "Example: make restart-service glance"; exit 1; fi
	@if [ -d "./build/services/$(word 2,$(MAKECMDGOALS))" ]; then \
		cd ./build/services/$(word 2,$(MAKECMDGOALS)) && docker compose restart; \
	else \
		echo "Service $(word 2,$(MAKECMDGOALS)) not found in ./build/services/"; \
	fi

stop-service: ## Stop specific service
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then echo "Usage: make stop-service <servicename>"; echo "Example: make stop-service glance"; exit 1; fi
	@if [ -d "./build/services/$(word 2,$(MAKECMDGOALS))" ]; then \
		cd ./build/services/$(word 2,$(MAKECMDGOALS)) && docker compose down; \
	else \
		echo "Service $(word 2,$(MAKECMDGOALS)) not found in ./build/services/"; \
	fi

logs-service: ## Show logs for specific service
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then echo "Usage: make logs-service <servicename>"; echo "Example: make logs-service glance"; exit 1; fi
	@if [ -d "./build/services/$(word 2,$(MAKECMDGOALS))" ]; then \
		cd ./build/services/$(word 2,$(MAKECMDGOALS)) && docker compose logs -f; \
	else \
		echo "Service $(word 2,$(MAKECMDGOALS)) not found in ./build/services/"; \
	fi

tasks: ## Show available service tasks
	@./scripts/tasks.sh

# Prevent make from treating service names as targets
%:
	@:

# Vault management
setup-vault: ## Initialize Ansible Vault (run once)
	ansible-vault create group_vars/all/vault.yml

edit-vault: ## Edit encrypted vault file
	ansible-vault edit group_vars/all/vault.yml

encrypt-vault: ## Encrypt the vault file
	ansible-vault encrypt group_vars/all/vault.yml

decrypt-vault: ## Decrypt vault file (for debugging)
	ansible-vault decrypt group_vars/all/vault.yml

# Development helpers  
dry-run: ## Test deployment without making changes
	ansible-playbook playbooks/deploy.yml --check --diff --ask-vault-pass --ask-become-pass

logs: ## Show logs for all services
	@find ./build/services -name "docker-compose.yml" -execdir docker compose logs -f \;

restart: ## Restart all services
	@find ./build/services -name "docker-compose.yml" -execdir docker compose restart \;

# Force operations
force-pull: ## Force pull latest images even if compose unchanged
	ansible-playbook playbooks/deploy.yml -e force_pull=true

# Configuration validation
validate: ## Validate Ansible configuration
	ansible-playbook playbooks/deploy.yml --syntax-check --ask-vault-pass
	ansible-inventory --list

raid: ## Configure/assemble RAID (set vars with -e, confirm required)
	ansible-playbook playbooks/raid.yml --ask-become-pass

zfs: ## Configure ZFS (set vars with -e, confirm required)
	ansible-playbook playbooks/zfs.yml --ask-become-pass

health: ## Collect system/storage health diagnostics
	ansible-playbook playbooks/health.yml --ask-vault-pass --ask-become-pass

# Generate current docker-compose.yml for inspection
generate-compose: ## Generate docker-compose.yml file for inspection
	ansible-playbook playbooks/deploy.yml --tags "template" --check
