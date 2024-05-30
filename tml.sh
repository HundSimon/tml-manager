#!/bin/bash

# Variables
tmodloader_directory=${TMODLOADER_DIRECTORY:-/root/.local/share/Terraria/}
temp_directory=${TEMP_DIRECTORY:-/root/.local/share/Terraria/Temp/}
release_url=$(curl -s https://api.github.com/repos/tModLoader/tModLoader/releases/latest | grep browser_download_url | grep tModLoader.zip | cut -d '"' -f 4)

# Menu/Color inspired by https://github.com/TheyCallMeSecond/sing-box-manager
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Install dependencies 
dependencies=("curl" "wget" "screen" "netcat")

install_deps() {
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            sudo $1 install -y "$dep"
        fi
    done
}

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
        debian|ubuntu|linuxmint)
            install_deps "apt-get"
            ;;
        centos|fedora|rhel)
            install_deps "yum"
            ;;
        arch|manjaro)
            install_deps "pacman -S --noconfirm"
            ;;
        *)
            echo "Unsupported distribution. Please install the dependencies manually."
            ;;
    esac
else
    echo "Can't detect the Linux distribution. Please install the dependencies manually."
fi

# 1 Start tModLoader
start_server() {
    clear
    local is_configured=false
    # Check if tModLoader installed
    if [ -f "$tmodloader_directory/start-tModLoaderServer.sh" ]; then
        # Check if "tml-manager" screen session exists
        if screen -S tml-manager -Q select >/dev/null; then
            # Check if serverconfig.txt is modified
            while IFS= read -r line; do
                # Use "#port=" to judge
                if [[ "$line" =~ ^#port=[0-9]+ ]]; then
                    is_configured=false
                    break
                else
                    is_configured=true
                fi
            done < "$tmodloader_directory/serverconfig.txt"

            if ! $is_configured; then
                echo -e "${CYAN}You haven't configured tModLoader, press enter to configure. ${NC}"
                read
                modify_config
                start_server
            else
                launch_server
            fi        
    else
            echo -e "${CYAN}Initialize session first${NC}"
            screen -dmS tml-manager
            echo -e "${CYAN}Initialized successfully! Press enter to continue. ${NC}"
            read
            start_server
        fi
    else
        echo -e "${CYAN}You haven't installed tModLoader, press enter to install. ${NC}"
        read
        update_tml
    fi
}

# 2 Stop tModLoader
stop_server() {
    clear
    sleep 1
    screen -S tml-manager -p 0 -X stuff 'exit\n'
    sleep 1
    echo -e "${CYAN}Server stopped successfully! Press enter to continue. ${NC}"
    read
    main_menu
}

# 3 Update tModLoader
update_tml() {
    clear
    rm -f "$temp_directory/tModLoader.zip"
    wget -P "$temp_directory" "${release_url}" -q
    unzip -d "$tmodloader_directory" -o "$temp_directory/tModLoader.zip" -x "serverconfig.txt" -q
    echo -e "${CYAN}Install successfully! Press enter to continue. ${NC}"
    read
    main_menu
}

# 4 Modify configs
modify_config() {
    clear
    read -p "Maximum number of players: " v_max
    read -p "Port of server: " v_port
    read -p "Password of server(Press enter to none): " v_pass

    # Modify server configs
    sed -i "/^#*maxplayers/c\maxplayers=$v_max" "$tmodloader_directory/serverconfig.txt"
    sed -i "/^#*port/c\port=$v_port" "$tmodloader_directory/serverconfig.txt"
    sed -i "/^#*password/c\password=$v_pass" "$tmodloader_directory/serverconfig.txt"
}

# 5 Manage Worlds
manage_worlds() {
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
        worlds=($(find "/root/.local/share/Terraria/tModLoader/Worlds" -type f -name "*.wld" -exec basename {} .wld \;))
        for i in "${!worlds[@]}"; do 
            echo -e "${CYAN}$((i+1)): ${worlds[$i]}${NC}"
        done
        read -p "Type in the index of the world you want to play: " v_index
        v_world=${worlds[$((v_index-1))]}
        sed -i "/^#*world/c\world="$tmodloader_directory"/tModLoader/Worlds/"$v_world".wld" "$tmodloader_directory/serverconfig.txt"
        echo -e "${CYAN}Changed successfully! Press enter to back to Menu. ${NC}"
        read

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

# 6 Update script
update_script () {
    echo "working in progress"
}

launch_server() {
    local port=$(grep -m1 "port=" $tmodloader_directory/serverconfig.txt | cut -d'=' -f2)

    chmod +x $tmodloader_directory/LaunchUtils/ScriptCaller.sh
    sleep 1
    screen -S tml-manager -p 0 -X stuff 'cd /root/.local/share/Terraria/\n'
    sleep 1
    screen -S tml-manager -p 0 -X stuff 'bash /root/.local/share/Terraria/LaunchUtils/ScriptCaller.sh -server -config serverconfig.txt\n'
    sleep 1
    echo "Starting..."
    while ! nc -z localhost $port; do
        sleep 1
    done
    echo -e "${CYAN}Server started! Press enter to back to Menu. ${NC}"
    read
    main_menu
}


main_menu() {
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
    echo -e "║ ${CYAN}[5]${NC}  Manage Worlds                     ${CYAN}[6]${NC}  Update Script              ║"
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
    6)
        update_script
        ;;
    *)
        main_menu
        ;;
    esac
}

main_menu
