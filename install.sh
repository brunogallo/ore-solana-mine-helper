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

    read -p "Please enter the RPC address: " common_rpc

    ore_count=$(ls -l /root/ore*.sh | wc -l)
    mkdir ore
    chmod 755 ore
    cp /root/ore*.sh /root/ore/
    chmod 755 /root/ore/ore*.sh

    for ((i=1; i<=$ore_count; i++)); do
        claim_file="/root/ore/claim$i.sh"
        echo "#!/bin/bash" > "$claim_file"
        echo "ore --rpc $common_rpc --keypair ~/.config/solana/id$i.json --priority-fee 20000000 claim" >> "$claim_file"
        chmod 755 "$claim_file"
    done

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
