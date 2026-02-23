#!/bin/bash

# ============================================================
# GIT MASTER CONTROL PANEL v7.1.0
# Professional Git Workflow Manager for QNAP & macOS
# ============================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# --- ENVIRONMENT DETECTION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/config/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/config/.env.example"

# Load environment variables
load_env() {
    if [[ ! -f "$ENV_FILE" ]]; then
        printf "\n${YELLOW}Configuration file not found.${NC}\n"

        if [[ -f "$ENV_EXAMPLE" ]]; then
            read -p "Create .env from template? (y/n): " create_env
            if [[ "$create_env" == "y" ]]; then
                cp "$ENV_EXAMPLE" "$ENV_FILE"
                printf "${GREEN}Created .env file.${NC}\n"
                printf "${CYAN}Opening editor to configure settings...${NC}\n"
                sleep 1
                ${EDITOR:-nano} "$ENV_FILE"
            else
                printf "${RED}Setup aborted. Please configure .env manually before running gitmaster.${NC}\n"
                exit 1
            fi
        else
            printf "${RED}ERROR: Template .env.example missing. Please create .env manually.${NC}\n"
            exit 1
        fi
    fi
    
    # Parse .env file, ignoring comments and empty lines
    # Using '|| [ -n "$key" ]' to handle files without trailing newline
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # Trim leading/trailing whitespace from key
        key=$(echo "$key" | xargs)

        # Validate key is a valid identifier (alphanumeric + underscore, starts with letter/underscore)
        if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            # echo "Warning: Skipping invalid key '$key'"
            continue
        fi

        # Remove quotes and export
        value="${value%\"}"
        value="${value#\"}"
        export "$key=$value"
    done < "$ENV_FILE"
    
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

# Ensure authentication token is configured in git remote
check_and_fix_remote_auth() {
    # Only run if we are in a git repo and have a token
    if [[ "${IN_GIT:-false}" == "true" ]] && [[ -n "${GITHUB_TOKEN:-}" ]]; then
        local remote_url
        remote_url=$(git remote get-url origin 2>/dev/null || echo "")

        # Check if it's an HTTPS URL to github.com
        if [[ "$remote_url" == https://github.com/* ]]; then
            # Check if token is missing (no @ symbol before github.com)
            if [[ "$remote_url" != *"@"* ]]; then
                 # Construct new URL with token
                 # Remove https:// prefix and prepend https://${GITHUB_TOKEN}@
                 local new_url="https://${GITHUB_TOKEN}@${remote_url#https://}"

                 # Update remote URL silently
                 git remote set-url origin "$new_url"
                 # printf "${GREEN}Added authentication token to git remote.${NC}\n"
            fi
        fi
    fi
}

# --- INITIALIZATION ---
load_env

# --- COMMAND LINE ARGUMENTS ---
CMD_SWITCH=""
if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help|-help)
            printf "${GREEN}Git Master Control Panel - Command Line Switches${NC}\n"
            printf "Usage: gitmaster [option]\n\n"
            printf "  ${CYAN}-st, --status${NC}     Dashboard (Option 1)\n"
            printf "  ${CYAN}-co, --checkout${NC}   Checkout Repo (Option 2)\n"
            printf "  ${CYAN}-br, --branch${NC}     Branch Explorer (Option 3)\n"
            printf "  ${CYAN}-cm, --commit${NC}     Quick Commit (Option 4)\n"
            printf "  ${CYAN}-pl, --pull${NC}       Sync Fetch (Option 5)\n"
            printf "  ${CYAN}-fs, --force-sync${NC} Sync Force (Option 6)\n"
            printf "  ${CYAN}-bk, --backup${NC}     Backup Point (Option 7)\n"
            printf "  ${CYAN}-pr, --prune${NC}      Cleanup Prune (Option 12)\n"
            printf "  ${CYAN}-h,  --help${NC}       Show this help\n"
            exit 0
            ;;
        -st|--status)     CMD_SWITCH="1" ;;
        -co|--checkout)   CMD_SWITCH="2" ;;
        -br|--branch)     CMD_SWITCH="3" ;;
        -cm|--commit)     CMD_SWITCH="4" ;;
        -pl|--pull)       CMD_SWITCH="5" ;;
        -fs|--force-sync) CMD_SWITCH="6" ;;
        -bk|--backup)     CMD_SWITCH="7" ;;
        -pr|--prune)      CMD_SWITCH="12" ;;
        *)
            printf "${RED}Unknown option: $1${NC}\n"
            printf "Use -h for help.\n"
            exit 1
            ;;
    esac
fi

# --- MAIN PROGRAM ---

while true; do
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

    # Check and fix authentication if needed
    check_and_fix_remote_auth

    if [[ -z "$CMD_SWITCH" ]]; then
        clear
        # Header
        printf -- "${GREEN}${BOLD}===============================================================${NC}\n"
        printf -- "       ${GREEN}${BOLD}GIT MASTER CONTROL PANEL v7.1.0${NC}\n"
        printf -- "${GREEN}${BOLD}===============================================================${NC}\n"
        printf -- " Status   : $ENV_VAL\n"
        printf -- " Project  : ${CYAN}$PROJECT_NAME${NC} @ ${YELLOW}$CURRENT_BRANCH${NC}\n"
        printf -- " Path     : ${CYAN}$CUR_PATH${NC}\n"
        printf -- " Auth     : $([ -n "$GITHUB_TOKEN" ] && echo -e "${GREEN}TOKEN ACTIVE${NC}" || echo -e "${RED}NO TOKEN FOUND${NC}")\n"
        printf -- "${GREEN}${BOLD}===============================================================${NC}\n"

        # --- FASE 1: CONTEXT & DEVELOPMENT ---
        printf "${YELLOW}${BOLD}[FASE 1] DEVELOPMENT CYCLE${NC}\n"
        printf " 1) DASHBOARD        - Status & History Overview (Scrollable)\n"
        printf " 2) CHECKOUT REPO    - Fetch & Switch to Repository (Branch)\n"
        printf " 3) BRANCH EXPLORER  - Switch or Create new Feature Branch\n"
        printf " 4) QUICK COMMIT     - Stage, Commit & Push active work\n"
        printf " 5) SYNC FETCH       - Pull remote changes into active branch\n"
        printf " 6) SYNC FORCE       - Overwrite Local or GitHub (Conflict fix)\n"
        printf " 7) BACKUP POINT     - Create local snapshot branch\n"

        # --- FASE 2: UAT & RELEASE ---
        printf "\n${MAGENTA}${BOLD}[FASE 2] UAT & RELEASE${NC}\n"
        printf " 8) PREPARE UAT      - Merge branch into TEST (Overwrite conflicts)\n"
        printf " 9) STAGING PUSH     - Force sync current to DEV-STABLE\n"
        printf " 10) MERGE FIXES     - Process external fixes (Jules)\n"
        printf " 11) RELEASE TAG     - Mark current state (v1.x)\n"

        # --- FASE 3: MAINTENANCE & SAFETY ---
        printf "\n${RED}${BOLD}[FASE 3] MAINTENANCE & EMERGENCY${NC}\n"
        printf " 12) CLEANUP PRUNE   - Delete branches gone on GitHub\n"
        printf " 13) DELETE LOCAL    - Manually delete a local branch\n"
        printf " 14) UNDO COMMIT     - Revert last commit (keep files)\n"
        printf " 15) FORCE RESET     - Wipe local and reset to main (CAUTION)\n"
        printf " 16) EMERGENCY       - Abort failed merges / Clear locks\n"

        # --- FASE 4: ANALYSIS & TOOLS ---
        printf "\n${BOLD}[FASE 4] ANALYSIS & TOOLS${NC}\n"
        printf " 17) DIFF VIEWER     - Compare changes between branches\n"
        printf " 18) FILE HISTORY    - Show all commits for a file\n"
        printf " 19) SEARCH CODE     - Find text in all files (grep)\n"
        printf " 20) COMMIT FINDER   - Search commits by message\n"
        printf " 21) BRANCH COMPARE  - See differences between branches\n"

        printf -- "\n---------------------------------------------------------------\n"
        printf " S) SETUP PERSISTENCE- Fix QNAP login & Aliases\n"
        printf " Q) QUIT\n"
        printf -- "${BOLD}===============================================================${NC}\n"
        read -p "Select action: " choice
    else
        choice="$CMD_SWITCH"
    fi

    case $choice in
        1) # DASHBOARD
            [[ "$IN_GIT" = false ]] && { printf "${RED}Not in git repo${NC}\n"; read -p "Enter..." junk; continue; }
            clear
            printf "${CYAN}${BOLD}DASHBOARD: $PROJECT_NAME${NC}\n\n"
            git fetch origin --prune 2>/dev/null || true
            
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

        2) # CHECKOUT REPO
            [[ "$IN_GIT" = false ]] && continue
            check_dirty || continue

            printf "${CYAN}Fetching updates from origin...${NC}\n"
            # Capture output to detect new branches
            # || true prevents crash if fetch fails (e.g., network/auth error)
            git fetch origin --prune > /tmp/git_fetch_out 2>&1 || true
            cat /tmp/git_fetch_out

            # Parse for new branches
            # Usually: * [new branch]      feature/foo -> origin/feature/foo
            # $4 is feature/foo
            new_branches=$(grep "\[new branch\]" /tmp/git_fetch_out | awk '{print $4}' || true)
            rm -f /tmp/git_fetch_out

            printf "\n${CYAN}${BOLD}Available Repositories (Branches):${NC}\n"

            # Build list from git branch -r
            i=1
            declare -a repo_list
            # git branch -r output: "  origin/HEAD -> origin/main", "  origin/main"
            while IFS= read -r branch; do
                # Clean up: remove "origin/" prefix
                raw_branch=$(echo "$branch" | sed 's/^[* ]*//')
                clean_branch=$(echo "$raw_branch" | sed 's/origin\///' | awk '{print $1}')

                # Skip HEAD pointer
                [[ "$clean_branch" == "HEAD" || "$raw_branch" == *"->"* ]] && continue

                mark=""
                # Check if clean_branch matches anything in new_branches
                if echo "$new_branches" | grep -q "^$clean_branch$"; then
                    mark=" ${GREEN}(NEW)${NC}"
                fi

                printf " %2d) %s%s\n" "$i" "$clean_branch" "$mark"
                repo_list[$i]="$clean_branch"
                ((i++))
            done < <(git branch -r | grep -v HEAD)

            read -p "Select Repo/Branch (X to cancel): " cr_idx
            [[ "$cr_idx" =~ ^[Xx]$ ]] && continue

            sel_br="${repo_list[$cr_idx]}"
            if [[ -n "$sel_br" ]]; then
                printf "${YELLOW}Checking out $sel_br...${NC}\n"
                git checkout "$sel_br" 2>/dev/null || git checkout -b "$sel_br" "origin/$sel_br"
                git pull origin "$sel_br"
            else
                printf "${RED}Invalid selection.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        3) # BRANCH EXPLORER
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

        4) # QUICK COMMIT
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

        5) # SYNC FETCH
            [[ "$IN_GIT" = false ]] && continue
            git pull origin "$CURRENT_BRANCH" || printf "${RED}Pull failed. Check conflicts/network.${NC}\n"
            read -p "Pull complete. Enter..." junk ;;

        6) # SYNC FORCE
            [[ "$IN_GIT" = false ]] && continue
            git fetch origin || printf "${RED}Fetch failed.${NC}\n"
            printf "A) OVERWRITE LOCAL (Loss of local work)\nB) FORCE PUSH (Loss of GitHub work)\nX) Cancel\n"
            read -p "Action: " fa_choice
            [[ "$fa_choice" =~ [Aa] ]] && git reset --hard "origin/$CURRENT_BRANCH"
            [[ "$fa_choice" =~ [Bb] ]] && git push origin "$CURRENT_BRANCH" --force
            read -p "Sync complete. Enter..." junk ;;

        7) # BACKUP POINT
            [[ "$IN_GIT" = false ]] && continue
            TS=$(date +%Y%m%d_%H%M)
            git branch "backup/${CURRENT_BRANCH}_$TS"
            printf "${GREEN}Backup created.${NC}\n"
            read -p "Enter..." junk ;;

        8) # PREPARE UAT
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

        9) # STAGING PUSH
            [[ "$IN_GIT" = false ]] && continue
            git branch -f dev-stable-backup dev-stable 2>/dev/null
            read -p "Push ${CURRENT_BRANCH} → dev-stable? (y/n): " s_conf
            
            if [[ "$s_conf" == "y" ]]; then
                git checkout dev-stable 2>/dev/null || git checkout -b dev-stable
                git reset --hard "$CURRENT_BRANCH"
                git push origin dev-stable --force && git checkout "$CURRENT_BRANCH"
            fi
            read -p "Enter..." junk ;;

        10) # MERGE FIXES
            [[ "$IN_GIT" = false ]] && continue
            get_branch_list_raw "mf"
            print_colored_branch_list "mf"
            read -p "Select Fix Branch: " mf_idx
            [[ "$mf_idx" =~ ^[Xx]$ ]] && continue

            # Validate input
            if [[ ! "$mf_idx" =~ ^[0-9]+$ ]]; then
                 printf "${RED}Invalid input.${NC}\n"
                 read -p "Enter..." junk
                 continue
            fi

            # Check range (avoid unbound variable crash)
            if [[ -z "$(eval echo "\${mf_${mf_idx}:-}")" ]]; then
                printf "${RED}Invalid selection.${NC}\n"
                read -p "Enter..." junk
                continue
            fi
            
            fix_br=$(eval echo "\$mf_${mf_idx}")
            fix_br="${fix_br#remotes/origin/}"
            
            if [[ -n "$fix_br" ]]; then
                git merge "origin/$fix_br" --no-edit && git push origin "$CURRENT_BRANCH" && git branch -D "$fix_br" 2>/dev/null
            fi
            read -p "Enter..." junk ;;

        11) # RELEASE TAG
            [[ "$IN_GIT" = false ]] && continue
            git tag -l | tail -n 5
            read -p "New version tag: " v_tag
            
            if [[ -n "$v_tag" ]]; then
                git tag -a "$v_tag" -m "Release $v_tag" && git push origin "$v_tag"
            fi
            read -p "Enter..." junk ;;

        12) # CLEANUP PRUNE
            [[ "$IN_GIT" = false ]] && continue
            git fetch origin --prune || true
            # || true prevents script exit if grep finds nothing (set -e)
            GONE=$(git branch -vv | grep ': gone]' | awk '{print $1}' || true)
            
            if [[ -n "$GONE" ]]; then
                echo "$GONE" | xargs git branch -D
                printf "${GREEN}Pruned dead branches.${NC}\n"
            else
                printf "Nothing to prune.\n"
            fi
            read -p "Enter..." junk ;;

        13) # DELETE LOCAL
            [[ "$IN_GIT" = false ]] && continue
            get_branch_list_raw "dk"
            print_colored_branch_list "dk"
            read -p "Number to DELETE (CAUTION): " dk_idx
            [[ "$dk_idx" =~ ^[Xx]$ ]] && continue

            # Validate input
            if [[ ! "$dk_idx" =~ ^[0-9]+$ ]]; then
                 printf "${RED}Invalid input.${NC}\n"
                 read -p "Enter..." junk
                 continue
            fi

            # Check range (avoid unbound variable crash)
            if [[ -z "$(eval echo "\${dk_${dk_idx}:-}")" ]]; then
                printf "${RED}Invalid selection.${NC}\n"
                read -p "Enter..." junk
                continue
            fi
            
            del_br=$(eval echo "\$dk_${dk_idx}")
            if [[ "$del_br" != "$CURRENT_BRANCH" ]] && [[ -n "$del_br" ]]; then
                git branch -D "$del_br"
                printf "${RED}Branch $del_br deleted.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        14) # UNDO COMMIT
            [[ "$IN_GIT" = false ]] && continue
            git reset --soft HEAD~1
            printf "${YELLOW}Last commit undone. Changes are kept in stage (files kept)${NC}\n"
            read -p "Enter..." junk ;;

        15) # FORCE RESET
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

        16) # EMERGENCY
            [[ "$IN_GIT" = false ]] && continue
            printf "1) ABORT MERGE 2) CLEAR LOCKS 3) POP STASH\n"
            read -p "Action: " em_c
            
            [[ "$em_c" == "1" ]] && git merge --abort
            [[ "$em_c" == "2" ]] && rm -f .git/index.lock
            [[ "$em_c" == "3" ]] && git stash pop
            read -p "Enter..." junk ;;

        17) # DIFF VIEWER
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
                    [[ "$b1" =~ ^[Xx]$ ]] && continue

                    if [[ ! "$b1" =~ ^[0-9]+$ ]] || [[ -z "$(eval echo "\${diff_${b1}:-}")" ]]; then
                        printf "${RED}Invalid selection.${NC}\n"
                        read -p "Enter..." junk
                        continue
                    fi

                    read -p "Second branch: " b2
                    [[ "$b2" =~ ^[Xx]$ ]] && continue

                    if [[ ! "$b2" =~ ^[0-9]+$ ]] || [[ -z "$(eval echo "\${diff_${b2}:-}")" ]]; then
                        printf "${RED}Invalid selection.${NC}\n"
                        read -p "Enter..." junk
                        continue
                    fi

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

        18) # FILE HISTORY
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

        19) # SEARCH CODE
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

        20) # COMMIT FINDER
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

        21) # BRANCH COMPARE
            [[ "$IN_GIT" = false ]] && continue
            clear
            printf "${CYAN}${BOLD}BRANCH COMPARISON${NC}\n\n"
            get_branch_list_raw "cmp"
            print_colored_branch_list "cmp"
            
            read -p "Base branch (what you have): " base_idx
            [[ "$base_idx" =~ ^[Xx]$ ]] && continue

            if [[ ! "$base_idx" =~ ^[0-9]+$ ]] || [[ -z "$(eval echo "\${cmp_${base_idx}:-}")" ]]; then
                printf "${RED}Invalid selection.${NC}\n"
                read -p "Enter..." junk
                continue
            fi

            read -p "Compare branch (what you want to check): " cmp_idx
            [[ "$cmp_idx" =~ ^[Xx]$ ]] && continue

            if [[ ! "$cmp_idx" =~ ^[0-9]+$ ]] || [[ -z "$(eval echo "\${cmp_${cmp_idx}:-}")" ]]; then
                printf "${RED}Invalid selection.${NC}\n"
                read -p "Enter..." junk
                continue
            fi
            
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
            printf "4) Install Aliases (Multi-Shell Support)\n"
            printf "X) Cancel\n\n"
            read -p "Choose option: " setup_choice
            
            case "$setup_choice" in
                1)
                    ${EDITOR:-nano} "$ENV_FILE"
                    printf "${GREEN}Reloading configuration...${NC}\n"
                    load_env
                    ;;
                2)
                    if [[ -f "$ENV_FILE" ]]; then
                        printf "\n${YELLOW}=== CURRENT REQUIRED INFO ===${NC}\n"
                        # Parse only REQUIRED fields for display
                        grep -E "^(GITHUB_TOKEN|GITHUB_USERNAME|PATH_ROOT)=" "$ENV_FILE" | while IFS='=' read -r key value; do
                            value="${value%\"}"
                            value="${value#\"}"
                            printf "  ${CYAN}%-15s${NC}: %s\n" "$key" "$value"
                        done
                        printf "${YELLOW}=============================${NC}\n\n"

                        read -p "Existing configuration found. Use this configuration (and cancel overwrite)? (y/n): " use_existing
                        if [[ "$use_existing" == "y" ]]; then
                            printf "${GREEN}Keeping existing configuration.${NC}\n"
                            read -p "Enter..." junk
                            continue
                        fi
                    fi

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
                4)
                     # Re-use the master dev-tools script if available, or simple local alias
                     ROOT_DIR=$(dirname "$SCRIPT_DIR")
                     if [[ -f "$ROOT_DIR/dev-tools.sh" ]]; then
                         printf "${CYAN}Launching Master Dev Tools Setup...${NC}\n"
                         "$ROOT_DIR/dev-tools.sh"
                     else
                         printf "${YELLOW}Master Dev Tools script not found. Please run it from root.${NC}\n"
                     fi
                     read -p "Enter..." junk
                     ;;
                [Xx]) ;;
            esac
            read -p "Enter..." junk ;;

        [Qq]) clear; exit 0 ;;
        *) sleep 0.1 ;;
    esac

    # Exit if running in command-line switch mode
    if [[ -n "$CMD_SWITCH" ]]; then
        exit 0
    fi
done
