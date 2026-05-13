#!/bin/bash

# Kleurcodes
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

if [ -z "$1" ]; then
  echo "Gebruik: $0 <domeinnaam of ip>"
  exit 1
fi

TARGET=$1
RISK_COUNTRIES="RU CN KP IR SY"

echo -e "${BOLD}Traceroute naar: $TARGET${NC}"
echo "Max 30 hops, niet-reagerende hops worden overgeslagen..."

TEMP_FILE=$(mktemp)

# Vang alle output op, filter header- en warningregels, parse hops
# -n: Geen DNS  -q 1: 1 pakket per hop  -w 2: wacht max 2s  -m 30: max 30 hops
HOPS=$(traceroute -n -q 1 -w 2 -m 30 "$TARGET" 2>&1 \
    | grep -vE "^traceroute|Warning:|^$" \
    | awk '{print $1","$2}')

# Resolve eindbestemming via dig of host
if command -v dig >/dev/null 2>&1; then
    TARGET_IP=$(dig +short A "$TARGET" 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
elif command -v host >/dev/null 2>&1; then
    TARGET_IP=$(host -4 "$TARGET" 2>/dev/null | awk '/has address/{print $4; exit}')
else
    TARGET_IP=""
fi

# Als TARGET al een IP is, gebruik het rechtstreeks
if [ -z "$TARGET_IP" ] && echo "$TARGET" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    TARGET_IP="$TARGET"
fi

# Forceer eindbestemming als laatste hop indien ontbrekend
if [ -n "$TARGET_IP" ]; then
    LAST_IP=$(echo "$HOPS" | tail -1 | cut -d',' -f2)
    if [ "$LAST_IP" != "$TARGET_IP" ]; then
        LAST_NUM=$(echo "$HOPS" | tail -1 | cut -d',' -f1)
        NEXT_NUM=$((10#$LAST_NUM + 1))
        HOPS="${HOPS}
${NEXT_NUM},${TARGET_IP}"
    fi
fi

for line in $HOPS; do
    (
        HOP_NUM=$(echo "$line" | cut -d',' -f1)
        IP=$(echo "$line" | cut -d',' -f2)

        if [ -z "$IP" ]; then
            exit 0
        fi

        # Toon * hops als "geen antwoord"
        if [ "$IP" = "*" ]; then
            printf "%02d|%-15s|%-15s|%-15s|%-14s|%s\n" \
                "$HOP_NUM" "*" "Geen antwoord" "-" "Tijdlimiet" "-" >> "$TEMP_FILE"
            exit 0
        fi

        # Privé IP check
        if echo "$IP" | grep -qE '^127\.|^10\.|^192\.168\.'; then
            printf "%02d|%-15s|%-15s|%-15s|%-14s|%s\n" \
                "$HOP_NUM" "$IP" "Lokaal" "Intern Netwerk" "-" "-" >> "$TEMP_FILE"
        elif echo "$IP" | grep -qE '^172\.(1[6-9]|2[0-9]|3[0-1])\.'; then
            printf "%02d|%-15s|%-15s|%-15s|%-14s|%s\n" \
                "$HOP_NUM" "$IP" "Lokaal" "Intern Netwerk" "-" "-" >> "$TEMP_FILE"
        else
            # API: volgorde continentCode,country,city,countryCode,isp
            DATA=$(curl -s --max-time 2 \
                "http://ip-api.com/csv/$IP?fields=continentCode,country,city,countryCode,isp")

            if [ $? -ne 0 ] || [ -z "$DATA" ]; then
                printf "%02d|%-15s|%-15s|%-15s|%-14s|%s\n" \
                    "$HOP_NUM" "$IP" "Timeout" "Onbekend" "API fout" "-" >> "$TEMP_FILE"
            else
                CONT=$(echo "$DATA"    | cut -d',' -f1)
                COUNTRY=$(echo "$DATA" | cut -d',' -f2)
                CITY=$(echo "$DATA"    | cut -d',' -f3)
                CODE=$(echo "$DATA"    | cut -d',' -f4)
                ISP=$(echo "$DATA"     | cut -d',' -f5)

                LABEL="OK"
                PREFIX=""
                SUFFIX=""

                if echo "$RISK_COUNTRIES" | grep -qw "$CODE"; then
                    PREFIX=$(printf '\033[0;31m')
                    SUFFIX=$(printf '\033[0m')
                    LABEL="!! RISICO !!"
                elif [ "$CONT" != "EU" ]; then
                    PREFIX=$(printf '\033[1;33m')
                    SUFFIX=$(printf '\033[0m')
                    LABEL="BUITEN-EU"
                fi

                printf "%02d|%-15s|%-15s|%-15s|%s%-14s%s|%s\n" \
                    "$HOP_NUM" "$IP" "$CITY" "$COUNTRY" \
                    "$PREFIX" "$LABEL" "$SUFFIX" "$ISP" >> "$TEMP_FILE"
            fi
        fi
    ) &
done

wait

echo ""
printf "${BOLD}%-4s %-15s %-15s %-15s %-14s %s${NC}\n" \
    "HOP" "IP-ADRES" "STAD" "LAND" "STATUS" "PROVIDER"
echo "-----------------------------------------------------------------------------------------"

if [ ! -s "$TEMP_FILE" ] || [ -z "$(tr -d '[:space:]' < "$TEMP_FILE")" ]; then
    echo "Geen actieve hops gevonden of doel onbereikbaar."
else
    sort "$TEMP_FILE" | while IFS='|' read -r hop ip city country status isp; do
        printf "%-4s %-15s %-15s %-15s %-14s %s\n" \
            "$hop" "$ip" "$city" "$country" "$status" "$isp"
    done
fi

echo "-----------------------------------------------------------------------------------------"
