#!/bin/bash

# Scarica ed esegui lo script di installazione di nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash

# Aggiungi nvm al profilo della shell
echo "Configuring shell profile for nvm..."
if [ -n "$ZSH_VERSION" ]; then
    PROFILE_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    PROFILE_FILE="$HOME/.bash_profile"
else
    PROFILE_FILE="$HOME/.profile"
fi

echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"' >> $PROFILE_FILE
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> $PROFILE_FILE

# Ricarica il profilo della shell
echo "Reloading shell profile..."
source $PROFILE_FILE

# Verifica l'installazione di nvm
if command -v nvm &> /dev/null; then
    echo "nvm installed successfully."
else
    echo "Failed to install nvm."
    exit 1
fi

# Installa Node.js versione 18
echo "Installing Node.js version 18..."
nvm install 18
nvm use 18

# Verifica l'installazione di Node.js
if node -v | grep -q 'v18'; then
    echo "Node.js v18 installed successfully."
else
    echo "Failed to install Node.js v18."
    exit 1
fi

echo "nvm and Node.js setup complete."
