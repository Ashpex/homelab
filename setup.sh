#!/bin/bash
# Homeserver Infrastructure as Code Project Setup Script
# This script sets up the Ansible project structure and configuration
# Run 'make init' first to install system dependencies

set -e

echo "🚀 Homeserver IaC Project Setup"
echo "==============================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites (should be installed via 'make init')
echo
echo "🔍 Checking prerequisites..."
missing_tools=""

if ! command_exists ansible-playbook; then
    missing_tools="$missing_tools ansible"
fi

if ! command_exists docker; then
    missing_tools="$missing_tools docker"
fi

if ! docker compose version >/dev/null 2>&1; then
    missing_tools="$missing_tools docker-compose"
fi

if [ -n "$missing_tools" ]; then
    echo "❌ Missing required tools:$missing_tools"
    echo "Please run 'make init' first to install system dependencies."
    exit 1
fi

echo "✅ All prerequisites are installed"
ansible --version | head -n1
docker --version
docker compose version --short

# Check/create directory structure
echo
echo "📁 Checking directory structure..."
missing_dirs=""
required_dirs="group_vars/all inventory playbooks templates/services configs scripts build/services"

for dir in $required_dirs; do
    if [ ! -d "$dir" ]; then
        missing_dirs="$missing_dirs $dir"
        mkdir -p "$dir"
    fi
done

if [ -n "$missing_dirs" ]; then
    echo "✅ Created missing directories:$missing_dirs"
else
    echo "✅ All directories already exist"
fi

# Set up vault if it doesn't exist
echo
echo "🔐 Setting up Ansible Vault..."
if [[ -f "group_vars/all/vault.yml" ]]; then
    echo "📄 Vault file already exists"
    read -p "Do you want to edit the vault file? (y/N): " edit_vault
    if [[ $edit_vault =~ ^[Yy]$ ]]; then
        ansible-vault edit group_vars/all/vault.yml
    fi
else
    echo "🆕 Creating new vault file..."
    echo "You will be prompted to create a password for encrypting sensitive data."
    ansible-vault create group_vars/all/vault.yml
fi

# Create .vault_pass file for convenience (optional)
echo
read -p "Do you want to create a .vault_pass file for convenience? (y/N): " create_pass_file
if [[ $create_pass_file =~ ^[Yy]$ ]]; then
    read -s -p "Enter your vault password: " vault_password
    echo
    echo "$vault_password" > .vault_pass
    chmod 600 .vault_pass
    echo "vault_password_file = .vault_pass" >> ansible.cfg
    echo "✅ Vault password file created (.vault_pass)"
    echo "⚠️  Make sure to add .vault_pass to your .gitignore!"
fi

# Validate configuration
echo
echo "🔍 Validating Ansible configuration..."
if ansible-playbook playbooks/deploy.yml --syntax-check >/dev/null 2>&1; then
    echo "✅ Ansible configuration is valid"
else
    echo "⚠️  Some configuration issues detected. You may need to:"
    echo "   - Adjust inventory/hosts.yml for your system"
    echo "   - Set up group_vars/all/services.yml"
    echo "   - Create templates in templates/services/"
fi

# Create Docker network
echo
echo "🌐 Creating Docker network..."
DOCKER_NETWORK="media"  # Default network name
if [ -f "inventory/hosts.yml" ]; then
    # Try to extract network name from inventory
    NETWORK_FROM_INVENTORY=$(grep "docker_network:" inventory/hosts.yml | cut -d'"' -f2 2>/dev/null || echo "media")
    DOCKER_NETWORK="$NETWORK_FROM_INVENTORY"
fi

if docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
    echo "✅ Docker network '$DOCKER_NETWORK' already exists"
else
    docker network create "$DOCKER_NETWORK"
    echo "✅ Docker network '$DOCKER_NETWORK' created"
fi

echo
echo "🎉 Project setup completed successfully!"
echo
echo "Next steps:"
echo "1. Edit inventory/hosts.yml to configure your server and paths"
echo "2. Edit group_vars/all/services.yml to enable/configure services"
echo "3. Add service templates to templates/services/"
echo "4. Run 'make deploy' to deploy your services"
echo
echo "Quick commands:"
echo "  make help           - Show all available commands"
echo "  make deploy         - Deploy all enabled services"
echo "  make deploy-service - Deploy a specific service"
echo "  make status         - Show service status"
echo "  make tasks          - Show service management tasks"
echo
echo "Configuration files:"
echo "  inventory/hosts.yml        - Server and path configuration"
echo "  group_vars/all/services.yml  - Service configurations"
echo "  group_vars/all/vault.yml     - Encrypted secrets (edit with: make edit-vault)"
echo
echo "📚 Generated files will be in build/ directory"
