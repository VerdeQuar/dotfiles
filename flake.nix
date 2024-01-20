{
  description = "Home Manager (dotfiles) and NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    nurpkgs.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    cargo2nix.url = "github:cargo2nix/cargo2nix";

    nix-colors.url = "github:Misterio77/nix-colors";

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

    codeium-nvim.url = "github:Exafunction/codeium.nvim";

    aniwall.url = "github:VerdeQuar/aniwall";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    nurpkgs,
    home-manager,
    sops-nix,
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
          stable = import nixpkgs-stable {
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
        inherit pkgs;
        specialArgs = {inherit system inputs common;};
        modules = [
          ./hosts/lapek/configuration.nix
        ];
      };
      pecet = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        specialArgs = {inherit system inputs common;};
        modules = [
          ./hosts/pecet/configuration.nix
        ];
      };
    };
  };
}
