#!/usr/bin/env bash

# Exit on error, undefined variable, and error in pipes
set -euo pipefail

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    echo "Usage: $(basename "${0}") <command> [args...]" >&2
    echo "Displays help output with syntax highlighting" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $(basename "${0}") ls" >&2
    echo "  $(basename "${0}") git status" >&2
    echo "  $(basename "${0}") nix-shell" >&2
    exit 1
fi

# Execute the command with --help and pipe through bat
"$@" --help 2>&1 | bat --language=help
