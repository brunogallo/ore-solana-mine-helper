#!/bin/bash

default_directory="/root/ore"
solana_config_path="/root/.config/solana/"
RED='\033[0;31m'
NC='\033[0m'

install(){
    echo -e "${RED}
    #########################################################
    #                                                       #
    #               Starting install packages               #
    #                                                       #
    #########################################################
    ${NC}"
    
    wget https://raw.githubusercontent.com/brunogallo/ore-solana-mine-helper/main/menu.sh && chmod +x menu.sh
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y npm
    npm install pm2 -g
    cargo install ore-cli

    echo -e "${RED}
    #########################################################
    #                                                       #
    #                          Done!                        #
    #                                                       #
    #########################################################
    ${NC}"

    select_random_rpc() {
        IFS=',' read -ra rpc_addresses <<< "$1"
        echo "${rpc_addresses[RANDOM % ${#rpc_addresses[@]}]}"
    }

    read -p "Please enter the list of RPC address separated by , : " common_rpcs

    wallet_count=$(ls -l ~/.config/solana/id*.json | wc -l)
    mkdir ore
    chmod 755 ore

    for ((i=1; i<=$wallet_count; i++)); do
        ore_file="/root/ore/ore$i.sh"
        echo "#!/bin/bash" > "$ore_file"
        rpc=$(select_random_rpc "$common_rpcs")
        echo "ore --rpc "$rpc" --keypair ~/.config/solana/id$i.json --priority-fee 100000 mine --threads 8" >> "$ore_file"
        chmod 755 "$ore_file"
    done

    read -p "Please only one RPC address: " common_rpc

    cx_script="#!/bin/bash
    keypairs=(\"$solana_config_path\"*.json)

    for config in \${keypairs[@]}
    do
        ore --rpc $common_rpc --keypair \"\$config\" rewards
    done"

    echo "$cx_script" > /root/ore/cx.sh

    chmod 755 /root/ore/cx.sh

    echo "cx.sh created with success at /root/ore/cx.sh."

    echo -e "${RED}
    #########################################################
    #                                                       #
    #                 Installation completed.               #
    #                     run ./menu.sh                     #
    #                                                       #
    #########################################################
    ${NC}"
}

install
