{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  wayfire,
  wayland-scanner,
  wf-config,
  libevdev,
  libinput,
  libxkbcommon,
  xcbutilwm,
  gtkmm3,
  boost,
  libdrm,
  vulkan-headers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wayfire-plugins-extra";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wayfire-plugins-extra";
    rev = "v${finalAttrs.version}";
    hash = "sha256-0cAPaj5PmGgX/Q0mkdsyjZTQ5JBPrnvB2EnLj89v13g=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    wayfire
    wf-config
    libevdev
    libinput
    libxkbcommon
    xcbutilwm
    gtkmm3
    boost
    libdrm
    vulkan-headers
  ];

  mesonFlags = [
    # plugins in submodule, packaged individually
    (lib.mesonBool "enable_pixdecor" false)
    (lib.mesonBool "enable_wayfire_shadows" false)
    (lib.mesonBool "enable_focus_request" false)
  ];

  env = {
    PKG_CONFIG_WAYFIRE_METADATADIR = "${placeholder "out"}/share/wayfire/metadata";
  };

  meta = {
    homepage = "https://github.com/WayfireWM/wayfire-plugins-extra";
    description = "Additional plugins for Wayfire";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ wineee ];
    inherit (wayfire.meta) platforms;
  };
})
