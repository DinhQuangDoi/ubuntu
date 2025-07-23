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
    printf "${W}\n" # Empty line below the banner
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
        
        # Log into Ubuntu with root and bind internal storage, then execute setup commands
        proot_login_cmd="proot-distro login ubuntu --user root"
        bind_mount_path="/data/data/com.termux/files/home/storage/shared:/mnt/shared"
        
        echo -e "\n${R} [${W}-${R}]${C} Logging into Ubuntu as root and binding internal storage..."${W}
        ${proot_login_cmd} --bind ${bind_mount_path} -- bash -c " \
            echo -e '\\n${R} [${W}-${R}]${C} Updating Ubuntu packages...${W}'; \
            apt update && apt upgrade -y; \
            echo -e '\\n${R} [${W}-${R}]${C} Installing required build tools...${W}'; \
            apt install -y git make gcc clang libssl-dev pkg-config flex bison libelf-dev libncurses-dev python3 python-is-python3 dos2unix curl unzip zip openjdk-17-jre; \
            echo -e '\\n${R} [${W}-${R}]${G} Initial Ubuntu setup (tools) complete!\\n${W}' \
        "
        if [[ $? -ne 0 ]]; then
            echo -e "\n${R} [${W}-${R}]${G} Error: Failed to complete initial setup inside Ubuntu!\n"${W}
            exit 1
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
		  --location --output ${path} "$2"
	echo
}

permission() {
	banner
	echo -e "${R} [${W}-${R}]${C} Setting up environment..."${W}

	local user_setup_script_name="user_setup.sh" # Or just "user.sh" if that's the canonical name
	local user_setup_source_url="https://raw.githubusercontent.com/your_repo/your_user_setup_script.sh" # **IMPORTANT: Replace with actual URL**
	
	downloader "$CURR_DIR/$user_setup_script_name" "$user_setup_source_url"
	
	cp -f "$CURR_DIR/$user_setup_script_name" "$UBUNTU_DIR/root/$user_setup_script_name"
	chmod +x "$UBUNTU_DIR/root/$user_setup_script_name"

	local welcome_script_path="$UBUNTU_DIR/etc/profile.d/termux_ubuntu_welcome.sh"
	local welcome_flag_file="$UBUNTU_DIR/root/.user_setup_done" # Flag file for user setup completion

	cat > "$welcome_script_path" <<- 'EOF_WELCOME'
	#!/bin/bash
	# This script runs when logging into Ubuntu through proot-distro

	# Check if this is the root user and if user setup has not been done yet
	if [[ "$USER" == "root" && ! -f "/root/.user_setup_done" ]]; then
	    echo -e "\n\e[1;32m [~] Welcome to Ubuntu Termux!\e[0m"
	    echo -e "\e[1;33m [~] Để tạo người dùng mới và cài đặt lệnh 'ubuntu' cho lần đăng nhập sau, hãy chạy lệnh sau:\e[0m"
	    echo -e "\e[1;36m       ./user_setup.sh\e[0m" # This will be the name of the script copied to /root/
	    echo -e "\e[1;33m [~] Để bỏ qua việc tạo người dùng và sử dụng tài khoản root, chỉ cần bỏ qua thông báo này.\e[0m"
	    echo -e "\e[1;33m [~] Lưu ý: Lệnh 'ubuntu' trực tiếp sẽ chỉ hoạt động sau khi bạn đã chạy ./user_setup.sh\e[0m\n"
	fi
	EOF_WELCOME
	chmod +x "$welcome_script_path"

	echo "$(getprop persist.sys.timezone)" > "$UBUNTU_DIR/etc/timezone" 
	termux-reload-settings

	banner
	cat <<- EOF
		${R} [${W}-${R}]${G} Basic Ubuntu-22.04 (CLI) and build tools are installed.
		${R} [${W}-${R}]${G} Please restart Termux to apply changes.
		${R} [${W}-${R}]${G} After restarting, log into Ubuntu as root to proceed with user setup:
		${C}proot-distro login ubuntu --user root${G}
		${R} [${W}-${R}]${G} Once inside Ubuntu, you will see instructions to create your user account.
		${R} [${W}-${R}]${G} Good luck with your compilation!
	EOF
	{ echo; sleep 2; exit 1; }
}

package
distro
permission
