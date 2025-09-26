#!/usr/bin/env bash

# Exit on error, undefined variable, and error in pipes
set -euo pipefail

# Function to get the main program name from a Nixpkg
get_main_program() {
    local pkg="$1"
    local stable_nixpkgs

    # Get current stable nixpkgs channel using shared norm command
    stable_nixpkgs=$(norm 2>/dev/null || echo "nixos-unstable")

    # Use the detected stable release
    main_program=$(nix eval --impure github:nixos/nixpkgs/"$stable_nixpkgs"#"$pkg".meta.mainProgram --raw 2>/dev/null || echo "")

    if [ -n "$main_program" ] && [ "$main_program" != "null" ]; then
        echo "$main_program"
        return 0
    fi

    # Fallback 1: Try with lib.getExe
    exe_name=$(nix eval --impure --expr "
        let pkgs = (builtins.getFlake \"github:nixos/nixpkgs/$stable_nixpkgs\").legacyPackages.\${builtins.currentSystem};
        in builtins.baseNameOf (pkgs.lib.getExe pkgs.\"$pkg\")" --raw 2>/dev/null || echo "")

    if [ -n "$exe_name" ]; then
        echo "$exe_name"
        return 0
    fi

    # Fallback 2: Use package name as heuristic
    echo "$pkg"
}

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    echo "Usage: $(basename "${0}") package [args...]" >&2
    exit 1
fi

# Get the actual executable name from the package
PACKAGE_NAME="${1}"
shift
NOUT_COMMAND=$(get_main_program "${PACKAGE_NAME}")

# Get current stable nixpkgs channel using shared norm command
STABLE_NIXPKGS=$(norm 2>/dev/null || echo "nixos-unstable")

# Build the command string starting with 'nom shell'
cmd="nom shell --impure github:nixos/nixpkgs/${STABLE_NIXPKGS}#${PACKAGE_NAME} --command ${NOUT_COMMAND}"

# Add remaining arguments if any
if [ $# -gt 0 ]; then
    cmd="${cmd} $*"
fi

export NIXPKGS_ALLOW_UNFREE=1
exec ${cmd}
