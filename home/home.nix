{ config, pkgs, ... }:

{
  imports = [
    ./hyprland.nix
  ];

  # Home Manager configuration for user-level dotfiles and applications
  
  home.username = "zeph";
  home.homeDirectory = "/home/zeph";

  # Packages to install for this user
  home.packages = with pkgs; [
    # Development tools
    vscode
    # neovim
    
    # Browsers
    # firefox
    # chromium
    
    # Terminal emulators
    alacritty
    # kitty
    # wezterm
    
    # File managers
    dolphin
    # thunar
    # ranger
    # nnn
    
    # Media
    # mpv
    # vlc
    # spotify
    
    # Communication
    legcord
    teams-for-linux
    # discord
    # slack
    
    # Screenshots and screen recording
    grim  # Screenshot tool for Wayland
    slurp  # Screen area selector for Wayland
    # obs-studio
    
    # Hyprland essentials
    waybar  # Status bar
    dunst  # Notifications
    wofi  # App launcher
    # rofi-wayland  # Alternative launcher
    
    # Wayland utilities
    wl-clipboard  # Clipboard for Wayland
    
    # Ricing essentials
    # hyprpaper  # Wallpaper daemon
    # swww  # Alternative animated wallpaper
    # lxappearance
    # pywal  # Color scheme generator
    
    # Themes and icons
    # papirus-icon-theme
    # arc-theme
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Zephrynis";
    userEmail = "zephrynis.yt@gmail.com";
  };

  # Terminal configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # autosuggestion.enable = true;
    # syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "ls -la";
      update-laptop = "cd ~/nix-flake && git pull && sudo nixos-rebuild switch --flake .#laptop";
      update-desktop = "cd ~/nix-flake && git pull && sudo nixos-rebuild switch --flake .#desktop";
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
      update-laptop = "cd ~/nix-flake && git pull && sudo nixos-rebuild switch --flake .#laptop";
      update-desktop = "cd ~/nix-flake && git pull && sudo nixos-rebuild switch --flake .#desktop";
    };
  };

  # Starship prompt
  # programs.starship = {
  #   enable = true;
  #   settings = {
  #     add_newline = false;
  #   };
  # };

  # Alacritty terminal emulator
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.9;
        padding = {
          x = 10;
          y = 10;
        };
      };
      
      font = {
        normal = {
          family = "FiraCode Nerd Font";
          style = "Regular";
        };
        size = 11.0;
      };
      
      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };
      };
      
      # Uncomment and customize as needed
      # cursor = {
      #   style = "Block";
      # };
    };
  };

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

  # Flatpaks are managed in system/flatpak.nix

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Home Manager state version
  home.stateVersion = "25.05";
}
