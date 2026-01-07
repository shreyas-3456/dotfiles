# Created by newuser for 5.9
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
alias explorer='explorer.exe $(wslpath -w $(pwd))'
export PATH=/snap/bin:$PATH
autoload -Uz compinit
compinit
# Load vcs_info
autoload -Uz vcs_info

# Enable git support (and others if needed)
zstyle ':vcs_info:*' enable git

# Must enable change checking for %c and %u to work
zstyle ':vcs_info:*' check-for-changes true

# Symbols for repo state
zstyle ':vcs_info:git:*' stagedstr '%F{green}+%f'     # Green + for staged changes
zstyle ':vcs_info:git:*' unstagedstr '%F{red}*%f'     # Red * for unstaged changes

# Format: branch in cyan, with staged/unstaged indicators after it
zstyle ':vcs_info:git:*' formats '(%F{cyan}%b%f%u%c)'
zstyle ':vcs_info:git:*' actionformats '(%F{red}%b|%a%f%u%c)'  # For merges/rebases etc.

# Update vcs_info before each prompt
precmd() { vcs_info }

# Enable prompt substitution (required for ${vcs_info_msg_0_} to work)
setopt prompt_subst

# Your prompt with username added
# %n = username, %m = hostname (optional), %~ = current directory
PROMPT='%F{blue}%n%f@%F{magenta}%m%f %F{green}%~%f ${vcs_info_msg_0_} %F{yellow}%#%f '

export PATH="/usr/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"


alias idea='"/mnt/c/Program Files/JetBrains/IntelliJ IDEA Community Edition 2025.2.6/bin/idea64.exe"'

export NVM_DIR="$HOME/.nvm"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
  source "$(brew --prefix nvm)/nvm.sh"
fi
# Bash-only completion (skip in zsh, but keeping in case you run bash)
if [ -n "$BASH_VERSION" ] && [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ]; then
  source "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
fi


HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY          # append to the history file, don't overwrite it
setopt INC_APPEND_HISTORY      # add commands to history immediately
setopt SHARE_HISTORY           # share history across all sessions
setopt HIST_IGNORE_DUPS        # don't store duplicate commands
setopt HIST_IGNORE_SPACE       # don't store commands that start with space
alias pbcopy="clip.exe"
alias pbpaste="powershell.exe -command Get-Clipboard"
alias c='pbcopy'
alias cat='bat'
alias restart='source ~/.zshrc'
alias open='xdg-open'

# ---- Assemble RPROMPT ----
RPROMPT='%F{cyan}%D{%H:%M}%f'

for file in ~/.config/*.sh; do
  [[ -r "$file" ]] && source "$file"
done

export JAVA_HOME="$(brew --prefix openjdk@17)"
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="$HOME/bin:$PATH"
