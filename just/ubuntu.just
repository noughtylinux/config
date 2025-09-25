# Perform Ubuntu setup based on config.toml
[private]
ubuntu-setup: _header _is_compatible _has_config
    #!/usr/bin/env bash
    set -euo pipefail

    is_package_installed() {
        local package="$1"
        dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q "install ok installed"
    }

    PACKAGES_TO_INSTALL=()
    PACKAGES_TO_REMOVE=()

    for PACKAGE in dconf-gsettings-backend fontconfig; do
        if ! is_package_installed "${PACKAGE}"; then
            PACKAGES_TO_INSTALL+=("${PACKAGE}")
        fi
    done
    if is_package_installed "kmscon"; then
        PACKAGES_TO_REMOVE+=("kmscon")
    fi

    # Check ubuntu configuration section
    if tq -f config.toml ubuntu >/dev/null 2>&1; then
        REMOVABLE_PACKAGES=("snapd" "apport" "pollinate" "unattended-upgrades")
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

    if [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]; then
        echo -e "{{GLYPH_UPDATE}}Installing Ubuntu packages..."
        echo -e "{{YELLOW}}{{DIM}}Packages to install: ${PACKAGES_TO_INSTALL[*]}{{RESET}}"
        sudo apt-get -y update
        sudo apt-get -y install "${PACKAGES_TO_INSTALL[@]}"
        echo -e "{{SUCCESS}}Successfully installed ${#PACKAGES_TO_INSTALL[@]} packages!"
    fi

    if [[ ${#PACKAGES_TO_REMOVE[@]} -gt 0 ]]; then
        echo -e "{{GLYPH_CANCEL}}Removing Ubuntu packages..."
        echo -e "{{YELLOW}}{{DIM}}Packages to remove: ${PACKAGES_TO_REMOVE[*]}{{RESET}}"
        sudo apt-get -y remove --purge "${PACKAGES_TO_REMOVE[@]}"
        sudo apt-get -y autoremove --purge
        sudo apt-get -y autoclean
        # If snapd was removed, also remove snap directories
        if [[ " ${PACKAGES_TO_REMOVE[*]} " == *" snapd "* ]]; then
            sudo rm -rf /usr/lib/snapd /snap /var/lib/snapd /var/snap
        fi
        echo -e "{{SUCCESS}}Successfully removed ${#PACKAGES_TO_REMOVE[@]} packages!"
    fi
