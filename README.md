# Git Master Control Panel v7.0

Professional Git workflow manager for QNAP NAS and macOS, designed to streamline development cycles on GitHub.

## ✨ Features

- **Environment Management**: Seamless switching between PROD, DEV, and TEST
- **Branch Operations**: Easy branch creation, switching, and merging
- **UAT Workflow**: Streamlined testing and staging processes
- **Emergency Tools**: Conflict resolution, rollback, and recovery
- **Secure Configuration**: Environment-based secrets management
- **Cross-Platform**: Works on QNAP NAS and macOS

## 🚀 Quick Start

### 1. Installation

```bash
# Clone or download the repository
git clone https://github.com/yourusername/git-master.git
cd git-master

# Make the script executable
chmod +x git-master.sh
```

### 2. Configuration

```bash
# Copy the example environment file
cp .env.example .env

# Edit with your settings
nano .env  # or vim, code, etc.
```

**Required `.env` settings:**

```bash
GITHUB_TOKEN="ghp_your_token_here"
GITHUB_USERNAME="yourusername"
PATH_ROOT="/your/projects/path"
```

### 3. Getting a GitHub Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes: `repo`, `workflow`, `delete_repo`
4. Copy the token and add to `.env`

### 4. Run

```bash
./git-master.sh
```

## 📖 Usage Guide

### Navigation (Phase 0)

| Key | Action | Description |
|-----|--------|-------------|
| `P` | PROD | Switch to production environment |
| `D` | DEV | Switch to development environment |
| `T` | TEST | Switch to test/UAT environment |
| `0` | Clone | Clone a new repository from GitHub |

### Development Cycle (Phase 1)

| Key | Action | Description |
|-----|--------|-------------|
| `1` | Dashboard | View status, branches, and commit history |
| `2` | Branch Explorer | Create or switch branches |
| `3` | Quick Commit | Stage, commit, and push changes |
| `4` | Pull | Fetch and merge remote changes |
| `5` | Force Sync | Resolve conflicts (overwrite local or remote) |
| `6` | Backup | Create a timestamped backup branch |

### UAT & Release (Phase 2)

| Key | Action | Description |
|-----|--------|-------------|
| `7` | Prepare UAT | Merge external branch for testing |
| `8` | Staging Push | Promote current branch to dev-stable |
| `9` | Merge Fixes | Integrate fix branches |
| `10` | Release Tag | Create version tag (e.g., v1.2.3) |

### Maintenance (Phase 3)

| Key | Action | Description |
|-----|--------|-------------|
| `11` | Prune | Remove dead branches (deleted on GitHub) |
| `12` | Delete Local | Remove a local branch |
| `13` | Undo Commit | Rollback last commit (keep changes) |
| `14` | Force Reset | Nuclear option - reset to main |
| `15` | Emergency | Abort merges, clear locks, pop stash |

## 🔧 Configuration Reference

### `.env` File Options

```bash
# ====== REQUIRED ======
GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"
GITHUB_USERNAME="yourname"
PATH_ROOT="/share/Web"

# ====== OPTIONAL ======
# Override derived paths
PATH_PROD="${PATH_ROOT}"
PATH_DEV="${PATH_ROOT}/DEV"
PATH_TEST="${PATH_ROOT}/TEST"

# QNAP-specific (for persistence across logins)
PERSISTENT_SCRIPT_PATH="${PATH_DEV}/scripts/git-master.sh"
PERSISTENT_ENV="${PATH_DEV}/scripts/.env"

# Git defaults
DEFAULT_BRANCH="main"
AUTO_PRUNE=true
```

### Path Structure Example

```
/share/Web/                    # PATH_ROOT (PROD)
├── project-a/                 # Production code
├── project-b/
└── DEV/                       # PATH_DEV
    ├── project-a/             # Development versions
    ├── project-b/
    ├── scripts/
    │   ├── git-master.sh
    │   └── .env
    └── TEST/                  # PATH_TEST (UAT)
        ├── project-a/
        └── project-b/
```

## 🛡️ Security Best Practices

1. **Never commit `.env`** - It's in `.gitignore` by default
2. **Use GitHub tokens** instead of passwords
3. **Rotate tokens** regularly (every 90 days)
4. **Limit token scope** to only required permissions
5. **On QNAP**: Set correct file permissions
   ```bash
   chmod 600 .env
   chmod 700 git-master.sh
   ```

## 🍎 macOS Specific Setup

```bash
# Install via Homebrew (if not already installed)
brew install git

# Set up PATH_ROOT for your user
export PATH_ROOT="$HOME/Projects"

# Add to ~/.zshrc or ~/.bashrc for persistence
echo 'export PATH_ROOT="$HOME/Projects"' >> ~/.zshrc

# Optional: Create alias
echo 'alias gitmaster="/path/to/git-master.sh"' >> ~/.zshrc
```

## 📦 QNAP Specific Setup

### Making it Persistent Across Reboots

The script can set itself up to survive QNAP reboots:

1. Run the script: `./git-master.sh`
2. Press `S` for Setup
3. Follow prompts to install to `/etc/profile`

This creates:
- Alias `gitmaster` to launch from anywhere
- Aliases `prod`, `dev`, `test` for quick navigation
- Auto-loads GitHub token on login

### SSH Access

```bash
# Connect to QNAP
ssh admin@your-qnap-ip

# Navigate to scripts
cd /share/Web/DEV/scripts

# Run
./git-master.sh
```

## 🔄 Workflow Examples

### Example 1: Feature Development

```
1. Press `D` → Go to DEV environment
2. Press `2` → Create branch "feature-login"
3. [Code your changes]
4. Press `3` → Commit "Add login form"
5. Press `4` → Pull latest changes
6. Press `8` → Push to dev-stable for review
```

### Example 2: Testing External Changes

```
1. Press `7` → Prepare UAT
2. Select Jules' branch from list
3. [Test in UAT environment]
4. If OK: Press `9` → Merge fixes
```

### Example 3: Emergency Rollback

```
1. Press `15` → Emergency menu
2. Select option to abort merge/clear locks
3. Press `13` → Undo last commit (if needed)
4. Press `14` → Force reset to main (nuclear option)
```

## 🐛 Troubleshooting

### "Authentication failed"
- Check your `GITHUB_TOKEN` in `.env`
- Verify token hasn't expired
- Ensure token has `repo` scope

### "Not in git repository"
- Navigate to a git project folder
- Or press `0` to clone a new repository

### Menu too large for terminal
- Resize terminal window
- Use `less` or `more` for dashboard (option 1)
- Menu has been optimized to fit 24-line terminals

### QNAP: Changes lost after reboot
- Run option `S` to install persistence
- Verify `/etc/profile` includes the source line

### macOS: Permission denied
```bash
chmod +x git-master.sh
```

## 📝 Version History

### v7.0.0 (Current)
- ✅ Environment-based configuration (.env)
- ✅ Improved security (no hardcoded secrets)
- ✅ Compact menu design
- ✅ Cross-platform compatibility
- ✅ Better error handling
- ✅ Template-based setup

### v6.9.1 (Legacy)
- Original hardcoded version

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License - Feel free to use and modify

## 💬 Support

For issues or questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review this README thoroughly

## 🔗 Related Resources

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Git Documentation](https://git-scm.com/doc)
- [QNAP CLI Guide](https://www.qnap.com/en/how-to/faq/article/how-to-access-qnap-nas-by-ssh)

---

**Made with ❤️ for efficient Git workflows**
