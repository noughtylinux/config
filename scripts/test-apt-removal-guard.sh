#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

printf '%s\n' \
    'Reading package lists...' \
    'Remv nix-bin [2.24.11-1]' \
    'Remv nix-setup-systemd:amd64 [2.24.11-1]' \
    > "${test_dir}/safe.txt"
"${script_dir}/check-apt-removal.sh" "${test_dir}/safe.txt"

printf '%s\n' \
    'Reading package lists...' \
    'Remv pollinate [4.33-3.1ubuntu1]' \
    'Remv ubuntu-server [1.539.2]' \
    'Remv ubuntu-server-minimal [1.539.2]' \
    'Remv openssh-server [1:9.6p1-3ubuntu13.14]' \
    > "${test_dir}/unsafe.txt"

if "${script_dir}/check-apt-removal.sh" "${test_dir}/unsafe.txt" 2> "${test_dir}/error.txt"; then
    printf 'guard accepted a protected removal transaction\n' >&2
    exit 1
fi

grep -Fq 'ubuntu-server' "${test_dir}/error.txt"
grep -Fq 'ubuntu-server-minimal' "${test_dir}/error.txt"
grep -Fq 'openssh-server' "${test_dir}/error.txt"

# Exercise package families and APT's optional architecture suffix. These are
# separate from the reproduced pollinate transaction so extending the policy
# cannot silently leave an important family untested.
for package in \
    apt dpkg sudo ubuntu-minimal ubuntu-standard \
    openssh-client:amd64 systemd-resolved netplan.io network-manager \
    libpam-runtime passwd login linux-image-generic linux-modules-extra-6.8.0 \
    linux-generic-hwe-24.04 grub2-common shim-signed init init-system-helpers; do
    printf 'Remv %s [test-version]\n' "${package}" > "${test_dir}/family.txt"
    if "${script_dir}/check-apt-removal.sh" "${test_dir}/family.txt" \
        2> "${test_dir}/family-error.txt"; then
        printf 'guard accepted protected package family member: %s\n' "${package}" >&2
        exit 1
    fi
    grep -Fq "${package%%:*}" "${test_dir}/family-error.txt"
done

printf 'APT removal guard tests passed.\n'
