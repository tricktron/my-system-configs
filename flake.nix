{
    description = "My Darwin System";

    inputs =
    {
        darwin-stable.url                   = "github:nixos/nixpkgs/nixpkgs-22.05-darwin";
        nixpkgs-stable.url                  = "github:nixos/nixpkgs/release-22.05";
        nixpkgs-fork.url                    = "github:tricktron/nixpkgs/develop";
        darwin.url                          = "github:lnl7/nix-darwin/master";
        darwin.inputs.nixpkgs.follows       = "darwin-stable";
        home-manager.url                    = "github:nix-community/home-manager/release-22.05";
        home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";
        private-flake.url                   = "git+ssh://git@github.com/tricktron/private-flake?ref=main";
        nixt.url                            = "github:tricktron/nixt/my-master";
    };

    outputs =
    { 
        self, 
        nixpkgs,
        darwin,
        home-manager,
        nixpkgs-fork,
        private-flake,
        nixt,
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
                    nixpkgs  =
                    {
                        config = { allowUnfree = true; };
                    };

                    fonts    =
                    {
                        fontDir.enable = true;
                        fonts = with pkgs; [ fira-code jetbrains-mono ];
                    };

                    
                    services =
                    {
                        nix-daemon.enable = true;
                        spotifyd          =
                        {
                            enable   = true;
                            settings =
                            {
                                username    = "116944127";
                                device_name = "gurten";
                                device_tpye = "computer";
                                use_keyring = true;
                                bitrate     = 320;
                            };

                            package  = (pkgs.spotifyd.override { withKeyring = true; });
                        };
                    };

                    nix      =
                    {
                        maxJobs               = 8;
                        buildCores            = 1;
                        package               = pkgs.nix;
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

                        distributedBuilds = true;

                        buildMachines =
                        [
                            {
                                hostName = "linuxbuilder";
                                maxJobs  = 1;
                                sshKey   = "~/.ssh/insecure_rsa";
                                sshUser  = "root";
                                systems   = ["x86_64-linux" "aarch64-linux"];
                            }
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
                        unstable  = import nixpkgs
                        {
                            inherit (config.nixpkgs) config;
                            inherit system;
                        };
                        pkgs-fork = import nixpkgs-fork
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
                            libreoffice-bin
                            teams
                            docker-compose
                            docker
                            docker-buildx
                            nixpkgs-review
                            cachix
                            nixt.defaultPackage.${system}
                            qemu
                            postman
                        ];

                        packages-fork = with pkgs-fork;
                        [
                            crc
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
                                (gradle_7.override
                                {
                                   java = jdk11;
                                })
                                spotify-tui
                                jq
                                colima
                                
                            ]
                            ++ packages-unstable
                            ++ packages-fork;

                            file."Applications/home-manager".source =
                                let apps = pkgs.buildEnv
                                {
                                    name = "home-manager-apps";
                                    paths = with pkgs; [ alacritty vscode ] ++ packages-unstable;
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
                            vscode = import ./vscode.nix { inherit pkgs config private-flake; };
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
                                matchBlocks    =
                                {
                                    "linuxbuilder" =
                                    {
                                        user         = "root";
                                        hostname     = "127.0.0.1";
                                        port         = 3022;
                                        identityFile = "~/.ssh/insecure_rsa";
                                    };
                                };
                            };

                            java      =
                            {
                                enable  = true;
                                package = pkgs.openjdk11;
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
