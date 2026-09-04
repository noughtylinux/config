#!/usr/bin/env bash
set -eu -o pipefail

NOUGHTYLINUX_DIR="${NOUGHTYLINUX_DIR:-${HOME}/NoughtyLinux}"
NOUGHTYLINUX_REPOSITORY="${NOUGHTYLINUX_REPOSITORY:-https://github.com/noughtylinux/config}"
NOUGHTYLINUX_REF="${NOUGHTYLINUX_REF:-}"
NOUGHTYLINUX_SOURCE="${NOUGHTYLINUX_SOURCE:-}"

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
GLYPH_EYE="${CYAN}⏿ ${RESET}"
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

function get_login_def() {
  # Extract specified value from /etc/login.defs, with fallback default
  local key="$1"
  local default="${2:-60000}"
  local value
  value=$(grep -E "^${key}" /etc/login.defs 2>/dev/null | awk '{print $2}')
  echo "${value:-$default}"
}

function apt_simulation_crosses_ubuntu_boundary() {
  local simulation="$1"
  local action package
  while read -r action package _; do
    [[ "${action}" == "Remv" ]] || continue
    package="${package%%:*}"
    case "${package}" in
      apt|dpkg|sudo|ubuntu-server|ubuntu-server-minimal|openssh-*|systemd|systemd-*|\
      netplan.io|network-manager|libpam-*|passwd|login|linux-image-*|linux-generic*|\
      grub-*|shim-*|init|init-system-helpers)
        printf '  %s\n' "${package}" >&2
        return 0
        ;;
    esac
  done < "${simulation}"
  return 1
}

function install_determinate_nix() {
  echo -e "${GLYPH_NIX}Installing Determinate Nix..."

  # Calculate UID and GID bases from system configuration
  local uid_base=$(($(get_login_def "UID_MAX") + 1))
  local gid_base=$(($(get_login_def "GID_MAX") + 1))

  curl -sSfL https://install.determinate.systems/nix | sh -s -- install \
    --determinate --no-confirm \
    --nix-build-user-id-base "${uid_base}" \
    --nix-build-group-id "${gid_base}"
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
  simulation=$(mktemp)
  trap 'rm -f "$simulation"' EXIT
  sudo apt-get --simulate remove --purge "${conflicting_packages[@]}" | tee "$simulation"
  if apt_simulation_crosses_ubuntu_boundary "$simulation"; then
    echo -e "${ERROR}Refusing to remove Ubuntu Nix packages because the simulated transaction crosses the protected Ubuntu boundary."
    exit 1
  fi
  sudo env DEBIAN_FRONTEND=noninteractive apt-get remove --purge --yes "${conflicting_packages[@]}"

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

# Clone the repository if it doesn't exist
if [[ -e "${NOUGHTYLINUX_DIR}/config.toml" ]]; then
  echo -e "${INFO}Directory ${NOUGHTYLINUX_DIR} appears to exist and is bootstrapped."
elif [[ -n "${NOUGHTYLINUX_SOURCE}" && -f "${NOUGHTYLINUX_DIR}/flake.nix" && -f "${NOUGHTYLINUX_DIR}/justfile" ]]; then
  echo -e "${INFO}Continuing with the previously staged local source in ${NOUGHTYLINUX_DIR}."
elif [[ "$(basename $0)" == "noughty-bootstrap.sh" ]] && [[ -e "${NOUGHTYLINUX_DIR}/justfile" ]]; then
  echo -e "${INFO}Directory ${NOUGHTYLINUX_DIR} exists and we appear to be bootstrapping remotely."
elif [[ -d "${NOUGHTYLINUX_DIR}/.git" ]] && [[ -f "${NOUGHTYLINUX_DIR}/.git/config" ]]; then
  echo -e "${INFO}Directory ${NOUGHTYLINUX_DIR} appears to be a git repository. Pulling latest changes..."
  pushd "${NOUGHTYLINUX_DIR}" 1>/dev/null
    nix shell nixpkgs#git --command git pull --rebase
  popd 1>/dev/null
else
  if [[ -n "${NOUGHTYLINUX_SOURCE}" ]]; then
    if [[ ! -f "${NOUGHTYLINUX_SOURCE}/flake.nix" || ! -f "${NOUGHTYLINUX_SOURCE}/justfile" ]]; then
      echo -e "${ERROR}NOUGHTYLINUX_SOURCE is not a Nøughty Linux config checkout: ${NOUGHTYLINUX_SOURCE}"
      exit 1
    fi
    if [[ -e "${NOUGHTYLINUX_DIR}" ]]; then
      echo -e "${ERROR}Refusing to copy local source over existing path: ${NOUGHTYLINUX_DIR}"
      exit 1
    fi
    echo -e "${INFO}Copying local Nøughty Linux source from ${NOUGHTYLINUX_SOURCE}..."
    mkdir -p "${NOUGHTYLINUX_DIR}"
    cp -a "${NOUGHTYLINUX_SOURCE}/." "${NOUGHTYLINUX_DIR}/"
  else
    echo -e "${INFO}Cloning Nøughty Linux configuration from ${NOUGHTYLINUX_REPOSITORY} into ${NOUGHTYLINUX_DIR}..."
    clone_args=(clone)
    if [[ -n "${NOUGHTYLINUX_REF}" ]]; then
      clone_args+=(--branch "${NOUGHTYLINUX_REF}" --single-branch)
    fi
    clone_args+=("${NOUGHTYLINUX_REPOSITORY}" "${NOUGHTYLINUX_DIR}")
    nix shell nixpkgs#git --command git "${clone_args[@]}"
  fi
fi

# Generate the initial configuration when needed, then always converge the
# machine.  A previous switch may have failed after creating config.toml, so
# its presence alone is not evidence of a completed bootstrap.
pushd "${NOUGHTYLINUX_DIR}" 1>/dev/null
  if [[ ! -f "config.toml" ]]; then
    nix develop --no-update-lock-file --impure --command just generate
  fi
  nix develop --no-update-lock-file --impure --command just switch
popd 1>/dev/null
