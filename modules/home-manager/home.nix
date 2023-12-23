{
  config,
  pkgs,
  lib,
  system,
  inputs,
  common,
  ...
}: {
  imports = [
    inputs.nix-colors.homeManagerModules.default
    inputs.sops-nix.homeManagerModules.sops
    ./joshuto.nix
    ./eww.nix
  ];

  home.username = "verdek";
  home.homeDirectory = "/home/verdek";

  home.stateVersion = "23.11";
  home.pointerCursor = {
    package = common.xcursor.theme.package;
    name = common.xcursor.theme.name;
    size = common.xcursor.theme.size;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = rec {
    EDITOR = "nvim";
    SUDO_EDITOR = "${EDITOR}";
    PAGER = "${pkgs.moar}/bin/moar -quit-if-one-screen";
    BAT_PAGER = "${PAGER}";
    DIRENV_LOG_FORMAT = "";
    XDG_CACHE_HOME = "${config.xdg.cacheHome}";
    XDG_DATA_HOME = "${config.xdg.dataHome}";
    XDG_CONFIG_HOME = "${config.xdg.configHome}";
    SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
    BAT_THEME = "catppuccin";
  };

  sops = lib.mkIf (builtins.pathExists ../sops/key.txt) {
    age.keyFile = ../sops/key.txt;
    age.generateKey = true;
    defaultSopsFile = ../sops/secrets.yaml;
    secrets = {
      id_ed25519 = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      id_ed25519_pub = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      };
      codeium_key = {
        path = "/run/user/1000/secrets/codeium_key";
      };
    };
  };

  colorScheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

  home.packages = with pkgs; [
    (rust-bin.selectLatestNightlyWith (toolchain: toolchain.default))
    rust-analyzer
    inputs.cargo2nix.packages.${system}.default
    inputs.aniwall.packages.${system}.default
    sops
    comma
    nurl
    wget
    moar
    wl-clipboard
    xorg.xsetroot
    (pkgs.nerdfonts.override {fonts = ["CascadiaCode" "VictorMono" "Noto"];})
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-monochrome-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    mpvScripts.uosc
    qbittorrent
    pavucontrol
    libnotify
    killall
    system-config-printer
    (pkgs.writeShellScriptBin "xdg-terminal-exec" ''
      exec kitty -e "$@"
    '')
    (discord.override {
      withVencord = true;
    })
    stable.youtube-music
    wine64Packages.waylandFull
    lutris
    winetricks
    protonup-qt
    steam
    (pkgs.writeShellScriptBin "nixos-update" ''
      if test $# -eq 0; then
          if test -f $PWD/home.nix; then
              flake_path=$PWD;
          else
              flake_path="${config.home.homeDirectory}/.system";
          fi
      else
          if test $# -eq 1; then
              flake_path=$1;
          elif test $# -eq 2 -a "$1" = "--flake"; then
              flake_path=$2;
          fi
      fi

      function nix-flake-update {
          local prev=$PWD;
          cd $flake_path;
          sudo nix --experimental-features "nix-command flakes" flake update --commit-lock-file;
          cd $prev;
      }

      function nix-flake-metadata {
          local prev=$PWD;
          cd $flake_path;
          sudo nix --experimental-features "nix-command flakes" flake metadata --json;
          cd $prev;
      }

      if ! test -f $flake_path/flake.lock; then
          nix-flake-update;
          echo $(nix-flake-metadata | nix run nixpkgs\#jq -- -r '.locks | .nodes | keys[] as $k | select( $k | startswith("crate-") ) | "\(.[$k].locked.repo) https://github.com/\(.[$k].locked.owner)/\(.[$k].locked.repo) \(.[$k].locked.rev)"') | while read line;
          do
              input=($line);
              nix run nixpkgs\#git -- clone --depth 1 ''${input[1]} /tmp/''${input[0]};
              cd /tmp/''${input[0]};
              git reset --hard ''${input[2]};
              sudo nix --experimental-features "nix-command flakes" run github:cargo2nix/cargo2nix -- -o -l -f ''${flake_path}/modules/crates/''${input[0]}.nix;
              rm -r /tmp/''${input[0]};
          done
      else
          old_revs=$(nix-flake-metadata | nix run nixpkgs\#jq -- -r '.locks | .nodes | keys[] as $k | select( $k | startswith("crate-") )| "\($k) \(.[$k] | .locked.rev)"');
          nix-flake-update;

          echo $old_revs | while read line; do
              old_input=($line);
              input=($(nix-flake-metadata | nix run nixpkgs\#jq -- -r '.locks | .nodes | keys[] as $k | select( $k | startswith("'"''${old_input[0]}"'") ) | "\(.[$k].locked.repo) https://github.com/\(.[$k].locked.owner)/\(.[$k].locked.repo) \(.[$k].locked.rev)"'));
              if ! test "''${old_input[1]}" = "''${input[2]}"; then
                  echo "''${old_input[1]} != ''${input[2]}";
                  echo "input ''${input[1]} changed, fetching Cargo.lock";
                  nix run nixpkgs\#git -- clone --depth 1 ''${input[1]} /tmp/''${input[0]};
                  cd /tmp/''${input[0]};
                  git reset --hard ''${input[2]};
                  sudo nix --experimental-features "nix-command flakes" run github:cargo2nix/cargo2nix -- -o -l -f ''${flake_path}/modules/crates/''${input[0]}.nix;
                  rm -r /tmp/''${input[0]};
              fi
          done
      fi

      exit;
    '')
  ];
  home.file = {
    ".icons/default/index.theme".text = ''
      [icon theme]
      Inherits=${common.xcursor.theme.name}
    '';
  };

  programs = {
    bat = {
      enable = true;
      themes = {
        catppuccin = {
          src = inputs.catppuccin-bat;
          file = "Catppuccin-mocha.tmTheme";
        };
      };
      config = {
        pager = "less -FR";
        theme = "Catppuccin-mocha";
      };
    };
    bacon = {
      enable = true;
      settings = {};
    };
    direnv = {
      enable = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
    };
    neovim = let
      fromLua = str: "lua << EOF\n${str}\nEOF\n";
    in {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      extraPackages = with pkgs; [
        nixd
      ];
      extraLuaConfig =
        /*
        lua
        */
        ''

          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.wrap = false
          vim.opt.linebreak = true
          vim.opt.ignorecase = true
          vim.opt.smartcase = true
          vim.opt.shiftwidth = 4
          vim.opt.softtabstop = 4
          vim.opt.expandtab = true
          vim.opt.clipboard = 'unnamed,unnamedplus'
          vim.opt.undofile = true
          vim.opt.undodir = '${config.xdg.dataHome}/nvim/undo'

          vim.opt.listchars = {
            eol = '⤶',
            trail = '•',
            tab = '->',
          }
          vim.opt.list = true

          vim.keymap.set('n', '<C-BS>', '<C-W>')
        '';
      plugins = with pkgs.vimPlugins; [
        {
          plugin = pkgs.vimUtils.buildVimPlugin {
            pname = "dummy";
            version = "2137";
            src = "";
            dontUnpack = true;
          };
          config =
            fromLua
            /*
            lua
            */
            ''
              vim.g.mapleader = ","
            '';
        }
        hmts-nvim
        {
          plugin = fidget-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              require('fidget').setup({})
            '';
        }
        {
          plugin = pkgs.nur.repos.m15a.vimExtraPlugins.smart-pairs;
          config =
            fromLua
            /*
            lua
            */
            "require('pairs'):setup({
            enter = {
              enable_mapping = false
            }
          })";
        }
        nvim-lspconfig
        {
          plugin = lsp-zero-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              local lsp_zero = require('lsp-zero')

              lsp_zero.on_attach(function(client, bufnr)
                -- see :help lsp-zero-keybindings
                -- to learn the available actions
                lsp_zero.default_keymaps({buffer = bufnr, preserve_mappings = false})
                vim.keymap.set('n', 'gr', '<cmd>Telescope lsp_references<cr>', {buffer = bufnr})
                vim.keymap.set('n', 'gd', '<cmd>Telescope lsp_definitions<cr>', {buffer = bufnr})
                vim.keymap.set('n', 'gi', '<cmd>Telescope lsp_implementations<cr>', {buffer = bufnr})
                vim.keymap.set('n', 'gt', '<cmd>Telescope lsp_type_definitions<cr>', {buffer = bufnr})
              end)


              lsp_zero.format_on_save({
                format_opts = {
                  async = false,
                  timeout_ms = 10000,
                },
                servers = {
                  ['lua_ls'] = {'lua'},
                  ['tsserver'] = {'javascript', 'typescript'},
                  ['rust_analyzer'] = {'rust'},
                }
              })

              require('lsp-zero').extend_lspconfig()

              require('lspconfig').lua_ls.setup({})
              require('lspconfig').tsserver.setup({})
              require('lspconfig').nixd.setup({})
            '';
        }
        {
          plugin = luasnip;
          config =
            fromLua
            /*
            lua
            */
            ''
              require('luasnip.loaders.from_vscode').lazy_load()
              require('luasnip').config.setup({})
            '';
        }
        {
          plugin = codeium-lsp;
          config =
            fromLua
            /*
            lua
            */
            ''
              require('codeium').setup({})
            '';
        }
        lspkind-nvim
        cmp_luasnip
        friendly-snippets
        cmp-nvim-lsp
        cmp-nvim-lua
        cmp-nvim-lsp-signature-help
        cmp-async-path
        cmp-buffer
        cmp-calc
        codeium-nvim
        {
          plugin = nvim-cmp;
          config =
            fromLua
            /*
            lua
            */
            ''
              local cmp = require('cmp')
              local cmp_action = require('lsp-zero').cmp_action()
              local cmp_format = require('lsp-zero').cmp_format()
              local luasnip = require('luasnip')
              local kind = cmp.lsp.CompletionItemKind

              local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
              end

              cmp.setup({
                snippet = {
                  expand = function(args)
                    luasnip.lsp_expand(args.body)
                  end
                },
                experimental = {
                  ghost_text = {hlgroup = "Comment"}
                },
                sources = {
                  {name = 'codeium'},
                  {name = 'luasnip'},
                  {name = 'nvim_lsp'},
                  {name = 'nvim_lsp_signature_help'},
                  {name = 'nvim_lua'},
                  {name = 'async_path'},
                  {name = 'buffer'},
                  {name = 'calc'},
                },
                mapping = cmp.mapping.preset.insert({
                  -- Scroll up and down in the completion documentation
                  ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                  ['<C-d>'] = cmp.mapping.scroll_docs(4),

                  ['<CR>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                      cmp.confirm({ select = true })
                    else
                      fallback()
                    end
                  end, { "i", "s" }),

                  ['<Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                      cmp.confirm({ select = true })
                    elseif luasnip.expand_or_locally_jumpable() then
                      luasnip.expand_or_jump()
                    elseif has_words_before() then
                      cmp.complete()
                      if #cmp.get_entries() == 1 then
                        cmp.confirm({ select = true })
                      end
                    else
                      fallback()
                    end
                  end, { "i", "s" }),

                  ['<S-Tab>'] = cmp.mapping(function(fallback)
                    if luasnip.locally_jumpable(-1) then
                      luasnip.jump(-1)
                    else
                      fallback()
                    end
                  end, { "i", "s" }),

                }),
                formatting = {
                  format = require('lspkind').cmp_format({
                    mode = "text_symbol",
                    maxwidth = 50,
                    ellipsis_char = '...',
                    symbol_map = { Codeium = "", }
                  })
                },
                preselect = 'none',
                completion = {
                  completeopt = 'menu,menuone,noselect',
                },
              })
            '';
        }
        {
          plugin = rust-tools-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              local rust_tools = require('rust-tools')
              local lsp_zero = require('lsp-zero')


              rust_tools.setup({
                tools = {
                  inlay_hints = {
                    auto = true,
                  }
                },
                server = {
                  standalone = true,
                  on_attach = function(client, bufnr)
                    vim.keymap.set('n', '<leader>a', rust_tools.hover_actions.hover_actions, {buffer = bufnr})
                    vim.keymap.set('n', '<space>', rust_tools.code_action_group.code_action_group, {buffer = bufnr})
                  end,
                  settings = {
                    ['rust-analyzer'] = {
                      inlayHints = {
                        lifetimeElisionHints = {
                          enable = "always",
                        },
                        reborrowHints = {
                          enable = "always",
                        },
                      },
                    },
                  },
                }
              })
            '';
        }
        {
          plugin = comment-nvim;
          config =
            fromLua
            /*
            lua
            */
            "require('Comment').setup()";
        }
        {
          plugin = guess-indent-nvim;
          config =
            fromLua
            /*
            lua
            */
            "require('guess-indent').setup({})";
        }
        telescope-ui-select-nvim
        telescope-undo-nvim
        {
          plugin = telescope-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              require("telescope").setup({})
              require("telescope").load_extension("ui-select")
              require("telescope").load_extension("undo")

              vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
            '';
        }
        nvim-notify
        modicator-nvim
        neoscroll-nvim
        twilight-nvim
        nvim-web-devicons
        trouble-nvim
        {
          plugin = neo-tree-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              require('neo-tree').setup({
              event_handlers = {
                {
                  event = "file_opened",
                  handler = function(file_path)
                    require("neo-tree.command").execute({ action = "close" })
                  end
                }
              },
                filesystem = {
                  use_libuv_file_watcher = true,
                  follow_current_file = {
                    enabled = true
                  },

                  filtered_items = {
                    visible = true
                  }
                }
              })
              vim.keymap.set({ "n" }, "<Leader>t", "<CMD>Neotree toggle source=filesystem<CR>", { desc = "Reveal Neotree" })
            '';
        }
        {
          plugin = indent-blankline-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              require("ibl").setup()
            '';
        }
        {
          plugin = catppuccin-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              vim.cmd.colorscheme "catppuccin"
              require("catppuccin").setup({
                flavour = "mocha",
                integrations = {
                  neotree = true,
                  fidget = true,
                  lsp_trouble = true,
                  symbols_outline = true,
                  which_key = true,
                  indent_blankline = {
                    colored_indent_levels = true,
                  },
                }
              })
            '';
        }
        {
          plugin = feline-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              local ctp_feline = require('catppuccin.groups.integrations.feline')

              ctp_feline.setup({})

              require("feline").setup({
                  components = ctp_feline.get(),
              })
            '';
        }
        {
          plugin = symbols-outline-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              require("symbols-outline").setup({
                auto_preview = true,
              })
            '';
        }
        # motions
        {
          plugin = nvim-surround;
          config =
            fromLua
            /*
            lua
            */
            ''
              require('nvim-surround').setup({})
            '';
        }
        nvim-treesitter-textobjects
        {
          plugin = nvim-treesitter.withAllGrammars;
          config =
            fromLua
            /*
            lua
            */
            ''
              require('nvim-treesitter.configs').setup({
                highlight = {
                  enable = true
                },
                indent = {
                  enable = true
                }
              })
            '';
        }
        {
          plugin = flash-nvim;
          config =
            fromLua
            /*
            lua
            */
            ''
              vim.keymap.set({ "n", "x" }, "s", function() require("flash").jump() end, { desc = "Flash" })
              vim.keymap.set({ "n", "x" }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
              vim.keymap.set({ "o" }, "f", function() require("flash").jump() end, { desc = "Flash" })
              vim.keymap.set({ "o" }, "F", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
              vim.keymap.set({ "o" }, "r", function() require("flash").remote() end, { desc = "Remote Flash" })
              vim.keymap.set({ "x", "o" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
              vim.keymap.set({ "c" }, "<c-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })
            '';
        }
        {
          plugin = which-key-nvim;
          config =
            fromLua
            /*
            lua
            */
            "require('which-key').setup({})";
        }
      ];
    };
    zathura = {
      enable = true;
      options = {
        default-fg = "#${config.colorScheme.colors.base05}";
        default-bg = "#${config.colorScheme.colors.base00}";

        completion-bg = "#${config.colorScheme.colors.base02}";
        completion-fg = "#${config.colorScheme.colors.base05}";
        completion-highlight-bg = "#${config.colorScheme.colors.base03}";
        completion-highlight-fg = "#${config.colorScheme.colors.base05}";
        completion-group-bg = "#${config.colorScheme.colors.base02}";
        completion-group-fg = "#${config.colorScheme.colors.base0D}";

        statusbar-fg = "#${config.colorScheme.colors.base05}";
        statusbar-bg = "#${config.colorScheme.colors.base02}";

        notification-bg = "#${config.colorScheme.colors.base02}";
        notification-fg = "#${config.colorScheme.colors.base05}";
        notification-error-bg = "#${config.colorScheme.colors.base02}";
        notification-error-fg = "#${config.colorScheme.colors.base08}";
        notification-warning-bg = "#${config.colorScheme.colors.base02}";
        notification-warning-fg = "#${config.colorScheme.colors.base0A}";

        inputbar-fg = "#${config.colorScheme.colors.base05}";
        inputbar-bg = "#${config.colorScheme.colors.base02}";

        recolor-lightcolor = "#${config.colorScheme.colors.base00}";
        recolor-darkcolor = "#${config.colorScheme.colors.base05}";

        index-fg = "#${config.colorScheme.colors.base05}";
        index-bg = "#${config.colorScheme.colors.base00}";
        index-active-fg = "#${config.colorScheme.colors.base05}";
        index-active-bg = "#${config.colorScheme.colors.base02}";

        render-loading-bg = "#${config.colorScheme.colors.base00}";
        render-loading-fg = "#${config.colorScheme.colors.base05}";

        highlight-color = "#${config.colorScheme.colors.base03}";
        highlight-fg = "#${config.colorScheme.colors.base09}";
        highlight-active-color = "#${config.colorScheme.colors.base09}";
      };
    };
    mpv = {
      enable = true;
      bindings = {
        MBTN_RIGHT = "ignore";
        MBTN_LEFT = "cycle pause";
      };
    };
    feh = {
      enable = true;
      buttons = {
        prev_img = null;
        next_img = null;
        zoom_in = 4;
        zoom_out = 5;
      };
    };
    firefox = {
      enable = true;
      profiles.${config.home.username} = {
        settings = {
          "dom.security.https_only_mode" = true;
          "browser.download.panel.shown" = true;
          "browser.download.dir" = "/home/${config.home.username}/downloads";
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.startup.page" = 3;
          "general.autoScroll" = true;
          "layout.css.prefers-color-scheme.content-override" = 0;
          "widget.non-native-theme.scrollbar.style" = 5;
          "signon.rememberSignons" = false;
        };
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          firefox-color
          search-by-image
          simple-tab-groups
          browserpass
          darkreader
          stylus
          ublock-origin
          youtube-shorts-block
        ];

        search.engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@np"];
          };
          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@no"];
          };
          "Home Manage Options" = {
            urls = [
              {
                template = "https://mipmip.github.io/home-manager-option-search";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@hm"];
          };
        };
        search.force = true;
      };
    };
    kitty = {
      enable = true;
      settings = {
        shell = "nu";
        window_padding_width = 5;
        enable_audio_bell = false;
        font_size = 12;
        font_family = "CaskaydiaCove NF";
        bold_font = "CaskaydiaCove NF Bold";
        italic_font = "CaskaydiaCove NF Italic";
        bold_italic_font = "CaskaydiaCove NF Bold Italic";
        font_features = "CaskaydiaCoveNF-Regular +ss02 +ss20 CaskaydiaCoveNF-Italic +ss02 +ss20 CaskaydiaCoveNF-BoldItalic +ss02 +ss20";
      };
      theme = "Catppuccin-Mocha";
    };
    starship = {
      enable = true;
      enableNushellIntegration = true;
    };

    joshuto = {
      enable = true;
    };
    nushell = {
      enable = true;

      configFile.text =
        /*
        nu
        */
        ''
          $env.config = {
            shell_integration: true
            use_kitty_protocol: true
            edit_mode: vi
            show_banner: false

            rm: {
              always_trash: true
            }
            filesize: {
              metric: true
            }
            cursor_shape: {
              vi_insert: line
              vi_normal: block
            }
          }
          ${(pkgs.fortune.override {withOffensive = true;})}/bin/fortune -a | ${pkgs.lolcrab}/bin/lolcrab --custom "${config.colorScheme.colors.base08}" "${config.colorScheme.colors.base09}" "${config.colorScheme.colors.base0A}" "${config.colorScheme.colors.base0B}" "${config.colorScheme.colors.base0C}" "${config.colorScheme.colors.base0D}" --scale 0.1
        '';
      shellAliases = let
        aliases = {
          # vim = "nvim";
          cat = "${pkgs.bat}/bin/bat";
        };
      in
        lib.attrsets.mapAttrs' (name: value: lib.attrsets.nameValuePair "'sudo ${name}'" ("sudo " + value)) aliases;

      # (pkgs.symlinkJoin {
      #   name = "youtube-music";
      #   paths = [stable.youtube-music];
      #   buildInputs = [pkgs.makeWrapper];
      #   postBuild = ''
      #     wrapProgram $out/bin/youtube-music \
      #       --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
      #   '';
      # })
      # vesktop
      environmentVariables = builtins.mapAttrs (name: value:
        if value != ""
        then "\"${builtins.toString value}\""
        else "''")
      config.home.sessionVariables;
    };
    git = {
      enable = true;
      userName = "VerdeQuar";
      userEmail = "verdequar@gmail.com";
      delta = {
        enable = true;
        options = {
          catppuccin = {
            dark = true;
            line-numbers = true;
            side-by-side = true;
            syntax-theme = "catppuccin";
            plus-style = ''syntax "#384D35"'';
            minus-style = ''syntax "#764351"'';
            plus-emph-style = ''syntax "#395426"'';
            minus-emph-style = ''syntax "#9C393A"'';
            line-numbers-plus-style = ''"#395426" bold'';
            line-numbers-minus-style = ''"#9C393A" bold'';
            map-styles = ''bold purple => syntax "#62517A", bold blue => syntax "#435A7D", bold cyan => syntax "#314C46", bold yellow => syntax "#635844"'';
            zero-style = ''syntax'';
            whitespace-error-style = ''"#${config.colorScheme.colors.base05}"'';
          };

          features = "catppuccin";
          whitespace-error-style = "22 reverse";
        };
      };
      extraConfig = {
        commit.gpgsigh = true;
        push = {autoSetupRemote = true;};
        diff = {colorMoved = "default";};
        credential.helper = "${pkgs.git.override {withLibsecret = true;}}/bin/git-credential-libsecret";
      };
      aliases = {
        c = "commit";
        p = "push origin main";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        st = "status";
        co = "checkout";
      };
    };
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      extraConfig = {
        modi = "drun";
        icon-theme = "Oranchelo";
        show-icons = true;
        terminal = "kitty";
        drun-display-format = "{icon} {name}";
        location = 0;
        hide-scrollbar = true;
        display-drun = "  Apps";
        display-window = "  Window";
      };
      theme = "${(pkgs.writeText "config.rasi" (builtins.replaceStrings ["width: 600" "height: 360px;"] ["width: 75%" "height: 75%;"] (builtins.readFile (inputs.catppuccin-rofi + "/basic/.local/share/rofi/themes/catppuccin-mocha.rasi"))))}";
      pass = {
        enable = true;
        stores = [config.programs.password-store.settings.PASSWORD_STORE_DIR];
      };
    };
    btop = {
      enable = true;
      settings = {
        color_theme = "dracula";
        theme_background = false;
        rounded_corners = true;
        graph_symbol = "braille";
        proc_tree = true;
      };
    };
    password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [
        exts.pass-otp
        exts.pass-audit
        exts.pass-import
        exts.pass-update
      ]);
      settings = {
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
      };
    };
    browserpass = {
      enable = true;
      browsers = ["firefox"];
    };
    gh = {
      enable = true;
      settings = {
        aliases = {};
      };
    };
  };
  # TODO
  # aniwall

  gtk = {
    enable = true;
    theme = {
      package = pkgs.catppuccin-gtk.override {
        accents = ["pink"];
        variant = "mocha";
      };
      name = "Catppuccin-Mocha-Standard-Pink-Dark";
    };
    cursorTheme = {
      package = common.xcursor.theme.package;
      name = common.xcursor.theme.name;
      size = common.xcursor.theme.size;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      exec-once = [
        "hyprctl setcursor ${common.xcursor.theme.name} ${toString common.xcursor.theme.size}"
        ''${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${common.xcursor.theme.package}/share/icons/${common.xcursor.theme.name}/cursors/left_ptr ${toString common.xcursor.theme.size}''
        "${pkgs.swww}/bin/swww init"
        "hyprctl dispatch workspace 3"
        "discord"
        "firefox"
      ];
      bind = [
        "CONTROL, space, exec, kitty"
        "SUPER, Q, killactive, "
        "SUPER SHIFT, F, togglefloating, "
        "SUPER, F, fullscreen, "
        '', Print, exec, ${pkgs.dash}/bin/dash -c "${pkgs.grim}/bin/grim -g '$(${pkgs.slurp}/bin/slurp)' - | ${pkgs.wl-clipboard}/bin/wl-copy"''
        ''SUPER, W, exec, ${pkgs.nushell}/bin/nu "${pkgs.aniwall}/bin/aniwall --width (${pkgs.hyprland}/bin/hyprctl monitors | parse --regex '(?P<width>\w+)x(?P<height>\w+)@' | get width) --height (${pkgs.hyprland}/bin/hyprctl monitors | parse --regex '(?P<width>\w+)x(?P<height>\w+)@' | get height) set random --category Liked --rating questionable"''
        ''SUPERSHIFT, W, exec, ${pkgs.nushell}/bin/nu "${pkgs.aniwall}/bin/aniwall --width (${pkgs.hyprland}/bin/hyprctl monitors | parse --regex '(?P<width>\w+)x(?P<height>\w+)@' | get width) --height (${pkgs.hyprland}/bin/hyprctl monitors | parse --regex '(?P<width>\w+)x(?P<height>\w+)@' | get height) set previous"''

        "SUPER,1,workspace,1"
        "SUPER,2,workspace,2"
        "SUPER,3,workspace,3"
        "SUPER,4,workspace,4"
        "SUPER,5,workspace,5"
        "SUPER,6,workspace,6"
        "SUPER,7,workspace,7"
        "SUPER,8,workspace,8"
        "SUPER,9,workspace,9"
        "SUPER,0,workspace,10"

        "SUPER,right,workspace,+1"
        "SUPER,left,workspace,-1"

        "SUPERSHIFT,1,movetoworkspace,1"
        "SUPERSHIFT,2,movetoworkspace,2"
        "SUPERSHIFT,3,movetoworkspace,3"
        "SUPERSHIFT,4,movetoworkspace,4"
        "SUPERSHIFT,5,movetoworkspace,5"
        "SUPERSHIFT,6,movetoworkspace,6"
        "SUPERSHIFT,7,movetoworkspace,7"
        "SUPERSHIFT,8,movetoworkspace,8"
        "SUPERSHIFT,9,movetoworkspace,9"
        "SUPERSHIFT,0,movetoworkspace,10"

        "SUPERSHIFT,right,movetoworkspace,+1"
        "SUPERSHIFT,left,movetoworkspace,-1"
      ];
      bindl = [
        ",switch:on:Lid Switch,exec,hyprctl keyword monitor 'eDP-1${config.wayland.windowManager.hyprland.settings.monitor}'"
        ",switch:off:Lid Switch,exec,hyprctl keyword monitor 'eDP-1, disable'"
      ];
      bindeli = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ];
      bindm = [
        "SUPER,mouse:272,movewindow"
        "SUPER,mouse:273,resizewindow"
      ];
      windowrule = [
        "workspace 1 silent,^(discord)$"
        "workspace 2 silent,^(firefox)$"
        "workspace 10,^(YouTube Music)$"
      ];
      xwayland.force_zero_scaling = true;
      input = {
        kb_layout = "pl";
        kb_variant = "basic";
        scroll_method = "2fg";
        # scroll_method = "edge";
        touchpad = {
          drag_lock = true;
          tap-and-drag = true;
          # clickfinger_behavior = false;
        };
      };
      gestures = {
        workspace_swipe = true;
        workspace_swipe_forever = false;
        workspace_swipe_cancel_ratio = 0.25;
        workspace_swipe_direction_lock = false;
      };
      misc = {
        enable_swallow = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
      };
      general = {
        border_size = 2;

        gaps_in = 5;
        gaps_out = 10;
        "col.inactive_border" = "rgba(${config.colorScheme.colors.base00}cc) rgba(${config.colorScheme.colors.base04}ff) 45deg";
        "col.active_border" = "rgba(${config.colorScheme.colors.base08}ff) rgba(${config.colorScheme.colors.base09}ff) rgba(${config.colorScheme.colors.base0A}ff) rgba(${config.colorScheme.colors.base0B}ff) rgba(${config.colorScheme.colors.base0C}ff) rgba(${config.colorScheme.colors.base0D}ff) 0deg";
      };
      bezier = "linear, 0.0, 0.0, 1.0, 1.0";
      animation = [
        "borderangle, 1, 100, linear, loop"
      ];
      decoration = {
        rounding = 5;
        active_opacity = 0.99;
        inactive_opacity = 0.97;
        fullscreen_opacity = 1.0;
      };
    };
  };

  systemd.user.services = {
    scan-known-hosts = {
      Unit = {
        Description = "scan known hosts";
        After = ["sops-nix.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.nushell}/bin/nu -c "if (not ('${config.home.homeDirectory}/.ssh/known_hosts' | path exists)) or (not (${pkgs.coreutils}/bin/cat ${config.home.homeDirectory}/.ssh/known_hosts | str contains 'github.com ssh-ed25519')) { ${pkgs.openssh}/bin/ssh-keyscan -t ed25519 github.com | save -a ${config.home.homeDirectory}/.ssh/known_hosts;}"
        '';
      };
      Install.WantedBy = ["default.target"];
    };
    decrypt-codeium-key = {
      Unit = {
        Description = "decrypt codeium key";
        After = ["sops-nix.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.nushell}/bin/nu -c "mkdir ${config.xdg.cacheHome}/nvim/codeium; echo $'{ \"api_key\": \"(${pkgs.coreutils}/bin/cat /run/user/1000/secrets/codeium_key)\" }' | save -f ${config.xdg.cacheHome}/nvim/codeium/config.json;"
        '';
      };
      Install.WantedBy = ["default.target"];
    };
    clone-password-store = {
      Unit = {
        Description = "clone password store repo to a default location";
        After = [
          "sops-nix.service"
          "scan-known-hosts.service"
        ];
      };
      Service = {
        Type = "oneshot";
        Environment = "PATH=${lib.makeBinPath [pkgs.openssh]}";
        ExecStart = ''
          ${pkgs.nushell}/bin/nu -c 'try { ${pkgs.git}/bin/git clone git@github.com:VerdeQuar/pwd-store.git "${config.programs.password-store.settings.PASSWORD_STORE_DIR}" }'
        '';
      };
      Install.WantedBy = ["default.target"];
    };
    copy-dot-initial = {
      Unit.Description = "copy .initial files so that the copy is writable";
      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.nushell}/bin/nu -c 'try { ls -a ${config.xdg.configHome}/**/*.initial | get name | path parse | each {|path| cp -f $\"($path.parent)/($path.stem).($path.extension)\" $\"($path.parent)/($path.stem)\"}}; ${pkgs.inotify-tools}/bin/inotifywait -e create -m -r -q  ${config.xdg.configHome} | each {|i| $i | split column \" \" | each {|$j| if ($j.column3 | str trim | str ends-with \".initial\") { [$\"($j.column1)($j.column3)\"] | str trim | path parse | each {|path| try { cp $\"($path.parent)/($path.stem).($path.extension)\" $\"($path.parent)/($path.stem)\"}}}}}'
        '';
      };
      Install.WantedBy = ["default.target"];
    };
  };
  services = {
    volnoti.enable = true;
    mako = {
      enable = true;
      borderRadius = 5;
      borderSize = 2;
      margin = "15";
      padding = "10";
      layer = "overlay";
      font = "monospace 11";
      width = 400;

      backgroundColor = "#${config.colorScheme.colors.base00}";
      textColor = "#${config.colorScheme.colors.base05}";
      borderColor = "#${config.colorScheme.colors.base06}";
      progressColor = "over #${config.colorScheme.colors.base02}";
      extraConfig = ''
        [urgency=high]
        border-color=#${config.colorScheme.colors.base09}
      '';

      defaultTimeout = 5000;
    };
    blueman-applet.enable = true;
    ssh-agent.enable = true;
    gnome-keyring = {
      enable = true;
      components = ["ssh" "secrets"];
    };
  };

  xdg = {
    mimeApps.defaultApplications = {
      "text/plain" = ["codium.desktop"];
      "application/pdf" = ["zathura.desktop"];
      "video/*" = ["mpv.desktop"];
      "image/*" = ["feh.desktop"];
    };
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/desktop";
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      music = "${config.home.homeDirectory}/audio";
      pictures = "${config.home.homeDirectory}/pictures";
      publicShare = "${config.home.homeDirectory}/public";
      templates = "${config.home.homeDirectory}/templates";
      videos = "${config.home.homeDirectory}/videos";
    };
    configFile = {
      "sops/age/keys.txt" = lib.mkIf (builtins.pathExists ../sops/key.txt) {source = ../sops/key.txt;};
      "aniwall/config.json.initial".text = builtins.toJSON {
        set_wallpaper_command = "${pkgs.swww}/bin/swww img {} --transition-type center";
        wallpapers_dir = "${config.xdg.userDirs.pictures}/wallpapers";
      };
      "nixpkgs/config.nix".text = ''
        {
          allowUnfree = true;
        }
      '';
      "YouTube Music/config.json.initial".text = builtins.toJSON {
        __internal__ = {migrations = {version = "1.20.0";};};
        options = {
          appVisible = true;
          autoResetAppCache = false;
          autoUpdates = true;
          disableHardwareAcceleration = false;
          hideMenu = false;
          proxy = "";
          restartOnConfigChanges = false;
          resumeOnStart = true;
          startAtLogin = false;
          startingPage = "";
          tray = false;
          trayClickPlayPause = false;
          themes = [
            (inputs.catppuccin-youtubemusic + "/src/mocha.css")
          ];
        };
        plugins = {
          adblocker = {
            additionalBlockLists = [];
            cache = true;
            enabled = true;
          };
          captions-selector = {
            disableCaptions = false;
            enabled = true;
          };
          crossfade = {
            enabled = false;
            fadeInDuration = 1500;
            fadeOutDuration = 5000;
            fadeScaling = "linear";
            secondsBeforeEnd = 10;
          };
          discord = {
            activityTimoutEnabled = true;
            activityTimoutTime = 600000;
            autoReconnect = true;
            enabled = true;
            hideDurationLeft = false;
            listenAlong = true;
          };
          downloader = {
            enabled = false;
            ffmpegArgs = [];
            preset = "mp3";
          };
          last-fm = {
            api_key = "04d76faaac8726e60988e14c105d421a";
            api_root = "http://ws.audioscrobbler.com/2.0/";
            enabled = false;
            secret = "a5d2a36fdf64819290f6982481eaffa2";
          };
          navigation = {enabled = true;};
          notifications = {
            enabled = true;
            hideButtonText = false;
            interactive = true;
            refreshOnPlayPause = false;
            toastStyle = 1;
            trayControls = true;
            unpauseNotification = true;
            urgency = "normal";
          };
          picture-in-picture = {
            alwaysOnTop = true;
            enabled = false;
            hotkey = "P";
            savePosition = true;
            saveSize = false;
          };
          precise-volume = {
            arrowsShortcut = true;
            enabled = false;
            globalShortcuts = {
              volumeDown = "";
              volumeUp = "";
            };
            steps = 1;
          };
          shortcuts = {
            enabled = false;
            overrideMediaKeys = false;
          };
          skip-silences = {onlySkipBeginning = false;};
          sponsorblock = {
            apiURL = "https://sponsor.ajay.app";
            categories = ["sponsor" "intro" "outro" "interaction" "selfpromo" "music_offtopic"];
            enabled = false;
          };
          video-toggle = {
            enabled = true;
            forceHide = false;
            mode = "custom";
          };
          visualizer = {
            butterchurn = {
              blendTimeInSeconds = 2.7;
              preset = "martin [shadow harlequins shape code] - fata morgana";
              renderingFrequencyInMs = 500;
            };
            enabled = false;
            type = "butterchurn";
            vudio = {
              accuracy = 128;
              effect = "lighting";
              lighting = {
                color = "#49f3f7";
                dottify = true;
                fadeSide = true;
                horizontalAlign = "center";
                lineWidth = 1;
                maxHeight = 160;
                maxSize = 12;
                prettify = false;
                shadowBlur = 2;
                shadowColor = "rgba(244,244,244,.5)";
                verticalAlign = "middle";
              };
            };
            wave = {
              animations = [
                {
                  config = {
                    bottom = true;
                    count = 30;
                    cubeHeight = 5;
                    fillColor = {gradient = ["#FAD961" "#F76B1C"];};
                    lineColor = "rgba(0,0,0,0)";
                    radius = 20;
                  };
                  type = "Cubes";
                }
                {
                  config = {
                    count = 12;
                    cubeHeight = 5;
                    fillColor = {gradient = ["#FAD961" "#F76B1C"];};
                    lineColor = "rgba(0,0,0,0)";
                    radius = 10;
                    top = true;
                  };
                  type = "Cubes";
                }
                {
                  config = {
                    count = 10;
                    diameter = 20;
                    frequencyBand = "base";
                    lineColor = {
                      gradient = ["#FAD961" "#FAD961" "#F76B1C"];
                      rotate = 90;
                    };
                    lineWidth = 4;
                  };
                  type = "Circles";
                }
              ];
            };
          };
          "lyrics-genius" = {
            enabled = true;
            romanizedLyrics = true;
          };
          "no-google-login" = {
            enabled = true;
          };
        };
        url = "https://music.youtube.com";
        window-maximized = false;
        window-position = {
          x = 0;
          y = 0;
        };
        window-size = {
          height = 840;
          width = 749;
        };
      };
      # "VencordDesktop/VencordDesktop/settings.json.initial".text = builtins.toJSON {
      #   splashTheming = true;
      #   firstLaunch = false;
      #   minimizeToTray = "on";
      #   discordBranch = "stable";
      #   arRPC = "on";
      # };
      # "VencordDesktop/VencordDesktop/settings/settings.json".text = builtins.toJSON {
      "Vencord/settings/settings.json.initial".text = builtins.toJSON {
        themeLinks = [
          "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
        ];
        plugins = {
          AlwaysAnimate.enabled = true;
          AnonymiseFileNames.enabled = true;
          BetterUploadButton.enabled = true;
          CallTimer.enabled = true;
          ClearURLs.enabled = true;
          CrashHandler.enabled = true;
          DisableDMCallIdle.enabled = true;
          FakeNitro.enabled = true;
          FavoriteEmojiFirst.enabled = true;
          FavoriteGifSearch.enabled = true;
          FixSpotifyEmbeds.enabled = true;
          GifPaste.enabled = true;
          ImageZoom.enabled = true;
          MemberCount.enabled = true;
          MessageLinkEmbeds.enabled = true;
          MessageLogger.enabled = true;
          MoreCommands.enabled = true;
          NoF1.enabled = true;
          NoUnblockToJump.enabled = true;
          NormalizeMessageLinks.enabled = true;
          OnePingPerDM.enabled = true;
          OpenInApp.enabled = true;
          PermissionsViewer.enabled = true;
          ReverseImageSearch.enabled = true;
          RoleColorEverywhere.enabled = true;
          SendTimestamps.enabled = true;
          ServerProfile.enabled = true;
          ShowMeYourName.enabled = true;
          StartupTimings.enabled = true;
          TypingIndicator.enabled = true;
          TypingTweaks.enabled = true;
          Unindent.enabled = true;
          ValidUser.enabled = true;
          ViewRaw.enabled = true;
          VoiceMessages.enabled = true;
          VolumeBooster.enabled = true;
          WhoReacted.enabled = true;
        };
      };
      "fontconfig/fonts.conf".text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Fallback fonts preference order -->
          <alias>
            <family>sans-serif</family>
            <prefer>
              <family>Noto Sans</family>
            </prefer>
          </alias>
          <alias>
            <family>serif</family>
            <prefer>
              <family>Noto Serif</family>
            </prefer>
          </alias>
          <alias>
            <family>monospace</family>
            <prefer>
              <family>CaskaydiaCove Nerd Font</family>
            </prefer>
          </alias>
        </fontconfig>
      '';
      "discord/settings.json".text = ''{ "DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING": true, "SKIP_HOST_UPDATE": true }'';
      "qBittorrent/qBittorrent.conf".text = ''
        [BitTorrent]
        Session\GlobalMaxSeedingMinutes=0
      '';
    };
  };
}
