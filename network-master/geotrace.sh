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
echo "Hops die niet antwoorden binnen 1.5s worden overgeslagen..."

TEMP_FILE=$(mktemp)

# Traceroute instellingen voor snelheid:
# -n: Geen DNS (essentieel voor snelheid)
# -q 1: Slechts 1 pakket per hop
# -w 1: Wacht maximaal 1 seconde op een antwoord
# -m 20: Maximaal 20 hops (voorkomt eindeloze lussen)
HOPS=$(traceroute -n -q 1 -w 1 -m 20 "$TARGET" | awk '$2 ~ /^[0-9]/ {print $1 "," $2}')

for line in $HOPS; do
    (
        HOP_NUM=$(echo $line | cut -d',' -f1)
        IP=$(echo $line | cut -d',' -f2)

        # Skip als IP leeg is of sterretje bevat
        if [[ -z "$IP" ]] || [[ "$IP" == "*" ]]; then
            exit 0
        fi

        # Privé IP check
        if [[ $IP =~ ^127\. ]] || [[ $IP =~ ^10\. ]] || [[ $IP =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || [[ $IP =~ ^192\.168\. ]]; then
            printf "%02d|%s|%s|%s|%s|%s\n" "$HOP_NUM" "$HOP_NUM" "$IP" "Lokaal" "Intern Netwerk" "-" >> "$TEMP_FILE"
        else
            # API aanroep met --max-time 2 om hangen te voorkomen
            DATA=$(curl -s --max-time 2 "http://ip-api.com/csv/$IP?fields=city,country,continentCode,countryCode,isp")
            
            # Als API niet antwoordt, vul lege waarden in
            if [ $? -ne 0 ] || [ -z "$DATA" ]; then
                printf "%02d|%s|%s|%s|%s|%s\n" "$HOP_NUM" "$HOP_NUM" "$IP" "Timeout" "Onbekend" "API niet bereikbaar" >> "$TEMP_FILE"
            else
                CITY=$(echo $DATA | cut -d',' -f1)
                COUNTRY=$(echo $DATA | cut -d',' -f2)
                CONT=$(echo $DATA | cut -d',' -f3)
                CODE=$(echo $DATA | cut -d',' -f4)
                ISP=$(echo $DATA | cut -d',' -f5)

                COLOR=$NC
                LABEL="OK"

                if [[ $RISK_COUNTRIES =~ $CODE ]]; then
                    COLOR=$RED
                    LABEL="!! RISICO !!"
                elif [[ "$CONT" != "EU" ]]; then
                    COLOR=$YELLOW
                    LABEL="BUITEN-EU"
                fi

                printf "%02d|%s|%s|%s|%s|${COLOR}%s${NC}\n" "$HOP_NUM" "$HOP_NUM" "$IP" "$CITY" "$COUNTRY" "$LABEL ($ISP)" >> "$TEMP_FILE"
            fi
        fi
    ) &
done

wait

echo -e "\n${BOLD}HOP  IP-ADRES        STAD            LAND            STATUS & PROVIDER${NC}"
echo "--------------------------------------------------------------------------------------"

# Check of het bestand leeg is (geen hops gevonden)
if [ ! -s "$TEMP_FILE" ]; then
    echo "Geen actieve hops gevonden of doel onbereikbaar."
else
    sort "$TEMP_FILE" | cut -d'|' -f2- | column -t -s '|'
fi

rm "$TEMP_FILE"
echo "--------------------------------------------------------------------------------------"
