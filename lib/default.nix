{
  inputs,
  outputs,
  noughtyConfig,
  ...
}:
let
  helpers = import ./helpers.nix {
    inherit
      inputs
      outputs
      noughtyConfig
      ;
  };
in
{
  inherit (helpers)
    mkHome
    forAllSystems
    ;
}
