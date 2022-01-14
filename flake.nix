{
    description = "My Darwin System";

    inputs =
    {
        darwin-stable.url                   = "github:nixos/nixpkgs/nixpkgs-21.11-darwin";
        nixpkgs-stable.url                  = "github:nixos/nixpkgs/release-21.11";
        darwin.url                          = "github:lnl7/nix-darwin/master";
        darwin.inputs.nixpkgs.follows       = "darwin-stable";
        home-manager.url                    = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    outputs =
    { 
        self, 
        nixpkgs,
        nixpkgs-stable,
        darwin,
        home-manager, 
        ...
    }:
    {
        darwinConfigurations."gurten" = darwin.lib.darwinSystem
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
                        package               = pkgs.nixUnstable;
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
                    };

                    system.defaults               =
                    {
                        dock.autohide     = true;
                        dock.orientation  = "left";
                        trackpad.Clicking = true;
                    };

                    environment.etc."profile".text  = 
                    ''
                        # /etc/profile: DO NOT EDIT -- this file has been generated automatically.
                            . ${config.system.build.setEnvironment}
                        ${config.system.build.setAliases.text}
                        ${config.environment.interactiveShellInit}
                    '';

                    users.nix.configureBuildUsers = true;
                    users.users.tricktron         =
                    {
                        name = "tricktron";
                        home = "/Users/tricktron";
                    };
                    home-manager.useGlobalPkgs   = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.tricktron =
                    { 
                        config,
                        lib,
                        pkgs,
                        ...
                    }:
                    {
                        home =
                        {
                            packages = with pkgs;
                            [
                                oksh
                                gnupg
                            ];

                            file.".profile".source                  = pkgs.writeText "profile"
                            ''
                                . "/etc/profile"
                                . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
                            '';
                            file.".kshrc".source                    = pkgs.writeText "kshrc"
                            ''
                                export PS1="in \\e[0;34m\\W\\e[m \\e[0;33m➜\\e[m "
                                export CLICOLOR=1
                                # sets emacs edit mode to navigate history with arrow keys
                                set -o emacs
                                alias drsf="darwin-rebuild switch --flake"
                            '';

                            file."Applications/home-manager".source =
                                let apps = pkgs.buildEnv
                                {
                                    name = "home-manager-apps";
                                    paths = [ pkgs.alacritty ];
                                    pathsToLink = "/Applications";
                                };
                            in
                            lib.mkIf pkgs.stdenv.targetPlatform.isDarwin "${apps}/Applications";

                            sessionPath =
                            [
                                "/run/current-system/sw/bin"
                                "${config.home.profileDirectory}/bin"
                                "/usr/local/bin"
                                "/usr/bin"
                                "/bin"
                                "/usr/sbin"
                                "/sbin"
                            ];

                            sessionVariables =
                            {
                                ENV    = "$HOME/.kshrc";
                                EDITOR = "nvim";
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
                            direnv =
                            {
                                enable            = true;
                                nix-direnv.enable = true;
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

                            ssh =
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
                                        program = "${pkgs.oksh}/bin/oksh";
                                        args    = [ "-l" ];
                                    };

                                    font  =
                                    {
                                        normal =
                                        {
                                            family = "JetBrains Mono";
                                        };

                                        size   = 12.0;
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
                                            red     = "#ff453a";
                                            green   = "#30d158";
                                            yellow  = "#e5f224";
                                            blue    = "#008cff";
                                            magenta = "#ff33cc";
                                            cyan    = "#0bcefd";
                                            white   = "#dcdbe0";
                                        };
                                        bright =
                                        {
                                            black   = "#746e82";
                                            red     = "#FF6A61";
                                            green   = "#59DA79";
                                            yellow  = "#EAF550";
                                            blue    = "#33A3FF";
                                            magenta = "#FF5CD6";
                                            cyan    = "#3CD8FD";
                                            white   = "#ffffff";
                                        };
                                        dim =
                                        {
                                            black   = "#2f2544";
                                            red     = "#CE3736";
                                            green   = "#29A74E";
                                            yellow  = "#BAC224";
                                            blue    = "#0270D3";
                                            magenta = "#CE29AB";
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
