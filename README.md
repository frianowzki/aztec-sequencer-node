# How to Run Aztec Sequencer Node 
#
![aztec-logo](https://github.com/user-attachments/assets/b0b56462-dbcf-4afc-8ff9-c9dc000b71f2)
#
### Latest image - aztecprotocol:aztec/alpha-testnet-8
#
## Hardware requirements to run Sequencer:
- Machine: 8-Core CPU; 16 GiB RAM; 1 TB NVMe SSD
- Network: 25 Mbps up/down bandwidth
#
## - Install Dependencies:
```
sudo apt-get update && sudo apt-get upgrade -y
  ```
```
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen  -y
```
```
source <(wget -O - https://raw.githubusercontent.com/frianowzki/installer/main/docker.sh)
```
```
sudo groupadd docker && sudo usermod -aG docker $(whoami) && newgrp docker
```
## - Install Aztec:
```
bash -i <(curl -s https://install.aztec.network)
```
```
echo 'export PATH=$PATH:/root/.aztec/bin' >> ~/.bashrc
```
```
source ~/.bashrc
```
~ Now check if Aztec successfully installed
```
aztec
```
~ Then update Aztec to Alpha Testnet
```
aztec-up alpha-testnet
```
## - Activate Firewall & Open Port:
```
# Firewall
ufw allow 22
ufw allow ssh
ufw enable

# Sequencer
ufw allow 40400
ufw allow 8080
```
## - Install Sequencer Node:
```
aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls RPC_URL  \
  --l1-consensus-host-urls CONSENSUS_HOST_URL \
  --sequencer.validatorPrivateKey 0xPrivateKey \
  --sequencer.coinbase 0xPublicAddress \
  --p2p.p2pIp IP \
  --p2p.maxTxPoolSize 1000000000
```
~ Change `RPC_URL` with RPC from [Alchemy](https://dashboard.alchemy.com/) or [Ankr](https://www.ankr.com/rpc/). (Choose Ethereum Sepolia Network)

~ Change `CONSENSUS_HOST_URL` with Beacon RPC from [dRPC](https://drpc.org/) or [Ankr](https://www.ankr.com/rpc/). (Make Sure You Check Beacon Option)

~ Change `0xPrivateKey` with your wallet private key with 0x included. (Make sure to have ETH Sepolia balance > 1 ETH)

~ Change `0xPublicAddress` with your public EVM address.

~ Change `IP` with your VPS IP address.

#### Hit enter and wait until it fully synced. 
#
Open New Terminal and check:
```
docker ps -a
```
If you see Aztec Image there you can close the previous terminal. 
#
## - Getting Apprentice Role:

Head to [Aztec Discord](https://discord.gg/aztec) and go to `operator | start-here` channel

Run command `/operator help` there
#
 
Run this command:
```
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
http://localhost:8080 | jq -r ".result.proven.number"
```
  ~ Change `http://localhost:8080` with your VPS IP:8080 

You will get a BLOCK_NUMBER like `21000` for example, save it. 
#

Now run this:
```
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["BLOCK_NUMBER","BLOCK_NUMBER"],"id":67}' \
http://localhost:8080 | jq -r ".result"
```

  ~ Change 2X `BLOCK_NUMBER` with the BLOCK_NUMBER you get recently. 

Copy the PROOF and save it. 
#
Now head back to `operator | start-here` and run `/operator start` command.

~ Change `address` with your Sequencer Node EVM address.

~ Change `block-number` with BLOCK_NUMBER you got above.

~ Change `proof` with PROOF you got above.

### Congratulations, now you have Apprentice role!

#
#
## - Register Validator: 
```
aztec add-l1-validator \
  --l1-rpc-urls RPC_URL \
  --private-key private-key \
  --attester validator-address \
  --proposer-eoa validator-address \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111
```
~ Change `RPC_URL` with RPC from [Alchemy](https://dashboard.alchemy.com/) or [Ankr](https://www.ankr.com/rpc/) we submit earlier. 

~ Change `PrivateKey` with your wallet private key.

~ Change 2X `validator-address` with your public EVM address.
#
### Hit enter and wait for it. 

If it successfully registered you can check it from `operator | start-here` and use the command `/operator my-stats` and enter your validator address. 
##### NOTE: Currently there is a daily registration quota each day, if you missed it now you can try tomorrow.

#
#
#
## - Errors:
#
#### If you see an errors like:
`proof too old`
### or 
`world-state:block_stream Error processing block stream: Error: Obtained L1 to L2 messages failed to be hashed to the block inHash`

#### 1 - Make sure to have a working Beacon RPC

You can add one from [Chainstack](https://console.chainstack.com)

Sign up/login > create a project > select Ethereum - Sepolia > deploy node > choose global deploment region > look for the URL and paste on `CONSENSUS_HOST_URL`

#### 2 - Run this and follow the steps from the start:

```
docker ps -a
```
```
docker stop [aztec-container-ID]
```
```
rm -r /root/.aztec/alpha-testnet
```
#

## - Update Sequencer Node:

```
docker ps -a
```
```
docker stop [aztec-container-id]
```
```
rm -rf .aztec/alpha-testnet/data
```
```
aztec-up alpha-testnet
```
```
aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls RPC_URL  \
  --l1-consensus-host-urls CONSENSUS_HOST_URL \
  --sequencer.validatorPrivateKey 0xPrivateKey \
  --sequencer.coinbase 0xPublicAddress \
  --p2p.p2pIp IP
```
After that wait until it fully synced and you can close the terminal.
#
#
## - Check Your Peer ID:

```
sudo docker logs $(docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1) 2>&1 | grep -i "peerId" | grep -o '"peerId":"[^"]*"' | cut -d'"' -f4 | head -n 1
```
If it gives you error you can replace `aztecprotocol/aztec:latest` with your Aztec docker image from 
```
docker ps -a
```
Then open [Node Explorers](https://aztec.nethermind.io/) and search your ID.
