{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/configuration.nix
    # ./amd.nix
    ./nvidia.nix
  ];

  home-manager.users = {
    verdek = import ./home.nix;
    root = {
      config,
      inputs,
      ...
    }: {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
      ];

      home.username = "root";
      home.homeDirectory = "/root";

      home.stateVersion = "23.11";

      sops = {
        age.keyFile = "/home/verdek/.config/sops/age/keys.txt";
        age.generateKey = true;
        defaultSopsFile = ../../modules/sops/secrets.yaml;
        secrets = {
          id_ed25519 = {
            path = "${config.home.homeDirectory}/.ssh/id_ed25519";
          };
          id_ed25519_pub = {
            path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
          };
        };
      };
    };
  };

  networking.hostName = "pecet";

  environment.etc = {
    "/etc/pipewire/pipewire.conf.d/92-low-latency.conf".text = ''
      context.properties = {
        ["default.clock.rate"] = 192000,
      }
    '';
  };
}
