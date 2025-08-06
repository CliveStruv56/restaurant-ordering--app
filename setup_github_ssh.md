# Setting Up SSH for GitHub

## Check if you have SSH keys
```bash
ls -la ~/.ssh
```

## Generate new SSH key (if needed)
```bash
ssh-keygen -t ed25519 -C "clive@platform91.com"
# Press Enter for default location
# Enter a passphrase (optional)
```

## Start SSH agent
```bash
eval "$(ssh-agent -s)"
```

## Add SSH key to agent
```bash
ssh-add ~/.ssh/id_ed25519
```

## Copy SSH public key
```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

## Add to GitHub
1. Go to GitHub.com → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste the key (it's already copied)
4. Give it a title like "MacBook"
5. Click "Add SSH key"

## Test connection
```bash
ssh -T git@github.com
```

## Switch back to SSH URL (if you want)
```bash
git remote set-url origin git@github.com:CliveStruv56/restaurant-ordering--app.git
```

## Push
```bash
git push -u origin main
```