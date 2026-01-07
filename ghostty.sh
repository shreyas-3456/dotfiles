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
APPIMAGE_NAME="Ghostty-1.2.0-x86_64.AppImage"
APPIMAGE_URL="https://git.lerch.org/api/packages/lobo/generic/ghostty-appimage/1.2.0/$APPIMAGE_NAME"
APP_DIR="$HOME/.local/share/applications"
INSTALL_DIR="/usr/local/bin"
echo "▶ Installing Ghostty (AppImage)"
# ---------------------------
# Download Ghostty AppImage
# ---------------------------
if [[ ! -f "$APPIMAGE_NAME" ]]; then
  echo "⬇ Downloading Ghostty AppImage..."
  curl -LO "$APPIMAGE_URL"
else
  echo "✔ Ghostty AppImage already exists"
fi
# ---------------------------
# Make executable and test
# ---------------------------
echo "🔧 Making AppImage executable..."
chmod +x "$APPIMAGE_NAME"
echo "🧪 Testing Ghostty AppImage..."
./"$APPIMAGE_NAME" --version || echo "⚠ Version check failed, continuing anyway..."
# ---------------------------
# Move to /usr/local/bin
# ---------------------------
echo "📦 Installing to $INSTALL_DIR..."
sudo mv "$APPIMAGE_NAME" "$INSTALL_DIR/ghostty"
sudo chmod +x "$INSTALL_DIR/ghostty"
# ---------------------------
# Verify installation
# ---------------------------
echo "✔ Ghostty installed at: $(which ghostty)"
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
Exec=/usr/local/bin/ghostty
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
echo "▶ Launch with: ghostty"
