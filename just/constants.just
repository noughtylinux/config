# Colours
BLACK := '\033[30m'
RED := '\033[31m'
GREEN := '\033[32m'
YELLOW := '\033[33m'
BLUE := '\033[34m'
MAGENTA := '\033[35m'
CYAN := '\033[36m'
WHITE := '\033[37m'

# Formatting
RESET := '\033[0m'
BOLD := '\033[1m'
DIM := '\033[2m'
ITALIC := '\033[3m'
UNDERLINE := '\033[4m'
BLINK := '\033[5m'
REVERSE := '\033[7m'
HIDDEN := '\033[8m'
STRIKETHROUGH := '\033[9m'

# Status messages
ERROR := RED + '✘ ' + UNDERLINE + DIM + 'ERROR' + RESET + BOLD + ': ' + RESET
WARNING := YELLOW + '🛆 ' + DIM + 'WARNING' + RESET + BOLD + ': ' + RESET
SUCCESS := GREEN + '✔ ' + DIM + 'SUCCESS' + RESET + BOLD + ': ' + RESET

# Glyphs
GLYPH_CANCEL := MAGENTA + '⊘ ' + RESET
GLYPH_CONFIG := BLUE + '✦ ' + RESET
GLYPH_FLAKE := BLUE + '❆ ' + RESET
GLYPH_FONT := BLUE + '🗚 ' + RESET
GLYPH_HOME := BLUE + '≋ ' + RESET
GLYPH_NET := BLUE + '🖧 ' + RESET
GLYPH_SHELL := BLUE + '﹩ ' + RESET
GLYPH_SYSTEM := BLUE + '▣ ' + RESET
GLYPH_TARBALL := BLUE + '🞋 ' + RESET
GLYPH_TRANSFER := BLUE + '➲ ' + RESET
GLYPH_UPDATE := BLUE + '⇩ ' + RESET
GLYPH_USER := BLUE + '☻ ' + RESET

# Constants
NIX_OPTS := "--no-update-lock-file --impure"
STAMP := `date +%Y%m%d-%H%M`
VERSION := "0.0.0"
