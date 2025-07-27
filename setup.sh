#!/bin/bash

CURR_DIR=$(realpath "$(dirname "$BASH_SOURCE")")
UBUNTU_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

banner() {
    clear
    echo "=========================================="
    echo "             Ubuntu Termux Setup          "
    echo "=========================================="
    echo
}

package() {
    banner
    echo "[*] Checking required packages..."

    if [ ! -d "$HOME/storage" ]; then
        echo "[*] Setting up Termux storage access..."
        termux-setup-storage
    fi

    if command -v pulseaudio >/dev/null && command -v proot-distro >/dev/null; then
        echo "[*] Required packages already installed."
    else
        echo "[*] Updating package list and installing packages..."
        yes | pkg upgrade
        pkg install -y pulseaudio proot-distro
    fi
}

distro() {
    echo "[*] Checking Ubuntu Distro installation..."

    termux-reload-settings

    if [ -d "$UBUNTU_DIR" ]; then
        echo "[*] Ubuntu Distro already installed."
    else
        echo "[*] Installing Ubuntu Distro..."
        proot-distro install ubuntu || {
            echo "[!] Failed to install Ubuntu Distro."
            exit 1
        }
        termux-reload-settings
    fi

    if [ -d "$UBUNTU_DIR" ]; then
        echo "[*] Ubuntu installation complete."

        read -p "[?] Do you want to install common development tools inside Ubuntu? (y/n): " install_tools_choice
        install_tools_choice=$(echo "$install_tools_choice" | tr '[:upper:]' '[:lower:]')

        if [[ "$install_tools_choice" == "y" || "$install_tools_choice" == "yes" ]]; then
            echo "[*] Logging into Ubuntu to install tools..."
            proot-distro login ubuntu --user root --bind "$HOME/storage/shared:/mnt/shared" -- bash -c "
                echo '[*] Updating packages...';
                apt update && apt upgrade -y;
                echo '[*] Installing development tools...';
                apt install -y git make gcc clang libssl-dev pkg-config llvm flex bison libelf-dev libncurses-dev python3 python-is-python3 dos2unix curl unzip zip openjdk-17-jre;
                echo '[*] Development tools installed.';
            " || {
                echo "[!] Error: Failed to complete tool installation."
                exit 1
            }
        else
            echo "[*] Skipping tool installation."
        fi
    else
        echo "[!] Ubuntu installation not found. Exiting."
        exit 1
    fi
}

downloader() {
    local file_path="$1"
    local url="$2"

    [ -e "$file_path" ] && rm -f "$file_path"
    echo "[*] Downloading $(basename "$file_path")..."
    curl --progress-bar --fail --retry 3 --retry-delay 2 --location --output "$file_path" "$url" || {
        echo "[!] Failed to download: $url"
        exit 1
    }
}

permission() {
    banner
    echo "[*] Setting up environment..."

    local user_sh_local="$CURR_DIR/distro/user.sh"
    local user_sh_remote="https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/user.sh"
    local user_sh_target="$UBUNTU_DIR/root/user.sh"

    if [[ -f "$user_sh_local" ]]; then
        cp -f "$user_sh_local" "$user_sh_target"
    else
        downloader "$CURR_DIR/user.sh" "$user_sh_remote"
        mv -f "$CURR_DIR/user.sh" "$user_sh_target"
    fi

    chmod +x "$user_sh_target"

    echo "$(getprop persist.sys.timezone)" > "$UBUNTU_DIR/etc/timezone"
    echo "proot-distro login ubuntu" > "$PREFIX/bin/ubuntu"
    chmod +x "$PREFIX/bin/ubuntu"

    termux-reload-settings

    if [[ -x "$PREFIX/bin/ubuntu" ]]; then
        banner
    cat <<- EOF
        [+] Ubuntu (CLI) is now installed on your Termux.
        [+] Restart Termux to avoid potential issues.
        [+] Type: ubuntu      --> to start Ubuntu CLI
        [+] Inside Ubuntu: bash user.sh   --> to create user
        EOF
    else
        echo "[!] Error: Failed to set up Ubuntu launcher."
        exit 1
    fi
}

# Run full setup
package
distro
permission
