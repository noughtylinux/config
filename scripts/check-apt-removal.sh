#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
    printf 'usage: %s APT-SIMULATION-OUTPUT\n' "$(basename -- "$0")" >&2
    exit 2
fi

protected=()
while read -r action package _; do
    [[ "${action}" == "Remv" ]] || continue
    package="${package%%:*}"
    case "${package}" in
        apt|dpkg|sudo|ubuntu-minimal|ubuntu-standard|ubuntu-server|ubuntu-server-minimal|\
        openssh-*|systemd|systemd-*|\
        netplan.io|network-manager|libpam-*|passwd|login|linux-image-*|linux-generic*|\
        linux-modules-*|grub-*|grub2-*|shim-*|init|init-system-helpers)
            protected+=("${package}")
            ;;
    esac
done < "$1"

if [[ ${#protected[@]} -gt 0 ]]; then
    printf 'protected package removal detected:\n' >&2
    printf '  %s\n' "${protected[@]}" >&2
    exit 1
fi
