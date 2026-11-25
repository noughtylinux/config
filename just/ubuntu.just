# Perform Ubuntu setup based on config.toml
[private]
ubuntu-pre: _header _is_compatible _has_config
    #!/usr/bin/env bash
    set -euo pipefail

    sudo true

    # Check that this is Ubuntu Server, not Desktop
    just _is_ubuntu_server

    is_package_installed() {
        local package="$1"
        dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q "install ok installed"
    }

    PACKAGES_TO_REMOVE=()
    PACKAGES_TO_INSTALL=()

    # Remove conflicting packages
    for PACKAGE in kmscon nix-bin nix-setup-systemd pulseaudio-module-bluetooth; do
        if is_package_installed "${PACKAGE}"; then
            PACKAGES_TO_REMOVE+=("${PACKAGE}")
        fi
    done

    # Essential packages that provide the Ubuntu system boundary
    for PACKAGE in avahi-daemon bluetooth bolt colord cups dconf-gsettings-backend \
        dbus-user-session dnsmasq-base fontconfig fwupd fwupd-signed geoclue-2.0 gvfs-backends \
        iio-sensor-proxy iputils-ping libfdk-aac2 libmbim-utils libmtp-runtime libnss-mdns \
        libpam-systemd libqmi-utils modemmanager network-manager pipewire-audio \
        plymouth-theme-spinner polkitd power-profiles-daemon ppp secureboot-db \
        smartmontools software-properties-common swaylock udisks2 usb-modeswitch whiptail \
        wireless-regdb wpasupplicant; do
        if ! is_package_installed "${PACKAGE}"; then
            PACKAGES_TO_INSTALL+=("${PACKAGE}")
        fi
    done

    # Install greetd from Ubuntu if desktop compositor is configured
    if tq -f config.toml desktop.compositor &>/dev/null && [ -n "$(tq -f config.toml desktop.compositor)" ]; then
        if ! is_package_installed "greetd"; then
            PACKAGES_TO_INSTALL+=("greetd")
        fi
    fi

    # Install thermald for Intel CPUs
    if grep -q "vendor_id.*:.*GenuineIntel" /proc/cpuinfo; then
        if ! is_package_installed "thermald"; then
            PACKAGES_TO_INSTALL+=("thermald")
        fi
    else
        if is_package_installed "thermald"; then
            PACKAGES_TO_REMOVE+=("thermald")
        fi
    fi

    # Install irqbalance for multi-core CPUs
    if [ "$(grep -c "^processor" /proc/cpuinfo)" -gt 1 ]; then
        if ! is_package_installed "irqbalance"; then
            PACKAGES_TO_INSTALL+=("irqbalance")
        fi
    else
        if is_package_installed "irqbalance"; then
            PACKAGES_TO_REMOVE+=("irqbalance")
        fi
    fi

    # Check ubuntu configuration section
    if tq -f config.toml ubuntu >/dev/null 2>&1; then
        REMOVABLE_PACKAGES=("apport" "cloud-init" "kdump-tools" "multipath-tools" "pollinate" "snapd" "unattended-upgrades")
        for package in "${REMOVABLE_PACKAGES[@]}"; do
            if is_package_installed "${package}"; then
                # Package is installed
                if [[ "$(tq -f config.toml ubuntu.remove.${package} 2>/dev/null || echo 'false')" == "true" ]]; then
                    PACKAGES_TO_REMOVE+=("${package}")
                fi
            fi
        done
    else
        echo -e "{{WARNING}}No {{DIM}}[ubuntu]{{RESET}} section found in config.toml - no packages will be removed."
        exit 0
    fi

    if [[ ${#PACKAGES_TO_REMOVE[@]} -gt 0 ]] || [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]; then
        sudo apt-get update
    fi

    if [[ ${#PACKAGES_TO_REMOVE[@]} -gt 0 ]]; then
        simulation=$(mktemp)
        trap 'rm -f "$simulation"' EXIT
        if ! sudo apt-get --simulate remove --purge "${PACKAGES_TO_REMOVE[@]}" | tee "$simulation"; then
            echo -e "{{ERROR}}APT could not simulate the removal transaction; nothing was removed."
            exit 1
        fi

        if ! ./scripts/check-apt-removal.sh "$simulation"; then
            echo -e "{{ERROR}}Refusing package removal: the simulated transaction removes protected Ubuntu boundary packages."
            exit 1
        fi

        echo -e "{{GLYPH_CANCEL}}Removing Ubuntu packages..."
        echo -e "{{YELLOW}}{{DIM}}Packages to remove: ${PACKAGES_TO_REMOVE[*]}{{RESET}}"
        sudo env DEBIAN_FRONTEND=noninteractive apt-get remove --purge --yes "${PACKAGES_TO_REMOVE[@]}"
        sudo apt-get clean
        # If snapd was removed, also remove snap directories
        if [[ " ${PACKAGES_TO_REMOVE[*]} " == *" snapd "* ]]; then
            sudo rm -rf /usr/lib/snapd /snap /var/lib/snapd /var/snap
        fi
        echo -e "{{SUCCESS}}Successfully removed ${#PACKAGES_TO_REMOVE[@]} packages!"
    fi

    if [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]; then
        echo -e "{{GLYPH_UPDATE}}Installing Ubuntu packages..."
        echo -e "{{YELLOW}}{{DIM}}Packages to install: ${PACKAGES_TO_INSTALL[*]}{{RESET}}"
        sudo env DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends "${PACKAGES_TO_INSTALL[@]}"
        echo -e "{{SUCCESS}}Successfully installed ${#PACKAGES_TO_INSTALL[@]} packages!"
    fi

    if [[ ! -e /usr/lib/netplan/00-network-manager-all.yaml ]]; then
        sudo mkdir -p /usr/lib/netplan 2>/dev/null || true
        echo -e "{{GLYPH_NET}}Configuring netplan to use NetworkManager..."
        echo -e "network:\n  version: 2\n  renderer: NetworkManager" | sudo tee /usr/lib/netplan/00-network-manager-all.yaml >/dev/null
        sudo chmod 600 /usr/lib/netplan/00-network-manager-all.yaml
        echo -e "{{WARNING}}Leaving systemd-networkd enabled until NetworkManager takeover is verified."
        echo -e "{{SUCCESS}}Successfully configured netplan to use NetworkManager!"
    fi

    # NetworkManager and systemd-networkd may coexist during migration, but
    # networkd-wait-online can block boot forever once NetworkManager owns the
    # active interface. Disable only the wait helper after proving that
    # NetworkManager is running and has a connected device; retain networkd as
    # a recovery path until the complete networking matrix has passed.
    if systemctl is-active --quiet NetworkManager.service \
        && nmcli --terse --fields STATE general | grep -qx connected \
        && nmcli --terse --fields DEVICE,STATE device status | grep -q ':connected$'; then
        echo -e "{{GLYPH_NET}}NetworkManager takeover verified; disabling systemd-networkd-wait-online..."
        sudo systemctl disable --now systemd-networkd-wait-online.service
        echo -e "{{SUCCESS}}NetworkManager owns a connected device; boot wait helper disabled."
    else
        echo -e "{{WARNING}}NetworkManager takeover is not yet verified; retaining systemd-networkd-wait-online."
    fi

    # Workarounds for system-manager file tracking
    echo -e "{{INFO}}Processing managed files in /etc..."
    for DIR in \
        "/etc/noughty/kmscon" \
        "/etc/noughty/greetd" \
        "/etc/noughty/grub/themes/catppuccin" \
        "/etc/noughty/plymouth/themes"; do
        if [[ ! -d "${DIR}" ]]; then
            echo -e "{{GLYPH_FOLDER}}Creating directory {{RESET}}{{DIM}}${DIR}{{RESET}}"
            sudo mkdir -p "${DIR}" 2>/dev/null || true
        fi
    done
    # Never pre-delete paths from system-manager's previous generation. Doing so
    # makes a subsequent build or activation failure non-transactional and can
    # remove unrelated Ubuntu configuration.

[private]
ubuntu-post:
    #!/usr/bin/env bash
    set -euo pipefail

    # NetworkManager may only become active during the first switch, after
    # ubuntu-pre has already checked the takeover. Check again at the end of
    # activation so the next boot does not wait for an unconfigured networkd.
    if systemctl is-active --quiet NetworkManager.service \
        && nmcli --terse --fields STATE general | grep -qx connected \
        && nmcli --terse --fields DEVICE,STATE device status | grep -q ':connected$'; then
        echo -e "{{GLYPH_NET}}NetworkManager takeover verified; disabling systemd-networkd-wait-online..."
        sudo systemctl disable --now systemd-networkd-wait-online.service
        echo -e "{{SUCCESS}}NetworkManager owns a connected device; boot wait helper disabled."
    else
        echo -e "{{WARNING}}NetworkManager takeover is not verified; retaining systemd-networkd-wait-online."
    fi

    echo -e "{{GLYPH_SHIELD}}Reloading AppArmor profiles for Nix..."
    for profile in /etc/apparmor.d/nix_*; do
        sudo apparmor_parser -r "$profile"
    done
    echo -e "{{SUCCESS}}AppArmor profiles reloaded!"

    echo -e "{{GLYPH_FONT}}Updating font cache..."
    sudo fc-cache --system-only --really-force
    echo -e "{{SUCCESS}}Font cache updated!"

    # Configure greetd service based on desktop compositor setting
    DESKTOP_COMPOSITOR=$(tq -f config.toml desktop.compositor 2>/dev/null || echo "")
    if [ -n "$DESKTOP_COMPOSITOR" ]; then
        echo -e "{{GLYPH_SCREEN}}Configuring greetd display manager for ${DESKTOP_COMPOSITOR}..."

        # Use dpkg-divert to safely override the package-managed config file
        if [ -f /etc/noughty/greetd/config.toml ]; then
            # Check if diversion already exists
            if ! dpkg-divert --list /etc/greetd/config.toml | grep -q "by noughty"; then
                echo -e "{{GLYPH_DIVERT}}Setting up dpkg diversion for greetd config..."
                sudo dpkg-divert --add --rename --divert /etc/greetd/config.toml.distrib --package noughty /etc/greetd/config.toml
            fi
            # Deploy our configuration (dereference symlink)
            sudo cp -L /etc/noughty/greetd/config.toml /etc/greetd/config.toml
        fi

        # Clean up any existing noughty wayland session files
        sudo rm -f /usr/share/wayland-sessions/noughty-*.desktop 2>/dev/null || true

        # Deploy Wayland session desktop file for the configured compositor
        if [ -f "/etc/noughty/greetd/${DESKTOP_COMPOSITOR}.desktop" ]; then
            echo -e "{{GLYPH_DESKTOP}}Deploying Wayland session for ${DESKTOP_COMPOSITOR}..."
            sudo mkdir -p /usr/share/wayland-sessions 2>/dev/null || true
            sudo cp -L "/etc/noughty/greetd/${DESKTOP_COMPOSITOR}.desktop" "/usr/share/wayland-sessions/noughty-${DESKTOP_COMPOSITOR}.desktop"
            echo -e "{{SUCCESS}}Wayland session file deployed!"
        else
            echo -e "{{WARNING}}No session file found for compositor: ${DESKTOP_COMPOSITOR}"
        fi

        # Enable and start greetd service
        sudo systemctl enable greetd.service &>/dev/null || true
        echo -e "{{SUCCESS}}greetd display manager configured and enabled."
    else
        # Clean up wayland session files and disable greetd
        sudo rm -f /usr/share/wayland-sessions/noughty-*.desktop 2>/dev/null || true
        # Only disable/stop greetd if it's currently enabled
        if systemctl is-enabled greetd.service &>/dev/null; then
            echo -e "{{GLYPH_SCREEN}}Disabling greetd display manager..."
            sudo systemctl disable greetd.service &>/dev/null || true
            echo -e "{{SUCCESS}}greetd display manager disabled and stopped."
        fi
    fi

    # Deploy console-setup configuration for initramfs
    if [ -f /etc/noughty/console-setup ]; then
        sudo cp /etc/noughty/console-setup /etc/default/console-setup
    fi

    if [ -f assets/Catppuccin-1920x1080.png ]; then
        echo -e "{{GLYPH_PICTURE}}Deploying background image..."
        sudo mkdir -p /etc/noughty/backgrounds 2>/dev/null || true
        sudo rm -f /etc/noughty/backgrounds/* 2>/dev/null || true
        sudo cp assets/*.png /etc/noughty/backgrounds/
        echo -e "{{SUCCESS}}Background image deployed!"
    else
        echo -e "{{WARNING}}Background image not found, skipping copy."
    fi

    # Deploy Plymouth theme from catppuccin-plymouth package and dynamic config
    PLYMOUTH_FLAVOR=$(tq -f config.toml catppuccin.flavor)
    if [ -L "/etc/noughty/plymouth/catppuccin-${PLYMOUTH_FLAVOR}" ]; then
        echo -e "{{GLYPH_LOADING}}Deploying Plymouth theme..."

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
        echo -e "{{GLYPH_BOOT}}Deploying GRUB theme to /boot..."
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

    # Create activation marker with metadata
    if [ ! -f /var/lib/noughty/activated ]; then
        echo -e "{{GLYPH_CREATE}}Creating activation marker..."
        sudo mkdir -p /var/lib/noughty
        printf "activated_at=%s\nactivated_by=%s\nhostname=%s\n" \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            "${USER}" \
            "${HOSTNAME}" | sudo tee /var/lib/noughty/activated > /dev/null
        echo -e "{{SUCCESS}}Nøughty Linux activated!"
    fi
