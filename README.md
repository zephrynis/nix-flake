# NixOS System Configuration

This is a NixOS flake configuration for managing your system setup, ricing, and applications across multiple devices.

## Structure

```
.
├── flake.nix                    # Main flake configuration
├── flake.lock                   # Locked dependency versions
├── system/
│   └── common.nix               # Shared system configuration
├── hosts/
│   └── my-machine/              # Per-machine configurations
│       ├── configuration.nix    # Machine-specific settings
│       └── hardware-configuration.nix  # Hardware-specific settings
└── home/
    └── home.nix                 # User-level configuration (dotfiles, packages)
```

## Initial Setup

1. **Generate hardware configuration** on your NixOS machine:
   ```bash
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```
   Copy the output to `hosts/my-machine/hardware-configuration.nix`

2. **Update configuration files**:
   - Change `my-machine` to your actual hostname throughout the files
   - Update `yourusername` to your actual username
   - Adjust timezone, locale, and other personal settings
   - Choose your desktop environment / window manager

3. **Update flake inputs**:
   ```bash
   nix flake update
   ```

4. **Build and switch to the new configuration**:
   ```bash
   sudo nixos-rebuild switch --flake .#my-machine
   ```

## Adding a New Machine

1. Create a new directory under `hosts/` with your machine's hostname
2. Generate and add the hardware configuration
3. Create a `configuration.nix` for machine-specific settings
4. Add the new machine to `flake.nix` under `nixosConfigurations`
5. Build with: `sudo nixos-rebuild switch --flake .#new-machine`

## Updating the System

```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake .#my-machine
```

## Customization Ideas

- Add window manager configurations (i3, bspwm, Hyprland, etc.)
- Configure terminal emulators (Alacritty, Kitty, WezTerm)
- Set up status bars (Polybar, Waybar)
- Add custom themes and color schemes
- Configure rofi, dunst for notifications
- Set up wallpaper management with nitrogen or variety

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Wiki](https://nixos.wiki/)
