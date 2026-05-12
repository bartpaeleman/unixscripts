# Script Master Control Panel - Handleiding

Deze handleiding beschrijft alle functionaliteiten en menuopties beschikbaar binnen de **Script Master Control Panel**. Deze toolset is een centrale hub voor diverse development, beheer en media utilities, speciaal ontworpen voor naadloze werking op QNAP NAS en macOS omgevingen.

---

## Hoofdmenu (`script-master.sh`)

Bij het starten van de hoofdtool krijg je toegang tot de volgende 9 modules en de setup configuratie:

1. **Git Master** (Workflow & Branching)
2. **Web Scaffold** (Project Generator)
3. **DB Master** (Database Tools)
4. **Container Master** (Docker Management)
5. **Network Master** (Port Scan & Utils)
6. **Data Master** (Convert/View CSV, JSON, XML)
7. **File Master** (Rename, Archive, Cleanup)
8. **Text Master** (Stats, Diff, Merge)
9. **Video Master** (Download & Clip Videos)
* **S) Setup Environment** (Permissies & Aliases instellen)
* **X) Exit** (Afsluiten)

---

## 1. Git Master (`git-master.sh`)
Een uitgebreide Git workflow beheerder die is opgedeeld in vier hoofdsecties (INFO, DEVELOPMENT, FIX, MAINTENANCE), plus een setup configuratie.

### 1. INFO
* **a) DASHBOARD:** Toont een overzicht van de repository status, inclusief actieve branches, ongecommite wijzigingen en recente git history.
* **b) DIFF VIEWER:** Vergelijk ongecommite/gestagede wijzigingen, of zie het verschil tussen twee specifieke branches of commits.
* **c) FILE HISTORY:** Bekijk de volledige commit historie van één specifiek bestand.
* **d) SEARCH CODE:** Zoek naar een specifiek woord of tekst binnen de bestanden (via `git grep` of standaard `grep`).
* **e) COMMIT FINDER:** Zoek specifieke commits op basis van hun bericht/titel.
* **f) BRANCH COMPARE:** Zie welke commits zich in de ene branch bevinden maar niet in een andere.

### 2. DEVELOPMENT
* **a) CHECKOUT REPO:** Haalt nieuwe branches op (`fetch --prune`) en stelt je in staat om eenvoudig van branch te wisselen of een nieuwe remote branch lokaal uit te checken.
* **b) BRANCH EXPLORER:** Maak een nieuwe feature branch aan of wissel tussen bestaande branches.
* **c) QUICK COMMIT:** Voegt automatisch alle wijzigingen toe (`git add .`), vraagt om een commitbericht en pusht deze naar de origin server.
* **d) SYNC FETCH:** Haalt externe wijzigingen (`git pull`) voor de huidige branch binnen.
* **e) PREPARE UAT:** Voegt een specifieke branch samen met de `uat` branch (forceert overschrijven bij conflicten) voor testdoeleinden.
* **f) STAGING PUSH:** Forceert de huidige branch naar de `dev-stable` branch.
* **g) MERGE FIXES:** Integreer gemakkelijk een externe 'fix'-branch in de huidige branch en verwijder daarna de fix-branch.
* **h) RELEASE TAG:** Geef het huidige werk een versie-tag (bijv. v1.0) en push deze direct naar de server.
* **i) CLEANUP PRUNE:** Verwijdert lokaal branches die op de server (GitHub) niet meer bestaan.
* **j) DELETE LOCAL:** Handmatig een lokale branch selecteren en verwijderen.

### 3. FIX
* **a) SYNC FORCE:** Handige tool bij conflicten; kies om de lokale wijzigingen te overschrijven met de serverversie, of forceer de lokale versie naar de server.
* **b) UNDO COMMIT:** Draait de laatste commit terug (`git reset --soft`), waardoor je bestanden behouden blijven in staging.
* **c) FORCE RESET:** Een gevaarlijke (rode) optie die alle lokale wijzigingen vernietigt en de repository reset naar `origin/main`.
* **d) EMERGENCY:** Opties om een mislukte merge af te breken, git locks `.git/index.lock` te verwijderen of een verborgen stash terug te halen.
* **e) RESTORE COMMIT:** Blader door recente commits en kies om een oudere commit uit te checken (voor inspectie), te reverten (een nieuwe undo-commit te maken) of de branch hard terug te zetten naar dit punt.
* **f) STASH PULL POP:** Slaat tijdelijke wijzigingen op (stash), haalt externe wijzigingen binnen via pull, en past de tijdelijke wijzigingen weer toe (pop).
* **g) FORGET FILE:** Verwijdert een bestand uit de git cache (`git rm --cached`).

### 4. MAINTENANCE
* **a) BACKUP POINT:** Maakt direct een lokale snapshot/kopie aan van de huidige branch met een tijdstempel.
* **b) RESTORE BACKUP:** Herstel een eerdere backup snapshot over de huidige branch, force push naar GitHub of check de backup los uit.

* **S) SETUP PERSISTENCE:** Configureert de `.env` file met je GitHub token en installeert command-line aliassen voor snelle toegang in elke terminal sessie.

---

## 2. Web Scaffold (`scaffold.sh`)
Genereert snel een standaard map- en bestandsstructuur voor een nieuw webproject (PHP, HTML, CSS, JS).

* **Project Aanmaken:** Vraagt om een projectnaam en installatiepad.
* **Generatie:** Maakt `assets/` (met css/js/img submappen), `includes/` en `config/` aan. Het vult de mappen direct met een basis `index.php`, `style.css`, `app.js`, configuratiebestand en `.gitignore`.
* **Documentatie:** Optionele prompt om direct een `README.md` via Python te laten genereren.

---

## 3. DB Master (`db-master.sh`)
Beheer lokale of netwerk databases (MySQL/MariaDB).

* **1) Backup Database:** Vraagt om database referenties (Host, User, Pass) en creëert een gecomprimeerde `.sql.gz` dump via `mysqldump`.
* **2) Analyze Database:** Gebruikt een Python script (`db_stats.py`) om tabelgroottes en rijen te analyseren en overzichtelijk weer te geven.

---

## 4. Container Master (`container-master.sh`)
Een command-line interface voor Docker, ideaal voor systemen zoals QNAP Container Station.

* **1) List Containers:** Toont de status en poorten van actieve (en gestopte) containers.
* **2) View Logs:** Bekijk live logs (tail follow) van een specifieke container.
* **3) Inspect Container:** Geeft de raw JSON data weer (of via een Python formatter indien beschikbaar) van een container.
* **4-6) Lifecycle:** Start, Stop, of Herstart een container.
* **7) Shell Access:** Opent een interactieve `/bin/sh` of `/bin/bash` in een geselecteerde container.
* **8) Create New Stack:** Start een nieuwe container op basis van een template (`docker-compose.yml`) uit de map of via een handmatig commando met poort mapping.
* **9) Remove Container:** Verwijdert (rm) een geselecteerde container.
* **10) System Cleanup:** Bevat acties voor `docker system prune` (verwijderen van ongebruikte images, containers en volumes).

---

## 5. Network Master (`network-master.sh`)
Toolkit voor netwerkdiagnostiek.

* **1) Interfaces & Routing:** Bekijk netwerkkaarten (`ifconfig`, `ip addr`), de routing tabel (`route`, `netstat -nr`) en de ARP cache.
* **2) Connectivity:** Test verbindingen met `ping` of volg de route met `traceroute`.
* **3) DNS Tools:** Bevat `nslookup` en `dig` (inclusief `+short`) om domeinnamen om te zetten of DNS server functionaliteit te controleren.
* **4) Statistics:** Bekijk actieve poorten en socket statistieken via `netstat` en `ss`.
* **5) Web Tools:** Haal HTTP headers op met `curl`, download bestanden met `wget`, of controleer je eigen publieke IP-adres via ifconfig.me.
* **6) Advanced / Python Tools:** Bevat een Python-gebaseerde TCP poort-scanner.

---

## 6. Data Master (`data-master.sh`)
Zet dataformaten om en bekijk/schoon ruwe databestanden.

* **1) View CSV as Table:** Converteert en toont een CSV-bestand als een leesbare ASCII-tabel in de terminal.
* **2) Convert CSV Delimiter:** Pas eenvoudig het scheidingsteken van een CSV aan (bijv. van komma naar puntkomma).
* **3) Convert File Format:** Converteert naadloos tussen verschillende structuren: CSV naar JSON, XML naar JSON, en YAML naar JSON of CSV.
* **4) Normalize CSV:** Schoon een dataset op door lege rijen en onnodige spaties te verwijderen.
* **5) Check Dependencies:** Controleert op ontbrekende Python bibliotheken (`pandas`, `pyyaml`) en installeert deze indien nodig via `pip3`.

---

## 7. File Master (`file-master.sh`)
Voor het massaal beheren en opschonen van bestanden en mappen.

* **1) Bulk Rename:** Gebruikt Python Regex patronen om meerdere bestanden tegelijk te hernoemen. Je krijgt een preview te zien voor de actie daadwerkelijk wordt uitgevoerd.
* **2) Create Directory Structure:** Leest een tekstbestand in en creëert alle paden die daarin gedefinieerd staan (ideaal voor project setups).
* **3) Archive Directory:** Comprimeert een map naar een `.zip` of `.tar.gz` archief.
* **4) Cleanup:** Biedt opties om systeembestanden (zoals `.DS_Store` of `Thumbs.db`), lege mappen, en duplicaten (via MD5 checksum hashing op identieke bestandsgroottes) te identificeren en verwijderen.
* **5) Compare Files:** Vergelijkt twee bestanden of mappen.

---

## 8. Text Master (`text-master.sh`)
Manipuleer en analyseer tekstbestanden direct in de terminal.

* **1) Text Statistics:** Telt woorden, regels en toont letterfrequentie.
* **2) Search & Replace:** Zoek met `grep` of doe een massale vervanging met `sed` waarbij automatisch een `.bak` backup wordt opgeslagen.
* **3) Compare Files (Diff):** Toont een gekleurde vergelijking (`diff`) tussen twee bestanden.
* **4) Merge Files:** Plakt (`cat`) de inhoud van meerdere bestanden achter elkaar in een nieuw doelbestand.
* **5) Case Conversion:** Zet de volledige tekst om naar uitsluitend HOOFDLETTERS of kleine letters.

---

## 9. Video Master (`video-master.sh`)
Geavanceerde manipulatie en downloadtool voor mediabestanden.

### Online Media (yt-dlp)
* **1) Download Media (Configuratiemenu):** Een interactief menu om downloads op te zetten.
  * **Type instellen:** Kies een losse URL of activeer "Batch Mode" via een tekstbestand vol URLs.
  * **Media Type:** Kies tussen Video, Audio, of Thumbnail. Het formatauto-detectiesysteem zorgt dat je altijd logische sub-extensies kunt kiezen (bijv. mp4/mkv voor video of mp3/flac voor audio).
  * **Fragment:** Definieer start- en eindtijden om direct een stukje uit een online video te knippen zonder de volledige video te downloaden. Er zit een ingebouwde tijdsvalidatie in (`yt-dlp` lengtecheck) waardoor je een waarschuwing krijgt als je tijden de video-lengte overschrijden.
  * **Conflict Resolutie:** Bij het downloaden controleert het systeem of het bestand lokaal al bestaat. Je kunt dan kiezen om te overschrijven of automatisch volgnummers (`-01`, `-02`) aan de naam toe te laten voegen.
* **2) Beschikbare Kwaliteiten:** Toont alle aanwezige formaten van de URL via `yt-dlp -F`.

### Lokale Media (ffmpeg/ffprobe)
* **File Kiezer:** Voor elke lokale optie krijg je een interactieve, genummerde lijst (`select_local_media_file`) van media in de huidige (of een handmatig geselecteerde) map, zodat je geen lastige paden hoeft in te typen.
* **Tijd Notatie:** Voor input velden met tijd (begin, einde, duur) kun je getallen gebruiken (`120` wordt automatisch `00:02:00`) of verkorte tijdsformaten (`1:20` wordt `00:01:20`).
* **Bestands Conflicten:** Net als bij de downloads, zul je bij elke lokale actie een waarschuwing krijgen met keuze voor Auto-Volgnummer of Overschrijven als het door jou gekozen uitvoerbestand al blijkt te bestaan.
* **Auto-Extensies:** Vergeet je een bestandsformaat in te typen (bv. enkel `uitvoerbestand`), voegt de tool automatisch zelf de benodigde bestandsextensie (zoals `.mp3`, `.mkv` of het bronformaat) toe.

**Opties Lokaal:**
* **3) Lokaal Mediabestand Knippen:** Knip fragmenten uit bestaande video's (gebaseerd op exacte tijden of duur mbv de `+` notatie). Controleert lokaal via `ffprobe` of de tijden geldig zijn voor deze bron.
* **4) Lokaal Mediabestand Converteren:** Vormt snel containers om (bijv. mp4 naar mkv) door middel van kopieer streams zonder zware hercodering.
* **5) Media Informatie Weergeven:** Geeft uitgebreide codec, bitrate en tijdsdata (metadata) terug via `ffprobe`.
* **6) Lokaal Mediabestand Audio Extraheren:** Isoleert razendsnel enkel het geluidspoor (`-vn`) van een video bestand om als audio-bestand op te slaan, eventueel met start/eind knipfunctionaliteit.
* **U) Update Afhankelijkheden:** Een slimme update functie die probeert `yt-dlp` via diens interne mechanisme te vernieuwen of terugvalt op system packages (brew, apt, pip) voor ffmpeg/yt-dlp updates.

---
