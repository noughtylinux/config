{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  meson,
  ninja,
  pkg-config,
  wayfire,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wf-info";
  version = "0.7.0-unstable-2025-04-28";

  src = fetchFromGitHub {
    owner = "soreau";
    repo = "wf-info";
    rev = "2d0127a484f332ffaf1c64a7be199f755d4f68a8";
    hash = "sha256-hp1HSef/jmp2SRck4OcfIut2lI7apOkYbw7/g4YY9nE=";
  };

  nativeBuildInputs = [
    cmake
    meson
    ninja
    pkg-config
  ];
  buildInputs = [
    wayfire
  ];

  #dontUseCmakeConfigure = true;
  #PKG_CONFIG_WAYFIRE_LIBDIR = "lib";
  #PKG_CONFIG_WAYFIRE_METADATADIR = "share/wayfire/metadata";

  meta = with lib; {
    homepage = "https://github.com/soreau/wf-info";
    description = "A simple wayfire plugin and program to get information from wayfire";
    license = licenses.mit;
    maintainers = with maintainers; [ flexiondotorg ];
    platforms = platforms.unix;
  };
})
