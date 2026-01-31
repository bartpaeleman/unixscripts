# Smart .env Handling - Installation Guide

## 🎯 Intelligent Configuration Management

The installer now intelligently handles existing `.env` files, making updates and re-installations seamless.

---

## 🔄 How It Works

### Scenario 1: Valid .env Already Exists ✅

**What happens:**
```bash
./install.sh

# Output:
Detected platform: QNAP

✓ Existing .env file found
✓ Configuration is complete and valid
  Username: bartpaeleman
  Token: ***configured***
  Root: /share/Web

✓ No new parameters needed

Proceeding with existing configuration...
```

**Result:** Installation continues automatically with your settings!

---

### Scenario 2: .env Exists with New Parameters Available 🔄

**What happens:**
```bash
./install.sh

# Output:
✓ Existing .env file found
✓ Configuration is complete and valid
⚠ New configuration parameters detected
✓ Backup created: .env.backup.20260131_150530
  + Added: NEW_PARAMETER_1
  + Added: NEW_PARAMETER_2
✓ Configuration automatically updated

Proceeding with existing configuration...
```

**Result:** 
- Your existing config is preserved
- New parameters are automatically added
- Backup created for safety
- Installation continues

---

### Scenario 3: .env Exists but Incomplete ⚠️

**What happens:**
```bash
./install.sh

# Output:
✓ Existing .env file found
⚠ Configuration incomplete. Missing:
  - GITHUB_TOKEN
  - PATH_ROOT

Complete the configuration now? (y/n):
```

**Options:**
- **y** → You'll be prompted only for missing fields
- **n** → Installation continues with what's available

---

### Scenario 4: No .env Exists 🆕

**What happens:**
```bash
./install.sh

# Output:
Creating .env from template...

Please provide the following information:
GitHub Username: 
```

**Result:** Normal first-time installation flow

---

## 💡 Smart Features

### 1. Automatic Merging
When new parameters are added to `.env.example` in a new version:
- ✅ Existing values are preserved
- ✅ New parameters added automatically
- ✅ Backup created before changes
- ✅ Timestamped comment added

**Example .env after merge:**
```bash
# Original config
GITHUB_TOKEN="ghp_xxxxx"
GITHUB_USERNAME="bartpaeleman"
PATH_ROOT="/share/Web"

# --- New parameters added 2026-01-31 ---
NEW_FEATURE_SETTING="default_value"
ANOTHER_OPTION="true"
```

### 2. No User Interruption
If your `.env` is valid:
- ✅ No prompts during installation
- ✅ Fully automated
- ✅ Perfect for scripts/automation
- ✅ Safe for CI/CD pipelines

### 3. Smart Field Detection
Only asks for what's missing:
```bash
# You have username but not token
GitHub Username: bartpaeleman (from existing .env)
GitHub Token (input hidden): [you type here]
```

### 4. Automatic Backups
Before any modification:
```bash
.env.backup.20260131_150530
.env.backup.20260131_160245
.env.backup.20260131_170815
```

**Format:** `.env.backup.YYYYMMDD_HHMMSS`

---

## 🔧 Use Cases

### Use Case 1: Team Member Update
```bash
# Team member already has .env configured
# New version adds features

git pull
./install.sh

# ✅ Automatic: Merges new parameters
# ✅ Keeps their token/username
# ✅ No manual editing needed
```

### Use Case 2: Version Upgrade
```bash
# Upgrading from v7.0.0 to v7.1.0
# New parameters added

cd git-master
git pull
./install.sh

# ✅ Detects new parameters
# ✅ Adds them automatically
# ✅ Creates backup
# ✅ Installation continues
```

### Use Case 3: Multi-Machine Deployment
```bash
# Copy .env to new machine
scp .env qnap2:/path/to/git-master/

# On new machine
cd /path/to/git-master
./install.sh

# ✅ Uses existing config
# ✅ No re-entering credentials
# ✅ Consistent setup
```

### Use Case 4: Recovery After Mistake
```bash
# Accidentally deleted .env
cp .env.backup.20260131_150530 .env
./install.sh

# ✅ Validates recovered config
# ✅ Merges any new parameters
# ✅ Back to working state
```

---

## 🛡️ Safety Features

### 1. Validation Before Use
```bash
# Checks required fields
✓ GITHUB_TOKEN exists and not empty
✓ GITHUB_USERNAME exists and not empty  
✓ PATH_ROOT exists and not empty
```

### 2. Timestamped Backups
```bash
# Always creates backup before changes
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
```

### 3. Non-Destructive Merge
```bash
# Original values never overwritten
# Only additions, never replacements
```

### 4. Visual Confirmation
```bash
# Shows what will be used
  Username: bartpaeleman
  Token: ***configured***
  Root: /share/Web

Proceeding with existing configuration...
```

---

## 📊 Decision Flow

```
Install Script Starts
    ↓
.env exists?
    ├─ NO → Create from .env.example → Ask for config
    │
    └─ YES → Validate contents
            ↓
        All required fields present?
            ├─ NO → Ask to complete
            │       ├─ YES → Ask only for missing
            │       └─ NO → Use as-is
            │
            └─ YES → Check for new parameters
                    ↓
                New parameters in .env.example?
                    ├─ YES → Backup .env
                    │        Add new parameters
                    │        Continue automatically
                    │
                    └─ NO → Continue automatically
```

---

## 🎯 Benefits

### For Individual Users
- ✅ No re-entering credentials on updates
- ✅ Safe backups before changes
- ✅ Only prompted when needed

### For Teams
- ✅ Consistent configuration across members
- ✅ Easy updates without manual edits
- ✅ Version control friendly

### For QNAP
- ✅ Persistence across reboots maintained
- ✅ No SSH session interruptions
- ✅ Automated deployment possible

---

## 🔍 Technical Details

### Parameter Detection
```bash
# Finds all uppercase parameters from .env.example
grep -E "^[A-Z_]+" .env.example | cut -d'=' -f1

# Checks if each exists in current .env
grep -q "^${param}=" .env
```

### Merge Process
```bash
1. Read .env.example line by line
2. Extract parameter name
3. Check if exists in .env
4. If not → append with default value
5. Add timestamp comment
```

### Backup Naming
```bash
# Format: .env.backup.YYYYMMDD_HHMMSS
.env.backup.$(date +%Y%m%d_%H%M%S)

# Example: .env.backup.20260131_150530
```

---

## 💬 Common Questions

**Q: Will my token be overwritten?**
A: No, existing values are never overwritten, only new parameters are added.

**Q: What if I want to change my config?**
A: Edit `.env` directly, or delete it and run `./install.sh` for fresh setup.

**Q: Can I skip the merge?**
A: It's automatic for safety. Manual edits always work if needed.

**Q: Where are backups stored?**
A: Same directory as `.env`, with timestamp suffix.

**Q: How do I restore a backup?**
A: `cp .env.backup.TIMESTAMP .env` then run `./install.sh`

**Q: What if installation fails mid-merge?**
A: Backup is created first, so restore from `.env.backup.*`

---

## 🚀 Best Practices

### 1. Keep Backups
```bash
# Backups are automatic, but you can make manual ones too
cp .env .env.my-backup
```

### 2. Version Control (Carefully)
```bash
# Never commit .env with real tokens!
# But .env.team (template) is safe to commit

git add .env.team
git commit -m "Update team config template"
```

### 3. Document Custom Changes
```bash
# Add comments to your .env
GITHUB_TOKEN="ghp_xxxxx"  # Personal access token
PATH_ROOT="/custom/path"   # Changed from default
```

### 4. Test After Merge
```bash
# After automatic merge, verify
./git-master.sh
# Press 1 for Dashboard to test connection
```

---

## 📋 Checklist

After running `./install.sh` with existing `.env`:

- [ ] Installation completed without errors
- [ ] Backup created (if parameters added)
- [ ] New parameters visible in `.env`
- [ ] Script launches successfully
- [ ] Dashboard shows correct info
- [ ] GitHub connection works

---

## 🎉 Result

**Seamless Updates!**

You can now:
- ✅ Update Git Master without reconfiguring
- ✅ Pull new versions worry-free
- ✅ Share configs across machines
- ✅ Automate deployments
- ✅ Recover from mistakes easily

**Your configuration is safe and smart!** 🚀
