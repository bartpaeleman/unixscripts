#!/bin/bash

# ============================================================
# GIT MASTER CONTROL PANEL v7.0.0
# Professional Git Workflow Manager for QNAP & macOS
# ============================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# --- ENVIRONMENT DETECTION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"

# Load environment variables
load_env() {
    if [[ ! -f "$ENV_FILE" ]]; then
        printf "\033[1;31mERROR: .env file not found at: ${ENV_FILE}\033[0m\n"
        if [[ -f "$ENV_EXAMPLE" ]]; then
            printf "Please copy .env.example to .env and configure your settings:\n"
            printf "  cp \"${ENV_EXAMPLE}\" \"${ENV_FILE}\"\n"
            printf "  nano \"${ENV_FILE}\"\n"
        else
            printf "Please create a .env file with your configuration.\n"
        fi
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

confirm_action() {
    local message="$1"
    local confirm_word="${2:-y}"
    
    printf "${YELLOW}${message}${NC}\n"
    read -p "Type '${confirm_word}' to confirm: " response
    [[ "$response" == "$confirm_word" ]] && return 0 || return 1
}

show_git_stats() {
    printf "${CYAN}${BOLD}Repository Statistics:${NC}\n"
    printf "  Total commits: $(git rev-list --count HEAD 2>/dev/null || echo '0')\n"
    printf "  Total branches: $(git branch -a | grep -v HEAD | wc -l)\n"
    printf "  Contributors: $(git log --format='%an' | sort -u | wc -l)\n"
    printf "  Last commit: $(git log -1 --format='%ar' 2>/dev/null || echo 'N/A')\n"
}

detect_environment() {
    local current_path="$1"
    
    if [[ "$current_path" == "$PATH_DEV"* ]]; then
        echo "${GREEN}[ ENV: DEV (QNAP) ]${NC}"
        return 0
    elif [[ "$current_path" == "$PATH_TEST"* ]]; then
        echo "${YELLOW}[ ENV: TEST (UAT) ]${NC}"
        return 0
    elif [[ "$current_path" == "$PATH_PROD"* ]]; then
        echo "${RED}${BOLD}[ ENV: PROD (LIVE) ]${NC}"
        return 1
    else
        echo "${NC}[ LOCATION: EXTERNAL ]"
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
    printf -- "${GREEN}${BOLD}===============================================================${NC}\n"
    printf -- "       ${GREEN}${BOLD}GIT MASTER CONTROL PANEL v7.0.0${NC}\n"
    printf -- "${GREEN}${BOLD}===============================================================${NC}\n"
    printf -- " Status   : $ENV_VAL\n"
    printf -- " Project  : ${CYAN}$PROJECT_NAME${NC} @ ${YELLOW}$CURRENT_BRANCH${NC}\n"
    printf -- " Path     : ${CYAN}$CUR_PATH${NC}\n"
    printf -- " Auth     : $([ -n "$GITHUB_TOKEN" ] && echo -e "${GREEN}TOKEN ACTIVE${NC}" || echo -e "${RED}NO TOKEN FOUND${NC}")\n"
    printf -- "${GREEN}${BOLD}===============================================================${NC}\n"

    # --- FASE 0: NAVIGATION & SETUP ---
    printf "${CYAN}${BOLD}[FASE 0] NAVIGATION & SETUP${NC}\n"
    printf " P) GOTO PROD        - Switch to $PATH_PROD\n"
    printf " D) GOTO DEV         - Switch to $PATH_DEV\n"
    printf " T) GOTO TEST        - Switch to $PATH_TEST\n"
    printf " 0) NEW CLONE        - Initial project setup\n"

    # --- FASE 1: CONTEXT & DEVELOPMENT ---
    printf "\n${YELLOW}${BOLD}[FASE 1] DEVELOPMENT CYCLE${NC}\n"
    printf " 1) DASHBOARD        - Status & History Overview (Scrollable)\n"
    printf " 2) BRANCH EXPLORER  - Switch or Create new Feature Branch\n"
    printf " 3) QUICK COMMIT     - Stage, Commit & Push active work\n"
    printf " 4) SYNC FETCH       - Pull remote changes into active branch\n"
    printf " 5) SYNC FORCE       - Overwrite Local or GitHub (Conflict fix)\n"
    printf " 6) BACKUP POINT     - Create local snapshot branch\n"

    # --- FASE 2: UAT & RELEASE ---
    printf "\n${MAGENTA}${BOLD}[FASE 2] UAT & RELEASE${NC}\n"
    printf " 7) PREPARE UAT      - Merge branch into TEST (Overwrite conflicts)\n"
    printf " 8) STAGING PUSH     - Force sync current to DEV-STABLE\n"
    printf " 9) MERGE FIXES      - Process external fixes (Jules)\n"
    printf " 10) RELEASE TAG     - Mark current state (v1.x)\n"

    # --- FASE 3: MAINTENANCE & SAFETY ---
    printf "\n${RED}${BOLD}[FASE 3] MAINTENANCE & EMERGENCY${NC}\n"
    printf " 11) CLEANUP PRUNE   - Delete branches gone on GitHub\n"
    printf " 12) DELETE LOCAL    - Manually delete a local branch\n"
    printf " 13) UNDO COMMIT     - Revert last commit (keep files)\n"
    printf " 14) FORCE RESET     - Wipe local and reset to main (CAUTION)\n"
    printf " 15) EMERGENCY       - Abort failed merges / Clear locks\n"
    
    # --- FASE 4: ANALYSIS & TOOLS ---
    printf "\n${BOLD}[FASE 4] ANALYSIS & TOOLS${NC}\n"
    printf " 16) DIFF VIEWER     - Compare changes between branches\n"
    printf " 17) FILE HISTORY    - Show all commits for a file\n"
    printf " 18) SEARCH CODE     - Find text in all files (grep)\n"
    printf " 19) COMMIT FINDER   - Search commits by message\n"
    printf " 20) BRANCH COMPARE  - See differences between branches\n"

    printf -- "\n---------------------------------------------------------------\n"
    printf " S) SETUP PERSISTENCE- Fix QNAP login & Aliases\n"
    printf " Q) QUIT\n"
    printf -- "${BOLD}===============================================================${NC}\n"
    read -p "Select action: " choice

    case $choice in
        [Pp]) cd "$PATH_PROD" 2>/dev/null || printf "${RED}Path not found${NC}\n" ;;
        [Dd]) cd "$PATH_DEV" 2>/dev/null || printf "${RED}Path not found${NC}\n" ;;
        [Tt]) cd "$PATH_TEST" 2>/dev/null || printf "${RED}Path not found${NC}\n" ;;
        
        0) # NEW CLONE
            clear
            printf "${CYAN}Fetching repositories...${NC}\n"
            API_URL="https://api.github.com/user/repos?per_page=100&affiliation=owner"
            # BusyBox-friendly: sed instead of grep -o
            REPOS_RAW=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL" \
                | sed -n 's/.*"name": "\([^"]*\)".*/\1/p' | grep -v "License" | grep -v "GNU")
            
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
            read -p "Enter..." junk ;;

        1) # DASHBOARD
            [[ "$IN_GIT" = false ]] && { printf "${RED}Not in git repo${NC}\n"; read -p "Enter..." junk; continue; }
            clear
            printf "${CYAN}${BOLD}DASHBOARD: $PROJECT_NAME${NC}\n\n"
            git fetch origin --prune 2>/dev/null
            
            # Use more instead of less for BusyBox compatibility
            # Simpler git log flags for BusyBox
            {
                show_git_stats
                printf "\n${BOLD}=== BRANCH INFO ===${NC}\n"
                git branch -vv
                printf "\n${BOLD}=== FILE STATUS ===${NC}\n"
                git status
                printf "\n${BOLD}=== RECENT HISTORY ===${NC}\n"
                git log -n 20 --oneline --graph
            } | more
            
            read -p "Enter..." junk ;;

        2) # BRANCH EXPLORER
            [[ "$IN_GIT" = false ]] && continue
            check_dirty || continue
            get_branch_list_raw "be"
            print_colored_branch_list "be"
            read -p "Select number or name for NEW branch: " be_val
            [[ "$be_val" =~ ^[Xx]$ ]] && continue
            
            if [[ "$be_val" =~ ^[0-9]+$ ]]; then
                target_branch="${!be_val@}"
                target_branch=$(eval echo "\$be_${be_val}")
                target_branch="${target_branch#remotes/origin/}"
                git checkout "$target_branch" 2>/dev/null || git checkout -b "$target_branch" "origin/$target_branch"
                git pull origin "$target_branch" 2>/dev/null
            else
                git checkout -b "$be_val" && printf "${GREEN}Branch $be_val created.${NC}\n"
            fi
            read -p "Enter..." junk junk ;;

        3) # QUICK COMMIT
            [[ "$IN_GIT" = false ]] && continue
            git status -s
            read -p "Commit Message (X to cancel): " msg
            [[ "$msg" =~ ^[Xx]$ ]] && continue
            
            if [[ -n "$msg" ]]; then
                git add . && \
                git commit -m "$msg" && \
                git push origin "$CURRENT_BRANCH"
                read -p "Work pushed. Enter..." junk
            fi ;;

        4) # SYNC FETCH
            [[ "$IN_GIT" = false ]] && continue
            git pull origin "$CURRENT_BRANCH"
            read -p "Pull complete. Enter..." junk ;;

        5) # SYNC FORCE
            [[ "$IN_GIT" = false ]] && continue
            git fetch origin
            printf "A) OVERWRITE LOCAL (Loss of local work)\nB) FORCE PUSH (Loss of GitHub work)\nX) Cancel\n"
            read -p "Action: " fa_choice
            [[ "$fa_choice" =~ [Aa] ]] && git reset --hard "origin/$CURRENT_BRANCH"
            [[ "$fa_choice" =~ [Bb] ]] && git push origin "$CURRENT_BRANCH" --force
            read -p "Sync complete. Enter..." junk ;;

        6) # BACKUP POINT
            [[ "$IN_GIT" = false ]] && continue
            TS=$(date +%Y%m%d_%H%M)
            git branch "backup/${CURRENT_BRANCH}_$TS"
            printf "${GREEN}Backup created.${NC}\n"
            read -p "Enter..." junk ;;

        7) # PREPARE UAT
            [[ "$IN_GIT" = false ]] && continue
            printf "${MAGENTA}Preparing UAT Environment (Force Overwrite Mode)...${NC}\n"
            git stash > /dev/null 2>&1
            get_branch_list_raw "uat"
            print_colored_branch_list "uat"
            read -p "Select Jules' branch to test: " uat_idx
            [[ "$uat_idx" =~ ^[Xx]$ ]] && continue
            
            jules_br=$(eval echo "\$uat_${uat_idx}")
            jules_br="${jules_br#remotes/origin/}"
            
            git checkout main && git pull origin main
            git checkout -B uat
            
            printf "${YELLOW}Merging and forcing file checkout to bypass untracked errors...${NC}\n"
            if git merge -X theirs "origin/$jules_br" --no-edit; then
                git checkout "origin/$jules_br" -- . 2>/dev/null
                printf "${GREEN}UAT environment is ready.${NC}\n"
            else
                printf "${RED}Merge failed. Check emergency options.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        8) # STAGING PUSH
            [[ "$IN_GIT" = false ]] && continue
            git branch -f dev-stable-backup dev-stable 2>/dev/null
            read -p "Push ${CURRENT_BRANCH} → dev-stable? (y/n): " s_conf
            
            if [[ "$s_conf" == "y" ]]; then
                git checkout dev-stable 2>/dev/null || git checkout -b dev-stable
                git reset --hard "$CURRENT_BRANCH"
                git push origin dev-stable --force && git checkout "$CURRENT_BRANCH"
            fi
            read -p "Enter..." junk ;;

        9) # MERGE FIXES
            [[ "$IN_GIT" = false ]] && continue
            get_branch_list_raw "mf"
            print_colored_branch_list "mf"
            read -p "Select Fix Branch: " mf_idx
            
            fix_br=$(eval echo "\$mf_${mf_idx}")
            fix_br="${fix_br#remotes/origin/}"
            
            if [[ -n "$fix_br" ]]; then
                git merge "origin/$fix_br" --no-edit && git push origin "$CURRENT_BRANCH" && git branch -D "$fix_br" 2>/dev/null
            fi
            read -p "Enter..." junk ;;

        10) # RELEASE TAG
            [[ "$IN_GIT" = false ]] && continue
            git tag -l | tail -n 5
            read -p "New version tag: " v_tag
            
            if [[ -n "$v_tag" ]]; then
                git tag -a "$v_tag" -m "Release $v_tag" && git push origin "$v_tag"
            fi
            read -p "Enter..." junk ;;

        11) # CLEANUP PRUNE
            [[ "$IN_GIT" = false ]] && continue
            git fetch origin --prune
            GONE=$(git branch -vv | grep ': gone]' | awk '{print $1}')
            
            if [[ -n "$GONE" ]]; then
                echo "$GONE" | xargs git branch -D
                printf "${GREEN}Pruned dead branches.${NC}\n"
            else
                printf "Nothing to prune.\n"
            fi
            read -p "Enter..." junk ;;

        12) # DELETE LOCAL
            [[ "$IN_GIT" = false ]] && continue
            get_branch_list_raw "dk"
            print_colored_branch_list "dk"
            read -p "Number to DELETE (CAUTION): " dk_idx
            
            del_br=$(eval echo "\$dk_${dk_idx}")
            if [[ "$del_br" != "$CURRENT_BRANCH" ]] && [[ -n "$del_br" ]]; then
                git branch -D "$del_br"
                printf "${RED}Branch $del_br deleted.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        13) # UNDO COMMIT
            [[ "$IN_GIT" = false ]] && continue
            git reset --soft HEAD~1
            printf "${YELLOW}Last commit undone. Changes are kept in stage (files kept)${NC}\n"
            read -p "Enter..." junk ;;

        14) # FORCE RESET
            [[ "$IN_GIT" = false ]] && continue
            if [[ $IS_PROD -eq 1 ]]; then
                printf "${RED}${BOLD}!!! WARNING: YOU ARE IN PROD ENVIRONMENT !!!${NC}\n"
            fi
            
            read -p "Type PROCEED to wipe local and reset to main: " p_conf
            if [[ "$p_conf" == "PROCEED" ]]; then
                git checkout main && \
                git reset --hard origin/main && \
                git clean -fd
                printf "${GREEN}Reset successful.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        15) # EMERGENCY
            [[ "$IN_GIT" = false ]] && continue
            printf "1) ABORT MERGE 2) CLEAR LOCKS 3) POP STASH\n"
            read -p "Action: " em_c
            
            [[ "$em_c" == "1" ]] && git merge --abort
            [[ "$em_c" == "2" ]] && rm -f .git/index.lock
            [[ "$em_c" == "3" ]] && git stash pop
            read -p "Enter..." junk ;;

        16) # DIFF VIEWER
            [[ "$IN_GIT" = false ]] && continue
            clear
            printf "${CYAN}${BOLD}DIFF VIEWER${NC}\n\n"
            printf "Compare:\n"
            printf "1) Current changes (unstaged)\n"
            printf "2) Staged changes\n"
            printf "3) Compare two branches\n"
            printf "4) Compare with specific commit\n"
            read -p "Select: " diff_choice
            
            case "$diff_choice" in
                1) git diff | more ;;
                2) git diff --cached | more ;;
                3) 
                    get_branch_list_raw "diff"
                    print_colored_branch_list "diff"
                    read -p "First branch: " b1
                    read -p "Second branch: " b2
                    br1=$(eval echo "\$diff_${b1}")
                    br2=$(eval echo "\$diff_${b2}")
                    git diff "${br1}".."${br2}" | more
                    ;;
                4)
                    git log --oneline -n 10
                    read -p "Commit hash: " commit_hash
                    git diff "${commit_hash}" | more
                    ;;
            esac
            read -p "Enter..." junk ;;

        17) # FILE HISTORY
            [[ "$IN_GIT" = false ]] && continue
            clear
            printf "${CYAN}${BOLD}FILE HISTORY${NC}\n\n"
            read -p "Enter filename (with path): " filename
            
            if [[ -n "$filename" ]]; then
                printf "\n${YELLOW}Commits affecting: ${filename}${NC}\n\n"
                git log --follow --oneline -- "$filename" | more
                printf "\n"
                read -p "See detailed changes? (y/n): " show_detail
                if [[ "$show_detail" == "y" ]]; then
                    git log --follow -p -- "$filename" | more
                fi
            fi
            read -p "Enter..." junk ;;

        18) # SEARCH CODE
            [[ "$IN_GIT" = false ]] && continue
            clear
            printf "${CYAN}${BOLD}CODE SEARCH${NC}\n\n"
            read -p "Search for text: " search_text
            
            if [[ -n "$search_text" ]]; then
                printf "\n${YELLOW}Searching for: '${search_text}'${NC}\n\n"
                git grep -n "$search_text" 2>/dev/null | more || {
                    printf "${YELLOW}Not found in tracked files. Searching all files...${NC}\n"
                    grep -r -n "$search_text" . 2>/dev/null | grep -v ".git/" | more
                }
            fi
            read -p "Enter..." junk ;;

        19) # COMMIT FINDER
            [[ "$IN_GIT" = false ]] && continue
            clear
            printf "${CYAN}${BOLD}COMMIT FINDER${NC}\n\n"
            read -p "Search commit messages for: " search_msg
            
            if [[ -n "$search_msg" ]]; then
                printf "\n${YELLOW}Commits containing: '${search_msg}'${NC}\n\n"
                git log --all --oneline --grep="$search_msg" | more
                printf "\n"
                read -p "Show full details? (y/n): " show_full
                if [[ "$show_full" == "y" ]]; then
                    git log --all --grep="$search_msg" | more
                fi
            fi
            read -p "Enter..." junk ;;

        20) # BRANCH COMPARE
            [[ "$IN_GIT" = false ]] && continue
            clear
            printf "${CYAN}${BOLD}BRANCH COMPARISON${NC}\n\n"
            get_branch_list_raw "cmp"
            print_colored_branch_list "cmp"
            
            read -p "Base branch (what you have): " base_idx
            read -p "Compare branch (what you want to check): " cmp_idx
            
            base_br=$(eval echo "\$cmp_${base_idx}")
            cmp_br=$(eval echo "\$cmp_${cmp_idx}")
            base_br="${base_br#remotes/origin/}"
            cmp_br="${cmp_br#remotes/origin/}"
            
            if [[ -n "$base_br" ]] && [[ -n "$cmp_br" ]]; then
                printf "\n${YELLOW}Commits in ${cmp_br} not in ${base_br}:${NC}\n\n"
                git log "${base_br}".."${cmp_br}" --oneline | more
                printf "\n"
                read -p "Show file differences? (y/n): " show_files
                if [[ "$show_files" == "y" ]]; then
                    git diff "${base_br}"..."${cmp_br}" --stat | more
                fi
            fi
            read -p "Enter..." junk ;;

        [Ss]) # SETUP
            clear
            printf "${YELLOW}Environment Setup${NC}\n"
            printf "Current .env: ${ENV_FILE}\n\n"
            
            printf "1) Edit current .env\n"
            printf "2) Create new .env from template\n"
            printf "3) Show current configuration\n"
            printf "X) Cancel\n\n"
            read -p "Choose option: " setup_choice
            
            case "$setup_choice" in
                1)
                    ${EDITOR:-nano} "$ENV_FILE"
                    printf "${GREEN}Reloading configuration...${NC}\n"
                    load_env
                    ;;
                2)
                    if [[ -f "$ENV_EXAMPLE" ]]; then
                        read -p "This will overwrite current .env. Continue? (y/n): " confirm
                        if [[ "$confirm" == "y" ]]; then
                            cp "$ENV_EXAMPLE" "$ENV_FILE"
                            printf "${GREEN}Created new .env from template${NC}\n"
                            printf "${YELLOW}Please edit and configure it now${NC}\n"
                            ${EDITOR:-nano} "$ENV_FILE"
                            load_env
                        fi
                    else
                        printf "${RED}.env.example not found at: ${ENV_EXAMPLE}${NC}\n"
                    fi
                    ;;
                3)
                    printf "\n${CYAN}Current Configuration:${NC}\n"
                    printf "  GitHub User: ${GITHUB_USERNAME}\n"
                    printf "  GitHub Token: $([ -n "$GITHUB_TOKEN" ] && echo "***configured***" || echo "NOT SET")\n"
                    printf "  PATH_ROOT: ${PATH_ROOT}\n"
                    printf "  PATH_PROD: ${PATH_PROD}\n"
                    printf "  PATH_DEV: ${PATH_DEV}\n"
                    printf "  PATH_TEST: ${PATH_TEST}\n"
                    ;;
                [Xx]) ;;
            esac
            read -p "Enter..." junk ;;

        [Qq]) clear; exit 0 ;;
        *) sleep 0.1 ;;
    esac
done
