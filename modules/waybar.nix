{pkgs, ...}: {
  style = ''
    * {
      border: none;
      border-radius: 0;
      min-height: 0;
      font-family: Material Design Icons, JetBrainsMono Nerd Font;
      font-size: 13px;
    }

    window#waybar {
      background-color: #181825;
      transition-property: background-color;
      transition-duration: 0.5s;
    }

    window#waybar.hidden {
      opacity: 0.5;
    }

    #workspaces {
      background-color: transparent;
    }

    #workspaces button {
      all: initial; /* Remove GTK theme values (waybar #1351) */
      min-width: 0; /* Fix weird spacing in materia (waybar #450) */
      box-shadow: inset 0 -3px transparent; /* Use box-shadow instead of border so the text isn't offset */
      padding: 6px 18px;
      margin: 6px 3px;
      border-radius: 4px;
      background-color: #1e1e2e;
      color: #cdd6f4;
    }

    #workspaces button.active {
      color: #1e1e2e;
      background-color: #cdd6f4;
    }

    #workspaces button:hover {
     box-shadow: inherit;
     text-shadow: inherit;
     color: #1e1e2e;
     background-color: #cdd6f4;
    }

    #workspaces button.urgent {
      background-color: #f38ba8;
    }

    #memory,
    #custom-power,
    #battery,
    #backlight,
    #pulseaudio,
    #network,
    #clock,
    #tray {
      border-radius: 4px;
      margin: 6px 3px;
      padding: 6px 12px;
      background-color: #1e1e2e;
      color: #181825;
    }

    #custom-power {
      margin-right: 6px;
    }

    #custom-logo {
      padding-right: 7px;
      padding-left: 7px;
      margin-left: 5px;
      font-size: 15px;
      border-radius: 8px 0px 0px 8px;
      color: #1793d1;
    }

    #memory {
      background-color: #fab387;
    }
    #battery {
      background-color: #f38ba8;
    }
    @keyframes blink {
      to {
        background-color: #f38ba8;
        color: #181825;
      }
    }

    #battery.warning,
    #battery.critical,
    #battery.urgent {
      background-color: #ff0048;
      color: #181825;
      animation-name: blink;
      animation-duration: 0.5s;
      animation-timing-function: linear;
      animation-iteration-count: infinite;
      animation-direction: alternate;
    }
    #battery.charging {
      background-color: #a6e3a1;
    }

    #backlight {
      background-color: #fab387;
    }

    #pulseaudio {
      background-color: #f9e2af;
    }

    #network {
      background-color: #94e2d5;
      padding-right: 17px;
    }

    #clock {
      font-family: JetBrainsMono Nerd Font;
      background-color: #cba6f7;
    }

    #custom-power {
      background-color: #f2cdcd;
    }


    tooltip {
    border-radius: 8px;
    padding: 15px;
    background-color: #131822;
    }

    tooltip label {
    padding: 5px;
    background-color: #131822;
    }
  '';
  settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      modules-left = ["hyprland/workspaces"];
      modules-center = ["hyprland/window"];
      modules-right = ["tray" "clock" "pipewire" "battery"];
    };
  };
}
