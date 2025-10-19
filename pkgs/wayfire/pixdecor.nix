{
  stdenv,
  lib,
  fetchFromGitHub,
  unstableGitUpdater,
  meson,
  ninja,
  pkg-config,
  wayfire,
  libinput,
  libxkbcommon,
  libGL,
  xcbutilwm,
  glm,
  libdrm,
  vulkan-headers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pixdecor";
  version = "0.11.0-unstable-2025-10-13";
  #version = "0.9.0-unstable-2025-09-02";

  src = fetchFromGitHub {
    owner = "soreau";
    repo = "pixdecor";
    # 0.11.0
    rev = "4893c7362d1b9b90b1208504579bc5b9618eceb5";
    hash = "sha256-+NvnG8tYc0M5zdxaI375+gqeWWWePyqPp+njI07ooXM=";
    # 0.9.0
    #rev = "fd86578f6e888497e8fee679bb3acd7fefbc572a";
    #hash = "sha256-JfdHP8x8hf8PvYF/q75m5dt9p9EqeZUxJJBVKFK/dcw=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  dontWrapGApps = true;

  buildInputs = [
    libGL
    libinput
    libxkbcommon
    wayfire
    xcbutilwm
    glm
    libdrm
    vulkan-headers
  ];

  postPatch = ''
    substituteInPlace meson.build \
      --replace-fail ">=0.11.0" ">=0.10.0"
    substituteInPlace metadata/meson.build \
      --replace-fail "wayfire.get_variable( pkgconfig: 'metadatadir' )" "join_paths(get_option('prefix'), 'share/wayfire/metadata')"
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/soreau/pixdecor";
    description = "A highly configurable decorator plugin for wayfire,";
    longDescription = "pixdecor features antialiased rounded corners with shadows and optional animated effects.";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ flexiondotorg ];
    inherit (wayfire.meta) platforms;
  };
})
