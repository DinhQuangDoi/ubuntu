#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

banner() {
    clear
    local text="Ubuntu Termux - User Setup" # Updated text for this script
    local term_width=$(tput cols)
    local text_len=${#text}
    local padding=$(( (term_width - text_len) / 2 ))
    
    printf "%*s%s%*s\n" $padding "" "${G}${text}${W}" $padding ""
    printf "${W}\n" # Empty line below the banner
}

install_sudo_and_tools() {
    echo -e "\n${R} [${W}-${R}]${C} Installing Sudo and essential user tools inside Ubuntu..."${W}
    apt update -y
    apt install -y sudo wget apt-utils locales-all dialog tzdata
    echo -e "\n${R} [${W}-${R}]${G} Sudo and tools installed successfully inside Ubuntu!"${W}
}

create_user() {
    banner
    read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Enter Username [Lowercase, no spaces] : \e[0m\e[1;96m\en' UBUNTU_NEW_USER
    echo -e "${W}"
    read -s -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Enter Password : \e[0m\e[1;96m\en' UBUNTU_NEW_PASS
    echo -e "${W}"
    read -s -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Confirm Password : \e[0m\e[1;96m\en' UBUNTU_NEW_PASS_CONFIRM
    echo -e "${W}"

    if [[ "$UBUNTU_NEW_PASS" != "$UBUNTU_NEW_PASS_CONFIRM" ]]; then
        echo -e "${R} [${W}-${R}]${G} Error: Passwords do not match. Exiting.\n"${W}
        exit 1
    fi

    echo -e '\\n${R} [${W}-${R}]${C} Creating user ${UBUNTU_NEW_USER} and setting up...${W}';
    useradd -m -s /bin/bash ${UBUNTU_NEW_USER};
    usermod -aG sudo ${UBUNTU_NEW_USER};
    echo '${UBUNTU_NEW_USER}:${UBUNTU_NEW_PASS}' | chpasswd;
    echo '${UBUNTU_NEW_USER} ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers;
    mkdir -p /home/${UBUNTU_NEW_USER}/phoenix;
    chown -R ${UBUNTU_NEW_USER}:${UBUNTU_NEW_USER} /home/${UBUNTU_NEW_USER};
    echo -e '\\n${R} [${W}-${R}]${G} User ${UBUNTU_NEW_USER} created and configured!\\n${W}'

    # Create the 'user_setup_done' flag file in root's home
    touch /root/.user_setup_done
    
    local termux_prefix_path="/data/data/com.termux/files/usr"
    
    echo "proot-distro login --user ${UBUNTU_NEW_USER} ubuntu --bind /data/data/com.termux/files/home/storage/shared:/mnt/shared --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" > "${termux_prefix_path}/bin/ubuntu"
    chmod +x "${termux_prefix_path}/bin/ubuntu"
    
    clear
    echo
    echo -e "\n${R} [${W}-${R}]${G} User setup complete! Please exit Ubuntu by typing 'exit'.\n"${W}
    echo -e "\n${R} [${W}-${R}]${G} After returning to Termux, restart Termux and then type ${C}ubuntu${G} to log in as your new user!"${W}
    echo -e "\n${R} [${W}-${R}]${G} Done "${W}
    echo
}

banner
install_sudo_and_tools
create_user
