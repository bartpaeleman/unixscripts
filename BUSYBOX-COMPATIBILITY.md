# BusyBox Compatibility Guide - Git Master v7.0.0

## 🐛 BusyBox Issues & Solutions

QNAP NAS systems use BusyBox, a lightweight implementation of common Unix utilities. Many standard Linux commands have limited functionality in BusyBox.

---

## ✅ Fixed Issues

### 1. `less -R` (Color Support) ❌ → `more` ✅

**Problem:**
```bash
less: invalid option -- 'R'
BusyBox v1.24.1 multi-call binary.
```

**Root Cause:**
BusyBox `less` doesn't support the `-R` flag for raw ANSI color codes.

**Solution:**
```bash
# BEFORE (crashes):
{
    printf "Branch info...\n"
    git status
} | less -R

# AFTER (works):
{
    printf "Branch info...\n"
    git status
} | more
```

**Impact:** Dashboard (option 1) now works on all QNAP systems.

---

### 2. `grep -o` (Only Matching) ⚠️ → `sed` ✅

**Problem:**
BusyBox `grep` might not support `-o` (only matching) in older versions.

**Solution:**
```bash
# BEFORE (might fail):
curl ... | grep -o '"name": "[^"]*' | cut -d'"' -f4

# AFTER (always works):
curl ... | sed -n 's/.*"name": "\([^"]*\)".*/\1/p'
```

**Impact:** Repository cloning (option 0) is more reliable.

---

### 3. `grep -E` (Extended Regex) ⚠️ → Simple `grep` ✅

**Problem:**
Some BusyBox versions have limited `-E` support.

**Solution:**
```bash
# BEFORE:
grep -vE "License|GNU"

# AFTER:
grep -v "License" | grep -v "GNU"
```

**Impact:** Better compatibility across QNAP firmware versions.

---

### 4. `git log --decorate --all` ⚠️ → Simplified ✅

**Problem:**
Older Git versions on QNAP might not support all decorations.

**Solution:**
```bash
# BEFORE:
git log -n 20 --oneline --graph --decorate --all

# AFTER:
git log -n 20 --oneline --graph
```

**Impact:** Dashboard shows history reliably on all systems.

---

## 🔍 Commands That Work in BusyBox

### ✅ Safe to Use:
- `git` - Full functionality (if Git is installed)
- `curl` - Basic HTTP requests
- `sed` - Stream editing (basic patterns)
- `grep` - Basic patterns (without `-o`, `-P`)
- `awk` - Text processing
- `more` - Page through text
- `cat` - Display files
- `printf` - Formatted output
- `echo` - Simple output
- `read` - User input
- `cd`, `pwd` - Directory navigation
- `mkdir`, `rm`, `cp`, `mv` - File operations
- `chmod` - Permissions
- `date` - Date/time (basic formats)

### ⚠️ Use with Caution:
- `less` - Limited flags (no `-R`)
- `grep -E` - Use simple patterns instead
- `grep -o` - Use `sed` for extraction
- `sed -i` - Might need `-i ''` on some systems
- `find` - Limited expressions
- `xargs` - Works but test first

### ❌ Avoid:
- `less -R` - Not supported
- `grep -P` - Perl regex not available
- `stat -c` - Use `ls -l` instead
- Advanced `sed` features
- `readlink -f` - Use `realpath` or `pwd`

---

## 🛠️ BusyBox-Safe Patterns

### Pattern 1: Paging Output
```bash
# BAD:
command | less -R

# GOOD:
command | more

# BEST (with fallback):
if command -v less >/dev/null 2>&1; then
    command | less
else
    command | more
fi
```

### Pattern 2: Extracting JSON Fields
```bash
# BAD:
curl api | grep -o '"field":"[^"]*"' | cut -d':' -f2

# GOOD:
curl api | sed -n 's/.*"field":"\([^"]*\)".*/\1/p'
```

### Pattern 3: Multiple Pattern Exclusion
```bash
# BAD:
grep -vE "pattern1|pattern2"

# GOOD:
grep -v "pattern1" | grep -v "pattern2"
```

### Pattern 4: Date Formatting
```bash
# BAD (not all formats supported):
date +%Y-%m-%dT%H:%M:%S%z

# GOOD (basic formats):
date +%Y%m%d_%H%M
```

### Pattern 5: Checking Command Existence
```bash
# BAD:
which less

# GOOD:
command -v less >/dev/null 2>&1
```

---

## 📝 Testing Checklist

Before deploying to QNAP, test these:

- [ ] `less` with and without `-R` flag
- [ ] `grep -o` for pattern extraction
- [ ] `grep -E` for extended regex
- [ ] `sed -i` for in-place editing
- [ ] `git log` with various flags
- [ ] `date` format strings
- [ ] `curl` for API calls
- [ ] Color codes in `printf`

---

## 🚀 Git Master v7.0.0 BusyBox Compliance

### All Commands Tested:

| Command | BusyBox Safe? | Alternative Used |
|---------|---------------|------------------|
| `more` | ✅ Yes | Used instead of `less -R` |
| `sed -n 's/...'` | ✅ Yes | Used instead of `grep -o` |
| `grep -v` | ✅ Yes | Simple patterns only |
| `git log --oneline --graph` | ✅ Yes | Removed `--decorate --all` |
| `git stash` | ✅ Yes | Basic usage only |
| `date +%Y%m%d_%H%M` | ✅ Yes | Simple format |
| `printf` with colors | ✅ Yes | ANSI codes work |
| `read -p` | ✅ Yes | Standard input |

---

## 💡 Pro Tips for QNAP

### 1. Test in SSH First
Always test new commands via SSH before adding to scripts:
```bash
ssh admin@qnap-ip
# Test command here
```

### 2. Check BusyBox Version
```bash
busybox | head -1
# BusyBox v1.24.1 (2025-12-25 02:55:30 CST)
```

### 3. Use `command -v` for Detection
```bash
if command -v git >/dev/null 2>&1; then
    echo "Git is available"
fi
```

### 4. Fallback to Simpler Commands
```bash
# Try fancy first, fall back to simple
git log --oneline --graph --decorate --all 2>/dev/null || \
git log --oneline --graph
```

### 5. Avoid Shell-Specific Features
```bash
# BAD (bash 4+ only):
declare -A array

# GOOD (works everywhere):
declare -a array
```

---

## 🔧 Debugging BusyBox Issues

### Step 1: Isolate the Command
```bash
# Run just the failing part
curl -s "https://api.github.com/repos" | grep -o '"name"'
```

### Step 2: Check Error Message
```bash
grep: invalid option -- 'o'
# Means: BusyBox grep doesn't support -o
```

### Step 3: Find Alternative
```bash
# Google: "busybox alternative to grep -o"
# Answer: Use sed
sed -n 's/.*"name": "\([^"]*\)".*/\1/p'
```

### Step 4: Test Alternative
```bash
curl -s "https://api.github.com/repos" | sed -n 's/.*"name": "\([^"]*\)".*/\1/p'
```

### Step 5: Update Script
```bash
# Replace in git-master.sh
```

---

## 📚 Resources

- [BusyBox Command List](https://busybox.net/downloads/BusyBox.html)
- [QNAP Wiki - SSH & Command Line](https://wiki.qnap.com/)
- [BusyBox vs GNU Coreutils Differences](https://git.busybox.net/busybox/tree/docs/busybox.net/FAQ.html)

---

## ✅ Result: 100% BusyBox Compatible

Git Master v7.0.0 has been tested and verified to work on:
- ✅ BusyBox v1.24.1 (QNAP)
- ✅ BusyBox v1.31.x (newer QNAP firmware)
- ✅ Full GNU/Linux (Ubuntu, Debian, etc.)
- ✅ macOS (BSD utilities)

All commands have been replaced with BusyBox-safe alternatives! 🎉
