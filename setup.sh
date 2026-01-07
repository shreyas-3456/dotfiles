#!/bin/bash

# Setup script for dotfiles repository
# Installs dependencies, homebrew/linuxbrew, configures zsh, and installs packages

set -e

# Default values
DEFAULT_GIT_NAME="Shreyas Nigam"
DEFAULT_GIT_EMAIL="shreyas@workemail.com"
DEFAULT_SHREYAS_NAME="Shreyas Personal Account"
DEFAULT_SHREYAS_EMAIL="shreyas-email@example.com"

# Parse command line arguments
GIT_NAME="${1:-$DEFAULT_GIT_NAME}"
GIT_EMAIL="${2:-$DEFAULT_GIT_EMAIL}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${BLUE}[*]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

info() {
    echo -e "${CYAN}[i]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Detect if running on WSL
is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null && echo "true" || echo "false"
}

# Backup existing file
backup_file() {
    local file="$1"
    if [ -f "$file" ] || [ -L "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log "Backing up existing file: $file -> $backup"
        mv "$file" "$backup"
        success "Backup created: $backup"
        return 0
    fi
    return 1
}

# Generate SSH key if it doesn't exist
generate_ssh_key() {
    local key_path="$1"
    local key_comment="$2"
    
    if [ -f "$key_path" ]; then
        success "SSH key already exists: $key_path"
        return 0
    fi
    
    log "Generating SSH key: $key_path"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    ssh-keygen -t ed25519 -f "$key_path" -C "$key_comment" -N "" -q
    chmod 600 "$key_path"
    chmod 644 "$key_path.pub"
    
    success "SSH key generated: $key_path"
}

# Create git config file
create_gitconfig() {
    local config_path="$1"
    local git_name="$2"
    local git_email="$3"
    local ssh_key="$4"
    
    log "Creating git config: $config_path"
    
    # Remove existing file if it's not writable
    if [ -f "$config_path" ] && [ ! -w "$config_path" ]; then
        log "Removing unwritable file: $config_path"
        rm -f "$config_path"
    fi
    
    cat > "$config_path" << EOF
[user]
    name = $git_name
    email = $git_email

[core]
    sshCommand = "ssh -i ~/.ssh/$ssh_key"
EOF
    
    success "Git config created: $config_path"
}

# Rollback function
rollback() {
    error "Setup failed! Rolling back changes..."
    
    # Restore backups if they exist
    for backup in ~/.gitconfig.backup.* ~/.zshrc.backup.*; do
        if [ -f "$backup" ]; then
            original="${backup%.backup.*}"
            log "Restoring $original from backup"
            mv "$backup" "$original"
        fi
    done 2>/dev/null
    
    error "Rollback complete. Please check the errors above and try again."
    exit 1
}

# Set up trap for errors
trap rollback ERR

OS=$(detect_os)
WSL=$(is_wsl)

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║           DOTFILES SETUP SCRIPT v2.0                       ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

log "Detected OS: $OS (WSL: $WSL)"
info "Git Name: $GIT_NAME"
info "Git Email: $GIT_EMAIL"
echo ""

# Confirmation prompt
read -p "$(echo -e "${YELLOW}Continue with setup? [y/N]: ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    warning "Setup cancelled by user"
    exit 0
fi

echo ""

# ==============================================================================
# Request sudo access upfront (cache for entire script)
# ==============================================================================
log "Requesting sudo access..."
sudo -v
success "Sudo access granted"

echo ""

# ==============================================================================
# Step 0: Pre-flight checks
# ==============================================================================
log "Step 0: Pre-flight checks..."

# Verify we're in the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! "$DOTFILES_DIR" =~ dotfiles$ ]]; then
    warning "Not in dotfiles directory. Assuming current directory: $DOTFILES_DIR"
fi

# Check if required directories exist
if [ ! -d "$DOTFILES_DIR/zsh" ]; then
    error "zsh directory not found in $DOTFILES_DIR"
    error "Please ensure you have the correct dotfiles structure"
    exit 1
fi

if [ ! -f "$DOTFILES_DIR/homebrew/Brewfile" ]; then
    warning "Brewfile not found at $DOTFILES_DIR/homebrew/Brewfile"
    warning "Will skip Homebrew package installation"
fi

success "Pre-flight checks passed"

# ==============================================================================
# Step 1: Setup SSH keys and Git configuration
# ==============================================================================
log "Step 1: Setting up SSH keys and Git configuration..."

# Generate default SSH key
generate_ssh_key ~/.ssh/id_ed25519 "Default Git Key"

# Generate Shreyas-specific SSH key
generate_ssh_key ~/.ssh/id_ed25519_shreyas "Shreyas Git Key"

# Backup existing gitconfig if it exists
if [ -f ~/.gitconfig ]; then
    backup_file ~/.gitconfig
fi

# Create global gitconfig
create_gitconfig ~/.gitconfig "$GIT_NAME" "$GIT_EMAIL" "id_ed25519"

# Create Shreyas-specific gitconfig
create_gitconfig ~/.gitconfig-shreyas "$DEFAULT_SHREYAS_NAME" "$DEFAULT_SHREYAS_EMAIL" "id_ed25519_shreyas"

# Add includeIf directives to gitconfig
log "Adding includeIf directives to ~/.gitconfig..."
cat >> ~/.gitconfig << 'EOF'

# --- SPECIAL OVERRIDES ---
# Both folders will now use the exact same special settings

[includeIf "gitdir/i:~/shreyas/"]
    path = ~/.gitconfig-shreyas

[includeIf "gitdir/i:~/dotfiles/"]
    path = ~/.gitconfig-shreyas
EOF
success "Added includeIf directives to ~/.gitconfig"

# Display SSH public keys
echo ""
info "SSH public keys created. Add these to GitHub:"
echo ""
echo -e "${GREEN}=== Default SSH Key (for work) ===${NC}"
cat ~/.ssh/id_ed25519.pub
echo ""
echo -e "${GREEN}=== Shreyas SSH Key (for personal repos) ===${NC}"
cat ~/.ssh/id_ed25519_shreyas.pub
echo ""

success "SSH keys and Git configuration setup complete"

# ==============================================================================
# Step 2: Install required tools (git, curl, stow)
# ==============================================================================
log "Step 2: Installing required tools..."

if [ "$OS" = "linux" ]; then
    # Update package lists
    log "Updating package lists..."
    sudo apt-get update -qq
    
    # Install git, curl, stow if not present
    for tool in git curl stow; do
        if ! command -v "$tool" &> /dev/null; then
            log "Installing $tool..."
            sudo apt-get install -y -qq "$tool"
            success "$tool installed"
        else
            success "$tool already installed"
        fi
    done
    
    # Install build-essential for compilation
    if ! dpkg -l | grep -q build-essential; then
        log "Installing build-essential..."
        sudo apt-get install -y -qq build-essential
        success "build-essential installed"
    fi
elif [ "$OS" = "macos" ]; then
    # On macOS, check for Xcode Command Line Tools
    if ! command -v git &> /dev/null; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install
        warning "Please complete the Xcode Command Line Tools installation and run this script again"
        exit 1
    fi
    
    # Check for stow
    if ! command -v stow &> /dev/null; then
        warning "GNU Stow not found. Will install via Homebrew in next step"
    fi
else
    error "Unsupported OS: $OS"
    exit 1
fi

success "Required tools installed"

# ==============================================================================
# Step 3: Install Homebrew or Linuxbrew
# ==============================================================================
log "Step 3: Installing Homebrew/Linuxbrew..."

if ! command -v brew &> /dev/null; then
    log "Homebrew not found. Installing..."
    
    # Disable prompts during installation
    export NONINTERACTIVE=1
    
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    success "Homebrew installed"
    
    # Determine Homebrew path based on OS
    if [ "$OS" = "linux" ]; then
        if [ "$WSL" = "true" ] || [ -d "/home/linuxbrew/.linuxbrew" ]; then
            BREW_PATH="/home/linuxbrew/.linuxbrew/bin"
        else
            BREW_PATH="$HOME/.linuxbrew/bin"
        fi
    elif [ "$OS" = "macos" ]; then
        # Check for Apple Silicon vs Intel
        if [ -d "/opt/homebrew" ]; then
            BREW_PATH="/opt/homebrew/bin"
        else
            BREW_PATH="/usr/local/bin"
        fi
    fi
    
    # Add brew to PATH for current session
    export PATH="$BREW_PATH:$PATH"
    
    # Initialize brew environment
    eval "$(${BREW_PATH}/brew shellenv)"
    
    success "Homebrew added to PATH"
else
    success "Homebrew already installed"
    
    # Ensure brew is in PATH
    if ! command -v brew &> /dev/null; then
        # Try to find and initialize brew
        for brew_location in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew ~/.linuxbrew/bin/brew; do
            if [ -f "$brew_location" ]; then
                eval "$(${brew_location} shellenv)"
                break
            fi
        done
    fi
fi

# Verify brew is working
if command -v brew &> /dev/null; then
    success "Homebrew ready: $(brew --version | head -n 1)"
else
    error "Homebrew installation failed or not in PATH"
    exit 1
fi

# Update brew
log "Updating Homebrew..."
brew update || warning "Brew update failed, continuing anyway..."

# ==============================================================================
# Step 4: Install Zsh (if not present)
# ==============================================================================
log "Step 4: Installing Zsh..."

if ! command -v zsh &> /dev/null; then
    if [ "$OS" = "linux" ]; then
        log "Installing zsh via apt..."
        sudo apt-get install -y -qq zsh
    elif [ "$OS" = "macos" ]; then
        log "Installing zsh via brew..."
        brew install zsh
    fi
    success "Zsh installed"
else
    success "Zsh already installed: $(zsh --version)"
fi

# Verify zsh is in /etc/shells
if ! grep -q "$(command -v zsh)" /etc/shells 2>/dev/null; then
    log "Adding zsh to /etc/shells..."
    echo "$(command -v zsh)" | sudo tee -a /etc/shells > /dev/null
    success "Zsh added to /etc/shells"
fi

# ==============================================================================
# Step 5: Stow Zsh configuration
# ==============================================================================
log "Step 5: Stowing Zsh configuration..."

cd "$DOTFILES_DIR"

# Check for existing .zshrc and handle it
if [ -f ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
    backup_file ~/.zshrc
fi

# Check what stow would do (dry run)
log "Checking stow conflicts..."
if stow -n -v zsh 2>&1 | grep -q "CONFLICT"; then
    warning "Stow conflicts detected. Creating backups..."
    
    # Find conflicting files and back them up
    stow -n -v zsh 2>&1 | grep "existing target" | awk '{print $NF}' | while read -r file; do
        backup_file "$file"
    done
fi

# Now perform the actual stow
log "Stowing zsh configuration..."
if stow -v zsh 2>/dev/null; then
    success "Zsh configuration stowed successfully"
elif stow -R -v zsh 2>/dev/null; then
    success "Zsh configuration restowed successfully"
else
    error "Failed to stow zsh configuration"
    error "Please check for conflicts manually"
    exit 1
fi

# Verify the symlink was created
if [ -L ~/.zshrc ]; then
    success "Verified: .zshrc is properly symlinked"
    info "Target: $(readlink ~/.zshrc)"
else
    error ".zshrc was not created as a symlink"
    exit 1
fi

# ==============================================================================
# Step 6: Install packages from Homebrew/Brewfile
# ==============================================================================
log "Step 6: Installing packages from Brewfile..."

if [ -f "$DOTFILES_DIR/homebrew/Brewfile" ]; then
    cd "$DOTFILES_DIR/homebrew"
    
    # Check current status
    log "Checking Brewfile dependencies..."
    if brew bundle check 2>/dev/null; then
        success "All Brewfile packages already installed"
    else
        log "Installing missing packages from Brewfile..."
        
        # Install with verbose output
        if brew bundle install; then
            success "Brewfile packages installed successfully"
        else
            warning "Some Brewfile packages failed to install"
            warning "You may need to install them manually"
        fi
    fi
    
    # List installed packages
    info "Installed brew packages: $(brew list --formula | wc -l) formulae"
else
    warning "Brewfile not found at $DOTFILES_DIR/homebrew/Brewfile"
    warning "Skipping Homebrew package installation"
fi

# ==============================================================================
# Step 7: Install packages from apt (Linux only)
# ==============================================================================
if [ "$OS" = "linux" ]; then
    log "Step 7: Installing packages from apt..."
    
    APT_PACKAGES_FILE="$DOTFILES_DIR/apt/.config/apt/packages.txt"
    
    if [ -f "$APT_PACKAGES_FILE" ]; then
        log "Updating package lists..."
        sudo apt-get update -qq
        
        log "Installing apt packages..."
        installed_count=0
        failed_count=0
        
        while IFS= read -r package; do
            # Skip empty lines and comments
            [[ -z "$package" || "$package" =~ ^# ]] && continue
            
            if ! dpkg -l | grep -q "^ii.*$package"; then
                if sudo apt-get install -y -qq "$package"; then
                    ((installed_count++))
                else
                    warning "Failed to install $package"
                    ((failed_count++))
                fi
            fi
        done < "$APT_PACKAGES_FILE"
        
        success "Apt packages processed: $installed_count installed, $failed_count failed"
    else
        warning "Apt packages file not found at $APT_PACKAGES_FILE"
    fi
else
    log "Step 7: Skipping apt packages (not on Linux)"
fi

# ==============================================================================
# Step 8: Make zsh the default shell
# ==============================================================================
log "Step 8: Setting Zsh as default shell..."

CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
ZSH_PATH=$(command -v zsh)

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    log "Changing default shell to zsh..."
    
    if chsh -s "$ZSH_PATH"; then
        success "Default shell changed to zsh"
        warning "You need to log out and log back in for shell change to take effect"
    else
        warning "Failed to change default shell automatically"
        warning "Please run manually: chsh -s $(command -v zsh)"
    fi
else
    success "Zsh is already the default shell"
fi

# ==============================================================================
# Step 9: Configure git remote for dotfiles repository
# ==============================================================================
log "Step 9: Configuring git remote for dotfiles repository..."

cd ~/dotfiles 2>/dev/null || cd "$DOTFILES_DIR"

# Check if we're in a git repository
if [ ! -d .git ]; then
    warning "Not a git repository. Initializing..."
    git init
    success "Git repository initialized"
fi

# Check if remote already exists
if git remote get-url origin &>/dev/null; then
    existing_url=$(git remote get-url origin)
    success "Git remote already configured: $existing_url"
    
    # Check if it's the correct URL
    if [[ ! "$existing_url" =~ "shreyas-3456/dotfiles" ]]; then
        warning "Remote URL doesn't match expected repository"
        info "Current: $existing_url"
        info "Expected: github.com/shreyas-3456/dotfiles"
        
        read -p "$(echo -e "${YELLOW}Update remote URL? [y/N]: ${NC}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git remote set-url origin git@github.com:shreyas-3456/dotfiles.git
            success "Remote URL updated to use SSH"
        fi
    fi
else
    log "Adding git remote origin..."
    
    # Use SSH URL for better authentication with SSH keys
    if git remote add origin git@github.com:shreyas-3456/dotfiles.git 2>/dev/null; then
        success "Git remote added successfully (SSH)"
    else
        warning "Failed to add SSH remote. Trying HTTPS..."
        if git remote add origin https://github.com/shreyas-3456/dotfiles.git 2>/dev/null; then
            success "Git remote added successfully (HTTPS)"
        else
            error "Failed to add git remote"
            echo ""
            warning "Please add the remote manually using one of:"
            echo ""
            echo "  SSH:   git remote add origin git@github.com:shreyas-3456/dotfiles.git"
            echo "  HTTPS: git remote add origin https://github.com/shreyas-3456/dotfiles.git"
            echo ""
        fi
    fi
fi

# Test git configuration in dotfiles directory
info "Testing git configuration in dotfiles directory..."
current_name=$(git config user.name)
current_email=$(git config user.email)
info "Current git identity: $current_name <$current_email>"

if [[ "$current_name" == "$DEFAULT_SHREYAS_NAME" ]]; then
    success "Git configuration correctly using Shreyas identity"
else
    warning "Git configuration not using Shreyas identity as expected"
fi

# ==============================================================================
# Final verification
# ==============================================================================
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║                  SETUP VERIFICATION                        ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

verify_check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[✓]${NC} $2"
        return 0
    else
        echo -e "${RED}[✗]${NC} $2"
        return 1
    fi
}

# Check SSH keys
[ -f ~/.ssh/id_ed25519 ] && verify_check 0 "Default SSH key exists" || verify_check 1 "Default SSH key missing"
[ -f ~/.ssh/id_ed25519_shreyas ] && verify_check 0 "Shreyas SSH key exists" || verify_check 1 "Shreyas SSH key missing"

# Check git configs
[ -f ~/.gitconfig ] && verify_check 0 "Global gitconfig exists" || verify_check 1 "Global gitconfig missing"
[ -f ~/.gitconfig-shreyas ] && verify_check 0 "Shreyas gitconfig exists" || verify_check 1 "Shreyas gitconfig missing"

# Check tools
command -v git &>/dev/null && verify_check 0 "Git installed" || verify_check 1 "Git not installed"
command -v stow &>/dev/null && verify_check 0 "Stow installed" || verify_check 1 "Stow not installed"
command -v brew &>/dev/null && verify_check 0 "Homebrew installed" || verify_check 1 "Homebrew not installed"
command -v zsh &>/dev/null && verify_check 0 "Zsh installed" || verify_check 1 "Zsh not installed"

# Check zsh config
[ -L ~/.zshrc ] && verify_check 0 ".zshrc symlinked to dotfiles" || verify_check 1 ".zshrc not symlinked"

# Check default shell
if [ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ]; then
    verify_check 0 "Zsh is default shell"
else
    verify_check 1 "Zsh is not default shell yet"
fi

# Check git remote
cd ~/dotfiles 2>/dev/null || cd "$DOTFILES_DIR"
if git remote get-url origin &>/dev/null; then
    remote=$(git remote get-url origin)
    verify_check 0 "Git remote configured: $remote"
else
    verify_check 1 "Git remote not configured"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║              ✓ SETUP COMPLETED SUCCESSFULLY!               ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Post-installation instructions
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║                   NEXT STEPS                               ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "1. Add SSH keys to GitHub:"
echo "   • Default key: https://github.com/settings/ssh/new"
echo "   • Shreyas key: https://github.com/settings/ssh/new"
echo ""
echo "2. Test SSH connection:"
echo "   ssh -T git@github.com"
echo ""
echo "3. Restart your terminal or run:"
echo "   exec zsh"
echo ""
echo "4. If shell didn't change, logout and login again"
echo ""
echo -e "${CYAN}Happy coding! 🚀${NC}"
echo ""

# Disable error trap
trap - ERR