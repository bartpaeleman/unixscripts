# Git Master v7.0.0

Professional Git workflow manager for QNAP & macOS.

## Quick Start

```bash
./install.sh    # Run installer
./git-master.sh # Launch control panel
```

## What's Inside

```
git-master-clean/
├── git-master.sh       # Main script (20+ Git commands)
├── install.sh          # Interactive installer
├── config/             # Configuration files
│   ├── .env.example    # Template (copy to .env)
│   ├── .env.team       # Team deployment template
│   └── .gitignore      # Security protection
└── docs/               # Documentation
    ├── PACKAGR-INFO.md
    ├── QUICKSTART.md   # 5-minute setup guide
    ├── INSTALL-GUIDE.md
    ├── README.md       # Complete manual
    └── CHANGELOG.md    # Version history
```

## Features

- **20+ Git Operations** organized in 4 workflow phases
- **Analysis Tools** - Diff viewer, code search, file history
- **Environment Switching** - Prod/Dev/Test navigation
- **BusyBox Compatible** - 100% QNAP NAS ready
- **Secure Config** - External .env, no hardcoded secrets
- **Smart Updates** - Auto-merge new parameters

## Installation

```bash
# 1. Extract
unzip git-master-v7.0.0.zip
cd git-master-clean

# 2. Configure
cp config/.env.example config/.env
nano config/.env  # Add your GitHub token

# 3. Install (or use existing .env)
./install.sh

# 4. Run
./git-master.sh
```

## Documentation

- **Quick Setup** → `docs/QUICKSTART.md`
- **Full Manual** → `docs/README.md`
- **Installation** → `docs/INSTALL-GUIDE.md`
- **Version History** → `docs/CHANGELOG.md`

## Requirements

- Bash 3.2+
- Git 1.7+
- GitHub Personal Access Token
- QNAP: BusyBox v1.24.1+ compatible

## Support

All documentation included in `docs/` folder.

---

**Version:** 7.0.0 | **Size:** 25KB | **Status:** Production Ready ✅
