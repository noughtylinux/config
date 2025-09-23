{
  config,
  pkgs,
  ...
}:
let
  gitsignCredentialCache = "${config.xdg.cacheHome}/sigstore/gitsign/cache.sock";
  shellAliases = {
    gitso = "${pkgs.git}/bin/git --signoff";
  };
in
{
  catppuccin = {
    delta.enable = config.programs.git.delta.enable;
    gitui.enable = config.programs.gitui.enable;
  };

  home = {
    file = {
      # Symlink ~/.gitconfig to ~/.config/git/config to prevent config divergence
      ".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/git/config";
    };
    packages = with pkgs; [
      git-igitt # git log/graph
      gitsign # Sign Git commits and tags with Sigstore
      pre-commit # Git pre-commit hooks
    ];
    sessionVariables = {
      GITSIGN_CONNECTOR_ID = "https://accounts.google.com";
      GITSIGN_CREDENTIAL_CACHE = "${gitsignCredentialCache}";
    };
  };

  programs = {
    bash = {
      inherit shellAliases;
    };
    fish = {
      inherit shellAliases;
    };
    git = {
      enable = true;
      aliases = {
        ci = "commit";
        cl = "clone";
        co = "checkout";
        puff = "pull --ff-only";
        purr = "pull --rebase";
        fucked = "reset --hard";
        graph = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
      delta = {
        enable = true;
        options = {
          hyperlinks = true;
          line-numbers = true;
          side-by-side = true;
        };
      };
      extraConfig = {
        advice = {
          statusHints = false;
        };
        diff = {
          colorMoved = "default";
        };
        push = {
          default = "matching";
        };
        pull = {
          rebase = false;
        };
        init = {
          defaultBranch = "main";
        };
      };
      ignores = [
        "*.log"
        "*.out"
        ".DS_Store"
        "bin/"
        "dist/"
        "direnv*"
        "result*"
      ];
    };
    gitui = {
      enable = true;
    };
    zsh = {
      inherit shellAliases;
    };
  };

  systemd.user = {
    services.gitsign-credential-cache = {
      Unit = {
        Description = "GitSign credential cache";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.gitsign}/bin/gitsign-credential-cache";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    sockets.gitsign-credential-cache = {
      Unit = {
        Description = "GitSign credential cache socket";
      };
      Socket = {
        ListenStream = "${gitsignCredentialCache}";
        DirectoryMode = "0700";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Enable and start the socket by default
    targets.gitsign-credential-cache = {
      Unit = {
        Description = "Start gitsign-credential-cache socket";
        Requires = [ "gitsign-credential-cache.socket" ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
