{config, ...}: {
  imports = [
    ../../modules/home-manager/home.nix
  ];

  wayland.windowManager.hyprland = {
    settings = {
      monitor = ",highres,auto,1.25";
      bind = [
        "Control, Tab, exec, rofi -show drun"
      ];
      bindl = [
        ",switch:on:Lid Switch,exec,hyprctl keyword monitor 'eDP-1${config.wayland.windowManager.hyprland.settings.monitor}'"
        ",switch:off:Lid Switch,exec,hyprctl keyword monitor 'eDP-1, disable'"
      ];
    };
  };
}
