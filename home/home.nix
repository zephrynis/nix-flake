{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hyprland.nix
  ];

  # Home Manager configuration for user-level dotfiles and applications
  
  home.username = "zeph";
  home.homeDirectory = "/home/zeph";

  # Packages to install for this user
  home.packages = with pkgs; [
    # Launcher
    inputs.vicinae.packages.${pkgs.system}.default  # Vicinae launcher
    
    # Development tools
    (vscode.override {
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
      ];
    })
    # neovim
    
    # Browsers
    # firefox
    # chromium
    
    # Terminal emulators
    alacritty
    # kitty
    # wezterm
    
    # File managers
    kdePackages.dolphin
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
    rofi-bluetooth  # Bluetooth menu
    networkmanagerapplet  # WiFi manager applet for system tray
    # rofi-wayland  # Alternative launcher
    
    # Wayland utilities
    wl-clipboard  # Clipboard for Wayland
    hyprcursor  # Hyprland cursor theme support
    # swww  # Animated wallpaper daemon (supports GIF/WebP/etc)
    mpvpaper  # Video wallpaper player (supports MP4)
    
    # Ricing essentials
    # hyprpaper  # Wallpaper daemon
    # swww  # Alternative animated wallpaper
    # lxappearance
    # pywal  # Color scheme generator
    
    # Themes and icons
    bibata-cursors  # Bibata cursor theme
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
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    
    # Increase font size for better readability on 4K
    font = {
      name = "Sans";
      size = 11;  # Increase if needed (default is usually 10)
    };
  };

  # Qt theming
  # qt = {
  #   enable = true;
  #   platformTheme.name = "gtk";
  # };
  
  # Cursor theme for Hyprland
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  
  # Override desktop entries to use Wayland flags for Electron apps
  xdg.desktopEntries = {
    legcord = {
      name = "Legcord";
      exec = "${pkgs.legcord}/bin/legcord --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland %U";
      icon = "legcord";
      type = "Application";
      categories = [ "Network" "InstantMessaging" ];
    };
    teams-for-linux = {
      name = "Microsoft Teams for Linux";
      exec = "${pkgs.teams-for-linux}/bin/teams-for-linux --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland %U";
      icon = "teams-for-linux";
      type = "Application";
      categories = [ "Network" "InstantMessaging" ];
    };
  };
  
  # Waybar configuration with glassmorphic theme
  home.file.".config/waybar/config".source = ./waybar-config.json;
  home.file.".config/waybar/style.css".source = ./waybar-style.css;

  # Flatpaks are managed in system/flatpak.nix

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Home Manager state version
  home.stateVersion = "25.05";
}
