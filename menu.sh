#!/bin/bash

default_directory="/root/ore"
solana_config_path="/root/.config/solana/"

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

# Start the claim function
start_claim() {
    echo "Starting Claim..."
    pm2 start -f /root/ore/claim*.sh
}

# Stop the claim function
stop_claim() {
    echo "Stopping Claim..."
    pm2 stop -f /root/ore/claim*.sh
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

# main_menu function
main_menu() {
    echo "Please select an option: "
    echo "1. Modify RPC"
    echo "2. Modify Gas Fee"
    echo "3. Start Mining"
    echo "4. Stop Mining"
    echo "5. Start Claim"
    echo "6. Stop Claim"
    echo "7. Watch"
    echo "8. Farmed Ore"
    echo "9. Clear ALL Proccess"
    echo "10. View Wallet Private Key"
    echo "0. exit"

    read -p "Please enter your choice: " choice

    case $choice in
        1) modify_rpc ;;
        2) modify_gas ;;
        3) start_mining ;;
        4) stop_mining ;;
        5) start_claim ;;
        6) stop_claim ;;
        7) watch ;;
        8) query_amount ;;
        9) clear_proc ;;
        10) view_wallet_private_key ;;
        0) echo "Exiting script. "; exit ;;
        *) echo "Invalid selection, please enter a valid option. " ;;
    esac
}

# Main execution starts
while true; do
    main_menu
done
