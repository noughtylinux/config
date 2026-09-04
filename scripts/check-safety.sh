#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ubuntu_recipe="${repo_root}/just/ubuntu.just"
wayfire_config="${repo_root}/home-manager/desktop/compositor/wayfire/default.nix"
session_script="${repo_root}/home-manager/scripts/wayland-session/wayland-session.sh"
bootstrap_script="${repo_root}/bootstrap.sh"
apt_guard="${repo_root}/scripts/check-apt-removal.sh"
flake_source_test="${repo_root}/scripts/test-local-flake-source.sh"
flake_file="${repo_root}/flake.nix"
system_config="${repo_root}/system-manager/default.nix"
justfile="${repo_root}/justfile"

fail() {
    printf 'safety check failed: %s\n' "$1" >&2
    exit 1
}

grep -Fq 'apt-get --simulate remove --purge' "${ubuntu_recipe}" \
    || fail 'Ubuntu removals are not simulated before activation'
grep -Fq 'Refusing package removal: the simulated transaction removes protected Ubuntu boundary packages.' "${ubuntu_recipe}" \
    || fail 'protected Ubuntu package transaction guard is missing'
for protected_pattern in ubuntu-server ubuntu-server-minimal 'openssh-*'; do
    grep -Fq "${protected_pattern}" "${apt_guard}" \
        || fail "protected package pattern is absent: ${protected_pattern}"
done

if grep -Eq 'system-manager-state\.json|jq .*managed.*sudo (rm|unlink)' "${ubuntu_recipe}"; then
    fail 'broad deletion of system-manager managed paths has returned'
fi

grep -Fq 'switch: build-system build-home ubuntu-pre switch-system switch-home ubuntu-post' "${justfile}" \
    || fail 'switch does not build both closures before Ubuntu preparation and activation'

grep -Fq 'DBUS_SESSION_BUS_ADDRESS="unix:path=${user_runtime_dir}/bus"' "${repo_root}/just/home-manager.just" \
    || fail 'Home Manager activation does not adopt the Ubuntu user D-Bus'
grep -Fq '/usr/bin/dbus-run-session' "${repo_root}/just/home-manager.just" \
    || fail 'Home Manager activation has no Ubuntu D-Bus fallback'
grep -Fq 'dbus-user-session dnsmasq-base' "${ubuntu_recipe}" \
    || fail 'Ubuntu user D-Bus package is missing from the system boundary'

if grep -Eq 'deb\.volian\.org|install-nala|sudo nala' "${ubuntu_recipe}"; then
    fail 'external Nala bootstrap is still present'
fi

if grep -Eq 'deb\.volian\.org|install_nala|sudo nala' "${bootstrap_script}"; then
    fail 'bootstrap still depends on an external Nala repository or command'
fi
grep -Fq 'NOUGHTYLINUX_SOURCE' "${bootstrap_script}" \
    || fail 'bootstrap cannot consume a local config checkout'
grep -Fq 'Continuing with the previously staged local source' "${bootstrap_script}" \
    || fail 'bootstrap cannot resume after a failed local-source run'
grep -Fq 'apt-get --simulate remove --purge' "${bootstrap_script}" \
    || fail 'bootstrap conflict removal is not simulated'
grep -Fq 'scripts/check-apt-removal.sh' "${ubuntu_recipe}" \
    || fail 'Ubuntu update path does not use the shared APT removal guard'
for protected_pattern in ubuntu-server ubuntu-server-minimal 'openssh-*'; do
    grep -Fq "${protected_pattern}" "${bootstrap_script}" \
        || fail "standalone bootstrap protected pattern is absent: ${protected_pattern}"
done

"${flake_source_test}"

if grep -Fq '/run/current-system/sw/bin/systemctl' "${session_script}"; then
    fail 'NixOS-only systemctl path is present in the Ubuntu session helper'
fi

if grep -Fq '../components/hyprpaper' "${wayfire_config}"; then
    fail 'Wayfire still imports the Hyprland wallpaper service'
fi

grep -Eq 'software-properties-common swaylock udisks2' "${ubuntu_recipe}" \
    || fail 'Ubuntu swaylock package is missing from the system boundary'
grep -Fq '/usr/bin/swaylock --daemonize' "${session_script}" \
    || fail 'Wayfire is not using Ubuntu swaylock for PAM authentication'

if grep -Fq 'inputs.determinate.packages' "${flake_file}" \
    || grep -Fq 'inputs.determinate.packages' "${system_config}"; then
    fail 'Determinate Nix is duplicated inside a Nix-managed package closure'
fi

printf 'NoughtyLinux safety checks passed.\n'
