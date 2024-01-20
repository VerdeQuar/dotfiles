{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/configuration.nix
  ];

  home-manager.users = {
    verdek = import ./home.nix;
  };

  boot.initrd.kernelModules = ["amdgpu"];

  hardware.fancontrol = {
    enable = true;
    config = ''
      INTERVAL=10
      DEVPATH=hwmon0=devices/pci0000:00/0000:00:03.2/0000:0e:00.0/0000:0f:00.0/0000:10:00.0
      DEVNAME=hwmon0=amdgpu
      FCTEMPS=hwmon0/pwm1=hwmon0/temp1_input
      FCFANS= hwmon0/pwm1=
      MINTEMP=hwmon0/pwm1=20
      MAXTEMP=hwmon0/pwm1=80
      MINSTART=hwmon0/pwm1=80
      MINSTOP=hwmon0/pwm1=80
      MINPWM=hwmon0/pwm1=80
      MAXPWM=hwmon0/pwm1=230
    '';
  };

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware.opengl.extraPackages = with pkgs; [
    rocmPackages.clr
    rocmPackages.clr.icd
  ];

  services.xserver.videoDrivers = ["modesetting"];

  environment.systemPackages = with pkgs; [
    vulkan-tools
    vulkan-headers
    vulkan-loader
    vulkan-validation-layers
  ];

  networking.hostName = "pecet";

  environment.etc = let
    json = pkgs.formats.json {};
    quantum = "768";
  in {
    "pipewire/pipewire.conf.d/92-low-latency.conf".text = ''
      context.properties = {
        default.clock.rate = 192000
      }
    '';
    # default.clock.quantum = ${quantum}
    # default.clock.min-quantum = ${quantum}
    # default.clock.max-quantum = ${quantum}
    # default.clock.allowed-rates = [ 192000 96000 48000 44100 ]
    # "pipewire/pipewire-pulse.d/92-low-latency.conf".source = json.generate "92-low-latency.conf" {
    #   context.modules = [
    #     {
    #       name = "libpipewire-module-protocol-pulse";
    #       args = {
    #         pulse.min.req = "${quantum}/192000";
    #         pulse.default.req = "${quantum}/192000";
    #         pulse.max.req = "${quantum}/192000";
    #         pulse.min.quantum = "${quantum}/192000";
    #         pulse.max.quantum = "${quantum}/192000";
    #       };
    #     }
    #   ];
    #   stream.properties = {
    #     node.latency = "${quantum}/192000";
    #     resample.quality = 1;
    #   };
    # };
  };
}
