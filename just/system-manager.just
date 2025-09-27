# Build system-manager configuration
[private]
build-system: _header _is_compatible _has_config
    @echo -e "{{GLYPH_BUILD}}Building {{BOLD}}system-manager{{RESET}} configuration..."
    @NOUGHTY_VERSION={{VERSION}} nom build {{NIX_OPTS}} ".#systemConfigs.default"
    @rm result 2> /dev/null || true

# Switch to system-manager configuration
[private]
switch-system: build-system
    @echo -e "{{GLYPH_SWITCH}}Switching to new {{BOLD}}system-manager{{RESET}} configuration..."
    @sudo env PATH="${PATH}" NOUGHTY_VERSION={{VERSION}} system-manager switch --flake '.#default' --nix-option pure-eval false 2> /dev/null
    @rm result 2> /dev/null || true
