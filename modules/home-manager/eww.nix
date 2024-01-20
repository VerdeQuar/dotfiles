{pkgs, ...}: {
  home.packages = [pkgs.eww-wayland];

  wayland.windowManager.hyprland.settings.exec-once = ["eww open bar"];

  xdg.configFile = {
    "eww/eww.yuck".text =
      /*
      yuck
      */
      ''
        (deflisten window :initial "" "bash ${pkgs.writeShellScript "get-window-title"
          /*
          bash
          */
          ''
            hyprctl activewindow -j | nix run nixpkgs#jq -- --raw-output '.title | select(. != null)'
            nix run nixpkgs#socat -- -u UNIX-CONNECT:/tmp/hypr/''$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | stdbuf -o0 grep '^activewindow>>' | stdbuf -o0 awk -F '>>|,' '{print ''$3}'
          ''}")
        (deflisten workspaces :initial "[]" "bash ${pkgs.writeShellScript "get-workspaces"
          /*
          bash
          */
          ''
            spaces (){
              WORKSPACE_WINDOWS=''$(hyprctl workspaces -j | nix run nixpkgs#jq -- 'map({key: .id | tostring, value: .windows}) | from_entries')
              nix-shell -p coreutils
              seq -- 1 10 | nix run nixpkgs#jq -- --argjson windows "''${WORKSPACE_WINDOWS}" --slurp -Mc 'map(tostring) | map({id: ., windows: (''$windows[.]//0)})'
            }

            spaces
            nix run nixpkgs#socat -- -u UNIX-CONNECT:/tmp/hypr/''$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
              spaces
            done
          ''}")
        (deflisten current_workspace :initial "1" "bash ${pkgs.writeShellScript "get-active-workspace"
          /*
          bash
          */
          ''
            hyprctl monitors -j | nix run nixpkgs#jq -- --raw-output .[0].activeWorkspace.id
            nix run nixpkgs#socat -- -u UNIX-CONNECT:/tmp/hypr/''$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | stdbuf -o0 grep '^workspace>>' | stdbuf -o0 awk -F '>>|,' '{print ''$2}'
          ''}")
        (deflisten urgent_workspace :initial "" "bash ${pkgs.writeShellScript "get-urgent-workspace"
          /*
          bash
          */
          ''
            nix run nixpkgs#socat -- -u UNIX-CONNECT:/tmp/hypr/''$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | stdbuf -o0 grep '^urgent>>' | stdbuf -o0 awk -F '>>|,' '{print ''$2}' | stdbuf -o0 xargs -I {} bash -c "/run/current-system/sw/bin/hyprctl clients -j | /run/current-system/sw/bin/nix run nixpkgs#jq -- '.[] | select(.address | endswith(\"{}\")) | .workspace.id'" | stdbuf -o0 awk -F '|,' '{print ''$1}'
          ''}")
        (defpoll time :interval "1s" :initial "" `nu -c 'date now | date to-record | ''$"(''$in.hour | fill -a right -c 0 -w 2):(''$in.minute | fill -a right -c 0 -w 2)"'`)
        (defpoll second :interval "1s" :initial "" `nu -c 'date now | date to-record | get second | fill -a right -c 0 -w 2'`)
        (defpoll date :interval "1s" :initial "" `nu -c 'date now | date to-record | ''$"(''$in.day | fill -a right -c 0 -w 2)/(''$in.month | fill -a right -c 0 -w 2)/(''$in.year | fill -a right -c 0 -w 4)"'`)
        (defvar reveal-date false)

        (defwidget workspaces []
            (eventbox :onscroll "bash ${pkgs.writeShellScript "change-active-workspace"
          /*
          bash
          */
          ''
            function clamp {
              min=''$1
              max=''$2
              val=''$3
              nix run nixpkgs#python3 -- -c "print(max(''$min, min(''$val, ''$max)))"
            }

            direction=''$1
            current=''$2
            if test "''$direction" = "down"
            then
              target=''$(clamp 1 10 ''$((''$current+1)))
              echo "jumping to ''$target"
              hyprctl dispatch workspace ''$target
            elif test "''$direction" = "up"
            then
              target=''$(clamp 1 10 ''$((''$current-1)))
              echo "jumping to ''$target"
              hyprctl dispatch workspace ''$target
            fi
          ''} {} ''${current_workspace}" :class "workspaces-widget"
                (box :space-evenly true
                    (label :text "''${workspaces}''${current_workspace}" :visible false)
                        (for workspace in workspaces
                            (eventbox :onclick "hyprctl dispatch workspace ''${workspace.id}"
                                (box :class "workspace-entry ''${workspace.id == current_workspace ? 'current' : '''} ''${workspace.id == urgent_workspace ? 'urgent' : '''} ''${workspace.windows > 0 ? 'occupied' : 'empty'}"
                                (label :text "''${workspace.id}"
                                )
                            )
                        )
                    )
                )
            )
        )

        (defwidget calendar-widget []
            (box
                (calendar :class "calendar")
            )
        )

        (defwidget bar [reveal-date]
            (box :class "wrapper"
                (centerbox :orientation "horizontal"
                    (box :halign "start" :class "module"
                        (workspaces)
                    )
                    (box :halign "center" :class "title ''${window == ''' ? ''': 'background'}"
                        (label :text "''${window}")
                    )
                    (box :halign "end" :class "module time" :space-evenly false
                        (eventbox :class "eventbox"
                            :onhover "eww update reveal-date=true"
                            :onhoverlost "eww update reveal-date=false"
                            (button
                                :onclick `nu -c 'eww (if (eww windows | grep calendar | str starts-with *) {"close"} else {"open"}) calendar'`
                                (box :space-evenly false
                                    time
                                    (revealer :reveal reveal-date
                                        :transition "slideright"
                                        :duration "500ms"
                                        (box :space-evenly false
                                            (label :text ":''${second} ")
                                            date
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )


        (defwindow calendar
            :monitor 0
            :geometry (geometry
                :x "15px"
                :y "15px"
                :anchor "top right"
            )
            :exclusive true
            :focusable false
            :stacking "overlay"
            :windowtype "dock"
            (calendar-widget)
        )

        (defwindow bar
            :monitor 0
            :geometry (geometry
                :width "100%"
                :anchor "top center"
            )
            :exclusive true
            :focusable false
            :stacking "bg"
            :windowtype "dock"
            (bar :reveal-date reveal-date)
        )
      '';
    "eww/eww.scss".text =
      /*
      scss
      */
      ''
        ''$bg: #1e1e2e;
        ''$black: #313244;
        ''$red: #f38ba8;
        ''$green: #a6e3a1;
        ''$yellow: #f9e2af;
        ''$pink: #f5c2e7;
        ''$blue: #89b4fa;
        ''$purple: #cba6f7;
        ''$cyan: #89dceb;
        ''$white: #cdd6f4;

        * {
            all: unset;
            font-family: "CaskaydiaCove Nerd Font";
            font-weight: 600;
        }

        .bar {
            background-color: transparent;
        }

        .wrapper {
            margin: 10px 10px 10px 0;
        }

        .module, .title {
            padding: 5px 10px;
            border-radius: 15px;
            color: ''$white;
        }

        .workspaces-widget {
            padding: 0;
        }

        .workspace-entry {
            padding: 5px;
            margin-right: 10px;
            border-radius: 50%;
            border: 2px solid ''$bg;
            background: ''$black;
        }

        .workspace-entry label {
            margin-left: 1px;
            margin-top: 1px;
        }

        .workspace-entry.occupied {
            background: linear-gradient(''$black, ''$black) padding-box,
                        linear-gradient(to right, ''$red, ''$pink) border-box;
            border: 2px solid transparent;
            color: ''$white;
        }

        .workspace-entry.urgent {
            background: linear-gradient(''$red, ''$red, ''$pink) padding-box,
                        linear-gradient(to right, ''$red, ''$red, ''$pink) border-box;
            color: ''$bg;
        }

        .workspace-entry.current {
            background: linear-gradient(''$red, ''$pink) padding-box,
                        linear-gradient(to right, ''$red, ''$pink) border-box;
            color: ''$bg;
        }


        .time {
            background: linear-gradient(45deg, ''$yellow, ''$red);
        }
        .title.background {
            background: linear-gradient(45deg, ''$blue, ''$cyan);
        }

        .time,
        .title.background {
            color: ''$bg;
            background-size: 400% 400%;
            animation: gradient 15s ease infinite;
            border: 2px solid ''$bg;
        }
        .calendar.view {
            background: linear-gradient(''$bg, ''$bg) padding-box,
                        linear-gradient(45deg, ''$red, ''$purple) border-box;
            border: 3px solid transparent;
            border-radius: 15px;
        }

        calendar {
            padding: 10px 5px 5px 5px;
        }

        calendar * {
            color: ''$white;
        }

        calendar:selected {
            color: ''$red;
        }

        @keyframes gradient {
          0% {
            background-position: 0% 50%;
          }
          50% {
            background-position: 100% 50%;
          }
          100% {
            background-position: 0% 50%;
          }
        }
      '';
  };
}
