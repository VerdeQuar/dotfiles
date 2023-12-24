{
  pkgs,
  config,
  ...
}: {
  programs.joshuto.package = pkgs.writeShellScriptBin "joshuto" ''
    export joshuto_wrap_id="$$"

    if test $# -eq 1; then
      directory=$1
    else
      directory=$PWD
    fi

    joshuto_temp="/tmp/joshuto-wrap-$joshuto_wrap_id"
    mkdir "$joshuto_temp"

    ${pkgs.joshuto}/bin/joshuto --output-file "$joshuto_temp/output" --change-directory $directory $@
    exit_code=$?
    case "$exit_code" in
        # output contains current directory
        101)
            JOSHUTO_CWD=$(cat "$joshuto_temp/output")
            echo "joshuto $@" >> ${config.xdg.configHome}/nushell/history.txt;
            echo "$JOSHUTO_CWD" | ${pkgs.findutils}/bin/xargs -o -I {} ${pkgs.nushell}/bin/nu -e "clear; cd {}"
            ;;
        # output selected files
        102)
            cat "$joshuto_temp/output"
            ;;
        *)
            exit $exit_code
            ;;
    esac
  '';
  home.packages = [pkgs.glib];
  xdg.mimeApps.defaultApplications."inode/directory" = ["joshuto.desktop"];
  xdg.desktopEntries.joshuto = {
    name = "joshuto";
    noDisplay = true;
    exec = "${pkgs.kitty}/bin/kitty -d %U ${config.programs.joshuto.package}/bin/joshuto";
    terminal = true;
    mimeType = ["inode/directory"];
  };
  xdg.configFile."joshuto/mimetype.toml".source = (pkgs.formats.toml {}).generate "mimetype.toml" {
    class = {
      audio_default = [
        {
          command = "${pkgs.mpv}/bin/mpv";
          args = ["--"];
        }
      ];
      image_default = [
        {
          command = "${pkgs.feh}/bin/feh";
          args = ["--"];
          fork = true;
          silent = true;
        }
      ];
      video_default = [
        {
          command = "${pkgs.mpv}/bin/mpv";
          args = ["--"];
          fork = true;
          silent = true;
        }
      ];
      text_default = [
        {
          command = "${pkgs.bat}/bin/bat";
          args = ["--paging=always"];
        }
      ];
    };
    extension = {
      # image formats
      avif."inherit" = "image_default";
      bmp."inherit" = "image_default";
      gif."inherit" = "image_default";
      heic."inherit" = "image_default";
      jpeg."inherit" = "image_default";
      jpe."inherit" = "image_default";
      jpg."inherit" = "image_default";
      jxl."inherit" = "image_default";
      pgm."inherit" = "image_default";
      png."inherit" = "image_default";
      ppm."inherit" = "image_default";
      webp."inherit" = "image_default";
      svg.app_list = [
        {
          command = "${pkgs.inkscape}/bin/inkview";
          fork = true;
          silent = true;
        }
        {
          command = "${pkgs.inkscape}/bin/inkscape";
          fork = true;
          silent = true;
        }
      ];
      tiff.app_list = [
        {
          command = "${pkgs.krita}/bin/krita";
          fork = true;
          silent = true;
        }
      ];
      kra.app_list = [
        {
          command = "${pkgs.krita}/bin/krita";
          fork = true;
          silent = true;
        }
      ];

      # audio formats
      aac."inherit" = "audio_default";
      ac3."inherit" = "audio_default";
      aiff."inherit" = "audio_default";
      ape."inherit" = "audio_default";
      dts."inherit" = "audio_default";
      flac."inherit" = "audio_default";
      m4a."inherit" = "audio_default";
      mp3."inherit" = "audio_default";
      oga."inherit" = "audio_default";
      ogg."inherit" = "audio_default";
      opus."inherit" = "audio_default";
      wav."inherit" = "audio_default";
      wv."inherit" = "audio_default";

      # video formats
      avi."inherit" = "video_default";
      av1."inherit" = "video_default";
      flv."inherit" = "video_default";
      mkv."inherit" = "video_default";
      m4v."inherit" = "video_default";
      mov."inherit" = "video_default";
      mp4."inherit" = "video_default";
      ts."inherit" = "video_default";
      webm."inherit" = "video_default";
      wmv."inherit" = "video_default";

      # text formats
      build."inherit" = "text_default";
      c."inherit" = "text_default";
      cmake."inherit" = "text_default";
      conf."inherit" = "text_default";
      cpp."inherit" = "text_default";
      css."inherit" = "text_default";
      csv."inherit" = "text_default";
      cu."inherit" = "text_default";
      ebuild."inherit" = "text_default";
      eex."inherit" = "text_default";
      env."inherit" = "text_default";
      ex."inherit" = "text_default";
      exs."inherit" = "text_default";
      go."inherit" = "text_default";
      h."inherit" = "text_default";
      hpp."inherit" = "text_default";
      hs."inherit" = "text_default";
      html."inherit" = "text_default";
      ini."inherit" = "text_default";
      java."inherit" = "text_default";
      js."inherit" = "text_default";
      json."inherit" = "text_default";
      kt."inherit" = "text_default";
      lua."inherit" = "text_default";
      log."inherit" = "text_default";
      md."inherit" = "text_default";
      micro."inherit" = "text_default";
      ninja."inherit" = "text_default";
      norg."inherit" = "text_default";
      org."inherit" = "text_default";
      py."inherit" = "text_default";
      rkt."inherit" = "text_default";
      rs."inherit" = "text_default";
      scss."inherit" = "text_default";
      sh."inherit" = "text_default";
      srt."inherit" = "text_default";
      svelte."inherit" = "text_default";
      toml."inherit" = "text_default";
      tsx."inherit" = "text_default";
      txt."inherit" = "text_default";
      vim."inherit" = "text_default";
      xml."inherit" = "text_default";
      yaml."inherit" = "text_default";
      yml."inherit" = "text_default";

      pdf."inherit" = "reader_default";

      # archive formats
      "7z".app_list = [
        {
          command = "${pkgs.p7zip}/bin/7z";
          args = [
            "x"
          ];
          confirm_exit = true;
        }
      ];
      bz2.app_list = [
        {
          command = "${pkgs.gnutar}/bin/tar";
          args = [
            "-xvjf"
          ];
          confirm_exit = true;
        }
      ];
      gz.app_list = [
        {
          command = "${pkgs.gnutar}/bin/tar";
          args = [
            "-xvzf"
          ];
          confirm_exit = true;
        }
      ];
      tar.app_list = [
        {
          command = "${pkgs.gnutar}/bin/tar";
          args = [
            "-xvf"
          ];
          confirm_exit = true;
        }
      ];
      tgz.app_list = [
        {
          command = "${pkgs.gnutar}/bin/tar";
          args = [
            "-xvzf"
          ];
          confirm_exit = true;
        }
      ];
      rar.app_list = [
        {
          command = "${pkgs.unrar}/bin/unrar";
          args = [
            "x"
          ];
          confirm_exit = true;
        }
      ];
      xz.app_list = [
        {
          command = "${pkgs.gnutar}/bin/tar";
          args = [
            "-xvJf"
          ];
          confirm_exit = true;
        }
      ];
      zip.app_list = [
        {
          command = "${pkgs.unzip}/bin/unzip";
          confirm_exit = true;
        }
      ];
    };
    mimetype = {
      mimetype.application.subtype.octet-stream."inherit" = "video_default";
      mimetype.text."inherit" = "text_default";
      mimetype.video."inherit" = "video_default";
    };
  };
  xdg.configFile."joshuto/keymap.toml".source = (pkgs.formats.toml {}).generate "keymap.toml" {
    default_view.keymap = [
      {
        keys = ["q"];
        commands = ["quit --output-current-directory"];
      }
      {
        keys = ["Q"];
        commands = ["quit --output-selected-files"];
      }
      {
        keys = ["escape"];
        commands = ["escape"];
      }
      {
        keys = ["ctrl+t"];
        commands = ["new_tab"];
      }
      {
        keys = ["alt+t"];
        commands = ["new_tab --cursor"];
      }
      {
        keys = ["T"];
        commands = ["new_tab --current"];
      }
      {
        keys = ["W"];
        commands = ["close_tab"];
      }
      {
        keys = ["ctrl+w"];
        commands = ["close_tab"];
      }
      {
        keys = ["ctrl+c"];
        commands = ["quit"];
      }

      {
        keys = ["R"];
        commands = ["reload_dirlist"];
      }
      {
        keys = ["z" "h"];
        commands = ["toggle_hidden"];
      }
      {
        keys = ["ctrl+h"];
        commands = ["toggle_hidden"];
      }
      {
        keys = ["\t"];
        commands = ["tab_switch 1"];
      }
      {
        keys = ["backtab"];
        commands = ["tab_switch -1"];
      }

      {
        keys = ["alt+1"];
        commands = ["tab_switch_index 1"];
      }
      {
        keys = ["alt+2"];
        commands = ["tab_switch_index 2"];
      }
      {
        keys = ["alt+3"];
        commands = ["tab_switch_index 3"];
      }
      {
        keys = ["alt+4"];
        commands = ["tab_switch_index 4"];
      }
      {
        keys = ["alt+5"];
        commands = ["tab_switch_index 5"];
      }

      {
        keys = ["1"];
        commands = ["numbered_command 1"];
      }
      {
        keys = ["2"];
        commands = ["numbered_command 2"];
      }
      {
        keys = ["3"];
        commands = ["numbered_command 3"];
      }
      {
        keys = ["4"];
        commands = ["numbered_command 4"];
      }
      {
        keys = ["5"];
        commands = ["numbered_command 5"];
      }
      {
        keys = ["6"];
        commands = ["numbered_command 6"];
      }
      {
        keys = ["7"];
        commands = ["numbered_command 7"];
      }
      {
        keys = ["8"];
        commands = ["numbered_command 8"];
      }
      {
        keys = ["9"];
        commands = ["numbered_command 9"];
      }

      # arrow keys
      {
        keys = ["arrow_up"];
        commands = ["cursor_move_up"];
      }
      {
        keys = ["arrow_down"];
        commands = ["cursor_move_down"];
      }
      {
        keys = ["arrow_left"];
        commands = ["cd .."];
      }
      {
        keys = ["arrow_right"];
        commands = ["open"];
      }
      {
        keys = ["\n"];
        commands = ["open"];
      }
      {
        keys = ["home"];
        commands = ["cursor_move_home"];
      }
      {
        keys = ["end"];
        commands = ["cursor_move_end"];
      }
      {
        keys = ["page_up"];
        commands = ["cursor_move_page_up"];
      }
      {
        keys = ["page_down"];
        commands = ["cursor_move_page_down"];
      }
      {
        keys = ["ctrl+u"];
        commands = ["cursor_move_page_up 0.5"];
      }
      {
        keys = ["ctrl+d"];
        commands = ["cursor_move_page_down 0.5"];
      }
      {
        keys = ["ctrl+b"];
        commands = ["cursor_move_page_up"];
      }
      {
        keys = ["ctrl+f"];
        commands = ["cursor_move_page_down"];
      }

      # vim-like keybindings
      {
        keys = ["j"];
        commands = ["cursor_move_down"];
      }
      {
        keys = ["k"];
        commands = ["cursor_move_up"];
      }
      {
        keys = ["h"];
        commands = ["cd .."];
      }
      {
        keys = ["l"];
        commands = ["open"];
      }
      {
        keys = ["g" "g"];
        commands = ["cursor_move_home"];
      }
      {
        keys = ["G"];
        commands = ["cursor_move_end"];
      }
      {
        keys = ["r"];
        commands = ["open_with"];
      }

      {
        keys = ["H"];
        commands = ["cursor_move_page_home"];
      }
      {
        keys = ["L"];
        commands = ["cursor_move_page_middle"];
      }
      {
        keys = ["M"];
        commands = ["cursor_move_page_end"];
      }

      {
        keys = ["["];
        commands = ["parent_cursor_move_up"];
      }
      {
        keys = ["]"];
        commands = ["parent_cursor_move_down"];
      }

      {
        keys = ["c" "d"];
        commands = [":cd "];
      }
      {
        keys = ["d" "d"];
        commands = ["cut_files"];
      }
      {
        keys = ["y" "y"];
        commands = ["copy_files"];
      }
      {
        keys = ["y" "n"];
        commands = ["copy_filename"];
      }
      {
        keys = ["y" "."];
        commands = ["copy_filename_without_extension"];
      }
      {
        keys = ["y" "p"];
        commands = ["copy_filepath"];
      }
      {
        keys = ["y" "a"];
        commands = ["copy_filepath --all-selected=true"];
      }
      {
        keys = ["y" "d"];
        commands = ["copy_dirpath"];
      }

      {
        keys = ["p" "l"];
        commands = ["symlink_files --relative=false"];
      }
      {
        keys = ["p" "L"];
        commands = ["symlink_files --relative=true"];
      }

      {
        keys = ["delete"];
        commands = ["delete_files"];
      }
      {
        keys = ["d" "D"];
        commands = ["delete_files"];
      }

      {
        keys = ["p" "p"];
        commands = ["paste_files"];
      }
      {
        keys = ["p" "o"];
        commands = ["paste_files --overwrite=true"];
      }

      {
        keys = ["a"];
        commands = ["rename_append"];
      }
      {
        keys = ["A"];
        commands = ["rename_prepend"];
      }

      {
        keys = ["f" "t"];
        commands = [":touch "];
      }

      {
        keys = [" "];
        commands = ["select --toggle=true"];
      }
      {
        keys = ["t"];
        commands = ["select --all=true --toggle=true"];
      }
      {
        keys = ["V"];
        commands = ["toggle_visual"];
      }

      {
        keys = ["w"];
        commands = ["show_tasks --exit-key=w"];
      }
      {
        keys = ["b" "b"];
        commands = ["bulk_rename"];
      }
      {
        keys = ["="];
        commands = ["set_mode"];
      }

      {
        keys = [":"];
        commands = [":"];
      }
      {
        keys = [";"];
        commands = [":"];
      }

      {
        keys = ["'"];
        commands = [":shell "];
      }
      {
        keys = ["m" "k"];
        commands = [":mkdir "];
      }
      {
        keys = ["c" "w"];
        commands = [":rename "];
      }

      {
        keys = ["/"];
        commands = [":search "];
      }
      {
        keys = ["|"];
        commands = [":search_inc "];
      }
      {
        keys = ["\\"];
        commands = [":search_glob "];
      }
      {
        keys = ["S"];
        commands = ["search_fzf"];
      }
      {
        keys = ["C"];
        commands = ["subdir_fzf"];
      }

      {
        keys = ["n"];
        commands = ["search_next"];
      }
      {
        keys = ["N"];
        commands = ["search_prev"];
      }

      {
        keys = ["s" "r"];
        commands = ["sort reverse"];
      }
      {
        keys = ["s" "l"];
        commands = ["sort lexical"];
      }
      {
        keys = ["s" "m"];
        commands = ["sort mtime"];
      }
      {
        keys = ["s" "n"];
        commands = ["sort natural"];
      }
      {
        keys = ["s" "s"];
        commands = ["sort size"];
      }
      {
        keys = ["s" "e"];
        commands = ["sort ext"];
      }

      {
        keys = ["m" "s"];
        commands = ["linemode size"];
      }
      {
        keys = ["m" "m"];
        commands = ["linemode mtime"];
      }
      {
        keys = ["m" "M"];
        commands = ["linemode size | mtime"];
      }
      {
        keys = ["m" "u"];
        commands = ["linemode user"];
      }
      {
        keys = ["m" "U"];
        commands = ["linemode user | group"];
      }
      {
        keys = ["m" "p"];
        commands = ["linemode perm"];
      }

      {
        keys = ["g" "r"];
        commands = ["cd /"];
      }
      {
        keys = ["g" "c"];
        commands = ["cd ~/.config"];
      }
      {
        keys = ["g" "d"];
        commands = ["cd ~/Downloads"];
      }
      {
        keys = ["g" "e"];
        commands = ["cd /etc"];
      }
      {
        keys = ["g" "h"];
        commands = ["cd ~/"];
      }
      {
        keys = ["?"];
        commands = ["help"];
      }
    ];
    task_view.keymap = [
      {
        keys = ["arrow_up"];
        commands = ["cursor_move_up"];
      }
      {
        keys = ["arrow_down"];
        commands = ["cursor_move_down"];
      }
      {
        keys = ["home"];
        commands = ["cursor_move_home"];
      }
      {
        keys = ["end"];
        commands = ["cursor_move_end"];
      }

      # vim-like keybindings
      {
        keys = ["j"];
        commands = ["cursor_move_down"];
      }
      {
        keys = ["k"];
        commands = ["cursor_move_up"];
      }
      {
        keys = ["g" "g"];
        commands = ["cursor_move_home"];
      }
      {
        keys = ["G"];
        commands = ["cursor_move_end"];
      }

      {
        keys = ["w"];
        commands = ["show_tasks"];
      }
      {
        keys = ["escape"];
        commands = ["show_tasks"];
      }
    ];
    help_view.keymap = [
      # arrow keys
      {
        keys = ["arrow_up"];
        commands = ["cursor_move_up"];
      }
      {
        keys = ["arrow_down"];
        commands = ["cursor_move_down"];
      }
      {
        keys = ["home"];
        commands = ["cursor_move_home"];
      }
      {
        keys = ["end"];
        commands = ["cursor_move_end"];
      }

      # vim-like keybindings
      {
        keys = ["j"];
        commands = ["cursor_move_down"];
      }
      {
        keys = ["k"];
        commands = ["cursor_move_up"];
      }
      {
        keys = ["g" "g"];
        commands = ["cursor_move_home"];
      }
      {
        keys = ["G"];
        commands = ["cursor_move_end"];
      }

      {
        keys = ["w"];
        commands = ["show_tasks"];
      }
      {
        keys = ["escape"];
        commands = ["show_tasks"];
      }
    ];
  };
  xdg.configFile."joshuto/joshuto.toml".source = (pkgs.formats.toml {}).generate "joshuto.toml" {
    use_trash = true;
    watch_files = true;
    xdg_open = true;
    xdg_open_fork = true;
    use_preview_script = true;
    display = {
      show_borders = false;
      show_hidden = true;
    };

    preview = {
      max_preview_size = 50000097152;
      preview_script = pkgs.writeShellScript "joshuto_preview_script.sh" ''
        set -o noclobber -o noglob -o nounset -o pipefail
        IFS=$'\n'

        ## If the option `use_preview_script` is set to `true`,
        ## then this script will be called and its output will be displayed in ranger.
        ## ANSI color codes are supported.
        ## STDIN is disabled, so interactive scripts won't work properly

        ## This script is considered a configuration file and must be updated manually.
        ## It will be left untouched if you upgrade ranger.

        ## Because of some automated testing we do on the script #'s for comments need
        ## to be doubled up. Code that is commented out, because it's an alternative for
        ## example, gets only one #.

        ## Meanings of exit codes:
        ## code | meaning    | action of ranger
        ## -----+------------+-------------------------------------------
        ## 0    | success    | Display stdout as preview
        ## 1    | no preview | Display no preview at all
        ## 2    | plain text | Display the plain content of the file
        ## 3    | fix width  | Don't reload when width changes
        ## 4    | fix height | Don't reload when height changes
        ## 5    | fix both   | Don't ever reload
        ## 6    | image      | Display the image `$IMAGE_CACHE_PATH` points to as an image preview
        ## 7    | image      | Display the file directly as an image

        FILE_PATH=""
        PREVIEW_WIDTH=10
        PREVIEW_HEIGHT=10
        PREVIEW_X_COORD=0
        PREVIEW_Y_COORD=0
        IMAGE_CACHE_PATH=""

        # echo "$@"

        while [ "$#" -gt 0 ]; do
            case "$1" in
                "--path")
                    shift
                    FILE_PATH="$1"
                    ;;
                "--preview-width")
                    shift
                    PREVIEW_WIDTH="$1"
                    ;;
                "--preview-height")
                    shift
                    PREVIEW_HEIGHT="$1"
                    ;;
                "--x-coord")
                    shift
                    PREVIEW_X_COORD="$1"
                    ;;
                "--y-coord")
                    shift
                    PREVIEW_Y_COORD="$1"
                    ;;
                "--image-cache")
                    shift
                    IMAGE_CACHE_PATH="$1"
                    ;;
            esac
            shift
        done

        FILE_EXTENSION="''${FILE_PATH##*.}"
        FILE_EXTENSION_LOWER="$(${pkgs.coreutils}/bin/printf "%s" "''${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"

        MIMETYPE=$(${pkgs.file}/bin/file --mime-type -Lb "''${FILE_PATH}")

        ## Settings
        HIGHLIGHT_SIZE_MAX=262143  # 256KiB
        HIGHLIGHT_TABWIDTH="''${HIGHLIGHT_TABWIDTH:-8}"
        HIGHLIGHT_STYLE="''${HIGHLIGHT_STYLE:-pablo}"
        HIGHLIGHT_OPTIONS="--replace-tabs=''${HIGHLIGHT_TABWIDTH} --style=''${HIGHLIGHT_STYLE} ''${HIGHLIGHT_OPTIONS:-}"
        PYGMENTIZE_STYLE="''${PYGMENTIZE_STYLE:-autumn}"
        OPENSCAD_IMGSIZE="''${RNGR_OPENSCAD_IMGSIZE:-1000,1000}"
        OPENSCAD_COLORSCHEME="''${RNGR_OPENSCAD_COLORSCHEME:-Tomorrow Night}"

        handle_extension() {
            case "''${FILE_EXTENSION_LOWER}" in
                ## Archive
                a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
                rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
                    ${pkgs.atool}/bin/atool --list -- "''${FILE_PATH}" && exit 5
                    ${pkgs.libarchive}/bin/bsdtar --list --file "''${FILE_PATH}" && exit 5
                    exit 1;;
                rar)
                    ## Avoid password prompt by providing empty password
                    ${pkgs.unrar}/bin/unrar lt -p- -- "''${FILE_PATH}" && exit 5
                    exit 1;;
                7z)
                    ## Avoid password prompt by providing empty password
                    ${pkgs.p7zip}/bin/7z l -p -- "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## PDF
                pdf)
                    ## Preview as text conversion
                    ${pkgs.poppler_utils}/bin/pdftotext -l 10 -nopgbrk -q -- "''${FILE_PATH}" - | \
                    ${pkgs.coreutils}/bin/fmt -w "''${PREVIEW_WIDTH}" && exit 5
                    ${pkgs.mupdf}/bin/mutool draw -F txt -i -- "''${FILE_PATH}" 1-10 | \
                    ${pkgs.coreutils}/bin/fmt -w "''${PREVIEW_WIDTH}" && exit 5
                    ${pkgs.exiftool}/bin/exiftool "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## BitTorrent
                torrent)
                    ${pkgs.transmission}/bin/transmission-show -- "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## OpenDocument
                odt|ods|odp|sxw)
                    ## Preview as text conversion
                    ${pkgs.odt2txt}/bin/odt2txt "''${FILE_PATH}" && exit 5
                    ## Preview as markdown conversion
                    ${pkgs.pandoc}/bin/pandoc -s -t markdown -- "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## XLSX
                xlsx)
                    ## Preview as csv conversion
                    ## Uses: https://github.com/dilshod/xlsx2csv
                    ${pkgs.xlsx2csv}/bin/xlsx2csv -- "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## HTML
                htm|html|xhtml)
                    ## Preview as text conversion
                    ${pkgs.w3m}/bin/w3m -dump "''${FILE_PATH}" && exit 5
                    ${pkgs.lynx}/bin/lynx -dump -- "''${FILE_PATH}" && exit 5
                    ${pkgs.elinks}/bin/elinks -dump "''${FILE_PATH}" && exit 5
                    ${pkgs.pandoc}/bin/pandoc -s -t markdown -- "''${FILE_PATH}" && exit 5
                    ;;

                ## JSON
                json|ipynb)
                    ${pkgs.jq}/bin/jq --color-output . "''${FILE_PATH}" && exit 5
                    ${pkgs.python3}/bin/python -m json.tool -- "''${FILE_PATH}" && exit 5
                    ;;

                ## Direct Stream Digital/Transfer (DSDIFF) and wavpack aren't detected
                ## by file(1).
                dff|dsf|wv|wvc)
                    ${pkgs.mediainfo}/bin/mediainfo "''${FILE_PATH}" && exit 5
                    ${pkgs.exiftool}/bin/exiftool "''${FILE_PATH}" && exit 5
                    ;; # Continue with next handler on failure
            esac
        }

        function get_preview_meta_file {
            echo "/tmp/joshuto-wrap-$joshuto_wrap_id/preview-meta-$(${pkgs.coreutils}/bin/echo "$1" | ${pkgs.coreutils}/bin/md5sum | ${pkgs.gnused}/bin/sed 's/  -//g')"
        }

        handle_image() {
            ## Size of the preview if there are multiple options or it has to be
            ## rendered from vector graphics. If the conversion program allows
            ## specifying only one dimension while keeping the aspect ratio, the width
            ## will be used.
            local DEFAULT_SIZE="40x30"

            local mimetype="''${1}"
            case "''${mimetype}" in
                ## Image
                image/*)
                    # ${pkgs.kitty}/bin/kitty +kitten icat --clear
                    ${pkgs.kitty}/bin/kitty +kitten icat \
                        --transfer-mode file \
                        --place "''${PREVIEW_WIDTH}x''${PREVIEW_HEIGHT}@''${PREVIEW_X_COORD}x''${PREVIEW_Y_COORD}" \
                        "''${FILE_PATH}"
                    exit 7
                    ;;
            esac
        }

        handle_mime() {
            local mimetype="''${1}"

            case "''${mimetype}" in
                ## RTF and DOC
                text/rtf|*msword)
                    ## Preview as text conversion
                    ## note: catdoc does not always work for .doc files
                    ## catdoc: http://www.wagner.pp.ru/~vitus/software/catdoc/
                    ${pkgs.catdoc}/bin/catdoc -- "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## DOCX, ePub, FB2 (using markdown)
                ## You might want to remove "|epub" and/or "|fb2" below if you have
                ## uncommented other methods to preview those formats
                *wordprocessingml.document|*/epub+zip|*/x-fictionbook+xml)
                    ## Preview as markdown conversion
                    ${pkgs.pandoc}/bin/pandoc -s -t markdown -- "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## E-mails
                message/rfc822)
                   ## Parsing performed by mu: https://github.com/djcb/mu
                   ${pkgs.mu}/bin/mu view -- "''${FILE_PATH}" && exit 5
                   exit 1;;

                ## XLS
                *ms-excel)
                    ## Preview as csv conversion
                    ## xls2csv comes with catdoc:
                    ##   http://www.wagner.pp.ru/~vitus/software/catdoc/
                    ${pkgs.catdoc}/bin/xls2csv -- "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## Text
                text/* | */xml)
                    ${pkgs.bat}/bin/bat --color=always --paging=never \
                --style=plain \
                --terminal-width="''${PREVIEW_WIDTH}" \
                "''${FILE_PATH}" && exit 5
                    exit 2;;

                ## DjVu
                image/vnd.djvu)
                    ## Preview as text conversion (requires djvulibre)
                    ${pkgs.djvulibre}/bin/djvutxt "''${FILE_PATH}" | fmt -w "''${PREVIEW_WIDTH}" && exit 5
                    ${pkgs.exiftool}/bin/exiftool "''${FILE_PATH}" && exit 5
                    exit 1;;

                ## Image
                image/*)
                    ## Preview as text conversion
                    metadata=$(${pkgs.exiftool}/bin/exiftool "''${FILE_PATH}" | grep -E "Image Size|File Type Extension|File Size")
                    echo "$metadata"
                    meta_file=$(get_preview_meta_file "''${FILE_PATH}")
                    let y_offset=`${pkgs.coreutils}/bin/printf "''${metadata}" | ${pkgs.gnused}/bin/sed -n '=' | ${pkgs.coreutils}/bin/wc -l`+2
                    echo "y-offset $y_offset" > "$meta_file"
                    exit 4;;

                ## Video and audio
                video/* | audio/*)
                    ${pkgs.mediainfo}/bin/mediainfo "''${FILE_PATH}" && exit 5
                    ${pkgs.exiftool}/bin/exiftool "''${FILE_PATH}" && exit 5
                    exit 1;;
            esac
        }

        handle_fallback() {
            # echo '----- File Type Classification -----' && file --dereference --brief -- "''${FILE_PATH}" && exit 5
            exit 1
        }


        MIMETYPE="$( ${pkgs.file}/bin/file --dereference --brief --mime-type -- "''${FILE_PATH}" )"
        handle_extension
        handle_mime "''${MIMETYPE}"
        handle_fallback

        exit 1
      '';
      preview_shown_hook_script = pkgs.writeShellScript "joshuto_preview_shown_hook_script.sh" ''
        path="$1"       # Full path of the previewed file
        x="$2"          # x coordinate of upper left cell of preview area
        y="$3"          # y coordinate of upper left cell of preview area
        width="$4"      # Width of the preview pane (number of fitting characters)
        height="$5"     # Height of the preview pane (number of fitting characters)


        # Find out mimetype and extension
        mimetype=$(${pkgs.file}/bin/file --mime-type -Lb "$path")
        extension=$(${pkgs.coreutils}/bin/echo "''${path##*.}" | ${pkgs.gawk}/bin/awk '{print tolower($0)}')

        function get_preview_meta_file {
            echo "/tmp/joshuto-wrap-$joshuto_wrap_id/preview-meta-$(${pkgs.coreutils}/bin/echo "$1" | ${pkgs.coreutils}/bin/md5sum | ${pkgs.gnused}/bin/sed 's/  -//g')"
        }

        function remove_image {
            ${pkgs.kitty}/bin/kitty +kitten icat \
                --transfer-mode=file \
                --clear 2>/dev/null
        }

        function show_image {
            path="$1"       # Full path of the previewed file
            x="$2"          # x coordinate of upper left cell of preview area
            y="$3"          # y coordinate of upper left cell of preview area
            width="$4"      # Width of the preview pane (number of fitting characters)
            height="$5"     # Height of the preview pane (number of fitting characters)
            ${pkgs.kitty}/bin/kitty +kitten icat \
                --transfer-mode=file \
                --place "''${width}x''${height}@''${x}x''${y}" \
                "$path" 2>/dev/null
        }

        case "$mimetype" in
            image/png | image/jpeg | image/gif)
                remove_image
                meta_file=$(get_preview_meta_file "$path")
                y_offset=`${pkgs.coreutils}/bin/cat "$meta_file" | ${pkgs.gnugrep}/bin/grep "y-offset" | ${pkgs.gawk}/bin/awk '{print $2}'`
                y=$(( $y + $y_offset ))
                show_image $path $x $y $width $height
                ;;
            *)
                remove_image
                ;;
        esac
      '';
      preview_removed_hook_script = pkgs.writeShellScript "preview_removed_hook_script.sh" ''
        ${pkgs.kitty}/bin/kitty +kitten icat --transfer-mode=file --clear 2>/dev/null
      '';
    };
  };
}
