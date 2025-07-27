#!/bin/bash

# Hiển thị banner
banner() {
    clear
    echo "=========================================="
    echo "         Ubuntu Termux - User Setup       "
    echo "=========================================="
    echo
}

# Cài đặt sudo và các công cụ cơ bản
install_sudo_and_tools() {
    echo "[*] Installing sudo and essential tools..."
    apt update -y
    apt install -y sudo wget apt-utils locales-all dialog tzdata
    echo "[+] Installation completed."
}

# Tạo user mới
create_user() {
    banner

    read -p "Enter Username (lowercase, no spaces): " UBUNTU_NEW_USER
    if [[ -z "$UBUNTU_NEW_USER" || "$UBUNTU_NEW_USER" =~ [[:space:]] ]]; then
        echo "[-] Invalid username. Exiting."
        exit 1
    fi

    echo
    read -s -p "Enter Password: " UBUNTU_NEW_PASS
    echo
    read -s -p "Confirm Password: " UBUNTU_NEW_PASS_CONFIRM
    echo

    if [[ "$UBUNTU_NEW_PASS" != "$UBUNTU_NEW_PASS_CONFIRM" ]]; then
        echo "[-] Passwords do not match. Exiting."
        exit 1
    fi

    echo "[*] Creating user '${UBUNTU_NEW_USER}'..."

    useradd -m -s /bin/bash "$UBUNTU_NEW_USER"
    usermod -aG sudo "$UBUNTU_NEW_USER"
    echo "${UBUNTU_NEW_USER}:${UBUNTU_NEW_PASS}" | chpasswd
    echo "${UBUNTU_NEW_USER} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

    mkdir -p "/home/${UBUNTU_NEW_USER}/phoenix"
    chown -R "${UBUNTU_NEW_USER}:${UBUNTU_NEW_USER}" "/home/${UBUNTU_NEW_USER}"

    touch /root/.user_setup_done

    local termux_prefix_path="/data/data/com.termux/files/usr"

    echo "proot-distro login --user ${UBUNTU_NEW_USER} ubuntu --bind /data/data/com.termux/files/home/storage/shared:/mnt/shared --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" > "${termux_prefix_path}/bin/ubuntu"
    chmod +x "${termux_prefix_path}/bin/ubuntu"

    clear
    echo "[+] User setup complete."
    echo "    Type 'exit' to leave Ubuntu."
    echo "    Then restart Termux and run 'ubuntu' to login as the new user."
    echo
}

banner
install_sudo_and_tools
create_user

