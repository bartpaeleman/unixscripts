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

# Function to validate .env configuration
validate_env() {
    local env_file="$1"
    local errors=()
    
    source "$env_file" 2>/dev/null || {
        errors+=("Cannot read .env file")
        return 1
    }
    
    [[ -z "${GITHUB_TOKEN:-}" ]] && errors+=("GITHUB_TOKEN is empty")
    [[ -z "${GITHUB_USERNAME:-}" ]] && errors+=("GITHUB_USERNAME is empty")
    [[ -z "${PATH_ROOT:-}" ]] && errors+=("PATH_ROOT is empty")
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        printf "${RED}Configuration errors:${NC}\n"
        for err in "${errors[@]}"; do
            printf "  ✗ $err\n"
        done
        return 1
    fi
    
    return 0
}

# Detect platform
if [[ -d "/share" ]]; then
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

# Step 2: Check for existing .env and handle intelligently
if [[ -f ".env" ]] && [[ -s ".env" ]]; then
    printf "${GREEN}✓ Existing .env file found${NC}\n"
    
    # Source existing .env to check completeness
    source .env 2>/dev/null || true
    
    # Check if existing .env has required fields
    MISSING_FIELDS=()
    [[ -z "${GITHUB_TOKEN:-}" ]] && MISSING_FIELDS+=("GITHUB_TOKEN")
    [[ -z "${GITHUB_USERNAME:-}" ]] && MISSING_FIELDS+=("GITHUB_USERNAME")
    [[ -z "${PATH_ROOT:-}" ]] && MISSING_FIELDS+=("PATH_ROOT")
    
    if [[ ${#MISSING_FIELDS[@]} -eq 0 ]]; then
        # Existing .env is complete
        printf "${GREEN}✓ Configuration is complete and valid${NC}\n"
        printf "  Username: ${GITHUB_USERNAME}\n"
        printf "  Token: ${GREEN}***configured***${NC}\n"
        printf "  Root: ${PATH_ROOT}\n\n"
        
        # Check if .env.example has new fields not in current .env
        if [[ -f ".env.example" ]]; then
            NEW_PARAMS=$(grep -E "^[A-Z_]+" .env.example | cut -d'=' -f1 | while read param; do
                if ! grep -q "^${param}=" .env 2>/dev/null; then
                    echo "$param"
                fi
            done)
            
            if [[ -n "$NEW_PARAMS" ]]; then
                printf "${YELLOW}⚠ New configuration parameters detected${NC}\n"
                
                # Backup existing .env
                cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
                printf "${GREEN}✓ Backup created: .env.backup.*${NC}\n"
                
                # Automatically add new parameters with defaults from .env.example
                echo "" >> .env
                echo "# --- New parameters added $(date +%Y-%m-%d) ---" >> .env
                echo "$NEW_PARAMS" | while read param; do
                    grep "^${param}=" .env.example >> .env
                    printf "${GREEN}  + Added: $param${NC}\n"
                done
                printf "${GREEN}✓ Configuration automatically updated${NC}\n\n"
            else
                printf "${GREEN}✓ No new parameters needed${NC}\n\n"
            fi
        fi
        
        printf "${CYAN}Proceeding with existing configuration...${NC}\n\n"
        NEED_CONFIG=false
        path_root="${PATH_ROOT}"
        
    else
        # Existing .env is incomplete
        printf "${YELLOW}⚠ Configuration incomplete. Missing:${NC}\n"
        for field in "${MISSING_FIELDS[@]}"; do
            printf "  - $field\n"
        done
        printf "\n"
        read -p "Complete the configuration now? (y/n): " complete_now
        
        if [[ "$complete_now" == "y" ]]; then
            # Backup existing .env
            cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
            printf "${GREEN}✓ Backup created${NC}\n"
            NEED_CONFIG=true
        else
            printf "${YELLOW}Installation will use existing .env as-is${NC}\n"
            NEED_CONFIG=false
            path_root="${PATH_ROOT:-$DEFAULT_ROOT}"
        fi
    fi
    
else
    # No .env exists - create from template
    printf "${CYAN}Creating .env from template...${NC}\n"
    cp .env.example .env
    NEED_CONFIG=true
fi

# Step 3: Gather configuration (only if needed)
if [[ "$NEED_CONFIG" == true ]]; then
    printf "\n${CYAN}Please provide the following information:${NC}\n\n"

    # Only ask for missing fields
    if [[ -z "${GITHUB_USERNAME:-}" ]]; then
        read -p "GitHub Username: " gh_user
    else
        gh_user="$GITHUB_USERNAME"
        printf "GitHub Username: ${GREEN}$gh_user${NC} (from existing .env)\n"
    fi
    
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        read -sp "GitHub Token (input hidden): " gh_token
        printf "\n"
    else
        gh_token="$GITHUB_TOKEN"
        printf "GitHub Token: ${GREEN}***configured***${NC} (from existing .env)\n"
    fi
    
    if [[ -z "${PATH_ROOT:-}" ]]; then
        read -p "Projects root path [${DEFAULT_ROOT}]: " path_root
        path_root="${path_root:-$DEFAULT_ROOT}"
    else
        path_root="$PATH_ROOT"
        printf "Projects root path: ${GREEN}$path_root${NC} (from existing .env)\n"
    fi

    # Step 4: Update .env file with new/missing values
    printf "\n${CYAN}Updating configuration...${NC}\n"

    # Update or add each field
    if [[ -n "$gh_user" ]] && ! grep -q "^GITHUB_USERNAME=" .env 2>/dev/null; then
        sed -i.bak "s|GITHUB_USERNAME=\"\"|GITHUB_USERNAME=\"${gh_user}\"|g" .env
    elif [[ -n "$gh_user" ]]; then
        sed -i.bak "s|^GITHUB_USERNAME=.*|GITHUB_USERNAME=\"${gh_user}\"|g" .env
    fi
    
    if [[ -n "$gh_token" ]] && ! grep -q "^GITHUB_TOKEN=" .env 2>/dev/null; then
        sed -i.bak "s|GITHUB_TOKEN=\"\"|GITHUB_TOKEN=\"${gh_token}\"|g" .env
    elif [[ -n "$gh_token" ]]; then
        sed -i.bak "s|^GITHUB_TOKEN=.*|GITHUB_TOKEN=\"${gh_token}\"|g" .env
    fi
    
    if [[ -n "$path_root" ]] && ! grep -q "^PATH_ROOT=" .env 2>/dev/null; then
        sed -i.bak "s|PATH_ROOT=\"/share/Web\"|PATH_ROOT=\"${path_root}\"|g" .env
    elif [[ -n "$path_root" ]]; then
        sed -i.bak "s|^PATH_ROOT=.*|PATH_ROOT=\"${path_root}\"|g" .env
    fi

    # Remove backup
    rm -f .env.bak
    printf "${GREEN}✓ Configuration saved${NC}\n"
else
    # Load existing .env to get path_root for directory creation
    source .env
    path_root="${PATH_ROOT}"
fi

# Step 5: Set permissions
printf "\n${CYAN}Setting secure permissions...${NC}\n"
chmod 600 .env
chmod 700 git-master.sh

# Validate final configuration
printf "${CYAN}Validating configuration...${NC}\n"
if validate_env ".env"; then
    printf "${GREEN}✓ Configuration validated successfully${NC}\n"
else
    printf "${YELLOW}⚠ Configuration validation failed${NC}\n"
    read -p "Edit .env now? (y/n): " edit_now
    if [[ "$edit_now" == "y" ]]; then
        ${EDITOR:-nano} .env
        # Re-validate
        if validate_env ".env"; then
            printf "${GREEN}✓ Configuration now valid${NC}\n"
        else
            printf "${RED}Configuration still has issues${NC}\n"
            read -p "Continue anyway? (y/n): " force_continue
            [[ "$force_continue" != "y" ]] && exit 1
        fi
    fi
fi

# Step 6: Create directory structure
printf "\n${CYAN}Creating directory structure...${NC}\n"
mkdir -p "${path_root}"
mkdir -p "${path_root}/DEV"
mkdir -p "${path_root}/TEST"

printf "${GREEN}✓ Directories created${NC}\n"

# Step 7: Platform-specific setup
if [[ "$PLATFORM" == "Linux" ]]; then
    printf "\n${CYAN}Linux Setup${NC}\n"
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
    
    # Keep .env.example in the script directory for reference
    if [[ ! -f "${SCRIPT_DIR}/.env.example" ]]; then
        cp .env.example "${SCRIPT_DIR}/.env.example"
        printf "${GREEN}✓ Template kept at ${SCRIPT_DIR}/.env.example${NC}\n"
    fi

elif [[ "$PLATFORM" == "QNAP" ]]; then
    printf "\n${CYAN}QNAP Setup${NC}\n"
    read -p "Install to /etc/profile for persistence? (y/n): " install_persist
    
    if [[ "$install_persist" == "y" ]]; then
        PERSIST_DIR="${path_root}/DEV/scripts"
        PERSIST_FILE="${PERSIST_DIR}/.env"
        PERSIST_EXAMPLE="${PERSIST_DIR}/.env.example"
        PERSIST_SCRIPT="${PERSIST_DIR}/git-master.sh"
        
        # Create scripts directory
        mkdir -p "$PERSIST_DIR"
        
        # Copy files to persistent location
        printf "${CYAN}Copying files to persistent location...${NC}\n"
        cp .env "$PERSIST_FILE"
        cp .env.example "$PERSIST_EXAMPLE"
        cp git-master.sh "$PERSIST_SCRIPT"
        
        # Copy additional files if they exist
        [[ -f .gitignore ]] && cp .gitignore "${PERSIST_DIR}/.gitignore"
        [[ -f .env.team ]] && cp .env.team "${PERSIST_DIR}/.env.team"
        [[ -f README.md ]] && cp README.md "${PERSIST_DIR}/README.md"
        
        # Set permissions
        chmod 600 "$PERSIST_FILE"
        chmod 644 "$PERSIST_EXAMPLE"
        chmod 700 "$PERSIST_SCRIPT"
        
        printf "${GREEN}✓ Files copied to ${PERSIST_DIR}/${NC}\n"
        printf "  ${BOLD}Essential:${NC}\n"
        printf "    - .env (secure config)\n"
        printf "    - .env.example (template)\n"
        printf "    - git-master.sh (main script)\n"
        if [[ -f "${PERSIST_DIR}/.gitignore" ]] || [[ -f "${PERSIST_DIR}/.env.team" ]] || [[ -f "${PERSIST_DIR}/README.md" ]]; then
            printf "  ${BOLD}Additional:${NC}\n"
            [[ -f "${PERSIST_DIR}/.gitignore" ]] && printf "    - .gitignore\n"
            [[ -f "${PERSIST_DIR}/.env.team" ]] && printf "    - .env.team (team template)\n"
            [[ -f "${PERSIST_DIR}/README.md" ]] && printf "    - README.md\n"
        fi
        
        # Update /etc/profile
        if ! grep -q "git-master" /etc/profile 2>/dev/null; then
            printf "\n${CYAN}Updating /etc/profile...${NC}\n"
            printf "\n# Git Master Setup\n" >> /etc/profile
            printf "source ${PERSIST_FILE}\n" >> /etc/profile
            printf "alias gitmaster='${PERSIST_SCRIPT}'\n" >> /etc/profile
            printf "alias prod='cd ${path_root}'\n" >> /etc/profile
            printf "alias dev='cd ${path_root}/DEV'\n" >> /etc/profile
            printf "alias test='cd ${path_root}/TEST'\n" >> /etc/profile
            printf "${GREEN}✓ Persistence installed to /etc/profile${NC}\n"
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
    printf "  ${YELLOW}Persistent Location:${NC}\n"
    printf "    ${path_root}/DEV/scripts/\n"
    printf "    ├── git-master.sh (executable)\n"
    printf "    ├── .env (your config)\n"
    printf "    ├── .env.example (template)\n"
    [[ -f "${path_root}/DEV/scripts/.gitignore" ]] && printf "    ├── .gitignore\n"
    [[ -f "${path_root}/DEV/scripts/.env.team" ]] && printf "    ├── .env.team\n"
    [[ -f "${path_root}/DEV/scripts/README.md" ]] && printf "    └── README.md\n"
fi
printf "\n"

printf "${CYAN}Next Steps:${NC}\n"
printf "  1. Run: ${YELLOW}./git-master.sh${NC}\n"
if [[ "$PLATFORM" == "Linux" ]] && [[ "$add_alias" == "y" ]]; then
    printf "  2. Or use: ${YELLOW}gitmaster${NC} (after sourcing ${SHELL_RC})\n"
elif [[ "$PLATFORM" == "QNAP" ]]; then
    printf "  2. Or use: ${YELLOW}gitmaster${NC} (from anywhere after reconnect)\n"
fi
printf "  3. Press ${YELLOW}0${NC} to clone your first project\n\n"

printf "${GREEN}Happy coding! 🚀${NC}\n\n"
