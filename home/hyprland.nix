{ config, pkgs, ... }:

{
  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    
    settings = {
      # Monitor configuration
      monitor = ",preferred,auto,1";
      
      # Autostart applications
      exec-once = [
        # For GIF/WebP/static images - use swww (works on all monitors):
        # "swww-daemon && swww img ~/nix-flake/assets/wallpaper.gif"
        
        # For MP4 videos - run separate instances per monitor for proper scaling:
        "mpvpaper -o 'no-audio loop' DP-2 ~/nix-flake/assets/wallpaper.mp4"
        "mpvpaper -o 'no-audio loop' DP-1 ~/nix-flake/assets/wallpaper.mp4"
        
        "waybar"
        "dunst"
        "nm-applet --indicator"  # WiFi manager in system tray
        "vicinae server"         # Start Vicinae server
      ];
      
      # Environment variables
      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Ice"
        "HYPRCURSOR_THEME,Bibata-Modern-Ice"
        "HYPRCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        
        # NVIDIA specific environment variables
        "LIBVA_DRIVER_NAME,nvidia"           # Hardware acceleration
        "GBM_BACKEND,nvidia-drm"             # Force GBM backend
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"   # GLX vendor
        "__GL_GSYNC_ALLOWED,1"               # Enable G-Sync if supported
        "__GL_VRR_ALLOWED,0"                 # Disable VRR to avoid game issues
        "WLR_NO_HARDWARE_CURSORS,1"          # Fix cursor issues on NVIDIA
        "WLR_DRM_NO_ATOMIC,1"                # Legacy mode (try disabling if issues)
        
        # Scaling for XWayland apps
        "GDK_SCALE,1.5"                      # GTK app scaling (matches 4K monitor scale)
        "GDK_DPI_SCALE,0.67"                 # GTK DPI scaling (inverse of GDK_SCALE)
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"      # Qt automatic scaling
        "QT_SCALE_FACTOR,1.5"                # Qt manual scaling for 4K monitor
      ];
      
      # Input configuration
      input = {
        kb_layout = "gb";
        follow_mouse = 1;
        
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
        };
        
        sensitivity = 0;
      };
      
      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        
        layout = "dwindle";
        allow_tearing = false;
      };
      
      # Enable better fractional scaling (experimental)
      xwayland = {
        force_zero_scaling = true;
      };
      
      # Decoration
      decoration = {
        rounding = 10;
        
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };
      
      # Animations
      animations = {
        enabled = true;
        
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
      
      # Layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      
      # Window rules
      windowrulev2 = [
        "float,class:^(pavucontrol)$"
        "float,class:^(blueman-manager)$"
      ];
      
      # Keybindings
      "$mod" = "SUPER";
      
      bind = [
        # Basic
        "$mod, Q, exec, alacritty"
        "$mod, C, killactive,"
        "$mod, M, exit,"
        "$mod, E, exec, dolphin"
        "$mod, V, togglefloating,"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"
        
        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        
        # Switch workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        
        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        
        # Special workspace (scratchpad)
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"
        
        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ];
      
      # Release keybinds - Super key alone opens app launcher
      bindr = [
        "SUPER, SUPER_L, exec, vicinae toggle"
      ];
      
      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
