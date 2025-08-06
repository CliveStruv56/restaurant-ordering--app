#!/bin/bash

# Install GitHub CLI (if you want to use it)
echo "To install GitHub CLI on macOS:"
echo ""
echo "Option 1: Using Homebrew"
echo "  brew install gh"
echo ""
echo "Option 2: Download from GitHub"
echo "  Visit: https://cli.github.com/"
echo ""
echo "After installation:"
echo "1. Run: gh auth login"
echo "2. Follow the prompts to authenticate"
echo "3. Run: gh repo create restaurant-ordering-app --public --source=. --remote=origin --push"