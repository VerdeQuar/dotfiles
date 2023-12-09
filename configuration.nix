{
  config,
  pkgs,
  system,
  inputs,
  common,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot = {
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

  networking = {
    firewall.enable = false;
    hostName = "lapek";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "pl2";
  };

  services = {
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
    xserver = {
      enable = true;
      displayManager = {
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
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security.rtkit.enable = true;
  security.pki.certificateFiles = ["/etc/ssl/certs/ca-bundle.crt"];

  sops = {
    age.keyFile = ./key.txt;
    defaultSopsFile = ./secrets.yaml;
    secrets.user-password.neededForUsers = true;
  };

  users.users.verdek = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    shell = pkgs.nushell;
    hashedPasswordFile = config.sops.secrets.user-password.path;
  };

  environment = {
    systemPackages = with pkgs; [
      home-manager
    ];
    binsh = "${pkgs.dash}/bin/dash";
  };
  programs.hyprland.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
