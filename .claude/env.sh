#!/bin/bash
# Environment setup for keyboard-playground
# Source this file to add Flutter to your PATH: source .claude/env.sh

# Add Flutter to PATH
if [ -d "/opt/flutter/bin" ]; then
    export PATH="/opt/flutter/bin:$PATH"
elif [ -d "$HOME/flutter/bin" ]; then
    export PATH="$HOME/flutter/bin:$PATH"
fi

# Verify Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter not found in PATH"
    echo "Run: ./.claude/setup.sh"
    return 1
fi
