{config, ...}: {
  imports = [
    ../../modules/home-manager/home.nix
  ];

  wayland.windowManager.hyprland = {
    settings = {
      monitor = ",highres,auto,1";

      bind = [
        "SUPER, Tab, exec, rofi -show drun"
        ",mouse:276,workspace,+1"
        ",mouse:275,workspace,-1"
      ];
    };
  };
}
