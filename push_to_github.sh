#!/bin/bash

# GitHub Push Instructions
# Replace YOUR_USERNAME with your GitHub username
# Replace YOUR_REPO_NAME with your repository name

echo "Setting up GitHub remote..."

# Add your GitHub repository as origin
# REPLACE THIS URL WITH YOUR ACTUAL GITHUB REPO URL
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Verify remote was added
git remote -v

# Push to GitHub
echo "Pushing to GitHub..."
git branch -M main
git push -u origin main

echo "Done! Your code is now on GitHub!"
echo "Visit: https://github.com/YOUR_USERNAME/YOUR_REPO_NAME"