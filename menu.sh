#!/bin/bash

default_directory="/root/ore"
solana_config_path="/root/.config/solana/"
RED='\033[0;31m'
NC='\033[0m'

# Modify the Gas fee function
modify_gas() {
    read -p "Please enter a new Gas fee value: " new_gas_fee
    echo "Changing the Gas fee value for all scripts under $default_directory to $new_gas_fee ..."

    # Iterate through all .sh files in the directory
    for file in "$default_directory"/*.sh; do
        # Check if the file exists and is read/write
        if [ -f "$file" ] && [ -w "$file" ]; then
            # Change the value of the gas fee
            sed -i "s|--priority-fee [0-9]* mine|--priority-fee $new_gas_fee mine|" "$file"
            echo "Successfully modified $file's gas fee to $new_gas_fee"
        else
            echo "Unable to modify $file, file does not exist or cannot be accessed."
        fi
    done
}

# Start mining function
start_mining() {
    echo "Starting mining..."
    pm2 start -f /root/ore/ore*.sh
}

# Stop the mining function
stop_mining() {
    echo "Stopping mining..."
    pm2 stop -f /root/ore/ore*.sh
}

# query_amount function
query_amount() {
    echo "Querying quantity..."

    common_rpc="https://solana-rpc.publicnode.com"

    keypairs=("$solana_config_path"*.json)
    total_ore=0

    for config in "${keypairs[@]}"; do
        filename=$(basename "$config" .json)
        numero="${filename//[!0-9]/}"
        valor=$(ore --rpc "$common_rpc" --keypair "$config" rewards)
        echo "Wallet: $numero - $valor"
        valor=$(echo $valor | tr -d 'ORE') 
        valor=$(echo $valor | awk '{print $1}')
        total_ore=$(bc <<< "scale=7; $total_ore + $valor")
    done

    echo "Total ore mined: $total_ore"
}

# View wallet private key function
view_wallet_private_key() {
    # List all .json files in the Solana configuration folder
    json_files=("$solana_config_path"*.json)
    if [ ${#json_files[@]} -eq 0 ]; then
        echo "No JSON files found at $solana_config_path"
        return
    fi

    echo "The following JSON files were found:"
    for ((i=0; i<${#json_files[@]}; i++)); do
        echo "$((i+1)). ${json_files[$i]}"
    done

    # Select JSON files
    read -p "Please select the JSON file number you want to view:" json_choice
    if [[ $json_choice =~ ^[0-9]+$ ]] && [ $json_choice -ge 1 ] && [ $json_choice -le ${#json_files[@]} ]; then
        selected_json="${json_files[$((json_choice-1))]}"
        echo "You have selected $selected_json"
        echo "The contents of the file are as follows:"
        cat "$selected_json"
    else
        echo "Invalid selection, please enter a valid number."
    fi
}

watch(){
    pm2 list --watch
}

clear_proc(){
    pm2 delete all
}

claim_all(){
    echo -e "${RED}
    #########################################################
    #                       CLAIM                           #
    #########################################################
    ${NC}"

    local config_file="config.json"
    local common_rpc
    local common_gas
    local common_wallet
    local receiver_wallet

    if [ -f "$config_file" ]; then
        common_rpc=$(jq -r '.rpc' "$config_file")
        common_gas=$(jq -r '.gas' "$config_file")
        receiver_wallet=$(jq -r '.wallet' "$config_file")
    else
        read -p "Please enter the RPC address: " common_rpc
        read -p "Please enter gas fee: " common_gas
        read -p "Please enter the wallet that will receive the ore: " common_wallet

        echo -e "${RED}
        #########################################################
        #                       ATENTION                        #
        #########################################################
        ${NC}"

        echo "Copy the Account info address bellow and past on next question..."

        echo -e "${RED}
        #########################################################
        ${NC}"

        spl-token accounts -u "$common_rpc" --owner "$common_wallet" -v

        echo -e "${RED}
        #########################################################
        ${NC}"

        read -p "Please enter Account info generated: " receiver_wallet

        jq -n --arg rpc "$common_rpc" --arg gas "$common_gas" --arg wallet "$receiver_wallet" '{"rpc": $rpc, "gas": $gas, "wallet": $wallet}' > "$config_file"
        chmod -x config.json
    fi

    keypairs=(~/.config/solana/*.json)

    for keypair in "${keypairs[@]}"
    do
        filename=$(basename "$keypair")
        result=$(ore --rpc "$common_rpc" --keypair "$keypair" rewards)
        number=$(echo "$result" | awk '{print $1}')  # 
        
        if (( $(echo "$number < 0.001" | bc -l) )); then
            echo "Skipping wallet: $filename, low ore balance: $number"
            continue
        fi
        
        echo "Wallet: $filename, ORE: $number"

        ore --rpc "$common_rpc" --keypair ~/.config/solana/"$filename" --priority-fee "$common_gas" claim "$number" "$receiver_wallet"
    done
}

update(){
    echo -e "${RED}
    #########################################################
    #                                                       #
    #                       UPDATE                          #
    #                                                       #
    #########################################################
    ${NC}"

    wget -O novo_menu.sh https://raw.githubusercontent.com/brunogallo/ore-solana-mine-helper/main/menu.sh && mv -f novo_menu.sh menu.sh && chmod +x menu.sh
}

# main_menu function
main_menu() {
    echo -e "${RED}
    #########################################################
    #                                                       #
    #                     BOMBERS TEAM                      #
    #                                                       #
    #########################################################
    ${NC}"
    echo ""
    echo ""
    echo "Please select an option: "
    echo "1. Modify RPC"
    echo "2. Modify Gas Fee"
    echo "3. Start Mining"
    echo "4. Stop Mining"
    echo "5. Claim"
    echo "6. Watch"
    echo "7. Farmed Ore"
    echo "8. Clear ALL Proccess"
    echo "9. View Wallet Private Key"
    echo "69. Update"
    echo "0. exit"

    read -p "Please enter your choice: " choice

    case $choice in
        1) modify_rpc ;;
        2) modify_gas ;;
        3) start_mining ;;
        4) stop_mining ;;
        5) claim_all ;;
        6) watch ;;
        7) query_amount ;;
        8) clear_proc ;;
        9) view_wallet_private_key ;;
        69) update ;;
        0) echo "Exiting script. "; exit ;;
        *) echo "Invalid selection, please enter a valid option. " ;;
    esac
}

# Main execution starts
while true; do
    main_menu
done
