#!/bin/bash
set -e

echo "🚀 Setting up Flutter development environment..."

# Check if we have sudo access
HAS_SUDO=false
if sudo -n true 2>/dev/null; then
    HAS_SUDO=true
fi

# Check if Flutter is already installed
if command -v flutter &> /dev/null; then
    echo "✓ Flutter is already installed"
    flutter --version
else
    echo "📦 Installing Flutter SDK..."

    # Install Flutter dependencies if we have sudo
    if [ "$HAS_SUDO" = true ]; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq curl git unzip xz-utils zip libglu1-mesa > /dev/null 2>&1
    else
        echo "  (Skipping apt dependencies - no sudo access)"
    fi

    # Download and install Flutter
    FLUTTER_VERSION="3.24.5"
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

    cd /tmp
    echo "  Downloading Flutter ${FLUTTER_VERSION}..."
    curl -sL "${FLUTTER_URL}" -o flutter.tar.xz

    echo "  Extracting Flutter..."
    tar xf flutter.tar.xz > /dev/null 2>&1

    # Try to move to /opt with sudo, fall back to home directory
    if [ "$HAS_SUDO" = true ]; then
        sudo mv flutter /opt/flutter 2>/dev/null && FLUTTER_DIR="/opt/flutter" || {
            mv flutter ~/flutter
            FLUTTER_DIR="$HOME/flutter"
        }
    else
        mv flutter ~/flutter
        FLUTTER_DIR="$HOME/flutter"
    fi

    # Add to PATH for current session
    export PATH="${FLUTTER_DIR}/bin:$PATH"

    # Add to bashrc if not already there
    if ! grep -q "flutter/bin" ~/.bashrc 2>/dev/null; then
        echo "export PATH=\"${FLUTTER_DIR}/bin:\$PATH\"" >> ~/.bashrc
    fi

    # Fix git ownership issue
    git config --global --add safe.directory "${FLUTTER_DIR}"

    # Clean up
    rm flutter.tar.xz

    echo "✓ Flutter installed successfully"
fi

# Ensure Flutter is in PATH for this session
if [ -d "/opt/flutter/bin" ]; then
    export PATH="/opt/flutter/bin:$PATH"
    # Fix git ownership issue if not already done
    git config --global --add safe.directory "/opt/flutter" 2>/dev/null || true
elif [ -d "$HOME/flutter/bin" ]; then
    export PATH="$HOME/flutter/bin:$PATH"
    # Fix git ownership issue if not already done
    git config --global --add safe.directory "$HOME/flutter" 2>/dev/null || true
fi

# Install Linux build dependencies
if [ "$HAS_SUDO" = true ]; then
    echo "📦 Installing Linux build dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
        libstdc++-12-dev \
        lcov \
        > /dev/null 2>&1
    echo "✓ Linux build dependencies installed"
else
    echo "⚠️  Skipping Linux build dependencies (no sudo access)"
    echo "   If you need to build the app, ensure these are installed:"
    echo "   - clang, cmake, ninja-build, pkg-config"
    echo "   - libgtk-3-dev, liblzma-dev, libstdc++-12-dev, lcov"
fi

# Configure Flutter
echo "🔧 Configuring Flutter..."
flutter config --no-analytics > /dev/null 2>&1
flutter config --enable-linux-desktop > /dev/null 2>&1

# Run flutter doctor to download additional tools
echo "🏥 Running Flutter doctor..."
flutter doctor

# Get Flutter dependencies
echo "📚 Getting Flutter dependencies..."
cd /home/user/keyboard-playground
flutter pub get

# Install git hooks
echo "🪝 Installing git hooks..."
if [ -f ".claude/hooks/pre-push.template" ]; then
    cp .claude/hooks/pre-push.template .git/hooks/pre-push
    chmod +x .git/hooks/pre-push
    echo "✓ Pre-push hook installed (enforces 'make ci' before pushing)"
else
    echo "⚠️  Pre-push hook template not found"
fi

echo ""
echo "✅ Setup complete! You can now:"
echo "   • Run tests: make test"
echo "   • Run linter: make analyze"
echo "   • Format code: make format"
echo "   • Build Linux app: make build-linux"
echo "   • Run all CI checks: make ci"
echo ""
echo "⚠️  IMPORTANT: Pre-push hook installed!"
echo "   All git pushes will run 'make ci' automatically"
echo "   Pushes are blocked if format, analyze, or tests fail"
echo ""
