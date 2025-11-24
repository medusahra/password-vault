# 🔐 Password Vault

Encrypted password manager built in Ruby with AES-256 encryption.

## Features

- ✅ Military-grade AES-256-CBC encryption
- ✅ Master password protection
- ✅ Generate strong passwords
- ✅ Copy to clipboard (macOS)
- ✅ Export/backup functionality
- ✅ Zero dependencies on cloud services

## Installation
```bash
# Install Ruby
sudo apt install ruby-full  # Linux
brew install ruby            # macOS

# Install dependencies
gem install colorize

# Clone and run
git clone https://github.com/medusahra/password-vault.git
cd password-vault
ruby vault.rb
```

## Usage
```bash
ruby vault.rb
```

First time: create a master password
Next times: unlock with your master password

### Commands
- **[1]** Add password
- **[2]** Get password
- **[3]** List all entries
- **[4]** Generate strong password
- **[5]** Delete password
- **[6]** Export vault
- **[0]** Exit

## Security

- Uses AES-256-CBC encryption
- PBKDF2 key derivation (100,000 iterations)
- Random salt and IV for each encryption
- Vault stored at `~/.password_vault.enc`

## ⚠️ Important

- **DO NOT** lose your master password (no recovery possible)
- **BACKUP** your vault file regularly
- Keep your master password **strong and unique**

## Created by

**medusahra** · [GitHub](https://github.com/medusahra) · [Web](https://medusahra.github.io)

Inspired by Mr. Robot aesthetics with real-world security.

## License

MIT
