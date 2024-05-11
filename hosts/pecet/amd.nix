{pkgs, ...}: {
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelParams = ["amdgpu.ppfeaturemask=0xfff7ffff"];

  systemd.services.amdgpu-undervolt = {
    description = "Undervolt AMD GPU";
    after = ["suspend.target" "multi-user.target" "systemd-user-sessions.service"];
    wantedBy = ["sleep.target" "multi-user.target"];
    wants = ["modprobe@amdgpu.service"];
    script = "${pkgs.writeShellScript "amdgpu_undervolt" ''
      ${pkgs.rocmPackages.rocm-smi}/bin/rocm-smi --setsrange 800 1800 --setvc 2 1800 1200 --autorespond y
      ${pkgs.fanctl}/bin/fanctl --config ${pkgs.writeText "fanctl.conf" ''
        interval: 1000
        log_interval: 300
        inputs:
          gpu_temp:
            HwmonSensor:
              hwmon: amdgpu
              label: junction
          gpu_mem_temp:
            HwmonSensor:
              hwmon: amdgpu
              label: mem
        outputs:
          gpu_fan:
            PwmFan:
              hwmon: amdgpu
              name: pwm1
        rules:
          - outputs:
              - gpu_fan
            rule:
              Maximum:
                - GateCritical:
                    input: gpu_temp
                    value: 1.0
                - Curve:
                    input: gpu_temp
                    keys:
                      - input: 0.0
                        output: 0.2
                      - input: 50.0
                        output: 0.6
                      - input: 60.0
                        output: 0.8
                      - input: 70.0
                        output: 1.0
                - GateStatic:
                    input: gpu_mem_temp
                    threshold: 65.0
                    value: 1.0
      ''}
    ''}";
    serviceConfig.Type = "simple";
    serviceConfig.Restart = "always";
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
}
