#!/usr/bin/env bash
set -eu -o pipefail

NOUGHTYLINUX_DIR="${HOME}/NoughtyLinux"

# Colours
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
RESET='\033[0m'

# Formatting
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'
STRIKETHROUGH='\033[9m'

# Status messages
ERROR="${RED}🗵 ${UNDERLINE}${DIM}ERROR${RESET}${BOLD}: ${RESET}"
WARNING="${YELLOW}🛆 ${DIM}WARNING${RESET}${BOLD}: ${RESET}"
SUCCESS="${GREEN}🗹 ${DIM}SUCCESS${RESET}${BOLD}: ${RESET}"
INFO="${BLUE}🛈 ${DIM}INFO${RESET}${BOLD}: ${RESET}"

# Glyphs
GLYPH_CONFIG="${BLUE}✦ ${RESET}"
GLYPH_KEY="${YELLOW}⚿ ${RESET}"
GLYPH_MINUS="${MAGENTA}⊟ ${RESET}"
GLYPH_NET="${BLUE}🖧 ${RESET}"
GLYPH_NIX="${BLUE}❆ ${RESET}"
GLYPH_UPGRADE="${CYAN}⬈ ${RESET}"

function ensure_sudo_access() {
  echo -e "${GLYPH_KEY}This script requires elevated permissions for package management."
  echo "Please enter your password to cache sudo credentials:"
  if ! sudo -v; then
    echo -e "${ERROR}: Failed to obtain sudo credentials."
    exit 1
  fi
}

function install_determinate_nix() {
  echo -e "${GLYPH_NIX}Installing Determinate Nix..."
  curl -sSfL https://install.determinate.systems/nix | sh -s -- install \
    --determinate --no-confirm
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
}

# Check if /etc/os-release exists
if [[ ! -f "/etc/os-release" ]]; then
    echo -e "${ERROR}/etc/os-release not found!"
    exit 1
fi

# Source the os-release file to get variables
source /etc/os-release

# Check if this is Ubuntu
if [[ "${ID:-}" != "ubuntu" ]]; then
    echo -e "${ERROR}This system is not Ubuntu (detected: ${ID:-unknown})"
    exit 1
fi

# Check if running as root (UID 0)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo -e "${ERROR}Do not run this script as root!"
  exit 1
fi

# Check if sudo was used
if [[ -n "${SUDO_USER:-}" ]]; then
  echo -e "${ERROR}Do not run this script with sudo!"
  exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
  echo -e "${ERROR}curl could not be found, please install curl first."
  exit 1
fi

# Ensure sudo access early - this will prompt for password if needed
ensure_sudo_access

# Check for conflicting Ubuntu Nix packages and remove them
echo "Checking for conflicting Ubuntu packages..."
conflicting_packages=()

if dpkg -l | grep -q "^ii.*nix-bin"; then
  conflicting_packages+=("nix-bin")
fi

if dpkg -l | grep -q "^ii.*nix-setup-systemd"; then
  conflicting_packages+=("nix-setup-systemd")
fi

if [[ ${#conflicting_packages[@]} -gt 0 ]]; then
  echo -e "${WARNING}Found conflicting Ubuntu Nix packages: ${conflicting_packages[*]}"

  for package in "${conflicting_packages[@]}"; do
    echo -e "${GLYPH_MINUS}Purging ${package}..."
    sudo apt-get purge -y "${package}"
  done

  echo -e "${SUCCESS}Conflicting packages removed successfully."
fi

# Check if Determinate Nix is installed
if ! command -v nix &> /dev/null; then
  install_determinate_nix
elif ! nix --version 2>/dev/null | grep -q "Determinate Nix"; then
  # This will catch upstream Nix installations and upgrade them
  install_determinate_nix
elif command -v determinate-nixd &> /dev/null; then
  echo -e "${GLYPH_UPGRADE}Upgrading Determinate Nix..."
  sudo determinate-nixd upgrade
fi

if ! command -v determinate-nixd &> /dev/null; then
  echo -e "${ERROR}Determinate Nix installation failed or is not in your PATH. Run bootstrap.sh again."
  exit 1
fi

echo -e "${GLYPH_CONFIG}Installing dconf..."
sudo apt-get -y update
sudo apt-get install -y dconf-gsettings-backend fontconfig udisks2

# Install and configure NetworkManager like Ubuntu Desktop does
echo -e "${GLYPH_NET}Installing NetworkManager..."
sudo apt-get install -y network-manager
if [[ ! -e /usr/lib/netplan/00-network-manager-all.yaml ]]; then
    sudo mkdir -p /usr/lib/netplan 2>/dev/null || true
    echo -e "${INFO}Configuring netplan to use NetworkManager..."
    echo -e "network:\n  version: 2\n  renderer: NetworkManager" | sudo tee /usr/lib/netplan/00-network-manager-all.yaml >/dev/null
    sudo chmod 600 /usr/lib/netplan/00-network-manager-all.yaml
    sudo systemctl disable systemd-networkd
fi

# Clone the repository if it doesn't exist
if [[ -e "${NOUGHTYLINUX_DIR}/config.toml" ]]; then
  echo -e "${INFO}Directory ${NOUGHTYLINUX_DIR} appears to exist and is bootstrapped."
elif [[ "$(basename $0)" == "noughty-bootstrap.sh" ]] && [[ -e "${NOUGHTYLINUX_DIR}/justfile" ]]; then
  echo -e "${INFO}Directory ${NOUGHTYLINUX_DIR} exists and we appear to be bootstrapping remotely."
elif [[ -d "${NOUGHTYLINUX_DIR}/.git" ]] && [[ -f "${NOUGHTYLINUX_DIR}/.git/config" ]]; then
  echo -e "${INFO}Directory ${NOUGHTYLINUX_DIR} appears to be a git repository. Pulling latest changes..."
  pushd "${NOUGHTYLINUX_DIR}" 1>/dev/null
    nix shell nixpkgs#git --command git pull --rebase
  popd 1>/dev/null
else
  echo -e "${INFO}Cloning Nøughty Linux configuration repository into ${NOUGHTYLINUX_DIR}..."
  nix shell nixpkgs#git --command git clone https://github.com/noughtylinux/config "${NOUGHTYLINUX_DIR}"
fi

# Run just generate and just switch
pushd "${NOUGHTYLINUX_DIR}" 1>/dev/null
  if [[ ! -f "config.toml" ]]; then
    nix develop --no-update-lock-file --impure --command just generate
    nix develop --no-update-lock-file --impure --command just switch
  fi
popd 1>/dev/null
