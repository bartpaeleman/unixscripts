# Script Master Control Panel - Gebruikershandleiding

Deze handleiding beschrijft alle functionaliteiten en menuopties beschikbaar binnen de **Script Master Control Panel**. Deze toolset is een centrale hub voor diverse development en beheer utilities, speciaal ontworpen voor naadloze werking op QNAP NAS omgevingen.

---

## 1. Container Master (Docker Management)
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

## 2. Git Master (Workflow & Branching)
Beheert complexe git workflows en vereenvoudigt het werken met de repository. Deze is verdeeld in vier hoofdcategorieën: INFO, DEVELOPMENT, FIX en MAINTENANCE.

### 1. INFO
* **1) STATUS & BRANCH INFO:** Toont de huidige branch, niet-gecommitte wijzigingen (status) en een beknopte log van de laatste paar commits.
* **2) PENDING CHANGES:** Toont in detail (diff) welke bestanden zijn aangepast en wat de specifieke code-wijzigingen zijn ten opzichte van de vorige commit.
* **3) COMMIT HISTORY:** Laat een uitgebreidere grafische weergave (tree view) zien van de commit geschiedenis over de verschillende branches.
* **4) COMPARE SERVER:** Vergelijkt je lokale `main` branch met de `origin/main` (op GitHub) om te zien of je achterloopt of wijzigingen klaar hebt staan om te pushen.

### 2. DEVELOPMENT
* **1) START FEATURE:** Vraagt om een naam (bijv. `login-page`) en creëert automatisch een nieuwe lokale branch (`feature/login-page`) gebaseerd op de actuele `main` branch.
* **2) SWITCH BRANCH:** Laat een lijst zien van alle lokale branches en stelt je in staat snel over te schakelen. Handig als je wil wisselen naar een nieuwe feature branch aan of wissel tussen bestaande branches.
* **3) QUICK COMMIT:** Voegt automatisch alle wijzigingen toe (`git add .`), vraagt om een commitbericht en pusht deze naar de origin server.
* **4) SYNC FETCH:** Haalt externe wijzigingen (`git pull`) voor de huidige branch binnen.
* **5) PREPARE UAT:** Voegt een specifieke branch samen met de `uat` branch (forceert overschrijven bij conflicten) voor testdoeleinden.
* **6) STAGING PUSH:** Forceert de huidige branch naar de `dev-stable` branch.
* **7) MERGE FIXES:** Integreer gemakkelijk een externe 'fix'-branch in de huidige branch en verwijder daarna de fix-branch.
* **8) RELEASE TAG:** Geef het huidige werk een versie-tag (bijv. v1.0) en push deze direct naar de server.
* **9) CLEANUP PRUNE:** Verwijdert lokaal branches die op de server (GitHub) niet meer bestaan.
* **10) DELETE LOCAL:** Handmatig een lokale branch selecteren en verwijderen.

### 3. FIX
* **1) SYNC FORCE:** Handige tool bij conflicten; kies om de lokale wijzigingen te overschrijven met de serverversie, of forceer de lokale versie naar de server.
* **2) UNDO COMMIT:** Draait de laatste commit terug (`git reset --soft`), waardoor je bestanden behouden blijven in staging.
* **3) FORCE RESET:** Een gevaarlijke (rode) optie die alle lokale wijzigingen vernietigt en de repository reset naar `origin/main`.
* **4) EMERGENCY:** Opties om een mislukte merge af te breken, git locks `.git/index.lock` te verwijderen of een verborgen stash terug te halen.
* **5) RESTORE COMMIT:** Blader door recente commits en kies om een oudere commit uit te checken (voor inspectie), te reverten (een nieuwe undo-commit te maken) of de branch hard terug te zetten naar dit punt.
* **6) STASH PULL POP:** Slaat tijdelijke wijzigingen op (stash), haalt externe wijzigingen binnen via pull, en past de tijdelijke wijzigingen weer toe (pop).
* **7) FORGET FILE:** Verwijdert een bestand uit de git cache (`git rm --cached`).

### 4. MAINTENANCE
* **1) BACKUP POINT:** Maakt direct een lokale snapshot/kopie aan van de huidige branch met een tijdstempel.
* **2) RESTORE BACKUP:** Herstel een eerdere backup snapshot over de huidige branch, force push naar GitHub of check de backup los uit.

* **S) SETUP PERSISTENCE:** Configureert de `.env` file met je GitHub token en installeert command-line aliassen voor snelle toegang in elke terminal sessie.

---

## 3. Text Master (Stats, Diff, Merge)
Manipuleer en analyseer tekstbestanden direct in de terminal.

* **1) Text Statistics:** Telt woorden, regels en toont letterfrequentie.
* **2) Search & Replace:** Zoek met `grep` of doe een massale vervanging met `sed` waarbij automatisch een `.bak` backup wordt opgeslagen.
* **3) Compare Files (Diff):** Toont een gekleurde vergelijking (`diff`) tussen twee bestanden.
* **4) Merge Files:** Plakt (`cat`) de inhoud van meerdere bestanden achter elkaar in een nieuw doelbestand.
* **5) Case Conversion:** Zet de volledige tekst om naar uitsluitend HOOFDLETTERS of kleine letters.

---

## 4. DB Master (Database Tools)
Beheer lokale of netwerk databases (MySQL/MariaDB).

* **1) Backup Database:** Vraagt om database referenties (Host, User, Pass) en creëert een gecomprimeerde `.sql.gz` dump via `mysqldump`.
* **2) Analyze Database:** Gebruikt een Python script (`db_stats.py`) om tabelgroottes en rijen te analyseren en overzichtelijk weer te geven.

---

## 5. File Master (Rename, Archive, Cleanup)
Voor het massaal beheren en opschonen van bestanden en mappen.

* **1) Bulk Rename:** Gebruikt Python Regex patronen om meerdere bestanden tegelijk te hernoemen. Je krijgt een preview te zien voor de actie daadwerkelijk wordt uitgevoerd.
* **2) Create Directory Structure:** Leest een tekstbestand in en creëert alle paden die daarin gedefinieerd staan (ideaal voor project setups).
* **3) Archive Directory:** Comprimeert een map naar een `.zip` of `.tar.gz` archief.
* **4) Cleanup:** Biedt opties om systeembestanden (zoals `.DS_Store` of `Thumbs.db`), lege mappen, en duplicaten (via MD5 checksum hashing op identieke bestandsgroottes) te identificeren en verwijderen.
* **5) Compare Files:** Vergelijkt twee bestanden of mappen.

---

## 6. Data Master (Convert/View CSV,JSON,XML)
Zet dataformaten om en bekijk/schoon ruwe databestanden.

* **1) View CSV as Table:** Converteert en toont een CSV-bestand als een leesbare ASCII-tabel in de terminal.
* **2) Convert CSV Delimiter:** Pas eenvoudig het scheidingsteken van een CSV aan (bijv. van komma naar puntkomma).
* **3) Convert File Format:** Converteert naadloos tussen verschillende structuren: CSV naar JSON, XML naar JSON, en YAML naar JSON of CSV.
* **4) Normalize CSV:** Schoon een dataset op door lege rijen en onnodige spaties te verwijderen.
* **5) Check Dependencies:** Controleert op ontbrekende Python bibliotheken (`pandas`, `pyyaml`) en installeert deze indien nodig via `pip3`.

---

## 7. Web Scaffold (Project Generator)
Genereert snel een standaard map- en bestandsstructuur voor een nieuw webproject (PHP, HTML, CSS, JS).

* **Project Aanmaken:** Vraagt om een projectnaam en installatiepad.
* **Generatie:** Maakt `assets/` (met css/js/img submappen), `includes/` en `config/` aan. Het vult de mappen direct met een basis `index.php`, `style.css`, `app.js`, configuratiebestand en `.gitignore`.
* **Documentatie:** Optionele prompt om direct een `README.md` via Python te laten genereren.
