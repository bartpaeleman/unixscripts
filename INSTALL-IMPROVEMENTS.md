# Install Script Improvements - Summary

## 🎯 Requested Feature: .env.example Copying

Het install script kopieert nu automatisch **alle relevante bestanden** naar de juiste locaties, inclusief het `.env.example` template bestand.

---

## 📦 Wat Wordt Er Gekopieerd?

### Voor QNAP (met persistence optie)

**Locatie**: `/share/Web/DEV/scripts/` (of je geconfigureerde `PATH_DEV/scripts/`)

**Bestanden**:
```
/share/Web/DEV/scripts/
├── git-master.sh         ✅ Hoofdscript (chmod 700)
├── .env                  ✅ Jouw configuratie (chmod 600)
├── .env.example          ✅ Template voor toekomstig gebruik
├── .gitignore            ✅ Security bestand (indien aanwezig)
├── .env.team             ✅ Team template (indien aanwezig)
└── README.md             ✅ Documentatie (indien aanwezig)
```

### Voor macOS/Linux

**Locatie**: Blijft in de originele script directory

**Actie**: .env.example wordt behouden als referentie voor toekomstige configuraties

---

## 🔄 Install Flow

```
1. Script start
   ↓
2. Platform detectie (QNAP/macOS/Linux)
   ↓
3. Check: bestaat .env al?
   ├─ NEE → Maak nieuwe van .env.example
   │
   └─ JA → Intelligent detectie:
           ├─ Compleet & geldig?
           │  ├─ JA → Check nieuwe parameters
           │  │      ├─ Gevonden → Offer merge
           │  │      └─ Geen → Gebruik bestaande
           │  │
           │  └─ NEE → Incomplete detectie
           │         ├─ Vraag om aan te vullen
           │         └─ Backup + update
   ↓
4. Validatie van configuratie
   ├─ Check required fields
   ├─ Validate values
   └─ Offer edit if invalid
   ↓
5. Voor QNAP: "Persistence installeren?"
   ├─ JA → Kopieer ALLES naar /DEV/scripts/
   │        ├── git-master.sh
   │        ├── .env
   │        ├── .env.example ⭐
   │        ├── .gitignore (indien aanwezig)
   │        ├── .env.team (indien aanwezig)
   │        └── README.md (indien aanwezig)
   │        
   │        Update /etc/profile met aliases
   └─ NEE → Alleen lokale setup
   ↓
6. Validatie GitHub connectie
   ↓
7. ✅ Klaar!
```

---

## 💡 Use Cases

### Use Case 1: Eerste Installatie op QNAP
```bash
./install.sh
# Geeft geen .env → maakt nieuwe van .env.example
# Kiest persistence → kopieert .env.example mee
# Later: gebruiker kan opnieuw .env maken via template
```

### Use Case 2: Team Member Setup
```bash
git clone <repo-met-.env.team>
cp .env.team .env
nano .env  # voeg token toe
./install.sh
# Gebruikt bestaande .env
# Kopieert .env.example EN .env.team naar persistent location
# Team heeft altijd template beschikbaar
```

### Use Case 3: Reset naar Defaults
```bash
# Gebruiker op QNAP kan altijd resetten:
cd /share/Web/DEV/scripts
cp .env.example .env
nano .env  # configureer opnieuw
```

### Use Case 4: Version Update met Merge ⭐ NEW
```bash
# Je hebt v6.9.1 met werkende .env
git pull  # v7.0.0 downloaden
./install.sh

# Installer detecteert:
✓ Existing .env file found
✓ Configuration is complete and valid
⚠ New configuration parameters available:
  - AUTO_PRUNE
  - DEFAULT_BRANCH

Merge new parameters into your .env? (y): y
✓ Backup created: .env.backup.20260131_150530
  + Added: AUTO_PRUNE
  + Added: DEFAULT_BRANCH
✓ Configuration updated

# Resultaat: je oude settings + nieuwe features!
```

---

## 🔧 Nieuwe Features in git-master.sh

### Verbeterd Setup Menu (Optie S)

**Voorheen**: Alleen .env editeren

**Nu**: 
```
1) Edit current .env           → Direct bewerken
2) Create new from template    → Reset naar .env.example ⭐ NIEUW
3) Show current configuration  → Toon huidige settings ⭐ NIEUW
X) Cancel
```

### Intelligente Error Messages

**Voorheen**:
```
ERROR: .env file not found
Please copy .env.example to .env
```

**Nu**:
```
ERROR: .env file not found at: /path/to/.env
Please copy .env.example to .env and configure your settings:
  cp "/path/to/.env.example" "/path/to/.env"
  nano "/path/to/.env"
```

---

## 📊 File Permissions

| File | Permission | Reden |
|------|-----------|-------|
| `.env` | 600 | Bevat secrets - alleen eigenaar leest |
| `.env.example` | 644 | Template - iedereen mag lezen |
| `.env.team` | 644 | Team template - iedereen mag lezen |
| `git-master.sh` | 700 | Executable - alleen eigenaar |
| `.gitignore` | 644 | Standaard bestand |
| `README.md` | 644 | Documentatie |

---

## 🎨 Output Voorbeeld

```
QNAP Setup
Install to /etc/profile for persistence? (y/n): y

Copying files to persistent location...
✓ Files copied to /share/Web/DEV/scripts/
  Essential:
    - .env (secure config)
    - .env.example (template)
    - git-master.sh (main script)
  Additional:
    - .gitignore
    - .env.team (team template)
    - README.md

Updating /etc/profile...
✓ Persistence installed to /etc/profile

╔════════════════════════════════════════════════════════╗
║              Installation Complete! ✓                  ║
╚════════════════════════════════════════════════════════╝

Configuration Summary:
  Platform: QNAP
  Config: Using repository .env file
  Root: /share/Web
  Script: /tmp/git-master/git-master.sh
  Persistent Location:
    /share/Web/DEV/scripts/
    ├── git-master.sh (executable)
    ├── .env (your config)
    ├── .env.example (template)
    ├── .gitignore
    ├── .env.team
    └── README.md
```

---

## ✅ Checklist

- [x] .env.example wordt gekopieerd naar persistent location (QNAP)
- [x] .env.example blijft beschikbaar voor macOS/Linux
- [x] Optionele bestanden (.gitignore, .env.team, README.md) worden mee gekopieerd
- [x] Correcte file permissions worden gezet
- [x] Setup menu in git-master.sh kan .env resetten naar template
- [x] Duidelijke output toont wat er gekopieerd is
- [x] Error messages tonen exacte pad naar .env.example

---

## 🚀 Resultaat

Gebruikers hebben nu **altijd** toegang tot:
1. ✅ Hun werkende configuratie (`.env`)
2. ✅ Een schone template (`.env.example`)
3. ✅ Team configuratie template (`.env.team` indien aanwezig)
4. ✅ Mogelijkheid om te resetten via Setup menu

Perfect voor:
- Nieuwe team members die snel moeten starten
- Recovery na verkeerde configuratie
- Documentatie van beschikbare opties
- Meerdere QNAP setups met verschillende configs
