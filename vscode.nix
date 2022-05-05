{ pkgs, config, private-flake, ... }:
{
    enable       = true;
    extensions   = (import ./vscode-extensions.nix { inherit pkgs private-flake; }).extensions;
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
        "editor.minimap.enabled"                     = false;
        "terminal.integrated.fontFamily"             = "Jetbrains Mono";
        "workbench.colorTheme"                       = "Dracula Pro (Van Helsing)";
        "files.autoSave"                             = "afterDelay";
        "nix.enableLanguageServer"                   = true;
        "vscode-neovim.neovimExecutablePaths.darwin" = "${config.home.profileDirectory}/bin/nvim";
        "xml.server.binary.path"                     =
            "\$HOME/github/integonch/lemminx/org.eclipse.lemminx/target/lemminx-osx-aarch_64-0.20.1-SNAPSHOT";
        "[nix]"                                      =
        {
            editor.tabSize = 4;
        };
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
}