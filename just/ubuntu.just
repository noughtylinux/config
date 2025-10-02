# I solemnly swear that I am up to no good
mischief: _header _is_compatible
    #!/usr/bin/env bash
    if [[ "${USER}" != "martin" ]]; then
        echo -e "{{GLYPH_CANCEL}}Only the user {{BOLD}}martin{{RESET}} can get up to mischief! {{GLYPH_DAMAGE}}"
        exit 0
    fi
    echo -e "{{GLYPH_DAMAGE}}I solemnly swear that I am up to no good..."
    sudo nala remove --assume-yes --simple --purge cups
    sudo nala install --assume-yes --simple pollinate
    sudo apt-get -y purge --autoremove nala whiptail 2> /dev/null || true
    sudo rm -f /usr/lib/netplan/00-network-manager-all.yaml
    echo -e "{{GLYPH_DAMAGE}}Mischief managed!"

# Perform Ubuntu setup based on config.toml
[private]
ubuntu-pre: _header _is_compatible _has_config
    #!/usr/bin/env bash
    set -euo pipefail

    sudo true

    is_package_installed() {
        local package="$1"
        dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q "install ok installed"
    }

    if ! is_package_installed "nala"; then
        just install-nala
    fi

    PACKAGES_TO_REMOVE=()
    PACKAGES_TO_INSTALL=()

    # Remove conflicting packages
    for PACKAGE in kmscon nix-bin nix-setup-systemd pulseaudio-module-bluetooth; do
        if is_package_installed "${PACKAGE}"; then
            PACKAGES_TO_REMOVE+=("${PACKAGE}")
        fi
    done

    # Essential Ubuntu host packages that provide hardware support for Nix integration
    for PACKAGE in bluez cups dconf-gsettings-backend fontconfig gstreamer1.0-pipewire \
        libfdk-aac2 libldacbt-abr2 libldacbt-enc2 libopenaptx0 \
        libspa-0.2-bluetooth libspa-0.2-jack network-manager \
        pipewire-audio-client-libraries plymouth-theme-spinner udisks2 whiptail wireplumber; do
        if ! is_package_installed "${PACKAGE}"; then
            PACKAGES_TO_INSTALL+=("${PACKAGE}")
        fi
    done

    # Check ubuntu configuration section
    if tq -f config.toml ubuntu >/dev/null 2>&1; then
        REMOVABLE_PACKAGES=("apport" "kdump-tools" "pollinate" "snapd" "unattended-upgrades")
        for package in "${REMOVABLE_PACKAGES[@]}"; do
            if is_package_installed "${package}"; then
                # Package is installed
                if [[ "$(tq -f config.toml ubuntu.remove.${package} 2>/dev/null || echo 'false')" == "true" ]]; then
                    PACKAGES_TO_REMOVE+=("${package}")
                fi
            else
                # Package is not installed
                if [[ "$(tq -f config.toml ubuntu.remove.${package} 2>/dev/null || echo 'false')" == "false" ]]; then
                    PACKAGES_TO_INSTALL+=("${package}")
                fi
            fi
        done
    else
        echo -e "{{WARNING}}No {{DIM}}[ubuntu]{{RESET}} section found in config.toml - no packages will be removed."
        exit 0
    fi

    if [[ ${#PACKAGES_TO_REMOVE[@]} -gt 0 ]] || [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]; then
        sudo nala update
    fi

    if [[ ${#PACKAGES_TO_REMOVE[@]} -gt 0 ]]; then
        echo -e "{{GLYPH_CANCEL}}Removing Ubuntu packages..."
        echo -e "{{YELLOW}}{{DIM}}Packages to remove: ${PACKAGES_TO_REMOVE[*]}{{RESET}}"
        sudo nala remove --purge --simple --assume-yes "${PACKAGES_TO_REMOVE[@]}"
        sudo nala clean
        # If snapd was removed, also remove snap directories
        if [[ " ${PACKAGES_TO_REMOVE[*]} " == *" snapd "* ]]; then
            sudo rm -rf /usr/lib/snapd /snap /var/lib/snapd /var/snap
        fi
        echo -e "{{SUCCESS}}Successfully removed ${#PACKAGES_TO_REMOVE[@]} packages!"
    fi

    if [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]; then
        echo -e "{{GLYPH_UPDATE}}Installing Ubuntu packages..."
        echo -e "{{YELLOW}}{{DIM}}Packages to install: ${PACKAGES_TO_INSTALL[*]}{{RESET}}"
        sudo nala install --assume-yes --simple "${PACKAGES_TO_INSTALL[@]}"
        echo -e "{{SUCCESS}}Successfully installed ${#PACKAGES_TO_INSTALL[@]} packages!"
    fi

    if [[ ! -e /usr/lib/netplan/00-network-manager-all.yaml ]]; then
        sudo mkdir -p /usr/lib/netplan 2>/dev/null || true
        echo -e "{{GLYPH_NET}}Configuring netplan to use NetworkManager..."
        echo -e "network:\n  version: 2\n  renderer: NetworkManager" | sudo tee /usr/lib/netplan/00-network-manager-all.yaml >/dev/null
        sudo chmod 600 /usr/lib/netplan/00-network-manager-all.yaml
        sudo systemctl disable systemd-networkd
        echo -e "{{SUCCESS}}Successfully configured netplan to use NetworkManager!"
    fi

    # Workarounds for system-manager file tracking
    echo -e "{{INFO}}Processing managed files in /etc..."
    for DIR in \
        "/etc/noughty/kmscon" \
        "/etc/noughty/grub/themes/catppuccin" \
        "/etc/noughty/plymouth/themes"; do
        if [[ ! -d "${DIR}" ]]; then
            echo -e "{{GLYPH_FOLDER}}Creating directory {{RESET}}{{DIM}}${DIR}{{RESET}}"
            sudo mkdir -p "${DIR}" 2>/dev/null || true
        fi
    done
    state_file="/var/lib/system-manager/state/system-manager-state.json"
    if [[ -e "$state_file" ]]; then
        sudo cat "$state_file" | \
            jq -r '.fileTree | .. | objects | select(.status == "managed") | .path' 2>/dev/null | \
            while IFS= read -r filepath; do
                [[ -z "$filepath" ]] && continue
                # Skip symlinks
                [[ -L "$filepath" ]] && continue
                if [[ -f "$filepath" ]]; then
                    echo -e "{{GLYPH_PROCESS}}Processing {{RESET}}{{DIM}}$filepath{{RESET}}"
                    sudo rm -f "$filepath"
                fi
            done
        echo -e "{{SUCCESS}}Files processed{{RESET}}"
    fi

[private]
ubuntu-post:
    #!/usr/bin/env bash
    set -euo pipefail
    echo -e "{{GLYPH_SHIELD}}Reloading AppArmor profiles for Nix..."
    for profile in /etc/apparmor.d/nix_*; do
        sudo apparmor_parser -r "$profile"
    done
    echo -e "{{SUCCESS}}AppArmor profiles reloaded!"

    echo -e "{{GLYPH_FONT}}Updating font cache..."
    sudo fc-cache --system-only --really-force
    echo -e "{{SUCCESS}}Font cache updated!"

    # Deploy console-setup configuration for initramfs
    if [ -f /etc/noughty/console-setup ]; then
        sudo cp /etc/noughty/console-setup /etc/default/console-setup
    fi

    # Deploy Plymouth theme from catppuccin-plymouth package and dynamic config
    PLYMOUTH_FLAVOR=$(tq -f config.toml catppuccin.flavor)
    if [ -L "/etc/noughty/plymouth/catppuccin-${PLYMOUTH_FLAVOR}" ]; then
        echo -e "{{GLYPH_SCREEN}}Deploying Plymouth theme (${PLYMOUTH_FLAVOR})..."

        # Create theme directory
        sudo rm -rf /usr/share/plymouth/themes/catppuccin-* 2>/dev/null
        sudo mkdir -p /usr/share/plymouth/themes/catppuccin-${PLYMOUTH_FLAVOR}

        # Copy PNG assets from catppuccin-plymouth package (dereference symlink)
        sudo cp -rL /etc/noughty/plymouth/catppuccin-${PLYMOUTH_FLAVOR}/*.png /usr/share/plymouth/themes/catppuccin-${PLYMOUTH_FLAVOR}/
        # Copy dynamically generated .plymouth theme file from system-manager (dereference symlink)
        sudo cp -L /etc/noughty/plymouth/catppuccin-${PLYMOUTH_FLAVOR}.plymouth /usr/share/plymouth/themes/catppuccin-${PLYMOUTH_FLAVOR}/

        # Set as default Plymouth theme using update-alternatives
        sudo update-alternatives --quiet --install \
            /usr/share/plymouth/themes/default.plymouth default.plymouth \
            /usr/share/plymouth/themes/catppuccin-${PLYMOUTH_FLAVOR}/catppuccin-${PLYMOUTH_FLAVOR}.plymouth 100
        sudo update-alternatives --quiet --set default.plymouth \
            /usr/share/plymouth/themes/catppuccin-${PLYMOUTH_FLAVOR}/catppuccin-${PLYMOUTH_FLAVOR}.plymouth

        echo -e "{{SUCCESS}}Plymouth theme deployed!"
    fi

    # Only deploy GRUB theme if GRUB is available
    if [ -d /boot/grub ] && command -v update-grub &>/dev/null; then
        echo -e "{{GLYPH_PAINT}}Deploying GRUB theme to /boot..."
        sudo mkdir -p /boot/grub/themes/catppuccin 2>/dev/null || true
        sudo cp -rfL /etc/noughty/grub/themes/catppuccin/* /boot/grub/themes/catppuccin/ 2>/dev/null || true
        sudo update-grub &> /dev/null || true
        echo -e "{{SUCCESS}}GRUB theme deployed!"

        echo -e "{{GLYPH_SYSTEM}}Updating initramfs..."
        sudo update-initramfs -u &> /dev/null || true
        echo -e "{{SUCCESS}}System is up to date!"
    else
        echo -e "{{WARNING}}Skipping GRUB operations - GRUB not detected"
    fi

[private]
install-nala:
    #!/usr/bin/env bash

    function ensure_sudo_access() {
        if sudo -n true 2>/dev/null; then
            echo -e "{{GLYPH_KEY}}sudo credentials are already cached."
            return 0
        fi

    echo -e "{{GLYPH_KEY}}This script requires elevated permissions for package management."
    echo "Please enter your password to cache sudo credentials:"
    if ! sudo -v; then
        echo -e "{{ERROR}}Failed to obtain sudo credentials."
        exit 1
    fi
    }

    function spinner() {
        local pid=$1
        local delay=0.1
        local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local message="${2:-Working...}"

        while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
            local temp=${spinstr#?}
            printf "\r%s %s " "${spinstr%"$temp"}" "$message"
            local spinstr=$temp${spinstr%"$temp"}
            sleep $delay
        done
        printf "\r\033[K"
    }

    if command -v nala &> /dev/null; then
        echo -e "{{SUCCESS}}nala is already installed, skipping installation."
        return 0
    fi

    tmp_dir=$(mktemp -d)
    base_url="https://deb.volian.org/volian/pool/main/v/volian-archive/"

    # Buffer for error output
    error_log=$(mktemp)

    # Dynamically get the latest version
    echo -e "{{GLYPH_EYE}}Detecting latest nala version..."
    version=$(curl -sSfL "$base_url" 2>>"$error_log" | grep -o 'volian-archive-nala_[0-9]\+\.[0-9]\+\.[0-9]\+_all\.deb' | sed 's/volian-archive-nala_\([0-9]\+\.[0-9]\+\.[0-9]\+\)_all\.deb/\1/' | sort -V | tail -n1)

    if [[ -z "$version" ]]; then
        echo -e "{{ERROR}}Failed to detect nala version from ${base_url}"
        cat "$error_log" 2>/dev/null
        rm -rf "$tmp_dir" "$error_log"
        exit 1
    fi

    archive="volian-archive-nala_${version}_all.deb"
    keyring="volian-archive-keyring_${version}_all.deb"

    # Download packages with spinner
    echo -e "{{INFO}}Found nala version: ${version}"
    {
        curl -sSfL "${base_url}${archive}" -o "${tmp_dir}/${archive}" 2>>"$error_log" &&
        curl -sSfL "${base_url}${keyring}" -o "${tmp_dir}/${keyring}" 2>>"$error_log"
    } &
    download_pid=$!
    spinner $download_pid "Downloading nala packages…"
    wait $download_pid
    download_result=$?

    if [ $download_result -ne 0 ]; then
        echo -e "{{ERROR}}Failed to download nala packages:"
        cat "$error_log"
        rm -rf "$tmp_dir" "$error_log"
        exit 1
    fi

    # Install packages with spinner
    {
        sudo apt-get install -y "${tmp_dir}/${archive}" "${tmp_dir}/${keyring}" >/dev/null 2>>"$error_log" &&
        sudo apt-get update >/dev/null 2>>"$error_log" &&
        sudo apt-get install -y nala whiptail >/dev/null 2>>"$error_log"
    } &
    install_pid=$!
    spinner $install_pid "Installing nala…"
    wait $install_pid
    install_result=$?

    # Clean up temporary files
    rm -rf "$tmp_dir"

    if [ $install_result -ne 0 ]; then
        echo -e "{{ERROR}}Failed to install nala:"
        cat "$error_log"
        rm -f "$error_log"
        exit 1
    fi

    rm -f "$error_log"
    echo -e "{{SUCCESS}}nala package manager installed successfully."

