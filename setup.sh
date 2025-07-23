#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')" 

CURR_DIR=$(realpath "$(dirname "$BASH_SOURCE")")
UBUNTU_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

banner() {
    clear
    local text="Ubuntu Termux"
    local term_width=$(tput cols)
    local text_len=${#text}
    local padding=$(( (term_width - text_len) / 2 ))
    
    printf "%*s%s%*s\n" $padding "" "${G}${text}${W}" $padding ""
    printf "${W}\n"
}

package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages..."${W}
	
	[ ! -d '/data/data/com.termux/files/home/storage' ] && echo -e "${R} [${W}-${R}]${C} Setting up storage..."${W} && termux-setup-storage

	if [[ $(command -v pulseaudio) && $(command -v proot-distro) ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Packages are already installed."${W}
	else
		yes | pkg upgrade
		packs=(pulseaudio proot-distro)
		for x in "${packs[@]}"; do
			type -p "$x" &>/dev/null || {
				echo -e "\n${R} [${W}-${R}]${G} Installing packages: ${Y}$x${C}"${W}
				yes | pkg install "$x"
			}
		done
	fi
}

distro() {
	echo -e "\n${R} [${W}-${R}]${C} Checking Distro..."${W}
	termux-reload-settings
	
	if [[ -d "$UBUNTU_DIR" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Distro is already installed."${W}
	else
		echo -e "\n${R} [${W}-${R}]${C} Installing Ubuntu Distro..."${W}
		proot-distro install ubuntu
		termux-reload-settings
	fi
	
	if [[ -d "$UBUNTU_DIR" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Distro Installation Complete! Proceeding with initial setup inside Ubuntu..."${W}
        
        echo -e "\n${R} [${W}-${R}]${Y} Do you want to install common kernel build tools (git, make, gcc, clang, etc.) inside Ubuntu? (y/n): ${W}"
        read -r install_tools_choice
        install_tools_choice=$(echo "$install_tools_choice" | tr '[:upper:]' '[:lower:]')

        if [[ "$install_tools_choice" == "y" || "$install_tools_choice" == "yes" ]]; then
            proot_login_cmd="proot-distro login ubuntu --user root"
            bind_mount_path="/data/data/com.termux/files/home/storage/shared:/mnt/shared"
            
            echo -e "\n${R} [${W}-${R}]${C} Logging into Ubuntu as root and binding internal storage to install tools..."${W}
            ${proot_login_cmd} --bind ${bind_mount_path} -- bash -c " \
                echo -e '\\n${R} [${W}-${R}]${C} Updating Ubuntu packages...${W}'; \
                apt update && apt upgrade -y; \
                echo -e '\\n${R} [${W}-${R}]${C} Installing required build tools...${W}'; \
                apt install -y git make gcc clang libssl-dev pkg-config flex bison libelf-dev libncurses-dev python3 python-is-python3 dos2unix curl unzip zip openjdk-17-jre; \
                echo -e '\\n${R} [${W}-${R}]${G} Initial Ubuntu setup (tools) complete!\\n${W}' \
            "
            if [[ $? -ne 0 ]]; then
                echo -e "\n${R} [${W}-${R}]${G} Error: Failed to complete setup inside Ubuntu!\n"${W}
                exit 1
            fi
        else
            echo -e "\n${R} [${W}-${R}]${Y} Skipping installation of build tools.${W}"
        fi

	else
		echo -e "\n${R} [${W}-${R}]${G} Error: Distro Installation Failed!\n"${W}
		exit 0
	fi
}


downloader(){
	path="$1"
	[ -e "$path" ] && rm -rf "$path"
	echo "Downloading $(basename $1)..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		  --location --output "${path}" "$2"
	echo
}

permission() {
	banner
	echo -e "${R} [${W}-${R}]${C} Setting up Environment..."${W}

	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/user.sh" ]]; then
		cp -f "$CURR_DIR/distro/user.sh" "$UBUNTU_DIR/root/user.sh"
	else
		downloader "$CURR_DIR/user.sh" "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/user.sh"
		mv -f "$CURR_DIR/user.sh" "$UBUNTU_DIR/root/user.sh"
	fi
	chmod +x $UBUNTU_DIR/root/user.sh

	setup_vnc
	echo "$(getprop persist.sys.timezone)" > $UBUNTU_DIR/etc/timezone
	echo "proot-distro login ubuntu" > $PREFIX/bin/ubuntu
	chmod +x "$PREFIX/bin/ubuntu"
	termux-reload-settings

	if [[ -e "$PREFIX/bin/ubuntu" ]]; then
		banner
		cat <<- EOF
			${R} [${W}-${R}]${G} Ubuntu-22.04 (CLI) is now Installed on your Termux
			${R} [${W}-${R}]${G} Restart your Termux to Prevent Some Issues.
			${R} [${W}-${R}]${G} Type ${C}ubuntu${G} to run Ubuntu CLI.
			${R} [${W}-${R}]${G} If you Want to create user then ,
			${R} [${W}-${R}]${G} Run ${C}ubuntu${G} first & then type ${C}bash user.sh${W}
		EOF
		{ echo; sleep 2; exit 1; }
	else
		echo -e "\n${R} [${W}-${R}]${G} Error Installing Distro !"${W}
		exit 0
	fi
}

package
distro
permission
