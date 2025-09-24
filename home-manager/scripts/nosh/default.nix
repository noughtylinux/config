{
  noughtyConfig,
  pkgs,
  ...
}:
let
  name = builtins.baseNameOf (builtins.toString ./.);
  # Get the shell executable name, fallback to fish if not set
  noshShell = noughtyConfig.terminal.shell or "bash";
  shellApplication = pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = with pkgs; [
      coreutils
      nix-output-monitor
    ];
    text = ''
      export NOSH_SHELL="${noshShell}"
      ${builtins.readFile ./${name}.sh}
    '';
  };
in
{
  home.packages = [ shellApplication ];
}
