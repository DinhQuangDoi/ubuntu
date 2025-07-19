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
	cat <<- EOF
		${Y}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  
		${C}    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ 
		${G}    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ 

	EOF
	echo -e "${G}     Ubuntu Termux\n\n"${W}
}

package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Đang kiểm tra các gói cần thiết..."${W}
	
	[ ! -d '/data/data/com.termux/files/home/storage' ] && echo -e "${R} [${W}-${R}]${C} Thiết lập bộ nhớ.."${W} && termux-setup-storage

	if [[ $(command -v pulseaudio) && $(command -v proot-distro) ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Các gói đã được cài đặt."${W}
	else
		yes | pkg upgrade
		packs=(pulseaudio proot-distro)
		for x in "${packs[@]}"; do
			type -p "$x" &>/dev/null || {
				echo -e "\n${R} [${W}-${R}]${G} Đang cài đặt các gói: ${Y}$x${C}"${W}
				yes | pkg install "$x"
			}
		done
	fi
}

distro() {
	echo -e "\n${R} [${W}-${R}]${C} Đang kiểm tra Distro..."${W}
	termux-reload-settings
	
	if [[ -d "$UBUNTU_DIR" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Distro đã được cài đặt."${W}
		exit 0
	else
		proot-distro install ubuntu
		termux-reload-settings
	fi
	
	if [[ -d "$UBUNTU_DIR" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Cài Đặt Hoàn Tất !!"${W}
	else
		echo -e "\n${R} [${W}-${R}]${G} Lỗi Distro Cài Đặt Không Thành Công!\n"${W}
		exit 0
	fi
}


downloader(){
	path="$1"
	[ -e "$path" ] && rm -rf "$path"
	echo "Đang tải xuống$(basename $1)..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		  --location --output ${path} "$2"
	echo
}

permission() {
	banner
	echo -e "${R} [${W}-${R}]${C} Đang thiết lập môi trường..."${W}

	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/user.sh" ]]; then
		cp -f "$CURR_DIR/distro/user.sh" "$UBUNTU_DIR/root/user.sh"
	else
		downloader "$CURR_DIR/user.sh" "https://raw.githubusercontent.com/DinhQuangDoi/ubuntu-no-gui/refs/heads/master/distro/user.sh"
		mv -f "$CURR_DIR/user.sh" "$UBUNTU_DIR/root/user.sh"
	fi
	chmod +x $UBUNTU_DIR/root/user.sh


	if [[ -e "$PREFIX/bin/ubuntu" ]]; then
		banner
		cat <<- EOF
			${R} [${W}-${R}]${G} Ubuntu-22.04 (CLI) đã được cài đặt trên Termux của bạn
			${R} [${W}-${R}]${G} Khởi động lại Termux để ngăn một vài lỗi.
			${R} [${W}-${R}]${G} Nhập ${C}ubuntu${G} để khởi động Ubuntu CLI.
		EOF
		{ echo; sleep 2; exit 1; }
	else
		echo -e "\n${R} [${W}-${R}]${G} Lỗi không thể cài đặt Distro !"${W}
		exit 0
	fi

}

package
distro
permission
