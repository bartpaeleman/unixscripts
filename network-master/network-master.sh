#!/bin/bash

# ============================================================
# NETWORK MASTER CONTROL PANEL
# Comprehensive Network Toolkit for QNAP & QNAP and general UNIX systems
# ============================================================

# set -e is disabled for interactive menu stability

# --- COLORS ---
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- FUNCTIONS ---

pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Command '$1' not found on this system.${NC}"
        pause
        return 1
    fi
    return 0
}

# --- HELPER: GEOTRACE ---
run_geotrace() {
    read -p "Target IP/Domain: " target
    if [[ -f "$SCRIPT_DIR/geotrace.sh" ]]; then
        "$SCRIPT_DIR/geotrace.sh" "$target"
    else
        echo -e "${RED}geotrace.sh script not found in $SCRIPT_DIR${NC}"
    fi
    pause
}

# --- SUBMENU: INTERFACES & ROUTING ---
menu_interfaces() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}=== Interfaces & Routing ===${NC}"
        echo "1) ifconfig - Show All Interfaces"
        echo "2) ip addr - Show IP Addresses (Linux/QNAP)"
        echo "3) route - Show Routing Table"
        echo "4) arp - Show ARP Table"
        echo "0) Back"

        read -p "Select: " choice
        case $choice in
            1) check_cmd ifconfig && ifconfig -a | more; pause ;;
            2) check_cmd ip && ip addr show | more; pause ;;
            3)
                if command -v netstat &>/dev/null; then
                    netstat -nr | more
                elif command -v route &>/dev/null; then
                    route -n | more
                else
                    echo "No routing tool found."
                fi
                pause ;;
            4) check_cmd arp && arp -a | more; pause ;;
            [0]) return ;;
        esac
    done
}

# --- SUBMENU: CONNECTIVITY ---
menu_connectivity() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}=== Connectivity ===${NC}"
        echo "1) ping - Test Connection"
        echo "2) traceroute - Trace Path"
        echo "3) geotrace - Trace Path with GeoIP Location"
        echo "0) Back"

        read -p "Select: " choice
        case $choice in
            1)
                check_cmd ping || continue
                read -p "Target IP/Domain: " target
                read -p "Count [4]: " count
                count=${count:-4}
                ping -c "$count" "$target"
                pause
                ;;
            2)
                read -p "Target IP/Domain: " target
                if command -v traceroute &>/dev/null; then
                    traceroute "$target"
                elif command -v tracert &>/dev/null; then
                    tracert "$target" # Windows/Generic
                else
                    echo "traceroute command not found"
                fi
                pause
                ;;
            3)
                run_geotrace
                ;;
            [0]) return ;;
        esac
    done
}

# --- SUBMENU: DNS ---
menu_dns() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}=== DNS Tools ===${NC}"
        echo "1) nslookup - Query Domain"
        echo "2) dig - Detailed Query"
        echo "3) dig short - Get IP only"
        echo "0) Back"

        read -p "Select: " choice
        case $choice in
            1)
                check_cmd nslookup || continue
                read -p "Domain: " domain
                nslookup "$domain"
                pause
                ;;
            2)
                check_cmd dig || continue
                read -p "Domain: " domain
                read -p "DNS Server (optional, e.g. 8.8.8.8): " server
                if [[ -n "$server" ]]; then
                    dig "@$server" "$domain"
                else
                    dig "$domain"
                fi
                pause
                ;;
            3)
                check_cmd dig || continue
                read -p "Domain: " domain
                dig +short "$domain"
                pause
                ;;
            [0]) return ;;
        esac
    done
}

# --- SUBMENU: STATS & SOCKETS ---
menu_stats() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}=== Network Statistics ===${NC}"
        echo "1) netstat - All Connections"
        echo "2) netstat - Listening Ports"
        echo "3) ss - Socket Stats (TCP)"
        echo "4) ss - Socket Stats (UDP)"
        echo "0) Back"

        read -p "Select: " choice
        case $choice in
            1) check_cmd netstat && netstat -a | more; pause ;;
            2)
                    netstat -tuln | more
                pause ;;
            3) check_cmd ss && ss -t -a | more; pause ;;
            4) check_cmd ss && ss -u -a | more; pause ;;
            [0]) return ;;
        esac
    done
}

# --- SUBMENU: WEB TOOLS ---
menu_web() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}=== Web Tools ===${NC}"
        echo "1) curl - Fetch Headers"
        echo "2) curl - Verbose Request"
        echo "3) wget - Download File"
        echo "4) Show Public IP (via ifconfig.me)"
        echo "0) Back"

        read -p "Select: " choice
        case $choice in
            1)
                check_cmd curl || continue
                read -p "URL: " url
                curl -I "$url"
                pause
                ;;
            2)
                check_cmd curl || continue
                read -p "URL: " url
                curl -v "$url"
                pause
                ;;
            3)
                check_cmd wget || continue
                read -p "URL: " url
                wget "$url"
                pause
                ;;
            4)
                check_cmd curl || continue
                echo "Fetching public IP..."
                curl -s ifconfig.me
                echo ""
                pause
                ;;
            [0]) return ;;
        esac
    done
}

# --- SUBMENU: PYTHON TOOLS ---
menu_python() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}=== Python Network Tools ===${NC}"

        if ! command -v python3 &> /dev/null; then
             echo -e "${YELLOW}Python3 not detected. These tools require python3.${NC}"
             pause
             return
        fi

        echo "1) Simple Port Scanner"
        echo "0) Back"

        read -p "Select: " choice
        case $choice in
            1)
                read -p "Target IP: " ip
                read -p "Start Port [1]: " sp
                sp=${sp:-1}
                read -p "End Port [1024]: " ep
                ep=${ep:-1024}
                python3 "${SCRIPT_DIR}/scan_ports.py" "$ip" "$sp" "$ep"
                pause
                ;;
            [0]) return ;;
        esac
    done
}

# --- SUBMENU: NMAP SCANNER ---

menu_nmap() {

    local target=""


        local myip=$(ip route get 1.1.1.1 2>/dev/null | awk "{for(i=1;i<=NF;i++) if (\$i==\"src\") print \$(i+1); exit}")



    if [[ -n "$myip" ]]; then

        target="${myip%.*}.0/24"




    local opt_os=0

    local opt_sv=0

    local opt_portscan=1

    local opt_noping=0

    local opt_output="screen"

    local opt_outfile=""

    local opt_timing=3

    local opt_disp_all=1
    local opt_disp_ports=0
    local opt_disp_active=0
    local opt_disp_progress=0

    local opt_sudo=0



    echo -e "${YELLOW}Checking nmap installation and version...${NC}"


        if ! command -v nmap &>/dev/null; then

            echo "Installing nmap via APT..."

            sudo apt-get update && sudo apt-get install -y nmap

        else

            sudo apt-get update && sudo apt-get install --only-upgrade -y nmap || true
        fi

    fi



    while true; do

        clear

        echo -e "${CYAN}${BOLD}=== Nmap Scanner ===${NC}"

        echo "1) Target IP/Range : ${target:-[None]}"

        if [[ $opt_os -eq 1 ]]; then

            echo "2) OS Detection    : Yes (-O)"

        else

            echo "2) OS Detection    : No"

        fi

        if [[ $opt_sv -eq 1 ]]; then

            echo "3) Service Version : Yes (-sV)"

        else

            echo "3) Service Version : No"

        fi

        if [[ $opt_portscan -eq 0 ]]; then
            echo "4) Port Scan       : Geen port scan (-sn)"
        elif [[ $opt_portscan -eq 1 ]]; then
            echo "4) Port Scan       : Common known ports"
        elif [[ $opt_portscan -eq 2 ]]; then
            echo "4) Port Scan       : Ports 1-1024 (-p 1-1024)"
        elif [[ $opt_portscan -eq 3 ]]; then
            echo "4) Port Scan       : All Ports (-p-)"
        fi

        if [[ $opt_noping -eq 1 ]]; then

            echo "5) Skip Ping       : Yes (-Pn)"

        else

            echo "5) Skip Ping       : No"

        fi



        local timing_label="3 (Normal)"

        if [[ $opt_timing -eq 1 ]]; then timing_label="1 (Sneaky)"; fi

        if [[ $opt_timing -eq 2 ]]; then timing_label="2 (Polite - Router Safe)"; fi

        if [[ $opt_timing -eq 4 ]]; then timing_label="4 (Aggressive)"; fi

        if [[ $opt_timing -eq 5 ]]; then timing_label="5 (Insane)"; fi

        echo "6) Timing Template : T${timing_label}"



        local disp_labels=()
        if [[ $opt_disp_all -eq 1 ]]; then disp_labels+=("After completing all"); fi
        if [[ $opt_disp_ports -eq 1 ]]; then disp_labels+=("After each target"); fi
        if [[ $opt_disp_active -eq 1 ]]; then disp_labels+=("Report active target"); fi
        if [[ $opt_disp_progress -eq 1 ]]; then disp_labels+=("Show progress"); fi

        if [[ ${#disp_labels[@]} -eq 0 ]]; then
            echo "7) Show on Screen: No"
        else
            local joined_labels=$(IFS=','; echo "${disp_labels[*]}")
            echo "7) Show on Screen: ${joined_labels}"
        fi



        if [[ $opt_sudo -eq 1 ]]; then

            echo "8) Run as Root     : Yes (sudo)"

        else

            echo "8) Run as Root     : No"

        fi



        if [[ "$opt_output" == "txt" ]]; then

            echo "9) Output Format   : txt (File: ${opt_outfile})"

        else

            echo "9) Output Format   : screen"

        fi

        echo "10) Update Port DB : (from IANA)"

        echo -e "---------------------------------------------------------------"

        echo "Press Enter to Start Scan"

        echo "0) Back"



        read -p "Select action: " choice

        case "$choice" in

            1)

                read -p "Enter Target IP or Range (e.g. 192.168.1.1, 192.168.1.0/24, 192.168.0.220-229): " new_target

                target="$new_target"

                ;;

            2)

                opt_os=$((1 - opt_os))

                if [[ $opt_os -eq 1 ]]; then opt_sudo=1; fi

                ;;

            3)

                opt_sv=$((1 - opt_sv))

                ;;

            4)

                opt_portscan=$((opt_portscan + 1))
                if [[ $opt_portscan -gt 3 ]]; then opt_portscan=0; fi

                ;;

            5)

                opt_noping=$((1 - opt_noping))

                ;;

            6)

                opt_timing=$((opt_timing + 1))

                if [[ $opt_timing -gt 5 ]]; then opt_timing=1; fi

                ;;

            7)

                while true; do
                    clear
                    echo -e "${CYAN}${BOLD}=== Display Options ===${NC}"
                    echo "Select which reports should be printed to the screen:"
                    echo ""
                    echo "1) [$( [[ $opt_disp_all -eq 1 ]] && echo "X" || echo " " )] After completing all (Full report at end)"
                    echo "2) [$( [[ $opt_disp_ports -eq 1 ]] && echo "X" || echo " " )] After each target (Shows target and open ports)"
                    echo "3) [$( [[ $opt_disp_active -eq 1 ]] && echo "X" || echo " " )] Report active target (Shows target IP when scan starts)"
                    echo "4) [$( [[ $opt_disp_progress -eq 1 ]] && echo "X" || echo " " )] Show progress (Background Nmap activity stats)"
                    echo "5) Disable all (No)"
                    echo -e "---------------------------------------------------------------"
                    echo "0) Back"
                    read -p "Toggle option: " disp_choice
                    case "$disp_choice" in
                        1) opt_disp_all=$((1 - opt_disp_all)) ;;
                        2) opt_disp_ports=$((1 - opt_disp_ports)) ;;
                        3) opt_disp_active=$((1 - opt_disp_active)) ;;
                        4) opt_disp_progress=$((1 - opt_disp_progress)) ;;
                        5)
                            opt_disp_all=0
                            opt_disp_ports=0
                            opt_disp_active=0
                            opt_disp_progress=0
                            ;;
                        0) break ;;
                        *) sleep 0.1 ;;
                    esac
                done

                ;;

            8)

                opt_sudo=$((1 - opt_sudo))

                ;;

            9)

                if [[ "$opt_output" == "screen" ]]; then

                    opt_output="txt"

                    echo -e "\n${YELLOW}Text file output selected.${NC}"

                    local default_file="$HOME/Downloads/nmap-$(date +%Y%m%d%H%M).txt"

                    if [ "${BASH_VERSINFO[0]:-3}" -ge 4 ]; then

                        read -e -i "$default_file" -p "Enter custom output filepath: " opt_outfile

                    else

                        read -p "Enter custom output filepath [$default_file]: " opt_outfile

                        opt_outfile="${opt_outfile:-$default_file}"

                    fi

                else

                    opt_output="screen"

                    opt_outfile=""

                fi

                ;;

            10)

                if ! command -v python3 &>/dev/null; then

                    echo -e "\n${YELLOW}Python3 is required for this feature.${NC}"

                else

                    python3 "${SCRIPT_DIR}/nmap_formatter.py" --update

                fi

                pause

                ;;

            "")

                if [[ -z "$target" ]]; then

                    echo -e "\n${YELLOW}Please specify a target first.${NC}"

                    pause

                    continue

                fi

                local cmd=()

                if [[ $opt_sudo -eq 1 ]]; then

                    echo -e "\n${YELLOW}Running scan with root privileges...${NC}"

                    cmd+=("sudo" "nmap")

                else

                    cmd+=("nmap")

                fi

                if [[ $opt_portscan -eq 0 ]]; then
                    cmd+=("-sn")
                else
                    if [[ $opt_os -eq 1 ]]; then cmd+=("-O"); fi
                    if [[ $opt_sv -eq 1 ]]; then cmd+=("-sV"); fi
                    if [[ $opt_portscan -eq 2 ]]; then cmd+=("-p" "1-1024"); fi
                    if [[ $opt_portscan -eq 3 ]]; then cmd+=("-p-"); fi
                fi

                if [[ $opt_noping -eq 1 ]]; then cmd+=("-Pn"); fi

                if [[ $opt_timing -eq 2 ]]; then cmd+=("--max-rate" "100"); fi

                cmd+=("-T${opt_timing}")

                cmd+=("$target")


                # Build common real-time display logic based on multiple flags
                local awk_script=""
                if [[ $opt_disp_active -eq 1 ]]; then
                    awk_script+="if(\$1==\"Nmap\" && \$2==\"scan\" && \$3==\"report\") print \"\\033[1;36mActive Target:\\033[0m \" \$5 \" \" \$6; "
                fi
                if [[ $opt_disp_ports -eq 1 ]]; then
                    awk_script+="if(\$1==\"Discovered\" && \$2==\"open\" && \$3==\"port\") print \"\\033[1;32mOpen Port:\\033[0m \" \$4 \" on \" \$6; "
                fi
                if [[ $opt_disp_progress -eq 1 ]]; then
                    awk_script+="if(\$1==\"Stats:\") print \"\\033[1;33mProgress:\\033[0m \" \$0; "
                    cmd+=("--stats-every" "10s")
                fi

                local filter_cmd=()
                if [[ -n "$awk_script" ]]; then
                    cmd+=("-v")
                    filter_cmd=("awk" "{ ${awk_script}fflush(); }")
                fi

                if [[ $opt_portscan -eq 0 ]]; then
                    echo -e "\n${CYAN}Running scan: ${cmd[*]}${NC}"
                    if [[ "$opt_output" == "txt" && -n "$opt_outfile" ]]; then
                        mkdir -p "$(dirname "$opt_outfile")"
                        if [[ -n "$awk_script" ]]; then
                            "${cmd[@]}" | tee >("${filter_cmd[@]}") > "$opt_outfile"
                        elif [[ $opt_disp_all -eq 1 ]]; then
                            "${cmd[@]}" | tee "$opt_outfile"
                        else
                            "${cmd[@]}" > "$opt_outfile"
                        fi
                        echo -e "${GREEN}Scan complete. Output saved to $opt_outfile${NC}"
                    else
                        if [[ -n "$awk_script" ]]; then
                            "${cmd[@]}" | "${filter_cmd[@]}"
                        elif [[ $opt_disp_all -eq 1 ]]; then
                            "${cmd[@]}" | more
                        else
                            "${cmd[@]}" > /dev/null 2>&1
                        fi
                    fi
                else
                    local tmp_xml="/tmp/nmap_$$.xml"
                    cmd+=("-oX" "$tmp_xml")
                    echo -e "\n${CYAN}Running scan: ${cmd[*]} (Output hidden)${NC}"

                    if ! command -v python3 &>/dev/null; then
                        echo -e "${YELLOW}Python3 not found. Falling back to raw output.${NC}"
                        if [[ "$opt_output" == "txt" && -n "$opt_outfile" ]]; then
                            mkdir -p "$(dirname "$opt_outfile")"
                            if [[ -n "$awk_script" ]]; then
                                "${cmd[@]}" | tee >("${filter_cmd[@]}") > "$opt_outfile"
                            elif [[ $opt_disp_all -eq 1 ]]; then
                                "${cmd[@]}" | tee "$opt_outfile"
                            else
                                "${cmd[@]}" > "$opt_outfile"
                            fi
                            echo -e "${GREEN}Scan complete. Output saved to $opt_outfile${NC}"
                        else
                            if [[ -n "$awk_script" ]]; then
                                "${cmd[@]}" | "${filter_cmd[@]}"
                            elif [[ $opt_disp_all -eq 1 ]]; then
                                "${cmd[@]}" | more
                            else
                                "${cmd[@]}" > /dev/null 2>&1
                            fi
                        fi
                    else
                        if [[ -n "$awk_script" ]]; then
                            "${cmd[@]}" | "${filter_cmd[@]}"
                        else
                            "${cmd[@]}" > /dev/null 2>&1
                        fi

                        if [[ -f "$tmp_xml" ]]; then
                            if [[ "$opt_output" == "txt" && -n "$opt_outfile" ]]; then
                                mkdir -p "$(dirname "$opt_outfile")"
                                if [[ $opt_disp_all -eq 1 ]]; then
                                    python3 "${SCRIPT_DIR}/nmap_formatter.py" "$tmp_xml" | tee -a "$opt_outfile"
                                else
                                    python3 "${SCRIPT_DIR}/nmap_formatter.py" "$tmp_xml" >> "$opt_outfile"
                                fi
                                echo -e "\n${GREEN}Scan complete. Output saved to $opt_outfile${NC}"
                            else
                                if [[ $opt_disp_all -eq 1 ]]; then
                                    python3 "${SCRIPT_DIR}/nmap_formatter.py" "$tmp_xml" | more
                                fi
                            fi
                            if [[ $opt_sudo -eq 1 ]]; then
                                sudo rm -f "$tmp_xml" 2>/dev/null
                            else
                                rm -f "$tmp_xml" 2>/dev/null || sudo -n rm -f "$tmp_xml" 2>/dev/null
                            fi
                        else
                            echo -e "${RED}Failed to generate XML output.${NC}"
                        fi
                    fi
                fi
                pause
                ;;

            [0]) return ;;

            *) sleep 0.1 ;;

        esac

    done

}


# --- SUBMENU: NETWORK SWEEP ---
menu_sweep() {
    local opt_subnet=""
    local opt_output="screen"
    local opt_outfile=""
    local opt_show_all=0
    local opt_vendor=0
    local opt_update_db=0

    while true; do
        clear
        echo -e "${CYAN}${BOLD}=== Network Sweep (sweep.sh) ===${NC}"
        echo "1) Subnet          : ${opt_subnet:-[Auto-detect]}"

        if [[ "$opt_output" == "csv" ]]; then
            echo "2) Output Format   : csv (File: ${opt_outfile:-[Auto-generated timestamp]})"
        else
            echo "2) Output Format   : screen"
        fi

        if [[ $opt_show_all -eq 1 ]]; then
            echo "3) Show All IPs    : Yes (254 addresses)"
        else
            echo "3) Show All IPs    : No (Active only)"
        fi
        if [[ $opt_vendor -eq 1 ]]; then
            echo "4) Vendor Lookup   : Yes"
        else
            echo "4) Vendor Lookup   : No"
        fi
        if [[ $opt_update_db -eq 1 ]]; then
            echo "5) Update OUI DB   : Yes"
        else
            echo "5) Update OUI DB   : No"
        fi
        echo -e "---------------------------------------------------------------"
        echo "Press Enter to Start Sweep"
        echo "0) Back"

        read -p "Select action: " choice
        case "$choice" in
            1)
                read -p "Enter Subnet (e.g. 192.168.1.0/24 or empty for auto): " new_subnet
                opt_subnet="$new_subnet"
                ;;
            2)
                if [[ "$opt_output" == "screen" ]]; then
                    opt_output="csv"
                    echo -e "\n${YELLOW}CSV output selected.${NC}"
                    local default_file="$HOME/Downloads/sweep-$(date +%Y%m%d%H%M).csv"
                    if [ "${BASH_VERSINFO[0]:-3}" -ge 4 ]; then
                        read -e -i "$default_file" -p "Enter custom output filepath: " opt_outfile
                    else
                        read -p "Enter custom output filepath [$default_file]: " opt_outfile
                        opt_outfile="${opt_outfile:-$default_file}"
                    fi
                else
                    opt_output="screen"
                    opt_outfile=""
                fi
                ;;
            3)
                opt_show_all=$((1 - opt_show_all))
                ;;
            4)
                opt_vendor=$((1 - opt_vendor))
                ;;
            5)
                opt_update_db=$((1 - opt_update_db))
                ;;
            "")
                local cmd=("${SCRIPT_DIR}/sweep.sh")
                if [[ -n "$opt_subnet" ]]; then
                    cmd+=("-s" "$opt_subnet")
                fi
                cmd+=("-o" "$opt_output")
                if [[ "$opt_output" == "csv" && -n "$opt_outfile" ]]; then
                    cmd+=("-f" "$opt_outfile")
                fi
                if [[ $opt_show_all -eq 1 ]]; then
                    cmd+=("-a")
                fi
                if [[ $opt_vendor -eq 1 ]]; then
                    cmd+=("-v")
                fi
                if [[ $opt_update_db -eq 1 ]]; then
                    cmd+=("-u")
                fi

                echo -e "\n${CYAN}Starting sweep...${NC}"
                "${cmd[@]}"
                pause
                ;;
            [0]) return ;;
            *) sleep 0.1 ;;
        esac
    done
}

if [[ "${1:-}" == "--sweep" ]]; then
    menu_sweep
    exit 0
fi

# --- MAIN LOOP ---

while true; do
    clear
    echo -e "${CYAN}${BOLD}===============================================================${NC}"
    echo -e "       ${CYAN}${BOLD}NETWORK MASTER CONTROL PANEL${NC}"
    echo -e "${CYAN}${BOLD}===============================================================${NC}"
    echo " 1) Interfaces & Routing (ifconfig, ip, route, arp)"
    echo " 2) Connectivity (ping, traceroute)"
    echo " 3) DNS Tools (nslookup, dig)"
    echo " 4) Statistics (netstat, ss)"
    echo " 5) Web Tools (curl, wget)"
    echo " 6) Advanced / Python Tools"
    echo " 7) GeoTrace (traceroute with GeoIP)"
    echo " 8) Network Sweep (sweep.sh)"
    echo " 9) Nmap Scanner"
    echo -e "---------------------------------------------------------------"
    echo " X) Exit"
    echo -e "${BOLD}===============================================================${NC}"

    read -p "Select action: " main_choice

    case $main_choice in
        1) menu_interfaces ;;
        2) menu_connectivity ;;
        3) menu_dns ;;
        4) menu_stats ;;
        5) menu_web ;;
        6) menu_python ;;
        7) run_geotrace ;;
        8) menu_sweep ;;
        9) menu_nmap ;;
        [xX]) clear; exit 0 ;;
        *) sleep 0.1 ;;
    esac
done
