{ config, pkgs, inputs, ... }:

let java11 = pkgs.adoptopenjdk-openj9-bin-11;
in
{
  nixpkgs = {
    overlays = [
      inputs.neovim-nightly.overlay
      inputs.nix-direnv.overlay
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "openssl-1.0.2u" ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      openconnect
      aria
      starship
      direnv
      nix-direnv
      python3Packages.pygments
      mkvtoolnix-cli
      maven
      cachix
      nixpkgs-fmt
      gh
      config.programs.vim.package
      qemu
      gradle
    ] ++ [ java11 ];
    variables = {
      JAVA_HOME = "${java11}/Contents/Home";
    };
    pathsToLink = [ "/share/nix-direnv" ];
  };

  fonts = {
    enableFontDir = true;
    fonts = [ pkgs.fira-code ];
  };

  services.nix-daemon.enable = true;
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        "gs" = "git status";
      };
    };
    vim = {
      package = pkgs.neovim-nightly;
    };
  };

  nix = {
    maxJobs = 8;
    buildCores = 1;
    package = pkgs.nixUnstable;
    useSandbox = false;
    trustedUsers = [ "@admin" ];
    binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "tricktron.cachix.org-1:N1aBeQuELyEAOgvizaDC/qqFltwv7N7oSMaNozyDz6w="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
    binaryCaches = [
      "https://cache.nixos.org"
      "https://tricktron.cachix.org"
      "https://nix-community.cachix.org"
      "https://hydra.iohk.io"
    ];
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };
  system.defaults = {
    dock.autohide = true;
    dock.orientation = "left";
    trackpad.Clicking = true;
  };
  users.nix.configureBuildUsers = true;
}
