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
ERROR="${RED}${BOLD}🗴 ${RESET}${RED}${UNDERLINE}${DIM}ERROR${RESET}${BOLD}: ${RESET}"
WARNING="${YELLOW}🛆 ${DIM}WARNING${RESET}${BOLD}: ${RESET}"
SUCCESS="${GREEN}${BOLD}🗸 ${RESET}${GREEN}${DIM}SUCCESS${RESET}${BOLD}: ${RESET}"
INFO="${BLUE}🛈 ${DIM}INFO${RESET}${BOLD}: ${RESET}"

# Glyphs
GLYPH_CHECK="${CYAN}≟ ${RESET}"
GLYPH_CONFIG="${BLUE}✦ ${RESET}"
GLYPH_EYE="${CYAN}⏿ ${RESET}"
GLYPH_INSTALL="${CYAN}⮯ ${RESET}"
GLYPH_KEY="${YELLOW}⚿ ${RESET}"
GLYPH_MINUS="${MAGENTA}⊟ ${RESET}"
GLYPH_NIX="${BLUE}❆ ${RESET}"
GLYPH_UPGRADE="${CYAN}⬈ ${RESET}"

function ensure_sudo_access() {
  if sudo -n true 2>/dev/null; then
    echo -e "${GLYPH_KEY}sudo credentials are already cached."
    return 0
  fi

  echo -e "${GLYPH_KEY}This script requires elevated permissions for package management."
  echo "Please enter your password to cache sudo credentials:"
  if ! sudo -v; then
    echo -e "${ERROR}Failed to obtain sudo credentials."
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

function install_nala() {
  if command -v nala &> /dev/null; then
    echo -e "${SUCCESS}nala is already installed, skipping installation."
    return 0
  fi

  # Create temporary directory for downloads
  local tmp_dir
  tmp_dir=$(mktemp -d)
  local base_url="https://deb.volian.org/volian/pool/main/v/volian-archive/"

  # Buffer for error output
  local error_log
  error_log=$(mktemp)

  # Dynamically get the latest version
  echo -e "${GLYPH_EYE}Detecting latest nala version..."
  local version
  version=$(curl -sSfL "$base_url" 2>>"$error_log" | grep -o 'volian-archive-nala_[0-9]\+\.[0-9]\+\.[0-9]\+_all\.deb' | sed 's/volian-archive-nala_\([0-9]\+\.[0-9]\+\.[0-9]\+\)_all\.deb/\1/' | sort -V | tail -n1)

  if [[ -z "$version" ]]; then
    echo -e "${ERROR}Failed to detect nala version from ${base_url}"
    cat "$error_log" 2>/dev/null
    rm -rf "$tmp_dir" "$error_log"
    exit 1
  fi

  local archive="volian-archive-nala_${version}_all.deb"
  local keyring="volian-archive-keyring_${version}_all.deb"

  # Download packages with spinner
  echo -e "${INFO}Found nala version: ${version}"
  {
    curl -sSfL "${base_url}${archive}" -o "${tmp_dir}/${archive}" 2>>"$error_log" &&
    curl -sSfL "${base_url}${keyring}" -o "${tmp_dir}/${keyring}" 2>>"$error_log"
  } &
  local download_pid=$!
  spinner $download_pid "Downloading nala packages…"
  wait $download_pid
  local download_result=$?

  if [ $download_result -ne 0 ]; then
    echo -e "${ERROR}Failed to download nala packages:"
    cat "$error_log"
    rm -rf "$tmp_dir" "$error_log"
    exit 1
  fi

  # Install packages with spinner
  {
    sudo apt-get install -y "${tmp_dir}/${archive}" "${tmp_dir}/${keyring}" >/dev/null 2>>"$error_log" &&
    sudo apt-get update >/dev/null 2>>"$error_log" &&
    sudo apt-get install -y nala >/dev/null 2>>"$error_log"
  } &
  local install_pid=$!
  spinner $install_pid "Installing nala…"
  wait $install_pid
  local install_result=$?

  # Clean up temporary files
  rm -rf "$tmp_dir"

  if [ $install_result -ne 0 ]; then
    echo -e "${ERROR}Failed to install nala:"
    cat "$error_log"
    rm -f "$error_log"
    exit 1
  fi

  rm -f "$error_log"
  echo -e "${SUCCESS}nala package manager installed successfully."
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

# Install nala package manager first
install_nala

# Check for conflicting Ubuntu Nix packages and remove them
echo -e "${GLYPH_CHECK}Checking for conflicting Ubuntu packages..."
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
    sudo nala purge --assume-yes "${package}"
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

echo -e "${GLYPH_INSTALL}Installing essentials..."
sudo nala update
sudo nala install --assume-yes dconf-gsettings-backend fontconfig network-manager udisks2
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
