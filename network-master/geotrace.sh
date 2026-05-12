#!/bin/bash

# Controleer of er een domein is opgegeven
if [ -z "$1" ]; then
  echo "Gebruik: $0 <domeinnaam of ip>"
  exit 1
fi

TARGET=$1

echo "Start traceroute naar $TARGET..."
echo "Privé IP-adressen worden overgeslagen."
echo "--------------------------------------------------------"

# Voer traceroute uit en filter IP's
traceroute -n "$TARGET" | awk '{print $2}' | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' | while read ip; do

    # Controleer of het IP-adres privé is (RFC1918)
    if [[ $ip =~ ^127\. ]] || [[ $ip =~ ^10\. ]] || [[ $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || [[ $ip =~ ^192\.168\. ]]; then
        echo "Hop: $ip -> [Lokaal Netwerk / Privé IP]"
        continue
    fi

    # Haal Stad en Land op via ip-api
    # We gebruiken een komma als scheidingsteken in de API response
    RESPONSE=$(curl -s "http://ip-api.com/csv/$ip?fields=city,country")

    if [ -z "$RESPONSE" ] || [[ "$RESPONSE" == "," ]]; then
        LOCATION="Locatie onbekend"
    else
        # Vervang de komma door een leesbaar streepje
        LOCATION=$(echo $RESPONSE | sed 's/,/ - /g')
    fi

    echo "Hop: $ip -> $LOCATION"
done

echo "--------------------------------------------------------"
echo "Klaar."
