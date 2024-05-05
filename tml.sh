#!/bin/bash

# Variables
tml_dir=/root/.local/share/Terraria/
tmp_dir=/root/.local/share/Terraria/Temp/
release_url=$(curl -s https://api.github.com/repos/tModLoader/tModLoader/releases/latest | grep browser_download_url | grep tModLoader.zip | cut -d '"' -f 4)

# Menu/Color inspired by https://github.com/TheyCallMeSecond/sing-box-manager
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 1 Start tModLoader
function start_server() {
    clear
    local is_exist=false
    # Check if tModLoader installed
    if [ -f "$tml_dir/start-tModLoaderServer.sh" ]; then
        # Check if "tml-manager" screen session exists
        if screen -S tml-manager -Q select >/dev/null; then
            # Check if serverconfig.txt is modified
            while IFS= read -r line; do
                # Use "#port=" to judge
                if [[ "$line" == *"#port="* ]]; then
                    is_exist=true
                    echo exist
                    break
                fi
            done < "$tml_dir/serverconfig.txt"
            if [ -e "is_exist" ]; then
                read -p "$(echo -e "${CYAN}You haven't configure tModLoader, press enter to configure. ${NC}")"
                modify_config
                start_server
            else
                read -p "$(echo -e "${CYAN}fff. ${NC}")"
                launch_server
            fi
        else
            echo -e "${CYAN}Initialize session first${NC}"
            screen -dmS tml-manager
            read -p "$(echo -e "${CYAN}Initialized successfully! Press enter to continue. ${NC}")"
            start_server
        fi
    else
        read -p "$(echo -e "${CYAN}You haven't installed tModLoader, press enter to install. ${NC}")"
        update_tml
    fi
}

function stop_server() {
    clear
    screen -S tml-manager -p 0 -X stuff 'exit\n'
    read -p "$(echo -e "${CYAN}Server stopped successfully! Press enter to continue. ${NC}")"
    main_menu
}

# 3 Update tModLoader
function update_tml() {
    clear
    rm "$tmp_dir/tModLoader.zip" >/dev/null
    wget -P "$tmp_dir" "${release_url}" >/dev/null
    unzip -d "$tml_dir" -o "$tmp_dir/tModLoader.zip" -x "serverconfig.txt" >/dev/null
    read -p "$(echo -e "${CYAN}Install successfully! Press enter to continue. ${NC}")"
    main_menu
}

# 4 Modify configs
function modify_config() {
    clear
    read -p "Maximum number of players: " v_max
    read -p "Port of server: " v_port
    read -p "Password of server(Press enter to none): " v_pass

    # Modify server configs
    sed -i "/^#*maxplayers/c\maxplayers=$v_max" "$tml_dir/serverconfig.txt"
    sed -i "/^#*port/c\port=$v_port" "$tml_dir/serverconfig.txt"
    sed -i "/^#*password/c\password=$v_pass" "$tml_dir/serverconfig.txt"
}

function manage_worlds() {
    clear
    local choice
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo -e "║ ${CYAN}[1]${NC}  Select World                      ${CYAN}[2]${NC}  Create World               ║"
    echo -e "║ ${CYAN}[3]${NC}  Delete World                      ${CYAN}[0]${NC}  Back to Menu               ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"

    read -p "select the option:" choice
    case $choice in
    0)
        main_menu
        ;;
    1)
        clear
        echo -e "Your Worlds:" 
        echo -e "${CYAN}$(find "/root/.local/share/Terraria/tModLoader/Worlds" -type f -name "*.wld" -exec basename {} .wld \;)${NC}"
        read -p "Type in the name of the world you want to play: " v_world
        sed -i "/^#*world/c\world="$tml_dir"tModLoader/Worlds/"$v_world".wld" "$tml_dir/serverconfig.txt"
        read -p "$(echo -e "${CYAN}Changed successfully! Press enter to back to Menu. ${NC}")"
        main_menu
        ;;
    2)
        exit 0
        ;;
    3)
        exit 0
        ;;
    esac
}

function launch_server() {
    chmod +x $tml_dir/LaunchUtils/ScriptCaller.sh
    # TODO: replace with $tml_dir
    screen -S tml-manager -p 0 -X stuff 'cd /root/.local/share/Terraria/\n'
    screen -S tml-manager -p 0 -X stuff 'bash ./LaunchUtils/ScriptCaller.sh -server -config serverconfig.txt\n'
    echo uee
}

function main_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo -e "║ ${YELLOW}                     ████████╗███╗   ███╗██╗     ${NC}                      ║"
    echo -e "║ ${YELLOW}                     ╚══██╔══╝████╗ ████║██║     ${NC}                      ║"
    echo -e "║ ${YELLOW}                        ██║   ██╔████╔██║██║     ${NC}                      ║"
    echo -e "║ ${YELLOW}                        ██║   ██║╚██╔╝██║██║     ${NC}                      ║"
    echo -e "║ ${YELLOW}                        ██║   ██║ ╚═╝ ██║███████╗${NC}                      ║"
    echo -e "║ ${YELLOW}                        ╚═╝   ╚═╝     ╚═╝╚══════╝${NC}                      ║" 
    echo -e "║ ${YELLOW}    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ ${NC}     ║" 
    echo -e "║ ${YELLOW}    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗${NC}     ║" 
    echo -e "║ ${YELLOW}    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝${NC}     ║" 
    echo -e "║ ${YELLOW}    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗${NC}     ║" 
    echo -e "║ ${YELLOW}    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║${NC}     ║" 
    echo -e "║ ${YELLOW}    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝${NC}     ║"                                              
    echo "╠════════════════════════════════════════════════════════════════════════╣"
    echo -e "║ ${CYAN}[1]${NC}  Start Server                      ${CYAN}[2]${NC}  Stop Server                ║"
    echo -e "║ ${CYAN}[3]${NC}  Install/Update Server             ${CYAN}[4]${NC}  Modify Server Configs      ║"
    echo -e "║ ${CYAN}[5]${NC}  Manage Worlds                     ${CYAN}[4]${NC}  Modify Server Configs      ║"
    echo -e "║ ${CYAN}[21]${NC} Uninstall                         ${CYAN}[0]${NC}  Exit                       ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"

    local choice
    read -p "Please select [0-21]: " choice

    case $choice in
    0)
        exit 0
        ;;
    1)
        start_server
        ;;
    2)
        stop_server
        ;;
    3)
        update_tml
        ;;
    4)
        modify_config
        ;;
    5)
        manage_worlds
        ;;
    *)
        main_menu
        ;;
    esac
}

main_menu
