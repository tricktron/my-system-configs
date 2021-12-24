{
  description = "My Darwin System";

  inputs = {
    stable.url = "github:nixos/nixpkgs/nixpkgs-21.11-darwin";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "stable";
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    nix-direnv.url = "github:nix-community/nix-direnv";
  };

  outputs = { self, nixpkgs, darwin, neovim-nightly, nix-direnv, ... }:
    {
      darwinConfigurations."matterhorn" = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        inputs = { inherit neovim-nightly nix-direnv; };
        modules = [ ./darwin-configuration.nix ];
      };
    };
}
