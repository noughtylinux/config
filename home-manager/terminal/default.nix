{
  pkgs,
  lib,
  ...
}:
let
  shellAliases = {
    banner = "${pkgs.figlet}/bin/figlet";
    banner-color = "${pkgs.figlet}/bin/figlet $argv | ${pkgs.dotacat}/bin/dotacat";
    clock = ''${pkgs.tty-clock}/bin/tty-clock -B -c -C 4 -f "%a, %d %b"'';
    dadjoke = ''${pkgs.curlMinimal}/bin/curl --header "Accept: text/plain" https://icanhazdadjoke.com/'';
    dmesg = "${pkgs.util-linux}/bin/dmesg --human --color=always";
    glow = "${pkgs.frogmouth}/bin/frogmouth";
    hr = ''${pkgs.hr}/bin/hr "─━"'';
    ip = "${pkgs.iproute2}/bin/ip --color --brief";
    lolcat = "${pkgs.dotacat}/bin/dotacat";
    lsusb = "${pkgs.cyme}/bin/cyme --headings";
    moon = "${pkgs.curlMinimal}/bin/curl -s wttr.in/Moon";
    rsync-copy = "${pkgs.rsync}/bin/rsync --archive --block-size=131072 --human-readable --info=progress2 --inplace --no-compress --partial --stats";
    rsync-mirror = "${pkgs.rsync}/bin/rsync --archive --block-size=131072 --delete --human-readable --info=progress2 --no-compress --inplace --partial --stats";
    ruler = ''${pkgs.hr}/bin/hr "╭─³⁴⁵⁶⁷⁸─╮"'';
    speedtest = "${pkgs.speedtest-go}/bin/speedtest-go";
    wormhole = "${pkgs.wormhole-rs}/bin/wormhole-rs";
    weather = "${lib.getExe pkgs.girouette} --quiet";
  };
in
{
  imports = [
    ./atuin.nix
    ./bat.nix
    ./bottom.nix
    ./btop.nix
    ./cava.nix
    ./dircolors.nix
    ./direnv.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./fzf.nix
    ./gh.nix
    ./git.nix
    ./gpg.nix
    ./jq.nix
    ./micro.nix
    ./pueue.nix
    ./rclone.nix
    ./ripgrep.nix
    ./starship.nix
    ./tldr.nix
    ./yazi.nix
    ./yt-dlp.nix
    ./zoxide.nix
  ];
  home = {
    packages = with pkgs; [
      bc # Terminal calculator
      bandwhich # Modern Unix `iftop`
      batmon # Terminal battery monitor
      bmon # Modern Unix `iftop`
      croc # Terminal file transfer
      cyme # Modern Unix `lsusb`
      dconf2nix # Nix code from Dconf files
      dogdns # Modern Unix `dig`
      dotacat # Modern Unix lolcat
      dua # Modern Unix `du`
      duf # Modern Unix `df`
      du-dust # Modern Unix `du`
      entr # Modern Unix `watch`
      figlet # Terminal ASCII banners
      file # Terminal file info
      frogmouth # Terminal markdown viewer
      fselect # Modern Unix find with SQL-like syntax
      girouette # Modern Unix weather
      gocryptfs # Terminal encrypted filesystem
      gping # Modern Unix `ping`
      hexyl # Modern Unix `hexedit`
      hr # Terminal horizontal rule
      hyperfine # Terminal benchmarking
      iperf3 # Terminal network benchmarking
      iw # Terminal WiFi info
      jpegoptim # Terminal JPEG optimizer
      lima-bin # Terminal VM manager
      lurk # Modern Unix `strace`
      magic-wormhole-rs # Terminal file transfer
      marp-cli # Terminal Markdown presenter
      mprocs # Terminal parallel process runner
      mtr # Modern Unix `traceroute`
      netdiscover # Modern Unix `arp`
      optipng # Terminal PNG optimizer
      pciutils # Terminal PCI info
      presenterm # Terminal Markdown presenter
      procs # Modern Unix `ps`
      psmisc # Traditional `ps`
      rsync # Traditional `rsync`
      s-tui # Terminal CPU stress test
      sd # Modern Unix `sed`
      speedtest-go # Terminal speedtest.net
      stress-ng # Terminal CPU stress test
      timer # Terminal timer
      tty-clock # Terminal clock
      unzip # Terminal ZIP extractor
      upterm # Terminal sharing
      usbutils # Terminal USB info
      vhs # Terminal GIF recorder
      wavemon # Terminal WiFi monitor
      wget # Terminal HTTP client
      wget2 # Terminal HTTP client
      writedisk # Modern Unix `dd`
      xh # Terminal HTTP client
      yq-go # Terminal `jq` for YAML
    ];
  };

  programs = {
    bash.shellAliases = shellAliases;
    fish.shellAliases = shellAliases;
    zsh.shellAliases = shellAliases;
  };
}
