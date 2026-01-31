# Smart .env Configuration Management

## 🎯 Problem Solved

When updating Git Master or sharing configurations across systems, you don't want to lose your existing settings or manually merge configuration files.

**Git Master v7.0.0 now intelligently handles existing .env files!**

---

## ✨ How It Works

### Scenario 1: Fresh Installation (No .env)
```bash
./install.sh
```

**What happens:**
1. Creates .env from .env.example
2. Asks for your credentials
3. Saves configuration
4. Validates settings

**Result:** Clean installation with your settings

---

### Scenario 2: Complete Existing .env

```bash
# You already have:
.env with:
  GITHUB_TOKEN="ghp_your_token"
  GITHUB_USERNAME="yourname"
  PATH_ROOT="/share/Web"
```

**What happens:**
```
./install.sh

✓ Existing .env file found
✓ Configuration is complete and valid
⚠ New configuration parameters available:
  - AUTO_PRUNE
  - DEFAULT_BRANCH

Merge new parameters into your .env? (y/n): y

✓ Backup created: .env.backup.20260131_150530
  + Added: AUTO_PRUNE
  + Added: DEFAULT_BRANCH
✓ Configuration updated with new parameters
```

**Result:** 
- Your existing settings preserved
- New parameters added automatically
- Backup created for safety
- No manual editing needed!

---

### Scenario 3: Incomplete Existing .env

```bash
# You have:
.env with only:
  PATH_ROOT="/share/Web"
  # Missing: GITHUB_TOKEN, GITHUB_USERNAME
```

**What happens:**
```
./install.sh

✓ Existing .env file found
⚠ Configuration incomplete. Missing:
  - GITHUB_TOKEN
  - GITHUB_USERNAME

Complete the configuration now? (y/n): y

✓ Backup created
GitHub Username: yourname
GitHub Token (input hidden): ****
Projects root path: /share/Web (from existing .env)

✓ Configuration saved
```

**Result:**
- Missing fields added
- Existing settings kept
- Backup created
- Complete configuration

---

### Scenario 4: Version Upgrade

```bash
# Old version .env:
GITHUB_TOKEN="..."
GITHUB_USERNAME="..."
PATH_ROOT="/share/Web"

# New version adds:
AUTO_PRUNE=true
DEFAULT_BRANCH="main"
BACKUP_ENABLED=true
```

**What happens:**
```
./install.sh

✓ Existing .env file found
✓ Configuration is complete and valid
⚠ New configuration parameters available:
  - AUTO_PRUNE
  - DEFAULT_BRANCH
  - BACKUP_ENABLED

Merge new parameters into your .env? (y/n): y

--- .env after merge ---
GITHUB_TOKEN="..." (kept)
GITHUB_USERNAME="..." (kept)
PATH_ROOT="/share/Web" (kept)

# --- New parameters added 2026-01-31 ---
AUTO_PRUNE=true (added)
DEFAULT_BRANCH="main" (added)
BACKUP_ENABLED=true (added)
```

**Result:**
- Zero downtime upgrade
- All old settings preserved
- New features available
- Dated comments for tracking

---

## 🔍 Smart Detection

The installer checks:

1. **File exists?** → Use or create
2. **Has required fields?** → Complete or ask
3. **New parameters available?** → Offer to merge
4. **Values valid?** → Validate or prompt

### Required Fields
- `GITHUB_TOKEN`
- `GITHUB_USERNAME`
- `PATH_ROOT`

### Optional Fields
- `PATH_PROD`
- `PATH_DEV`
- `PATH_TEST`
- `AUTO_PRUNE`
- `DEFAULT_BRANCH`
- And any future additions...

---

## 🛡️ Safety Features

### Automatic Backups
Every time .env is modified:
```bash
.env.backup.20260131_150530  # Timestamp backup
.env.backup.20260131_151245
.env.backup.20260131_152010
```

**You can always restore:**
```bash
cp .env.backup.20260131_150530 .env
```

### Validation
After every change:
```
✓ GITHUB_TOKEN: Set
✓ GITHUB_USERNAME: Set
✓ PATH_ROOT: Valid path
✓ Configuration validated successfully
```

### Rollback
If validation fails:
```
⚠ Configuration validation failed
Edit .env now? (y/n): y
[Opens editor]
✓ Configuration now valid
```

---

## 💡 Use Cases

### Use Case 1: Team Onboarding
```bash
# Team admin creates .env.team with company settings
PATH_ROOT="/company/projects"
# (tokens left empty)

# New team member:
cp .env.team .env
# Add personal token
./install.sh
# Installer detects partial config, asks only for missing token
```

### Use Case 2: Multi-Environment Setup
```bash
# Development machine
PATH_ROOT="$HOME/Projects"
./install.sh  # Creates config

# Copy to production QNAP
scp .env admin@qnap:/share/Web/DEV/scripts/
ssh admin@qnap
cd /share/Web/DEV/scripts
./install.sh  # Uses existing .env, just validates
```

### Use Case 3: Version Update
```bash
# You're on v6.9.1 with working .env
git pull  # Get v7.0.0
./install.sh
# Installer: "New parameters available, merge?"
# Result: v7.0.0 features + your old settings
```

### Use Case 4: Configuration Recovery
```bash
# Accidentally deleted .env
ls .env.backup.*
.env.backup.20260131_150530  # Found it!

cp .env.backup.20260131_150530 .env
./install.sh  # Validates and continues
```

---

## 🔧 Manual Merge Example

If you prefer manual control:

```bash
./install.sh

Merge new parameters into your .env? (y/n): n

# Later, manually add:
nano .env

# At bottom of file:
# --- Optional new features ---
AUTO_PRUNE=true
DEFAULT_BRANCH="main"
```

---

## 📊 Comparison: Old vs New

### Old Behavior (v6.9.1)
```
./install.sh
→ Overwrites any existing .env
→ Lose all your settings
→ Manual reconfiguration needed
→ No validation
```

### New Behavior (v7.0.0)
```
./install.sh
→ Detects existing .env
→ Validates completeness
→ Merges new parameters
→ Creates backups
→ Validates result
→ You're done!
```

---

## 🎓 Best Practices

### 1. Always Keep .env.example Updated
When adding new features:
```bash
# Add to .env.example:
NEW_FEATURE=true

# Installer will detect and offer to merge
```

### 2. Use Descriptive Comments
```bash
# .env.example
# Enable automatic branch cleanup (v7.0+)
AUTO_PRUNE=true
```

### 3. Version Your .env.team
```bash
# .env.team
# Git Master v7.0.0 - Company Template
# Last updated: 2026-01-31
PATH_ROOT="/company/shared"
```

### 4. Keep Backups
```bash
# Before major changes
cp .env .env.backup.manual

# Installer creates automatic backups too
```

---

## 🚨 Troubleshooting

### "Configuration incomplete"
**Problem:** Missing required fields

**Solution:**
```bash
./install.sh
# Choose 'y' to complete now
# Or manually edit:
nano .env
# Add missing fields
./install.sh  # Re-validate
```

### "Cannot read .env file"
**Problem:** Syntax error in .env

**Solution:**
```bash
# Check for errors
cat .env

# Common issues:
GITHUB_TOKEN=token  # Missing quotes!
GITHUB_TOKEN="token"  # ✓ Correct

# Fix and re-run:
./install.sh
```

### "Merge failed"
**Problem:** Conflicting parameters

**Solution:**
```bash
# Manual merge
diff .env .env.example
# Add missing parameters manually
nano .env
```

---

## 🎯 Technical Details

### Detection Logic
```bash
1. Check if .env exists
2. Source .env safely
3. Check for GITHUB_TOKEN, GITHUB_USERNAME, PATH_ROOT
4. Compare with .env.example for new params
5. Offer merge if differences found
```

### Merge Algorithm
```bash
1. Create timestamped backup
2. Read new params from .env.example
3. Append to .env with comment header
4. Preserve original formatting
5. Validate merged result
```

### Validation Process
```bash
1. Source .env
2. Check all required fields are non-empty
3. Verify paths are valid (optional)
4. Test GitHub token (optional)
5. Report success or errors
```

---

## ✅ Summary

**Before (v6.9.1):**
- 😞 Manual .env management
- 😞 Lost settings on update
- 😞 No validation
- 😞 No backups

**After (v7.0.0):**
- 😊 Automatic detection
- 😊 Intelligent merging
- 😊 Safe backups
- 😊 Validation included
- 😊 Zero-downtime updates

**Your configuration is now safe, smart, and future-proof!** 🎉

---

## 📚 Related Documentation

- INSTALL-GUIDE.md - Full installation guide
- .env.example - Configuration template
- .env.team - Team deployment template

---

*Last updated: 2026-01-31*
*Git Master v7.0.0*
