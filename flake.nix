{
  description = "Home Manager (dotfiles) and NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nurpkgs.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private = {
      url = "github:VerdeQuar/empty-flake";
    };

    cargo2nix = {
      url = "github:cargo2nix/cargo2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors = {
      url = "github:Misterio77/nix-colors";
    };

    catppuccin-youtubemusic = {
      url = "github:catppuccin/youtubemusic";
      flake = false;
    };

    catppuccin-rofi = {
      url = "github:catppuccin/rofi";
      flake = false;
    };

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };

    crate-lolcrab = {
      url = "github:mazznoer/lolcrab";
      flake = false;
    };

    codeium-nvim = {
      url = "github:Exafunction/codeium.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aniwall = {
      url = "github:VerdeQuar/aniwall";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nurpkgs,
    home-manager,
    sops-nix,
    private,
    cargo2nix,
    aniwall,
    codeium-nvim,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
      overlays = [
        (final: prev: {
          python3 = prev.python3.override {
            packageOverrides = pfinal: pprev: {
              debugpy = pprev.debugpy.overrideAttrs (oldAttrs: {
                pytestCheckPhase = "true";
              });
            };
          };
          python3Packages = final.python3.pkgs;
        })
        (final: prev: {
          unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        })
        nurpkgs.overlay
        cargo2nix.overlays.default
        (final: prev: {
          lolcrab =
            prev.callPackage
            (pkgs.rustBuilder.makePackageSet {
              rustVersion = "latest";
              packageFun = import ./modules/crates/lolcrab.nix;
              workspaceSrc = inputs.crate-lolcrab;
            })
            .workspace
            .lolcrab {};
        })

        (final: prev: {
          vimPlugins =
            prev.vimPlugins
            // {
              codeium-nvim = codeium-nvim.packages.${system}.vimPlugins.codeium-nvim;
              codeium-lsp = codeium-nvim.packages.${system}.codeium-lsp;
            };
        })

        (final: prev: {
          aniwall = aniwall.packages.${system}.default;
        })
      ];
    };
    common = {
      xcursor.theme = {
        package = pkgs.catppuccin-cursors.mochaLavender;
        name = "Catppuccin-Mocha-Lavender-Cursors";
        size = 24;
      };
    };
  in {
    formatter.${system} = pkgs.alejandra;

    nixosConfigurations = {
      lapek = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {inherit system inputs common;};
        modules = [
          ./hosts/lapek/configuration.nix
        ];
      };
      pecet = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {inherit system inputs common;};
        modules = [
          ./hosts/pecet/configuration.nix
        ];
      };
    };
  };
}
