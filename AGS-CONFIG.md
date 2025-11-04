# AGS Colorshell Configuration - Fully Declarative

Your AGS configuration with colorshell is now **completely reproducible** and managed by your Nix flake.

## What's Now Declarative

### ✅ In Your Flake (`~/nix-flake/`)

1. **AGS Configuration** (`home/ags-config/`)
   - Complete colorshell source code
   - Modified SCSS with full opacity (`resources/styles/_colors.scss`, `_bar.scss`)
   - Disabled NightLight tile (`window/control-center/widgets/tiles/index.tsx`)
   - Disabled runner plugin (`app.ts`)
   - Pre-compiled gresource file (`resources.gresource`)
   - All module modifications (uwsm, wallpaper, etc.)

2. **Color Scheme** (`home/pywal-colors/colors.json`)
   - Dark pale blue theme
   - Full opacity (alpha: 100)
   - Automatically deployed to `~/.cache/wal/colors.json`

3. **Nix Configuration**
   - AGS v3 with all Astal packages (`flake.nix`)
   - Home-manager module (`home/ags.nix`)
   - Icon themes (Papirus-Dark)
   - GTK settings
   - Hyprland integration

## Configuration Structure

```
~/nix-flake/
├── home/
│   ├── ags-config/          # Complete colorshell configuration
│   │   ├── app.ts           # Modified (runner disabled, DEVEL constant)
│   │   ├── modules/         # Modified modules
│   │   ├── resources/       # SCSS with full opacity
│   │   ├── resources.gresource  # Pre-compiled resources
│   │   └── window/          # Modified windows (NightLight disabled)
│   ├── pywal-colors/
│   │   └── colors.json      # Dark pale blue theme
│   └── ags.nix              # AGS home-manager configuration
└── flake.nix                # AGS v3 + Astal inputs
```

## Making Changes

### To Modify Colors

1. Edit `home/pywal-colors/colors.json`
2. Rebuild: `sudo nixos-rebuild switch --flake .#desktop`

### To Modify SCSS Styles

1. Edit files in `home/ags-config/resources/styles/`
2. Rebuild gresource: 
   ```bash
   cd ~/nix-flake/home/ags-config
   nix-shell -p glib.dev --run "glib-compile-resources --sourcedir=resources resources.gresource.xml --target=resources.gresource"
   ```
3. Commit changes: `git add home/ags-config/resources.gresource`
4. Rebuild: `sudo nixos-rebuild switch --flake .#desktop`

### To Modify AGS Code

1. Edit TypeScript files in `home/ags-config/`
2. Commit changes: `git add home/ags-config/`
3. Rebuild: `sudo nixos-rebuild switch --flake .#desktop`

## Benefits

- 🔒 **Immutable**: `~/.config/ags/` is read-only and owned by root
- 📦 **Reproducible**: Exact same configuration on any machine
- 🔄 **Version Controlled**: All changes tracked in git
- 🧹 **Clean**: No manual file management in home directory
- ⚡ **Atomic**: Changes applied all-at-once, rollback-able

## Current Customizations

- ✅ Colorshell v2.0.3 (without runner/launcher)
- ✅ Dark pale blue color scheme
- ✅ Full opacity (no transparency)
- ✅ NightLight tile disabled (was trying to use hyprctl)
- ✅ Papirus-Dark icon theme
- ✅ All Astal modules integrated
- ✅ Pywal colors configured

## Testing Reproducibility

To verify everything is declarative, you can:

1. Delete `~/.config/ags/` and `~/.cache/wal/`
2. Run `sudo nixos-rebuild switch --flake .#desktop`
3. Everything will be restored exactly as configured!
