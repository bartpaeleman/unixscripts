#!/bin/bash

# ============================================================
# GIT MASTER CONTROL PANEL v7.0.0
# Professional Git Workflow Manager for QNAP & macOS
# ============================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# --- ENVIRONMENT DETECTION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Load environment variables
load_env() {
    if [[ ! -f "$ENV_FILE" ]]; then
        printf "\033[1;31mERROR: .env file not found at: ${ENV_FILE}\033[0m\n"
        printf "Please copy .env.example to .env and configure your settings.\n"
        exit 1
    fi
    
    # Parse .env file, ignoring comments and empty lines
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # Remove quotes and export
        value="${value%\"}"
        value="${value#\"}"
        export "$key=$value"
    done < <(grep -v '^[[:space:]]*$' "$ENV_FILE")
    
    # Validate required variables
    if [[ -z "${GITHUB_TOKEN:-}" ]] || [[ -z "${GITHUB_USERNAME:-}" ]]; then
        printf "\033[1;31mERROR: GITHUB_TOKEN and GITHUB_USERNAME must be set in .env\033[0m\n"
        exit 1
    fi
    
    # Set default paths if not configured
    PATH_ROOT="${PATH_ROOT:-/share/Web}"
    PATH_PROD="${PATH_PROD:-${PATH_ROOT}}"
    PATH_DEV="${PATH_DEV:-${PATH_ROOT}/DEV}"
    PATH_TEST="${PATH_TEST:-${PATH_ROOT}/TEST}"
    
    # QNAP persistence paths
    PERSISTENT_SCRIPT_PATH="${PERSISTENT_SCRIPT_PATH:-${PATH_DEV}/scripts/git-master.sh}"
    PERSISTENT_ENV="${PERSISTENT_ENV:-${PATH_DEV}/scripts/.env}"
}

# --- COLOR DEFINITIONS ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m'

# --- HELPER FUNCTIONS ---

get_branch_list_raw() {
    local prefix="${1:-br}"
    local counter=1
    
    while IFS= read -r branch; do
        branch=$(echo "$branch" | sed 's/^[* ]*//' | awk '{print $1}')
        [[ -z "$branch" ]] && continue
        eval "${prefix}_${counter}='${branch}'"
        ((counter++))
    done < <(git branch -a | grep -v HEAD)
    
    eval "${prefix}_count=$((counter - 1))"
}

print_colored_branch_list() {
    local prefix="${1:-br}"
    local count_var="${prefix}_count"
    local count="${!count_var}"
    
    printf "\n${CYAN}${BOLD}Available Branches:${NC}\n"
    for ((i=1; i<=count; i++)); do
        local var="${prefix}_${i}"
        local branch="${!var}"
        
        if [[ "$branch" == *"remotes/origin"* ]]; then
            printf " ${YELLOW}%2d) %s${NC}\n" "$i" "$branch"
        else
            printf " ${GREEN}%2d) %s${NC}\n" "$i" "$branch"
        fi
    done
    printf " ${RED}X) Cancel${NC}\n"
}

check_dirty() {
    if [[ -n $(git status -s) ]]; then
        printf "${YELLOW}Uncommitted changes detected!${NC}\n"
        git status -s
        read -p "Continue anyway? (y/n): " cont
        [[ "$cont" != "y" ]] && return 1
    fi
    return 0
}

detect_environment() {
    local current_path="$1"
    
    if [[ "$current_path" == "$PATH_DEV"* ]]; then
        echo -e "${GREEN}DEV${NC}"
        return 0
    elif [[ "$current_path" == "$PATH_TEST"* ]]; then
        echo -e "${YELLOW}TEST${NC}"
        return 0
    elif [[ "$current_path" == "$PATH_PROD"* ]]; then
        echo -e "${RED}${BOLD}PROD${NC}"
        return 1
    else
        echo -e "${NC}EXTERNAL${NC}"
        return 0
    fi
}

# --- INITIALIZATION ---
load_env

# --- MAIN PROGRAM ---

while true; do
    clear
    CUR_PATH=$(pwd)
    PROJECT_NAME=$(basename "$CUR_PATH")
    
    # Git status check
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        IN_GIT=true
    else
        CURRENT_BRANCH="N/A"
        IN_GIT=false
    fi
    
    # Environment detection
    ENV_VAL=$(detect_environment "$CUR_PATH")
    IS_PROD=$?
    
    # Header
    printf "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
    printf "   ${GREEN}${BOLD}GIT MASTER v7.0${NC} │ ${ENV_VAL}\n"
    printf "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
    printf " Project: ${CYAN}${PROJECT_NAME}${NC} @ ${YELLOW}${CURRENT_BRANCH}${NC}\n"
    printf " Auth: $([ -n "$GITHUB_TOKEN" ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}")\n"
    printf "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"

    # Compact menu
    printf "${CYAN}NAV${NC} P)Prod D)Dev T)Test 0)Clone │ ${YELLOW}DEV${NC} 1)Status 2)Branch\n"
    printf "3)Commit 4)Pull 5)Force 6)Backup │ ${MAGENTA}RELEASE${NC} 7)UAT 8)Stable\n"
    printf "9)Merge 10)Tag │ ${RED}MAINT${NC} 11)Prune 12)Delete 13)Undo 14)Reset\n"
    printf "15)Emergency │ S)Setup Q)Quit\n"
    printf "${GREEN}${BOLD}───────────────────────────────────────────────────────────${NC}\n"
    read -p "→ " choice

    case $choice in
        [Pp]) cd "$PATH_PROD" 2>/dev/null || printf "${RED}Path not found${NC}\n" ;;
        [Dd]) cd "$PATH_DEV" 2>/dev/null || printf "${RED}Path not found${NC}\n" ;;
        [Tt]) cd "$PATH_TEST" 2>/dev/null || printf "${RED}Path not found${NC}\n" ;;
        
        0) # NEW CLONE
            clear
            printf "${CYAN}Fetching repositories...${NC}\n"
            API_URL="https://api.github.com/user/repos?per_page=100&affiliation=owner"
            REPOS_RAW=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL" \
                | grep -o '"name": "[^"]*' | cut -d'"' -f4 | grep -vE "License|GNU")
            
            i=1
            declare -a repo_array
            while IFS= read -r repo; do
                [[ -n "$repo" ]] && printf "%2d) %s\n" "$i" "$repo" && repo_array[$i]="$repo" && ((i++))
            done <<< "$REPOS_RAW"
            
            read -p "Select number (X to cancel): " r_idx
            [[ "$r_idx" =~ ^[Xx]$ ]] && continue
            
            sel_repo="${repo_array[$r_idx]}"
            if [[ -n "$sel_repo" ]]; then
                CLONE_URL="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${sel_repo}.git"
                git clone "$CLONE_URL" && cd "$sel_repo" || printf "${RED}Clone failed${NC}\n"
            fi
            read -p "Press Enter..." ;;

        1) # DASHBOARD
            [[ "$IN_GIT" = false ]] && { printf "${RED}Not in git repo${NC}\n"; read -p "Enter..."; continue; }
            clear
            printf "${CYAN}${BOLD}DASHBOARD: ${PROJECT_NAME}${NC}\n\n"
            git fetch origin --prune 2>/dev/null
            {
                printf "${BOLD}═══ BRANCHES ═══${NC}\n"
                git branch -vv
                printf "\n${BOLD}═══ STATUS ═══${NC}\n"
                git status
                printf "\n${BOLD}═══ HISTORY ═══${NC}\n"
                git log -n 15 --oneline --graph --decorate --all
            } | less -R
            read -p "Press Enter..." ;;

        2) # BRANCH EXPLORER
            [[ "$IN_GIT" = false ]] && continue
            check_dirty || continue
            get_branch_list_raw "be"
            print_colored_branch_list "be"
            read -p "Number or new name: " be_val
            [[ "$be_val" =~ ^[Xx]$ ]] && continue
            
            if [[ "$be_val" =~ ^[0-9]+$ ]]; then
                target_branch="${!be_val@}"
                target_branch=$(eval echo "\$be_${be_val}")
                target_branch="${target_branch#remotes/origin/}"
                git checkout "$target_branch" 2>/dev/null || git checkout -b "$target_branch" "origin/$target_branch"
                git pull origin "$target_branch" 2>/dev/null
            else
                git checkout -b "$be_val" && printf "${GREEN}Branch created${NC}\n"
            fi
            read -p "Press Enter..." ;;

        3) # QUICK COMMIT
            [[ "$IN_GIT" = false ]] && continue
            git status -s
            read -p "Commit message (X to cancel): " msg
            [[ "$msg" =~ ^[Xx]$ ]] && continue
            
            if [[ -n "$msg" ]]; then
                git add . && \
                git commit -m "$msg" && \
                git push origin "$CURRENT_BRANCH" && \
                printf "${GREEN}✓ Pushed${NC}\n"
            fi
            read -p "Press Enter..." ;;

        4) # SYNC FETCH
            [[ "$IN_GIT" = false ]] && continue
            git pull origin "$CURRENT_BRANCH" && printf "${GREEN}✓ Synced${NC}\n"
            read -p "Press Enter..." ;;

        5) # SYNC FORCE
            [[ "$IN_GIT" = false ]] && continue
            git fetch origin
            printf "A) Reset LOCAL to GitHub\nB) Force push LOCAL to GitHub\nX) Cancel\n"
            read -p "Choose: " fa_choice
            
            case "$fa_choice" in
                [Aa]) git reset --hard "origin/$CURRENT_BRANCH" && printf "${GREEN}✓ Local reset${NC}\n" ;;
                [Bb]) git push origin "$CURRENT_BRANCH" --force && printf "${GREEN}✓ Force pushed${NC}\n" ;;
            esac
            read -p "Press Enter..." ;;

        6) # BACKUP POINT
            [[ "$IN_GIT" = false ]] && continue
            TS=$(date +%Y%m%d_%H%M%S)
            git branch "backup/${CURRENT_BRANCH}_${TS}"
            printf "${GREEN}✓ Backup: backup/${CURRENT_BRANCH}_${TS}${NC}\n"
            read -p "Press Enter..." ;;

        7) # PREPARE UAT
            [[ "$IN_GIT" = false ]] && continue
            printf "${MAGENTA}UAT Preparation${NC}\n"
            git stash push -u -m "Auto-stash before UAT" 2>/dev/null
            get_branch_list_raw "uat"
            print_colored_branch_list "uat"
            read -p "Select branch to test: " uat_idx
            [[ "$uat_idx" =~ ^[Xx]$ ]] && continue
            
            jules_br=$(eval echo "\$uat_${uat_idx}")
            jules_br="${jules_br#remotes/origin/}"
            
            git checkout main && git pull origin main
            git checkout -B uat
            
            if git merge -X theirs "origin/$jules_br" --no-edit; then
                git checkout "origin/$jules_br" -- . 2>/dev/null
                printf "${GREEN}✓ UAT ready${NC}\n"
            else
                printf "${RED}✗ Merge failed${NC}\n"
            fi
            read -p "Press Enter..." ;;

        8) # STAGING PUSH
            [[ "$IN_GIT" = false ]] && continue
            git branch -f dev-stable-backup dev-stable 2>/dev/null
            read -p "Push ${CURRENT_BRANCH} → dev-stable? (y/n): " s_conf
            
            if [[ "$s_conf" == "y" ]]; then
                git checkout dev-stable 2>/dev/null || git checkout -b dev-stable
                git reset --hard "$CURRENT_BRANCH"
                git push origin dev-stable --force
                git checkout "$CURRENT_BRANCH"
                printf "${GREEN}✓ Staged${NC}\n"
            fi
            read -p "Press Enter..." ;;

        9) # MERGE FIXES
            [[ "$IN_GIT" = false ]] && continue
            get_branch_list_raw "mf"
            print_colored_branch_list "mf"
            read -p "Select fix branch: " mf_idx
            
            fix_br=$(eval echo "\$mf_${mf_idx}")
            fix_br="${fix_br#remotes/origin/}"
            
            if [[ -n "$fix_br" ]]; then
                git merge "origin/$fix_br" --no-edit && \
                git push origin "$CURRENT_BRANCH" && \
                git branch -D "$fix_br" 2>/dev/null
                printf "${GREEN}✓ Merged${NC}\n"
            fi
            read -p "Press Enter..." ;;

        10) # RELEASE TAG
            [[ "$IN_GIT" = false ]] && continue
            printf "${CYAN}Recent tags:${NC}\n"
            git tag -l | tail -n 5
            read -p "New version tag (e.g., v1.2.3): " v_tag
            
            if [[ -n "$v_tag" ]]; then
                git tag -a "$v_tag" -m "Release $v_tag" && \
                git push origin "$v_tag" && \
                printf "${GREEN}✓ Tagged: $v_tag${NC}\n"
            fi
            read -p "Press Enter..." ;;

        11) # CLEANUP PRUNE
            [[ "$IN_GIT" = false ]] && continue
            git fetch origin --prune
            GONE=$(git branch -vv | grep ': gone]' | awk '{print $1}')
            
            if [[ -n "$GONE" ]]; then
                echo "$GONE" | xargs git branch -D
                printf "${GREEN}✓ Pruned${NC}\n"
            else
                printf "Nothing to prune\n"
            fi
            read -p "Press Enter..." ;;

        12) # DELETE LOCAL
            [[ "$IN_GIT" = false ]] && continue
            get_branch_list_raw "dk"
            print_colored_branch_list "dk"
            read -p "Number to DELETE: " dk_idx
            
            del_br=$(eval echo "\$dk_${dk_idx}")
            if [[ "$del_br" != "$CURRENT_BRANCH" ]] && [[ -n "$del_br" ]]; then
                git branch -D "$del_br" && printf "${RED}✓ Deleted${NC}\n"
            fi
            read -p "Press Enter..." ;;

        13) # UNDO COMMIT
            [[ "$IN_GIT" = false ]] && continue
            git reset --soft HEAD~1
            printf "${YELLOW}✓ Last commit undone (files kept)${NC}\n"
            read -p "Press Enter..." ;;

        14) # FORCE RESET
            [[ "$IN_GIT" = false ]] && continue
            [[ $IS_PROD -eq 1 ]] && printf "${RED}${BOLD}!!! PRODUCTION WARNING !!!${NC}\n"
            
            read -p "Type RESET to wipe and reset to main: " p_conf
            if [[ "$p_conf" == "RESET" ]]; then
                git checkout main && \
                git reset --hard origin/main && \
                git clean -fd
                printf "${GREEN}✓ Reset complete${NC}\n"
            fi
            read -p "Press Enter..." ;;

        15) # EMERGENCY
            [[ "$IN_GIT" = false ]] && continue
            printf "1) Abort merge  2) Clear locks  3) Pop stash\n"
            read -p "Action: " em_c
            
            case "$em_c" in
                1) git merge --abort && printf "${GREEN}✓ Aborted${NC}\n" ;;
                2) rm -f .git/index.lock && printf "${GREEN}✓ Unlocked${NC}\n" ;;
                3) git stash pop && printf "${GREEN}✓ Popped${NC}\n" ;;
            esac
            read -p "Press Enter..." ;;

        [Ss]) # SETUP
            clear
            printf "${YELLOW}Environment Setup${NC}\n"
            printf "Current .env: ${ENV_FILE}\n\n"
            printf "Edit .env file manually with your preferred editor.\n"
            printf "Example: nano ${ENV_FILE}\n\n"
            
            read -p "Open .env now? (y/n): " edit_choice
            if [[ "$edit_choice" == "y" ]]; then
                ${EDITOR:-nano} "$ENV_FILE"
                printf "${GREEN}Reloading configuration...${NC}\n"
                load_env
            fi
            read -p "Press Enter..." ;;

        [Qq]) clear; exit 0 ;;
        *) sleep 0.1 ;;
    esac
done
