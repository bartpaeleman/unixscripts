#!/bin/bash

# ============================================================
# Git Master - Quick Installation Script
# ============================================================

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'

printf "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${NC}\n"
printf "${GREEN}${BOLD}║     Git Master Control Panel - Installation Setup     ║${NC}\n"
printf "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${NC}\n\n"

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    DEFAULT_ROOT="$HOME/Projects"
elif [[ -d "/share" ]]; then
    PLATFORM="QNAP"
    DEFAULT_ROOT="/share/Web"
else
    PLATFORM="Linux"
    DEFAULT_ROOT="$HOME/projects"
fi

printf "${CYAN}Detected platform: ${PLATFORM}${NC}\n\n"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 1: Check if .env exists
if [[ -f ".env" ]]; then
    printf "${YELLOW}⚠ .env file already exists!${NC}\n"
    read -p "Overwrite? (y/n): " overwrite
    [[ "$overwrite" != "y" ]] && printf "${GREEN}Keeping existing .env${NC}\n" && exit 0
fi

# Step 2: Copy template or use existing .env
if [[ -f ".env" ]] && [[ -s ".env" ]]; then
    printf "${GREEN}.env file found in repository${NC}\n"
    read -p "Use this .env file? (y/n): " use_existing
    
    if [[ "$use_existing" != "y" ]]; then
        printf "${CYAN}Creating .env from template...${NC}\n"
        cp .env.example .env
        NEED_CONFIG=true
    else
        printf "${GREEN}Using existing .env configuration${NC}\n"
        NEED_CONFIG=false
    fi
else
    printf "${CYAN}Creating .env from template...${NC}\n"
    cp .env.example .env
    NEED_CONFIG=true
fi

# Step 3: Gather configuration (only if needed)
if [[ "$NEED_CONFIG" == true ]]; then
    printf "\n${CYAN}Please provide the following information:${NC}\n\n"

    read -p "GitHub Username: " gh_user
    read -sp "GitHub Token (input hidden): " gh_token
    printf "\n"
    read -p "Projects root path [${DEFAULT_ROOT}]: " path_root
    path_root="${path_root:-$DEFAULT_ROOT}"

    # Step 4: Update .env file
    printf "\n${CYAN}Updating configuration...${NC}\n"

    sed -i.bak "s|GITHUB_TOKEN=\"\"|GITHUB_TOKEN=\"${gh_token}\"|g" .env
    sed -i.bak "s|GITHUB_USERNAME=\"\"|GITHUB_USERNAME=\"${gh_user}\"|g" .env
    sed -i.bak "s|PATH_ROOT=\"/share/Web\"|PATH_ROOT=\"${path_root}\"|g" .env

    # Remove backup
    rm -f .env.bak
else
    # Load existing .env to get path_root for directory creation
    source .env
    path_root="${PATH_ROOT}"
fi

# Step 5: Set permissions
printf "${CYAN}Setting secure permissions...${NC}\n"
chmod 600 .env
chmod 700 git-master.sh

# Step 6: Create directory structure
printf "\n${CYAN}Creating directory structure...${NC}\n"
mkdir -p "${path_root}"
mkdir -p "${path_root}/DEV"
mkdir -p "${path_root}/TEST"

printf "${GREEN}✓ Directories created${NC}\n"

# Step 7: Platform-specific setup
if [[ "$PLATFORM" == "macOS" ]]; then
    printf "\n${CYAN}macOS Setup${NC}\n"
    SHELL_RC="$HOME/.zshrc"
    [[ ! -f "$SHELL_RC" ]] && SHELL_RC="$HOME/.bashrc"
    
    read -p "Add alias to ${SHELL_RC}? (y/n): " add_alias
    if [[ "$add_alias" == "y" ]]; then
        echo "" >> "$SHELL_RC"
        echo "# Git Master Alias" >> "$SHELL_RC"
        echo "alias gitmaster='${SCRIPT_DIR}/git-master.sh'" >> "$SHELL_RC"
        echo "alias gm='${SCRIPT_DIR}/git-master.sh'" >> "$SHELL_RC"
        printf "${GREEN}✓ Aliases added to ${SHELL_RC}${NC}\n"
        printf "${YELLOW}Run 'source ${SHELL_RC}' to activate${NC}\n"
    fi

elif [[ "$PLATFORM" == "QNAP" ]]; then
    printf "\n${CYAN}QNAP Setup${NC}\n"
    read -p "Install to /etc/profile for persistence? (y/n): " install_persist
    
    if [[ "$install_persist" == "y" ]]; then
        PERSIST_FILE="${path_root}/DEV/scripts/.env"
        PERSIST_SCRIPT="${path_root}/DEV/scripts/git-master.sh"
        
        # Create scripts directory
        mkdir -p "${path_root}/DEV/scripts"
        
        # Copy files to persistent location
        printf "${CYAN}Copying files to persistent location...${NC}\n"
        cp .env "$PERSIST_FILE"
        cp git-master.sh "$PERSIST_SCRIPT"
        
        # Set permissions
        chmod 600 "$PERSIST_FILE"
        chmod 700 "$PERSIST_SCRIPT"
        
        printf "${GREEN}✓ Files copied to ${path_root}/DEV/scripts/${NC}\n"
        
        # Update /etc/profile
        if ! grep -q "git-master" /etc/profile 2>/dev/null; then
            printf "${CYAN}Updating /etc/profile...${NC}\n"
            printf "\n# Git Master Setup\n" >> /etc/profile
            printf "source ${PERSIST_FILE}\n" >> /etc/profile
            printf "alias gitmaster='${PERSIST_SCRIPT}'\n" >> /etc/profile
            printf "alias prod='cd ${path_root}'\n" >> /etc/profile
            printf "alias dev='cd ${path_root}/DEV'\n" >> /etc/profile
            printf "alias test='cd ${path_root}/TEST'\n" >> /etc/profile
            printf "${GREEN}✓ Persistence installed${NC}\n"
        else
            printf "${YELLOW}⚠ /etc/profile already contains git-master config${NC}\n"
        fi
    fi
fi

# Step 8: Test configuration
printf "\n${CYAN}Testing GitHub connection...${NC}\n"
source .env

if curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | grep -q "login"; then
    printf "${GREEN}✓ GitHub authentication successful${NC}\n"
else
    printf "${RED}✗ GitHub authentication failed${NC}\n"
    printf "${YELLOW}Please check your token and try again${NC}\n"
fi

# Final summary
printf "\n${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${NC}\n"
printf "${GREEN}${BOLD}║              Installation Complete! ✓                  ║${NC}\n"
printf "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${NC}\n\n"

printf "${CYAN}Configuration Summary:${NC}\n"
printf "  Platform: ${PLATFORM}\n"
if [[ "$NEED_CONFIG" == false ]]; then
    printf "  Config: ${GREEN}Using repository .env file${NC}\n"
else
    printf "  Username: ${gh_user}\n"
fi
printf "  Root: ${path_root}\n"
printf "  Script: ${SCRIPT_DIR}/git-master.sh\n"

# Show persistent location if QNAP
if [[ "$PLATFORM" == "QNAP" ]] && [[ "$install_persist" == "y" ]]; then
    printf "  ${YELLOW}Persistent:${NC}\n"
    printf "    Script: ${path_root}/DEV/scripts/git-master.sh\n"
    printf "    Config: ${path_root}/DEV/scripts/.env\n"
fi
printf "\n"

printf "${CYAN}Next Steps:${NC}\n"
printf "  1. Run: ${YELLOW}./git-master.sh${NC}\n"
if [[ "$PLATFORM" == "macOS" ]] && [[ "$add_alias" == "y" ]]; then
    printf "  2. Or use: ${YELLOW}gitmaster${NC} (after sourcing ${SHELL_RC})\n"
elif [[ "$PLATFORM" == "QNAP" ]]; then
    printf "  2. Or use: ${YELLOW}gitmaster${NC} (from anywhere after reconnect)\n"
fi
printf "  3. Press ${YELLOW}0${NC} to clone your first project\n\n"

printf "${GREEN}Happy coding! 🚀${NC}\n\n"
