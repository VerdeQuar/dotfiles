{
  config,
  pkgs,
  lib,
  system,
  inputs,
  common,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.extraSpecialArgs = {inherit system inputs common;};

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.extraOptions = lib.mkIf (builtins.hasAttr "nix_access_tokens" config.sops.secrets) "!include ${config.sops.secrets.nix_access_tokens.path}";
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];

    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';

    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        devices = ["nodev"];
        efiSupport = true;
        theme =
          pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "grub";
            rev = "803c5df0e83aba61668777bb96d90ab8f6847106";
            hash = "sha256-/bSolCta8GCZ4lP0u5NVqYQ9Y3ZooYCNdTwORNvR7M0=";
          }
          + "/src/catppuccin-mocha-grub-theme";
      };
      timeout = 1;
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "01:00";
    randomizedDelaySec = "1h";
  };

  networking = {
    nameservers = ["127.0.0.1" "::1"];
    networkmanager.dns = "none";
    firewall.enable = false;
    networkmanager.enable = true;
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "pl2";
  };

  services = {
    prometheus = {
      enable = true;
      port = 9090;
      scrapeConfigs = [
        {
          job_name = "blocky";
          scrape_interval = "15s";
          # evaluation_interval = "15s";
          static_configs = [
            {
              targets = [
                "127.0.0.1:4000"
              ];
            }
          ];
        }
      ];
    };
    grafana = {
      enable = true;
      declarativePlugins = with pkgs.grafanaPlugins; [
        grafana-piechart-panel
      ];
      settings = {
        server = {
          # Listening Address
          http_addr = "127.0.0.1";
          # and Port
          http_port = 3000;
          # Grafana needs to know on which domain and URL it's running
          domain = "127.0.0.1";
          serve_from_sub_path = true;
        };
        panels = {
          disable_sanitize_html = true;
        };
      };
    };

    blocky = {
      enable = true;
      settings = {
        ports = {
          dns = "127.0.0.1:53";
          http = "127.0.0.1:4000";
        };
        upstream.default = [
          "https://one.one.one.one/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
        ];
        # For initially solving DoH/DoT Requests when no system Resolver is available.
        bootstrapDns = {
          upstream = "https://one.one.one.one/dns-query";
          ips = ["1.1.1.1" "1.0.0.1"];
        };
        prometheus = {
          enable = true;
        };
        #Enable Blocking of certian domains.
        blocking = {
          blackLists = {
            #Adblocking
            ads = [
              "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            ];
            #You can add additional categories
          };
          #Configure what block categories are used
          clientGroupsBlock = {
            default = ["ads"];
          };
        };
      };
    };
    printing = {
      enable = true;
      webInterface = false;
      drivers = [pkgs.gutenprint];
    };
    avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };

    system-config-printer.enable = true;

    blueman.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    dbus.enable = true;

    xserver.enable = true;
    xserver.displayManager = {
      defaultSession = "hyprland";
      sddm = {
        enable = true;
        wayland.enable = true;
        settings = {
          Theme = {
            CursorTheme = "${common.xcursor.theme.name}";
            CursorSize = "${toString (common.xcursor.theme.size * 1.25)}";
          };
          # Autologin = {
          #   Session = "hyprland";
          #   User = "verdek";
          # };
        };
        theme = "${pkgs.stdenv.mkDerivation {
          name = "catppuccin-mocha";
          src =
            pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "sddm";
              rev = "a13cf43fe05a6c463a7651eb2d96691a36637913";
              hash = "sha256-tyuwHt48cYqG5Pn9VHa4IB4xlybHOxPmhdN9eae36yo=";
            }
            + "/src/catppuccin-mocha";
          installPhase = ''
            mkdir -p $out
            cp -R ./* $out/
          '';
        }}";
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };
  hardware.sane.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security.rtkit.enable = true;
  #security.pki.certificateFiles = ["${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"];

  security.sudo.extraConfig = ''
    Defaults !tty_tickets
    Defaults timestamp_timeout=-1
  '';

  security.polkit.enable = true;

  sops = lib.mkIf (builtins.pathExists ../sops/key.txt) {
    age.keyFile = /home/verdek/.system/modules/sops/key.txt;
    age.generateKey = true;
    defaultSopsFile = ../sops/secrets.yaml;
    secrets.user_password.neededForUsers = true;
    secrets.nix_access_tokens.neededForUsers = true;
  };

  users.users.verdek = {
    isNormalUser = true;
    extraGroups = ["wheel" "realtime" "audio" "scanner" "lp"];
    shell = pkgs.nushell;
    hashedPasswordFile = lib.mkIf (builtins.hasAttr "user_password" config.sops.secrets) config.sops.secrets.user_password.path;
  };

  environment = {
    systemPackages = with pkgs; [
      home-manager
    ];
    binsh = "${pkgs.dash}/bin/dash";

    memoryAllocator.provider = "libc";
  };

  programs = {
    hyprland.enable = true;
    seahorse.enable = true;
    gamemode.enable = true;

    gnupg.agent = {
      enable = true;
      pinentryFlavor = "gnome3";
      # pinentryPackage = pkgs.pinentry-gnome3;
      enableSSHSupport = true;
    };

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        clang
        zlib
        zstd
        stdenv.cc.cc
        curl
        openssl
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        util-linux
        xz
        systemd
        libGL
        glibc
        openal
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXext
        xorg.libX11
        xorg.libXxf86vm
        xorg.libXrender
        xorg.libXtst
        xorg.libXi
        dbus.lib
        glib
      ];
    };
  };

  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "soft";
      value = "99999";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "hard";
      value = "524288";
    }
  ];
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
