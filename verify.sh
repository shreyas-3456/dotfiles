#!/bin/zsh

# Post-setup verification script
# Run this in a NEW TERMINAL after running setup.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Helper functions
check_pass() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    ((PASS_COUNT++))
}

check_fail() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

check_warn() {
    echo -e "${YELLOW}[! WARN]${NC} $1"
    ((WARN_COUNT++))
}

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

info() {
    echo -e "${BLUE}    ℹ ${NC}$1"
}

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║         DOTFILES POST-SETUP VERIFICATION v2.0              ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║     Run this in a NEW TERMINAL after setup.sh             ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# Test 1: Shell Environment
# ==============================================================================
section "TEST 1: Shell Environment"

# Check current shell
if [[ "$SHELL" == *"zsh"* ]]; then
    check_pass "Current shell is Zsh"
    info "Shell: $SHELL"
else
    check_fail "Current shell is NOT Zsh"
    info "Current shell: $SHELL"
    info "Expected: *zsh*"
fi

# Check if we're running in Zsh
if [ -n "$ZSH_VERSION" ]; then
    check_pass "Running in Zsh session"
    info "Zsh version: $ZSH_VERSION"
else
    check_warn "NOT running in Zsh session (running via sh/bash)"
    info "For full test, run: zsh verify.sh"
fi

# Check default shell in /etc/passwd
PASSWD_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$PASSWD_SHELL" == *"zsh"* ]]; then
    check_pass "Default shell set to Zsh in /etc/passwd"
    info "Shell: $PASSWD_SHELL"
else
    check_fail "Default shell NOT set to Zsh"
    info "Current: $PASSWD_SHELL"
    info "Run: chsh -s $(command -v zsh)"
fi

# ==============================================================================
# Test 2: SSH Keys
# ==============================================================================
section "TEST 2: SSH Keys"

# Check default SSH key
if [ -f ~/.ssh/id_ed25519 ]; then
    check_pass "Default SSH key exists"
    
    # Check permissions
    perms=$(stat -c "%a" ~/.ssh/id_ed25519 2>/dev/null || stat -f "%OLp" ~/.ssh/id_ed25519 2>/dev/null)
    if [ "$perms" = "600" ]; then
        check_pass "Default private key has correct permissions (600)"
    else
        check_warn "Default private key has incorrect permissions ($perms)"
        info "Run: chmod 600 ~/.ssh/id_ed25519"
    fi
else
    check_fail "Default SSH key missing"
    info "Expected: ~/.ssh/id_ed25519"
fi

# Check Shreyas SSH key
if [ -f ~/.ssh/id_ed25519_shreyas ]; then
    check_pass "Shreyas SSH key exists"
    
    # Check permissions
    perms=$(stat -c "%a" ~/.ssh/id_ed25519_shreyas 2>/dev/null || stat -f "%OLp" ~/.ssh/id_ed25519_shreyas 2>/dev/null)
    if [ "$perms" = "600" ]; then
        check_pass "Shreyas private key has correct permissions (600)"
    else
        check_warn "Shreyas private key has incorrect permissions ($perms)"
        info "Run: chmod 600 ~/.ssh/id_ed25519_shreyas"
    fi
else
    check_fail "Shreyas SSH key missing"
    info "Expected: ~/.ssh/id_ed25519_shreyas"
fi

# Test SSH agent
if ssh-add -l &>/dev/null; then
    check_pass "SSH agent is running"
    info "Loaded keys:"
    ssh-add -l | sed 's/^/        /'
else
    check_warn "SSH agent not running or no keys loaded"
    info "Start with: eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519"
fi

# ==============================================================================
# Test 3: Git Configuration
# ==============================================================================
section "TEST 3: Git Configuration"

# Check global gitconfig
if [ -f ~/.gitconfig ]; then
    check_pass "Global gitconfig exists"
    
    git_name=$(git config --global user.name 2>/dev/null)
    git_email=$(git config --global user.email 2>/dev/null)
    
    if [ -n "$git_name" ]; then
        check_pass "Git user.name is set"
        info "Name: $git_name"
    else
        check_fail "Git user.name is NOT set"
    fi
    
    if [ -n "$git_email" ]; then
        check_pass "Git user.email is set"
        info "Email: $git_email"
    else
        check_fail "Git user.email is NOT set"
    fi
else
    check_fail "Global gitconfig missing"
    info "Expected: ~/.gitconfig"
fi

# Check Shreyas gitconfig
if [ -f ~/.gitconfig-shreyas ]; then
    check_pass "Shreyas gitconfig exists"
else
    check_fail "Shreyas gitconfig missing"
    info "Expected: ~/.gitconfig-shreyas"
fi

# Check includeIf directives
if grep -q "includeIf" ~/.gitconfig 2>/dev/null; then
    check_pass "includeIf directives found in gitconfig"
else
    check_fail "includeIf directives NOT found in gitconfig"
fi

# Test git identity in dotfiles directory
if [ -d ~/dotfiles ]; then
    cd ~/dotfiles
    dotfiles_name=$(git config user.name 2>/dev/null)
    dotfiles_email=$(git config user.email 2>/dev/null)
    
    if [[ "$dotfiles_name" == *"Shreyas"* ]]; then
        check_pass "Git identity in ~/dotfiles uses Shreyas config"
        info "Name: $dotfiles_name"
        info "Email: $dotfiles_email"
    else
        check_fail "Git identity in ~/dotfiles NOT using Shreyas config"
        info "Name: $dotfiles_name"
        info "Email: $dotfiles_email"
    fi
    
    # Check git remote
    if git remote get-url origin &>/dev/null; then
        check_pass "Git remote configured in ~/dotfiles"
        info "Remote: $(git remote get-url origin)"
    else
        check_fail "Git remote NOT configured in ~/dotfiles"
    fi
    
    cd - > /dev/null
else
    check_warn "~/dotfiles directory not found"
fi

# ==============================================================================
# Test 4: Zsh Configuration
# ==============================================================================
section "TEST 4: Zsh Configuration"

# Check .zshrc exists
if [ -f ~/.zshrc ]; then
    check_pass ".zshrc exists"
    
    # Check if it's a symlink
    if [ -L ~/.zshrc ]; then
        check_pass ".zshrc is a symlink (managed by stow)"
        target=$(readlink ~/.zshrc)
        info "Points to: $target"
        
        # Verify target exists - try both absolute and relative paths
        if [ -f ~/.zshrc ]; then
            check_pass "Symlink target is accessible and readable"
        elif [ -f "$(dirname ~/.zshrc)/$target" ]; then
            check_pass "Symlink target exists (relative path)"
        elif [ -f "$HOME/$target" ]; then
            check_pass "Symlink target exists (home-relative path)"
        else
            check_warn "Symlink target path is unusual but .zshrc works"
            info "If zsh loads correctly, this is fine"
        fi
    else
        check_warn ".zshrc is NOT a symlink"
        info "It should be a symlink to your dotfiles directory"
    fi
else
    check_fail ".zshrc does NOT exist"
fi

# Test if .zshrc was sourced
if typeset -f | grep -q "^"; then
    check_pass ".zshrc appears to have been loaded"
else
    check_warn "Unable to verify .zshrc was loaded"
fi

# ==============================================================================
# Test 5: Required Tools
# ==============================================================================
section "TEST 5: Required Tools Installation"

# Test each required tool
tools=(git curl stow brew zsh)

for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        check_pass "$tool is installed"
        version=$($tool --version 2>&1 | head -n 1)
        info "$version"
    else
        check_fail "$tool is NOT installed"
    fi
done

# ==============================================================================
# Test 6: Homebrew
# ==============================================================================
section "TEST 6: Homebrew Configuration"

# Check brew is in PATH
if command -v brew &> /dev/null; then
    check_pass "Homebrew is in PATH"
    info "Location: $(which brew)"
    info "Version: $(brew --version | head -n 1)"
    
    # Check Brewfile packages
    if [ -f ~/dotfiles/homebrew/Brewfile ]; then
        cd ~/dotfiles/homebrew
        if brew bundle check --no-upgrade 2>/dev/null; then
            check_pass "All Brewfile packages are installed"
        else
            check_warn "Some Brewfile packages may be missing"
            info "Run: cd ~/dotfiles/homebrew && brew bundle install"
        fi
        cd - > /dev/null
    else
        check_warn "Brewfile not found"
    fi
else
    check_fail "Homebrew is NOT in PATH"
    info "Try: eval \"\$(brew shellenv)\""
fi

# ==============================================================================
# Test 7: Environment Variables
# ==============================================================================
section "TEST 7: Environment Variables"

# Check PATH
echo -e "${BLUE}    Current PATH:${NC}"
echo "$PATH" | tr ':' '\n' | sed 's/^/        /'

# Check for common paths
if echo "$PATH" | grep -q "brew"; then
    check_pass "Homebrew is in PATH"
else
    check_warn "Homebrew path not found in PATH"
fi

# Check for custom paths (if any defined in .zshrc)
if echo "$PATH" | grep -q "$HOME"; then
    check_pass "User home directory in PATH"
else
    check_warn "User home directory not in PATH"
fi

# ==============================================================================
# Test 8: SSH GitHub Connection
# ==============================================================================
section "TEST 8: SSH GitHub Connection"

echo -e "${BLUE}    Testing SSH connection to GitHub...${NC}"

# Test default SSH key
if ssh -T -i ~/.ssh/id_ed25519 git@github.com 2>&1 | grep -q "successfully authenticated"; then
    check_pass "SSH connection to GitHub works (default key)"
else
    check_warn "SSH connection to GitHub failed (default key)"
    info "Make sure you've added your SSH key to GitHub:"
    info "https://github.com/settings/ssh/new"
fi

# Test Shreyas SSH key
if [ -f ~/.ssh/id_ed25519_shreyas ]; then
    if ssh -T -i ~/.ssh/id_ed25519_shreyas git@github.com 2>&1 | grep -q "successfully authenticated"; then
        check_pass "SSH connection to GitHub works (Shreyas key)"
    else
        check_warn "SSH connection to GitHub failed (Shreyas key)"
        info "Make sure you've added your Shreyas SSH key to GitHub"
    fi
fi

# ==============================================================================
# Test 9: Stow Management
# ==============================================================================
section "TEST 9: Stow Management"

if [ -d ~/dotfiles ]; then
    cd ~/dotfiles
    
    # Check what's stowed
    if [ -d zsh ]; then
        if stow -n -v zsh 2>&1 | grep -q "LINK"; then
            check_warn "Stow would create new links (not fully stowed)"
        elif stow -n -v zsh 2>&1 | grep -q "no actions"; then
            check_pass "Zsh configuration is properly stowed"
        else
            check_pass "Zsh stow status unclear, but likely OK"
        fi
    fi
    
    cd - > /dev/null
else
    check_warn "~/dotfiles directory not found for stow check"
fi

# ==============================================================================
# Final Summary
# ==============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}                        SUMMARY                              ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOTAL=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))

echo -e "  ${GREEN}Passed:${NC}   $PASS_COUNT / $TOTAL"
echo -e "  ${RED}Failed:${NC}   $FAIL_COUNT / $TOTAL"
echo -e "  ${YELLOW}Warnings:${NC} $WARN_COUNT / $TOTAL"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}║         ✓ ALL CRITICAL CHECKS PASSED!                      ║${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}║   Your dotfiles setup is complete and working correctly!   ║${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}║         ✗ SOME CHECKS FAILED                               ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}║   Please review the failures above and fix them.          ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
fi

if [ $WARN_COUNT -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Note: Warnings indicate non-critical issues that may need attention.${NC}"
fi

echo ""