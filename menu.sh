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
    # Go to the path where the script is located and execute it
    cd "$default_directory" || return
    ./cx.sh
    # Return to the parent path after execution
    cd - || return
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
    #                                                       #
    #                       CLAIM                           #
    #                                                       #
    #########################################################
    ${NC}"

    local common_rpc
    local common_gas
    local common_wallet

    read -p "Please enter the RPC address: " common_rpc
    read -p "Please enter gas fee: " common_gas

    priority_fee=$common_gas
    rpc_url=$common_rpc

    keypairs=(~/.config/solana/*.json)

    for keypair in "${keypairs[@]}"
    do
        filename=$(basename "$keypair")
        result=$(ore --rpc "$rpc_url" --keypair "$keypair" rewards)
        number=$(echo "$result" | awk '{print $1}')  # 
        
        if (( $(echo "$number < 0.005" | bc -l) )); then
            echo "Skipping wallet: $filename, low ore balance: $number"
            continue
        fi
        
        echo "Wallet: $filename, ORE: $number"

        ore --rpc "$rpc_url" --keypair ~/.config/solana/"$filename" --priority-fee "$priority_fee" claim
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
