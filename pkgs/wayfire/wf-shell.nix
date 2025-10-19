{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  wayfire,
  wf-config,
  alsa-lib,
  gtkmm3,
  gtk-layer-shell,
  libpulseaudio,
  wayland,
  wayland-protocols,
  libdbusmenu-gtk3,
  wayland-scanner,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wf-shell";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wf-shell";
    rev = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-PLTeFGecxVwU2LdwnDwiWB1OcbaZjJemMpT0pcCFf/w=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland-scanner
    cmake
  ];

  buildInputs = [
    wayfire
    wf-config
    alsa-lib
    gtkmm3
    gtk-layer-shell
    libpulseaudio
    wayland
    wayland-protocols
    libdbusmenu-gtk3
  ];

  meta = {
    homepage = "https://github.com/WayfireWM/wf-shell";
    description = "GTK3-based panel for Wayfire";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      wucke13
    ];
    platforms = lib.platforms.unix;
  };
})
