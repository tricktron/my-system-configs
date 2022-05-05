{ pkgs, private-flake }:
{
    extensions   = with pkgs.vscode-extensions;
    [
        redhat.java
        jnoortheen.nix-ide
        asvetliakov.vscode-neovim
        editorconfig.editorconfig
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace
    [
        {
              name       = "vscode-xml";
              publisher  = "redhat";
              version    = "0.20.0";
              sha256     = "sha256-GKBrf9s8n7Wv14RSfwyDma1dM0fGMvRkU/7v2DAcB9A=";
        }
    ] ++ [ private-flake.packages.${pkgs.system}.vscodeDraculaProTheme ];
}