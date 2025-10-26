{ config, pkgs, ... }:

{
  # Home Manager configuration for user-level dotfiles and applications
  
  home.username = "yourusername"; # Change this
  home.homeDirectory = "/home/yourusername"; # Change this

  # Packages to install for this user
  home.packages = with pkgs; [
    # Development tools
    vscode
    # neovim
    
    # Browsers
    firefox
    # chromium
    
    # Terminal emulators
    # alacritty
    # kitty
    # wezterm
    
    # File managers
    # thunar
    # ranger
    # nnn
    
    # Media
    # mpv
    # vlc
    # spotify
    
    # Communication
    # discord
    # slack
    
    # Screenshots and screen recording
    # flameshot
    # maim
    # obs-studio
    
    # System utilities
    # rofi
    # dunst
    # polybar
    # picom
    
    # Ricing essentials
    # lxappearance
    # nitrogen  # wallpaper setter
    # pywal     # color scheme generator
    
    # Themes and icons
    # papirus-icon-theme
    # arc-theme
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };

  # Terminal configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # autosuggestion.enable = true;
    # syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "ls -la";
      update = "sudo nixos-rebuild switch --flake .#my-machine";
      # Add more aliases
    };
    
    # oh-my-zsh = {
    #   enable = true;
    #   theme = "robbyrussell";
    #   plugins = [ "git" "sudo" ];
    # };
  };

  # Bash configuration (if you prefer bash)
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      update = "sudo nixos-rebuild switch --flake .#my-machine";
    };
  };

  # Starship prompt
  # programs.starship = {
  #   enable = true;
  #   settings = {
  #     add_newline = false;
  #   };
  # };

  # GTK theming
  gtk = {
    enable = true;
    # theme = {
    #   name = "Arc-Dark";
    #   package = pkgs.arc-theme;
    # };
    # iconTheme = {
    #   name = "Papirus-Dark";
    #   package = pkgs.papirus-icon-theme;
    # };
  };

  # Qt theming
  # qt = {
  #   enable = true;
  #   platformTheme.name = "gtk";
  # };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Home Manager state version
  home.stateVersion = "25.05";
}
