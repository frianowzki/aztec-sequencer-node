#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "-----------------------------------------------------"
echo "   Aztec Sequencer Node"
echo "-----------------------------------------------------"
echo ""

# ====================================================
# Aztec alpha-testnet full node automated installation & startup script
# Version: v0.85.0-alpha-testnet.8
# For Ubuntu/Debian only, requires sudo privileges
# ====================================================

if [ "$(id -u)" -ne 0 ]; then
  echo "⚠️ This script must be run with root (or sudo) privileges."
  exit 1
fi

if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
  echo "🐋 Docker or Docker Compose not found. Installing..."
  apt-get update
  apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "🐋 Docker and Docker Compose are already installed."
fi

if ! command -v node &> /dev/null; then
  echo "🟢 Node.js not found. Installing the latest version..."
  curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
  apt-get install -y nodejs
else
  echo "🟢 Node.js is already installed."
fi

echo "⚙️ Installing Aztec CLI and preparing alpha-testnet..."
curl -sL https://install.aztec.network | bash

export PATH="$HOME/.aztec/bin:$PATH"

if ! command -v aztec-up &> /dev/null; then
  echo "❌ Aztec CLI installation failed."
  exit 1
fi

aztec-up alpha-testnet

echo -e "\n📋 Instructions for obtaining RPC URLs:"
echo "  - L1 Execution Client (EL) RPC URL:"
echo "    1. Sign up or log in at https://dashboard.alchemy.com/"
echo "    2. Create a new app for the Sepolia testnet"
echo "    3. Copy the HTTPS URL (e.g., https://eth-sepolia.g.alchemy.com/v2/<your-key>)"
echo ""
echo "  - L1 Consensus (CL) RPC URL:"
echo "    1. Sign up or log in at https://drpc.org/"
echo "    2. Create an API key for the Sepolia testnet"
echo "    3. Copy the HTTPS URL (e.g., https://lb.drpc.org/ogrpc?network=sepolia&dkey=<your-key>)"
echo ""

read -p "▶️ L1 Execution Client (EL) RPC URL: " ETH_RPC
read -p "▶️ L1 Consensus (CL) RPC URL: " CONS_RPC
read -p "▶️ Blob Sink URL (press Enter if none): " BLOB_URL
read -p "▶️ Validator Private Key: " VALIDATOR_PRIVATE_KEY

echo "🌐 Fetching public IP..."
PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
echo "    → $PUBLIC_IP"

cat > .env <<EOF
ETHEREUM_HOSTS="$ETH_RPC"
L1_CONSENSUS_HOST_URLS="$CONS_RPC"
P2P_IP="$PUBLIC_IP"
VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
DATA_DIRECTORY="/data"
LOG_LEVEL="debug"
EOF

if [ -n "$BLOB_URL" ]; then
  echo "BLOB_SINK_URL=\"$BLOB_URL\"" >> .env
fi

BLOB_FLAG=""
if [ -n "$BLOB_URL" ]; then
  BLOB_FLAG="--sequencer.blobSinkUrl \$BLOB_SINK_URL"
fi

cat > docker-compose.yml <<EOF
version: "3.8"
services:
  node:
    image: aztecprotocol/aztec:0.85.0-alpha-testnet.8
    network_mode: host
    environment:
      - ETHEREUM_HOSTS=\${ETHEREUM_HOSTS}
      - L1_CONSENSUS_HOST_URLS=\${L1_CONSENSUS_HOST_URLS}
      - P2P_IP=\${P2P_IP}
      - VALIDATOR_PRIVATE_KEY=\${VALIDATOR_PRIVATE_KEY}
      - DATA_DIRECTORY=\${DATA_DIRECTORY}
      - LOG_LEVEL=\${LOG_LEVEL}
      - BLOB_SINK_URL=\${BLOB_SINK_URL:-}
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer $BLOB_FLAG'
    volumes:
      - $(pwd)/data:/data
EOF

mkdir -p data

echo "🚀 Starting Aztec full node (docker-compose up -d)..."
docker-compose up -d

echo -e "\n✅ Installation and startup completed!"
echo "   - Check logs: docker-compose logs -f"
echo "   - Data directory: $(pwd)/data"
