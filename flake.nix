{
    description = "My Darwin System";

    inputs =
    {
        darwin-stable.url                   = "github:nixos/nixpkgs/nixpkgs-21.11-darwin";
        nixpkgs-stable.url                  = "github:nixos/nixpkgs/release-21.11";
        nixpkgs-fork.url                    = "github:tricktron/nixpkgs/develop";
        darwin.url                          = "github:lnl7/nix-darwin/master";
        darwin.inputs.nixpkgs.follows       = "darwin-stable";
        home-manager.url                    = "github:nix-community/home-manager/release-21.11";
        home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    outputs =
    { 
        self, 
        nixpkgs,
        darwin,
        home-manager,
        nixpkgs-fork,
        ...
    }:
    {
        darwinConfigurations."gurten" = darwin.lib.darwinSystem rec
        {
            system = "aarch64-darwin";
            modules =
            [
                (home-manager.darwinModules.home-manager)(
                {
                    config,
                    lib,
                    pkgs,
                    ...
                }:
                {
                    nixpkgs =
                    {
                        config = { allowUnfree = true; };
                    };

                    fonts   =
                    {
                        enableFontDir = true;
                        fonts = with pkgs; [ fira-code jetbrains-mono ];
                    };

                    services.nix-daemon.enable = true;

                    nix     =
                    {
                        maxJobs               = 8;
                        buildCores            = 1;
                        package               = pkgs.nix_2_4;
                        useSandbox            = false;
                        trustedUsers          = [ "@admin" ];
                        binaryCachePublicKeys =
                        [
                            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                            "tricktron.cachix.org-1:N1aBeQuELyEAOgvizaDC/qqFltwv7N7oSMaNozyDz6w="
                            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                            "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
                        ];
                        binaryCaches =
                        [
                            "https://cache.nixos.org"
                            "https://tricktron.cachix.org"
                            "https://nix-community.cachix.org"
                            "https://hydra.iohk.io"
                        ];
                        extraOptions =
                        ''
                            experimental-features = nix-command flakes
                            keep-outputs          = true
                            keep-derivations      = true
                        '';
                        
                        nixPath      =
                        [
                            "/nix/var/nix/profiles/per-user/root/channels"
                            "\$HOME/.nix-defexpr/channels"
                            { nixpkgs-fork = "\$HOME/github/my-forks/nixpkgs"; }
                        ];
                    };

                    system.defaults               =
                    {
                        dock.autohide     = true;
                        dock.orientation  = "left";
                        trackpad.Clicking = true;
                    };

                    programs.zsh.enable = true;

                    environment.etc              =
                    {
                        "containers/containers.conf.d/99-gvproxy-path.conf".text = 
                        ''
                            [engine]
                            helper_binaries_dir = ["/etc/profiles/per-user/tricktron/bin"]
                        '';
                    };

                    users.nix.configureBuildUsers = true;
                    users.users.tricktron         =
                    {
                        name = "tricktron";
                        home = "/Users/tricktron";
                    };
                    home-manager.useGlobalPkgs   = true;
                    home-manager.useUserPackages = true;
                    home-manager.extraSpecialArgs =
                    {
                        pkgs-fork = import nixpkgs-fork
                        {
                            inherit (config.nixpkgs) config;
                            inherit system;
                        };
                        unstable  = import nixpkgs
                        {
                            inherit (config.nixpkgs) config;
                            inherit system;
                        };
                    };
                    home-manager.users.tricktron =
                    { 
                        config,
                        lib,
                        pkgs,
                        pkgs-fork,
                        unstable,
                        ...
                    }:
                    let
                        packages-unstable = with unstable;
                        [
                            libreoffice
                            teams
                            colima
                            docker-compose_2
                            docker
                            nixpkgs-review
                        ];
                        packages-fork = with pkgs-fork;
                        [
                            pkgs-fork.qemu
                            pkgs-fork.podman
                            pkgs-fork.podman-compose
                        ];
                    in
                    {
                        home =
                        {
                            packages = with pkgs;
                            [
                                gnupg
                                xz
                                gvproxy
                                (maven.override { jdk = jdk8; })
                                rnix-lsp
                                ((gradleGen.override { java = openjdk11; }).gradle_latest)
                            ]
                            ++ packages-fork
                            ++ packages-unstable;

                            file."Applications/home-manager".source =
                                let apps = pkgs.buildEnv
                                {
                                    name = "home-manager-apps";
                                    paths = with pkgs; [ alacritty vscode ] ++ packages-fork;
                                    pathsToLink = "/Applications";
                                };
                            in
                            lib.mkIf pkgs.stdenv.targetPlatform.isDarwin "${apps}/Applications";

                            shellAliases =
                            {
                                drsf           = "darwin-rebuild switch --flake";
                            };

                            sessionVariables =
                            {
                                EDITOR = "nvim";
                            };
                        };

                        targets.darwin.defaults = 
                        {
                            "com.microsoft.VSCode" =
                            {
                              "ApplePressAndHoldEnabled" = false;
                            };
                        };

                        programs =
                        {
                            neovim =
                            {
                                enable      = true;
                                extraConfig =
                                ''
                                    set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab
                                '';
                            };

                            zsh    =
                            {
                                enable                   = true;
                                enableAutosuggestions    = true;
                                enableSyntaxHighlighting = true;
                                initExtra                =
                                ''
                                    if [ -f ~/.profile ]; then
                                        . ~/.profile
                                    fi
                                '';
                            };

                            starship =
                            {
                                enable = true;
                            };
                            
                            direnv =
                            {
                                enable     = true;
                                nix-direnv =
                                {
                                  enable       = true;
                                  enableFlakes = true;
                                };
                            };

                            gh     =
                            {
                                enable   = true;
                                settings =
                                {
                                    git_protocol = "ssh";
                                    prompt       = "enabled";
                                    aliases      =
                                    {
                                        co = "pr checkout";
                                        pv = "pr view";
                                    };
                                };
                            };

                            git    =
                            {
                                enable   = true;
                                aliases  =
                                {
                                    co = "checkout";
                                    cl = "clone";
                                };
                                signing  =
                                {
                                    signByDefault = true;
                                    key = "44BD0764ACAE8E25";
                                };
                                userEmail = "tgagnaux@gmail.com";
                                userName  = "Thibault Gagnaux";
                            };

                            ssh       =
                            {
                                enable         = true;
                                hashKnownHosts = true;
                                extraConfig    =
                                ''
                                    IgnoreUnknown UseKeychain
                                    UseKeychain yes
                                    IdentityFile ~/.ssh/gurten
                                    AddKeysToAgent yes
                                '';
                            };

                            java      =
                            {
                                enable  = true;
                                package = pkgs.openjdk11;
                            };

                            vscode    =
                            {
                                enable       = true;
                                extensions   = with pkgs.vscode-extensions;
                                [
                                    redhat.java
                                    jnoortheen.nix-ide
                                    asvetliakov.vscode-neovim
                                    editorconfig.editorconfig
                                ];

                                userSettings =
                                {
                                    "editor.fontFamily"                          = "Jetbrains Mono, monospace";
                                    "editor.fontLigatures"                       = true;
                                    "editor.rulers"                              = [80 100];
                                    "editor.scrollBeyondLastLine"                = false;
                                    "editor.fontSize"                            = 14;
                                    "editor.tabSize"                             = 4;
                                    "editor.formatOnSave"                        = false;
                                    "editor.detectIndentation"                   = false;
                                    "editor.insertSpaces"                        = true;
                                    "terminal.integrated.fontFamily"             = "Jetbrains Mono";
                                    "workbench.colorTheme"                       = "Dracula Pro (Van Helsing)";
                                    "files.autoSave"                             = "afterDelay";
                                    "nix.enableLanguageServer"                   = true;
                                    "vscode-neovim.neovimExecutablePaths.darwin" = 
                                        "${config.home.profileDirectory}/bin/nvim";
                                };
                                
                                keybindings  =
                                [
                                    {
                                        "key"     = "ctrl+j";
                                        "when"    = "editorTextFocus && !suggestWidgetVisible";
                                        "command" = "workbench.action.terminal.toggleTerminal";
                                    }
                                    {
                                        "key"     = "ctrl+j";
                                        "when"    = "editorTextFocus && suggestWidgetMultipleSuggestions && suggestWidgetVisible";
                                        "command" = "selectNextSuggestion";
                                    }
                                    {
                                        "key"     = "ctrl+j";
                                        "when"    = "inQuickOpen";
                                        "command" = "workbench.action.quickOpenNavigateNext";
                                    }
                                    {
                                        "key"     = "ctrl+k";
                                        "when"    = "terminalFocus";
                                        "command" = "workbench.action.terminal.toggleTerminal";
                                    }
                                    {
                                        "key"     = "ctrl+k";
                                        "when"    = "editorTextFocus && suggestWidgetMultipleSuggestions && suggestWidgetVisible";
                                        "command" = "selectPrevSuggestion";
                                    }
                                    {
                                        "key"     = "ctrl+k";
                                        "when"    = "inQuickOpen";
                                        "command" = "workbench.action.quickOpenNavigatePrevious";
                                    }
                                    {
                                        "key"     = "ctrl+h";
                                        "when"    = "editorTextFocus && activeEditorGroupIndex == 1";
                                        "command" = "workbench.action.focusSideBar";
                                    }
                                    {
                                        "key"     = "ctrl+h";
                                        "when"    = "editorTextFocus && activeEditorGroupIndex != 1";
                                        "command" = "workbench.action.focusPreviousGroup";
                                    }
                                    {
                                        "key"     = "ctrl+l";
                                        "when"    = "sideBarFocus";
                                        "command" = "workbench.action.focusFirstEditorGroup";
                                    }
                                    {
                                        "key"     = "ctrl+l";
                                        "when"    = "editorTextFocus";
                                        "command" = "workbench.action.focusNextGroup";
                                    }
                                ];
                            };

                            alacritty =
                            {
                                enable   = true;
                                settings =
                                {
                                    key_bindings =
                                    [
                                        {
                                            key   = 20;
                                            mods  = "Alt";
                                            chars = "#";
                                        }
                                        {
                                            key   = 22;
                                            mods  = "Alt";
                                            chars = "]";
                                        }
                                        {
                                            key   = 23;
                                            mods  = "Alt";
                                            chars = "[";
                                        }
                                        {
                                            key   = 25;
                                            mods  = "Alt";
                                            chars = "}";
                                        }
                                        {
                                            key   = 26;
                                            mods  = "Alt";
                                            chars = "|";
                                        }
                                        {
                                            key   = 26;
                                            mods  = "Shift|Alt";
                                            chars = "\\\\";
                                        }
                                        {
                                            key   = 28;
                                            mods  = "Alt";
                                            chars = "{";
                                        }
                                        {
                                            key   = 5;
                                            mods  = "Alt";
                                            chars = "@";
                                        }
                                    ];

                                    shell =
                                    {
                                        program = "${pkgs.zsh}/bin/zsh";
                                        args    = [ "-l" ];
                                    };

                                    font  =
                                    {
                                        normal =
                                        {
                                            family = "JetBrains Mono";
                                        };

                                        size   = 13.0;
                                    };

                                    colors =
                                    {
                                        primary =
                                        {
                                            background = "#0c0125";
                                            foreground = "#dcdbe0";
                                        };
                                        cursor  =
                                        {
                                            text   = "#0c0125";
                                            cursor = "#18dafe";
                                        };
                                        selection =
                                        {
                                            text       = "#0c0125";
                                            background = "#008cff";
                                        };
                                        normal =
                                        {
                                            black   = "#514a63";
                                            red     = "#ff4040";
                                            green   = "#73d988";
                                            yellow  = "#e5f224";
                                            blue    = "#008cff";
                                            magenta = "#e5599e";
                                            cyan    = "#0bcefd";
                                            white   = "#dcdbe0";
                                        };
                                        bright =
                                        {
                                            black   = "#746e82";
                                            red     = "#FF6666";
                                            green   = "#8FE1A0";
                                            yellow  = "#EAF550";
                                            blue    = "#33A3FF";
                                            magenta = "#EA7AB1";
                                            cyan    = "#3CD8FD";
                                            white   = "#ffffff";
                                        };
                                        dim =
                                        {
                                            black   = "#2f2544";
                                            red     = "#CE333B";
                                            green   = "#5EAE74";
                                            yellow  = "#BAC224";
                                            blue    = "#0270D3";
                                            magenta = "#BA4786";
                                            cyan    = "#0BA5D2";
                                            white   = "#bab6c1";
                                        };
                                    };

                                    window =
                                    {
                                        decorations = "buttonless";
                                        padding     =
                                        {
                                            y = 4;
                                        };
                                    };

                                    debug  =
                                    {
                                        print_events = true;
                                    };
                                };
                            };
                        };
                    };
                })
            ];
        };
    };
}
