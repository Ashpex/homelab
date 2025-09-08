#!/bin/bash
# Homelab Infrastructure Initialization Script  
# Installs: Docker, Docker Compose, Git, Ansible, Tailscale
# Usage: make init

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect architecture
ARCH="$(uname -m)"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}     ${YELLOW}HOMELAB INFRASTRUCTURE SETUP${NC}            ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Detected Architecture: ${YELLOW}${ARCH}${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}


# Function to install Git
install_git() {
    if ! command_exists git; then
        echo -e "${CYAN}📦 Installing Git...${NC}"
        if command_exists apt; then
            sudo apt update && sudo apt install -y git
        elif command_exists yum; then
            sudo yum install -y git
        elif command_exists pacman; then
            sudo pacman -S git
        fi
    else
        echo -e "${GREEN}✅ Git already installed ($(git --version))${NC}"
    fi
}

# Function to install Docker
install_docker() {
    if ! command_exists docker; then
        echo -e "${CYAN}🐳 Installing Docker...${NC}"
        if command_exists apt; then
            # Ubuntu/Debian
            sudo apt update
            sudo apt install -y ca-certificates curl gnupg lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$USER"
        elif command_exists yum; then
            # CentOS/RHEL
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$USER"
        elif command_exists pacman; then
            # Arch Linux
            sudo pacman -S docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$USER"
        fi
    else
        echo -e "${GREEN}✅ Docker already installed ($(docker --version))${NC}"
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        echo -e "${CYAN}🐳 Installing Docker Compose...${NC}"
        # Docker Compose is included with Docker Engine installation via docker-compose-plugin
        # But we'll install standalone version as fallback
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        if command_exists docker-compose; then
            echo -e "${GREEN}✅ Docker Compose already installed ($(docker-compose --version))${NC}"
        else
            echo -e "${GREEN}✅ Docker Compose (v2) already installed ($(docker compose version))${NC}"
        fi
    fi
}

# Function to install Ansible
install_ansible() {
    if ! command_exists ansible; then
        echo -e "${CYAN}⚙️  Installing Ansible...${NC}"
        if command_exists apt; then
            sudo apt update && sudo apt install -y ansible
        elif command_exists yum; then
            sudo yum install -y epel-release
            sudo yum install -y ansible
        elif command_exists pacman; then
            sudo pacman -S ansible
        fi
    else
        echo -e "${GREEN}✅ Ansible already installed ($(ansible --version | head -n1))${NC}"
    fi
}

# Function to install Tailscale
install_tailscale() {
    if ! command_exists tailscale; then
        echo -e "${CYAN}🔗 Installing Tailscale...${NC}"
        curl -fsSL https://tailscale.com/install.sh | sh
    else
        echo -e "${GREEN}✅ Tailscale already installed ($(tailscale version))${NC}"
    fi
}

# Function to install useful utilities
install_utilities() {
    echo -e "${CYAN}🛠️  Installing useful utilities...${NC}"
    
    # Install via package manager
    if command_exists apt; then
        sudo apt install -y curl jq rsync tree htop openssh-client rclone
    elif command_exists yum; then
        sudo yum install -y curl jq rsync tree htop openssh-clients rclone
    elif command_exists pacman; then
        sudo pacman -S curl jq rsync tree htop openssh rclone
    fi
    
    # Check what was installed
    local installed=""
    command_exists curl && installed="$installed curl"
    command_exists jq && installed="$installed jq"
    command_exists rsync && installed="$installed rsync"
    command_exists tree && installed="$installed tree"
    command_exists htop && installed="$installed htop"
    command_exists rclone && installed="$installed rclone"
    
    if [ -n "$installed" ]; then
        echo -e "${GREEN}✅ Utilities installed:$installed${NC}"
    fi
}

# Function to verify installations
verify_installations() {
    echo -e "${BLUE}🔍 Verifying installations...${NC}"
    echo ""
    
    local all_good=true
    
    # Check Git
    if command_exists git; then
        echo -e "${GREEN}✅ Git: $(git --version)${NC}"
    else
        echo -e "${RED}❌ Git: Not installed${NC}"
        all_good=false
    fi
    
    # Check Docker
    if command_exists docker; then
        echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"
    else
        echo -e "${RED}❌ Docker: Not installed${NC}"
        all_good=false
    fi
    
    # Check Docker Compose
    if command_exists docker-compose; then
        echo -e "${GREEN}✅ Docker Compose: $(docker-compose --version)${NC}"
    elif docker compose version >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker Compose: $(docker compose version --short)${NC}"
    else
        echo -e "${RED}❌ Docker Compose: Not installed${NC}"
        all_good=false
    fi
    
    # Check Ansible
    if command_exists ansible; then
        echo -e "${GREEN}✅ Ansible: $(ansible --version | head -n1 | cut -d' ' -f3)${NC}"
    else
        echo -e "${RED}❌ Ansible: Not installed${NC}"
        all_good=false
    fi
    
    # Check Tailscale
    if command_exists tailscale; then
        echo -e "${GREEN}✅ Tailscale: $(tailscale version | head -n1)${NC}"
    else
        echo -e "${RED}❌ Tailscale: Not installed${NC}"
        all_good=false
    fi
    
    # Check utilities
    echo ""
    echo -e "${CYAN}Utilities:${NC}"
    command_exists curl && echo -e "${GREEN}✅ curl: $(curl --version | head -n1 | cut -d' ' -f1-2)${NC}" || echo -e "${YELLOW}⚠️  curl: Not installed${NC}"
    command_exists jq && echo -e "${GREEN}✅ jq: $(jq --version)${NC}" || echo -e "${YELLOW}⚠️  jq: Not installed${NC}"
    command_exists rsync && echo -e "${GREEN}✅ rsync: $(rsync --version | head -n1 | cut -d' ' -f1-3)${NC}" || echo -e "${YELLOW}⚠️  rsync: Not installed${NC}"
    command_exists tree && echo -e "${GREEN}✅ tree: installed${NC}" || echo -e "${YELLOW}⚠️  tree: Not installed${NC}"
    command_exists htop && echo -e "${GREEN}✅ htop: installed${NC}" || echo -e "${YELLOW}⚠️  htop: Not installed${NC}"
    command_exists rclone && echo -e "${GREEN}✅ rclone: $(rclone version | head -n1 | cut -d' ' -f1-2)${NC}" || echo -e "${YELLOW}⚠️  rclone: Not installed${NC}"
    
    echo ""
    if $all_good; then
        echo -e "${GREEN}🎉 Core tools successfully installed!${NC}"
        echo ""
        echo -e "${CYAN}Next Steps:${NC}"
        echo -e "1. ${YELLOW}Connect to Tailscale${NC}: sudo tailscale up"
        echo -e "2. ${YELLOW}Set up Ansible Vault${NC}: make setup-vault"
        echo -e "3. ${YELLOW}Deploy services${NC}: make deploy"
        echo -e "4. ${YELLOW}Reboot or logout/login${NC} to activate Docker group membership"
    else
        echo -e "${RED}⚠️  Some tools failed to install. Please check the errors above.${NC}"
        exit 1
    fi
}

# Main installation flow
main() {
    echo -e "${CYAN}Starting installation of required tools...${NC}"
    echo ""
    
    # Install tools in order
    install_git
    install_docker
    install_docker_compose
    install_ansible
    install_tailscale
    install_utilities
    
    echo ""
    verify_installations
}

# Run main function
main "$@"
