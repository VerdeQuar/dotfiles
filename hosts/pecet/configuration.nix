{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/configuration.nix
    # ./amd.nix
    ./nvidia.nix
  ];

  home-manager.users = {
    verdek = import ./home.nix;
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
