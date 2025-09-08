#!/bin/bash
# Service Tasks Menu
# Usage: make tasks

set -e

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}            ${YELLOW}SERVICE TASKS MENU${NC}              ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Function to show available tasks
show_tasks() {
    echo -e "${CYAN}Available Service Tasks:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} backup-romm     - Backup RomM database"
    echo -e "  ${GREEN}2)${NC} restore-romm    - Restore RomM database"
    echo -e "  ${GREEN}3)${NC} list-backups    - List available RomM backups"
    echo ""
    echo -e "  ${RED}0)${NC} Exit"
    echo ""
}

# Function to list backups
list_backups() {
    echo -e "${CYAN}📁 Available RomM Backups:${NC}"
    echo ""
    
    if [ -d "./backups/romm" ] && [ "$(ls -A ./backups/romm/*.sql.gz 2>/dev/null)" ]; then
        ls -la ./backups/romm/*.sql.gz | while read -r line; do
            # Extract filename and size
            filename=$(echo "$line" | awk '{print $9}' | xargs basename)
            size=$(echo "$line" | awk '{print $5}')
            date=$(echo "$line" | awk '{print $6" "$7" "$8}')
            
            echo -e "  📄 ${GREEN}${filename}${NC}"
            echo -e "     Size: ${size} bytes | Date: ${date}"
            echo ""
        done
        
        if [ -L "./backups/romm/romm-db-latest.sql.gz" ]; then
            latest=$(readlink ./backups/romm/romm-db-latest.sql.gz)
            echo -e "  🔗 ${YELLOW}Latest:${NC} ${latest}"
        fi
    else
        echo -e "  ${YELLOW}No backups found.${NC}"
        echo -e "  Run '${GREEN}backup-romm${NC}' to create your first backup."
    fi
    
    echo ""
}

# Function to execute task
execute_task() {
    case $1 in
        1|backup-romm)
            echo -e "${CYAN}🔄 Starting RomM database backup...${NC}"
            ./scripts/backup-romm.sh
            ;;
        2|restore-romm)
            echo -e "${CYAN}🔄 Starting RomM database restore...${NC}"
            echo ""
            list_backups
            echo -e "${YELLOW}Enter backup filename (or press Enter for latest):${NC}"
            read -r backup_file
            if [ -z "$backup_file" ]; then
                ./scripts/restore-romm.sh
            else
                ./scripts/restore-romm.sh "./backups/romm/$backup_file"
            fi
            ;;
        3|list-backups)
            list_backups
            echo -e "${BLUE}Press Enter to continue...${NC}"
            read -r
            ;;
        0|exit)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option: $1${NC}"
            echo ""
            ;;
    esac
}

# Main menu loop
while true; do
    show_tasks
    echo -e "${CYAN}Select a task (1-3) or 0 to exit:${NC}"
    read -r choice
    echo ""
    
    execute_task "$choice"
    
    if [ "$choice" != "3" ] && [ "$choice" != "list-backups" ]; then
        echo ""
        echo -e "${BLUE}Press Enter to return to menu...${NC}"
        read -r
    fi
    
    # Clear screen for better UX (optional)
    clear
done
