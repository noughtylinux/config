#!/usr/bin/env bash

set +e  # Disable errexit
set +u  # Disable nounset
HOSTNAME=$(hostname -s)
IS_HYPRLAND=$(set | grep -q HYPRLAND_INSTANCE_SIGNATURE && echo "yes" || echo "no")
IS_WAYFIRE=$(set | grep -q WAYFIRE_SOCKET && echo "yes" || echo "no")

function session_start() {
  local LAYOUT=""
  LAYOUT="$(localectl | grep "X11 Layout" | cut -d':' -f2 | sed 's/ //g')"
  if [ -z "$LAYOUT" ]; then
    LAYOUT="gb"
  fi
  if [[ "${IS_HYPRLAND}" != "yes" ]]; then
    hyprctl keyword input:kb_layout "${LAYOUT}"
    dconf write /org/gnome/desktop/wm/preferences/button-layout "':appmenu'"
  fi

}

function session_stop() {
  playerctl --all-players pause
  if [[ "${IS_HYPRLAND}" == "yes" ]]; then
    hyprctl dispatch workspace 1 &>/dev/null
    hyprctl clients -j | jq -r ".[].address" | xargs -I {} sh -c 'hyprctl dispatch movetoworkspacesilent 1,"address:{}" &>/dev/null; sleep 0.1'
    hyprctl clients -j | jq -r ".[].address" | xargs -I {} sh -c 'hyprctl dispatch closewindow "address:{}" &>/dev/null; sleep 0.1'
  fi
}

OPT="help"
if [ -n "$1" ]; then
  OPT="$1"
fi

case "$OPT" in
    start) session_start;;
    lock)
        pkill -u "$USER" wlogout
        sleep 0.5
        if [[ "${IS_HYPRLAND}" == "yes" ]]; then
          hyprlock --immediate
        fi
        ;;
    logout)
        session_stop
        if [[ "${IS_HYPRLAND}" = "yes" ]]; then
          hyprctl dispatch exit
        elif [[ "${IS_WAYFIRE}" = "yes" ]]; then
          wayland-logout
        else
          wayland-logout
        fi
        ;;
    reboot)
        session_stop
        /run/current-system/sw/bin/systemctl reboot;;
    shutdown)
        session_stop
        /run/current-system/sw/bin/systemctl poweroff;;
    *) echo "Usage: $(basename "$0") {start|lock|logout|reboot|shutdown}";
        exit 1;;
esac
