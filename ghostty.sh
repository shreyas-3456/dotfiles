#!/usr/bin/env zsh
set -e

# ---------------------------
# Only run in Zsh
# ---------------------------
if [[ -z "$ZSH_VERSION" ]]; then
  echo "❌ This script only runs in Zsh. Exiting."
  exit 1
fi

# ---------------------------
# Variables
# ---------------------------
BIN_DIR="$HOME/bin"
APP_DIR="$HOME/.local/share/applications"
APPIMAGE_NAME="Ghostty-1.2.3-x86_64.AppImage"
APPIMAGE_URL="https://github.com/pkgforge-dev/ghostty-appimage/releases/download/v1.2.3/$APPIMAGE_NAME"

echo "▶ Installing Ghostty (AppImage)"

# ---------------------------
# Install required libraries for Ghostty (Ubuntu 24.04 WSL)
# ---------------------------
echo "⬇ Installing required packages (OpenGL, GTK4, fonts, X11)..."
sudo apt update
sudo apt install -y wget libegl-mesa0 libglx-mesa0 libgl1-mesa-dri mesa-utils \
libgtk-4-1 libadwaita-1-0 libfreetype6 libfontconfig1 libharfbuzz0b \
libx11-6 libxrandr2 libxcursor1 libxinerama1 libxext6

# ---------------------------
# Create ~/bin if missing
# ---------------------------
mkdir -p "$BIN_DIR"
cd "$BIN_DIR"

# ---------------------------
# Download Ghostty AppImage if missing
# ---------------------------
if [[ ! -f "$APPIMAGE_NAME" ]]; then
  echo "⬇ Downloading Ghostty AppImage..."
  wget --show-progress "$APPIMAGE_URL"
else
  echo "✔ Ghostty AppImage already exists"
fi

# ---------------------------
# Make executable
# ---------------------------
chmod +x "$APPIMAGE_NAME"

# ---------------------------
# Create ghostty command
# ---------------------------
ln -sf "$BIN_DIR/$APPIMAGE_NAME" "$BIN_DIR/ghostty"

# ---------------------------
# Ensure ~/bin is in PATH
# ---------------------------
add_path_if_missing() {
  local rc_file="$1"
  if [[ -f "$rc_file" ]] && ! grep -q 'export PATH="$HOME/bin:$PATH"' "$rc_file"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$rc_file"
    echo "➕ Added ~/bin to $(basename "$rc_file")"
  fi
}

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  add_path_if_missing "$HOME/.zshrc"
  add_path_if_missing "$HOME/.bashrc"
else
  echo "✔ ~/bin already in PATH"
fi

# ---------------------------
# WSL-only desktop entry
# ---------------------------
if grep -qi microsoft /proc/version; then
  echo "🪟 WSL detected — creating desktop entry"
  mkdir -p "$APP_DIR"
  cat > "$APP_DIR/ghostty.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Ghostty
Exec=$HOME/bin/ghostty
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF
  echo "✔ Desktop entry created (WSL only)"
else
  echo "🐧 Non-WSL environment — skipping desktop entry"
fi

echo ""
echo "✔ Ghostty installation complete"
echo "▶ Restart your shell or run: source ~/.zshrc"
echo "▶ Launch with: ghostty"
