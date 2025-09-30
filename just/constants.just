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
ERROR := RED + BOLD + '🗴 ' + RESET + RED + UNDERLINE + DIM + 'ERROR' + RESET + BOLD + ': ' + RESET
WARNING := YELLOW + '🛆 ' + DIM + 'WARNING' + RESET + BOLD + ': ' + RESET
SUCCESS := GREEN + BOLD + '🗸 ' + RESET + GREEN + DIM + 'SUCCESS' + RESET + BOLD + ': ' + RESET
INFO := BLUE + '🛈 ' + DIM + 'INFO' + RESET + BOLD + ': ' + RESET

# Glyphs
GLYPH_BUILD := BLUE + '☭ ' + RESET
GLYPH_CANCEL := MAGENTA + '⌧ ' + RESET
GLYPH_CONFIG := BLUE + '🖬 ' + RESET
GLYPH_DAMAGE := YELLOW + '🗲 ' + RESET
GLYPH_ERASE := MAGENTA + '⌦ ' + RESET
GLYPH_EYE := BLUE + '⏿ ' + RESET
GLYPH_FLAKE := BLUE + '❆ ' + RESET
GLYPH_FOLDER := BLUE + BOLD + '🗀 ' + RESET
GLYPH_FONT := BLUE + '🗚 ' + RESET
GLYPH_HOME := BLUE + BOLD + '⌂ ' + RESET
GLYPH_INSTALL := BLUE + '⮯ ' + RESET
GLYPH_KEY := YELLOW + '⚿ ' + RESET
GLYPH_NET := BLUE + '🖀 ' + RESET
GLYPH_PAINT := BLUE + '🌢 ' + RESET
GLYPH_SHELL := BLUE + '﹩ ' + RESET
GLYPH_SHIELD := BLUE + '⛨ ' + RESET
GLYPH_SWITCH := BLUE + '⤮ ' + RESET
GLYPH_SYSTEM := BLUE + '▣ ' + RESET
GLYPH_TARBALL := BLUE + '🞋 ' + RESET
GLYPH_TRANSFER := BLUE + '⮩ ' + RESET
GLYPH_UPDATE := BLUE + '♼ ' + RESET
GLYPH_USER := BLUE + '☻ ' + RESET
GLYPH_UPGRADE := CYAN + '⬈ ' + RESET

# Constants
NIX_OPTS := "--no-update-lock-file --impure"
STAMP := `date +%Y%m%d-%H%M`
VERSION := "0.0.0"
