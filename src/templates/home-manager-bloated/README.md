
TODO: revise the flake.nix and add what may be missing.
```nix
  nixpkgs.config = {
    allowBroken = false;
    allowUnfree = true;
  };


  nix = {
    enable = true;
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      show-trace = false;
      keep-outputs = true;
      keep-derivations = true;
    };
  };



  "nix" = {
    "enableLanguageServer" = false;
    "formatterPath" = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
    "serverPath" = "${pkgs.rnix-lsp}/bin/rnix-lsp";
  };
  "[nix]" = {
    "editor.insertSpaces" = true;
    "editor.tabSize" = 2;
  };



plugins = with pkgs.vimPlugins; [
  # (nvim-treesitter.withAllGrammars)
  # Tree sitter
  {
    plugin = nvim-treesitter.withAllGrammars;
    type = "lua";
    config = /* lua */ ''
      require('nvim-treesitter.configs').setup{
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      }
    '';
  }                  
];


xdg.configFile."nvim" = { source = "${pkgs.nvchad}"; };

# startLSP
nodePackages_latest.pyright # Python
nodePackages_latest.bash-language-server # Bash
lua-language-server # Lua
ccls # C
nil # Nix
texlab # Latex
# Web stuff LSP
nodePackages_latest.vscode-html-languageserver-bin
nodePackages_latest.vscode-css-languageserver-bin
nodePackages_latest.vscode-json-languageserver
nodePackages_latest.typescript-language-server

# Formatting 
nixfmt # Nix Formatting
nodePackages_latest.prettier # HTML/CSS/Markdown Formatting
stylua # Lua Formatting
# endLSP

bufferline-nvim
catppuccin-nvim
cmp-nvim-lsp
cmp-path
cmp_luasnip
comment-nvim
csv-vim
dart-vim-plugin
friendly-snippets
gemini-vim-syntax
gitsigns-nvim
haskell-vim
hmts-nvim
indent-blankline-nvim
kotlin-vim
lualine-nvim
luasnip
mermaid-vim
neodev-nvim
nvim-cmp
nvim-compe
nvim-lspconfig
nvim-surround
nvim-treesitter-context
nvim-treesitter-refactor
nvim-treesitter-textobjects
nvim-treesitter.withAllGrammars
nvim-web-devicons
oil-nvim                
pgsql-vim
plantuml-syntax
plenary-nvim
rust-vim
telescope-fzf-native-nvim                        
telescope-manix
telescope-nvim
undotree
vim-caddyfile
vim-fugitive
vim-jsx-typescript
vim-markdown
vim-nix
vim-oscyank
vim-repeat
vim-rhubarb
vim-sleuth
vim-syntax-shakespeare
vim-terraform
vim-toml
which-key-nvim


#  programs.direnv = {
#    enable = true;
#    nix-direnv = {
#      enable = true;
#    };
#    enableZshIntegration = true;
#  };
#
#  programs.fzf = {
#    enable = true;
#    enableZshIntegration = true;
#  };
#
#  programs.nix-index = {
#    enable = true;
#    enableZshIntegration = true;
#  };
# # https://nixos.wiki/wiki/VSCodium
#  programs.vscode = {
#    enable = true;
#    package = pkgs.vscodium;
#    extensions = (with pkgs.vscode-extensions; [
#      arrterian.nix-env-selector
#      bbenoist.nix
#      brettm12345.nixfmt-vscode
#      catppuccin.catppuccin-vsc
#      jnoortheen.nix-ide
#      mkhl.direnv
#      streetsidesoftware.code-spell-checker
#    ]);
#    userSettings = {
#      "editor.formatOnSave" = false;
#      "workbench.colorTheme" = "Catppuccin Mocha";
#    };
#    enableExtensionUpdateCheck = false;
#    enableUpdateCheck = false;
#  };
#
#  programs.neovim = {
#    enable = true;
#    viAlias = true;
#    vimAlias = true;
#    vimdiffAlias = true;
#  };
```
