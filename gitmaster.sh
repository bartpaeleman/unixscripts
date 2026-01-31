#!/bin/bash

# --- CONFIGURATIE: BASIS PADEN ---
DEFAULT_USER="bartpaeleman"
PATH_ROOT="/share/Web"

# Automatische generatie van sub-omgevingen
PATH_PROD="${PATH_ROOT}"
PATH_DEV="${PATH_ROOT}/DEV"
PATH_TEST="${PATH_ROOT}/TEST"

PERSISTENT_SCRIPT_PATH="${PATH_DEV}/scripts/git-master.sh"
PERSISTENT_ENV="${PATH_DEV}/scripts/qnap_init.sh"

# --- AUTO-RECOVERY ---
[[ -f "$PERSISTENT_ENV" ]] && source "$PERSISTENT_ENV"

# --- KLEUR DEFINITIES ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m'

# --- HELPER FUNCTIES ---

get_branch_list_raw() {
    printf "${CYAN}Fetching branches from GitHub...${NC}\n"
    git fetch origin --prune > /dev/null 2>&1
    git branch -a | grep -v 'origin/HEAD' | sed -e 's/remotes\/origin\///' -e 's/\* //' -e 's/  //' | sort -u > /tmp/git_br_raw
}

print_colored_branch_list() {
    local i=1
    local cur_br=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    while IFS= read -r line; do
        if [ "$line" == "$cur_br" ]; then
            printf "$i) ${YELLOW}${BOLD}* $line (ACTIVE)${NC}\n"
        else
            printf "$i) ${CYAN}$line${NC}\n"
        fi
        eval "$1_$i=\"$line\""
        i=$((i+1))
    done < /tmp/git_br_raw
    printf "X) ${RED}Cancel / Back${NC}\n"
}

check_dirty() {
    if [[ -n $(git status -s) ]]; then
        printf "${RED}${BOLD}WARNING: Uncommitted changes detected!${NC}\n"
        read -p "Force proceed anyway? (y/n): " cont
        [[ "$cont" != "y" ]] && return 1
    fi
    return 0
}

# --- MAIN PROGRAM ---

while true; do
    clear
    CUR_PATH=$(pwd)
    PROJECT_NAME=$(basename "$CUR_PATH")
    
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        IN_GIT=true
    else
        CURRENT_BRANCH="N/A"
        IN_GIT=false
    fi
    
    # Omgevingsdetectie
    if [[ "$CUR_PATH" == "$PATH_DEV"* ]]; then
        ENV_VAL="${GREEN}[ ENV: DEV (QNAP) ]${NC}"
        IS_PROD=false
    elif [[ "$CUR_PATH" == "$PATH_TEST"* ]]; then
        ENV_VAL="${YELLOW}[ ENV: TEST (UAT) ]${NC}"
        IS_PROD=false
    elif [[ "$CUR_PATH" == "$PATH_PROD"* ]]; then
        ENV_VAL="${RED}${BOLD}[ ENV: PROD (LIVE) ]${NC}"
        IS_PROD=true
    else
        ENV_VAL="${NC}[ LOCATION: EXTERNAL ]"
        IS_PROD=false
    fi

    printf -- "${GREEN}${BOLD}===============================================================${NC}\n"
    printf -- "       ${GREEN}${BOLD}GIT MASTER CONTROL PANEL v6.9.1${NC}\n"
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

    printf -- "\n---------------------------------------------------------------\n"
    printf " S) SETUP PERSISTENCE- Fix QNAP login & Aliases\n"
    printf " Q) QUIT\n"
    printf -- "${BOLD}===============================================================${NC}\n"
    read -p "Select action: " choice

    case $choice in
        [Pp]) cd "$PATH_PROD" || printf "${RED}Path not found${NC}\n" ;;
        [Dd]) cd "$PATH_DEV" || printf "${RED}Path not found${NC}\n" ;;
        [Tt]) cd "$PATH_TEST" || printf "${RED}Path not found${NC}\n" ;;
        
        0) # NEW CLONE
            clear; printf "${CYAN}Fetching repo list...${NC}\n"
            API_URL="https://api.github.com/user/repos?per_page=100&affiliation=owner"
            REPOS_RAW=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL" | sed -n '/"name":/ s/.*"name": "\(.*\)".*/\1/p' | grep -vE "License|GNU")
            i=1; declare -a repo_array
            while IFS= read -r r; do [ ! -z "$r" ] && printf "$i) $r\n" && repo_array[$i]=$r && i=$((i+1)) ; done <<< "$REPOS_RAW"
            read -p "Number to clone: " r_idx
            [[ "$r_idx" =~ [Xx] ]] && continue
            sel_repo=${repo_array[$r_idx]}
            if [ ! -z "$sel_repo" ]; then
                CLONE_URL="https://$DEFAULT_USER:$GITHUB_TOKEN@github.com/$DEFAULT_USER/$sel_repo.git"
                git clone "$CLONE_URL" && cd "$sel_repo"
            fi ;;

        1) # DASHBOARD
            [[ "$IN_GIT" = false ]] && continue
            clear; printf "${CYAN}${BOLD}DASHBOARD: $PROJECT_NAME${NC}\n"
            git fetch origin --prune
            (
                printf "${BOLD}=== BRANCH INFO ===${NC}\n"; git branch -vv
                printf "\n${BOLD}=== FILE STATUS ===${NC}\n"; git status
                printf "\n${BOLD}=== RECENT HISTORY ===${NC}\n"; git log -n 20 --oneline --graph --decorate --color
            ) | more
            read -p "Back to menu? (Enter)" junk ;;

        2) # BRANCH EXPLORER
            [[ "$IN_GIT" = false ]] && continue
            check_dirty || continue
            get_branch_list_raw; print_colored_branch_list "be"
            read -p "Select number or name for NEW branch: " be_val
            [[ "$be_val" =~ [Xx] ]] && continue
            if [[ "$be_val" =~ ^[0-9]+$ ]]; then
                act_br=$(eval echo "\$be_$be_val")
                git checkout "$act_br" 2>/dev/null || git checkout -b "$act_br" "origin/$act_br"
                git pull origin "$act_br" 2>/dev/null
            else
                git checkout -b "$be_val" && printf "${GREEN}Branch $be_val created.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        3) # QUICK COMMIT
            [[ "$IN_GIT" = false ]] && continue
            git status -s; read -p "Commit Message (X to cancel): " msg
            [[ "$msg" =~ [Xx] ]] && continue
            if [ -n "$msg" ]; then
                git add . && git commit -m "$msg" && git push origin "$CURRENT_BRANCH"
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
            printf "${GREEN}Backup created.${NC}\n"; read -p "Enter..." junk ;;

        7) # PREPARE UAT
            [[ "$IN_GIT" = false ]] && continue
            printf "${MAGENTA}Preparing UAT Environment (Force Overwrite Mode)...${NC}\n"
            git stash > /dev/null 2>&1
            get_branch_list_raw; print_colored_branch_list "uat"
            read -p "Select Jules' branch to test: " uat_idx
            [[ "$uat_idx" =~ [Xx] ]] && continue
            jules_br=$(eval echo "\$uat_$uat_idx")
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
            read -p "Push $CURRENT_BRANCH to DEV-STABLE? (y/n): " s_conf
            if [[ "$s_conf" == "y" ]]; then
                git checkout dev-stable || git checkout -b dev-stable
                git reset --hard "$CURRENT_BRANCH"
                git push origin dev-stable --force && git checkout "$CURRENT_BRANCH"
            fi
            read -p "Enter..." junk ;;

        9) # MERGE FIXES
            [[ "$IN_GIT" = false ]] && continue
            get_branch_list_raw; print_colored_branch_list "mf"
            read -p "Select Fix Branch: " mf_idx
            fix_br=$(eval echo "\$mf_$mf_idx")
            if [ -n "$fix_br" ]; then
                git merge "origin/$fix_br" --no-edit && git push origin "$CURRENT_BRANCH" && git branch -D "$fix_br" 2>/dev/null
            fi
            read -p "Enter..." junk ;;

        10) # RELEASE TAG
            [[ "$IN_GIT" = false ]] && continue
            git tag -l | tail -n 5; read -p "New version tag: " v_tag
            if [ -n "$v_tag" ]; then
                git tag -a "$v_tag" -m "Release $v_tag" && git push origin "$v_tag"
            fi
            read -p "Enter..." junk ;;

        11) # CLEANUP PRUNE
            [[ "$IN_GIT" = false ]] && continue
            git fetch origin --prune
            GONE=$(git branch -vv | grep ': gone]' | awk '{print $1}')
            if [ -n "$GONE" ]; then
                echo "$GONE" | xargs git branch -D
                printf "${GREEN}Pruned dead branches.${NC}\n"
            else
                printf "Nothing to prune.\n"
            fi
            read -p "Enter..." junk ;;

        12) # DELETE LOCAL
            [[ "$IN_GIT" = false ]] && continue
            get_branch_list_raw; print_colored_branch_list "dk"
            read -p "Number to DELETE (CAUTION): " dk_idx
            del_br=$(eval echo "\$dk_$dk_idx")
            if [ "$del_br" != "$CURRENT_BRANCH" ] && [ -n "$del_br" ]; then
                git branch -D "$del_br"
                printf "${RED}Branch $del_br deleted.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        13) # UNDO COMMIT
            [[ "$IN_GIT" = false ]] && continue
            git reset --soft HEAD~1
            printf "${YELLOW}Last commit undone. Changes are kept in stage.${NC}\n"
            read -p "Enter..." junk ;;

        14) # FORCE RESET
            [[ "$IN_GIT" = false ]] && continue
            if [ "$IS_PROD" = true ]; then
                printf "${RED}${BOLD}!!! WARNING: YOU ARE IN PROD ENVIRONMENT !!!${NC}\n"
            fi
            read -p "Type PROCEED to wipe local and reset to main: " p_conf
            if [ "$p_conf" == "PROCEED" ]; then
                git checkout main && git reset --hard origin/main
                git clean -fd
                printf "${GREEN}Reset successful.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        15) # EMERGENCY
            [[ "$IN_GIT" = false ]] && continue
            printf "1) ABORT MERGE 2) CLEAR LOCKS 3) POP STASH\n"; read -p "Action: " em_c
            [[ "$em_c" == "1" ]] && git merge --abort
            [[ "$em_c" == "2" ]] && rm -f .git/index.lock
            [[ "$em_c" == "3" ]] && git stash pop
            read -p "Enter..." junk ;;

        [Ss]) # SETUP QNAP
            clear; printf "${YELLOW}Setting up QNAP Persistence...${NC}\n"
            read -p "Enter GitHub Token: " new_token
            if [ -n "$new_token" ]; then
                echo "export GITHUB_TOKEN=\"$new_token\"" > "$PERSISTENT_ENV"
                echo "alias gitmaster='$PERSISTENT_SCRIPT_PATH'" >> "$PERSISTENT_ENV"
                echo "alias prod='cd $PATH_PROD'" >> "$PERSISTENT_ENV"
                echo "alias dev='cd $PATH_DEV'" >> "$PERSISTENT_ENV"
                echo "alias test='cd $PATH_TEST'" >> "$PERSISTENT_ENV"
                
                sed -i '/qnap_init.sh/d' /etc/profile && echo "source $PERSISTENT_ENV" >> /etc/profile
                [ "$IN_GIT" = true ] && git remote set-url origin "https://$DEFAULT_USER:$new_token@github.com/$DEFAULT_USER/$PROJECT_NAME.git"
                source "$PERSISTENT_ENV"
                printf "${GREEN}Persistence updated.${NC}\n"
            fi
            read -p "Enter..." junk ;;

        [Qq]) clear; exit 0 ;;
        *) sleep 0.1 ;;
    esac
done
