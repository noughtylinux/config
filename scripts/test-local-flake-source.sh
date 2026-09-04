#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
    printf 'local flake source test failed: %s\n' "$1" >&2
    exit 1
}

# config.toml is intentionally machine-local and ignored by Git. Commands that
# use the implicit Git flake source therefore omit it; every build and switch
# entry point must force a path source.
git -C "${repo_root}" check-ignore -q config.toml \
    || fail 'config.toml is no longer ignored; revisit the source-boundary test'

grep -Fq '"path:.#systemConfigs.default"' "${repo_root}/just/system-manager.just" \
    || fail 'system-manager build does not use the local path source'
grep -Fq -- "--flake 'path:.#default'" "${repo_root}/just/system-manager.just" \
    || fail 'system-manager switch does not use the local path source'
grep -Fq '"path:.#homeConfigurations.' "${repo_root}/just/home-manager.just" \
    || fail 'Home Manager build does not use the local path source'
grep -Fq 'flake "path:.#' "${repo_root}/just/home-manager.just" \
    || fail 'Home Manager switch does not use the local path source'

printf 'Local config flake-source wiring tests passed.\n'
