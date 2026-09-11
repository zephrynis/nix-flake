{ config, inputs, lib, pkgs, ... }:

let
  share-picker = inputs.hyprland-preview-share-picker.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    # XDPH supplies a stable window address. Matching only class/title drops
    # windows when the portal's title is stale (e.g. after changing Chrome tabs).
    # Keep the old match only for portals that do not provide an address.
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/views/windows.rs --replace-fail \
        'self.clients.iter().find(|c| c.class.eq(&toplevel.class) && c.title.eq(&toplevel.title))' \
        'self.clients.iter().find(|c| match toplevel.window_address {
            Some(address) => u64::from_str_radix(&c.address.to_string()[2..], 16).ok() == Some(address),
            None => c.class.eq(&toplevel.class) && c.title.eq(&toplevel.title),
        })'
    '';
  });
  # Substitutes the current wallpaper palette (matugen's colors.json) into the
  # picker stylesheet template on every launch, so the picker re-themes with
  # the wallpaper, then hands off to the real picker binary.
  share-picker-themed = pkgs.writeShellScript "share-picker-themed" ''
    dir="$HOME/.config/hyprland-preview-share-picker"
    colors="$HOME/.local/state/quickshell/user/generated/colors.json"
    if [ -f "$colors" ]; then
      ${pkgs.jq}/bin/jq -r 'to_entries[] | "s|@\(.key)@|\(.value)|g"' "$colors" \
        | ${pkgs.gnused}/bin/sed -f - "$dir/style.css.in" > "$dir/generated.css" || true
    else
      cp -f "$dir/style.css.in" "$dir/generated.css"
    fi
    exec ${share-picker}/bin/hyprland-preview-share-picker "$@"
  '';

  firefoxBin = "${config.programs.firefox.finalPackage}/bin/firefox";

  # Redirects an app's outgoing links into the Firefox "work" profile, reusing
  # the same --name/WM class as the firefox-work desktop entry so links land in
  # the existing Work window. Linux has no per-app "use browser Y" mapping, so
  # instead we launch the app (below) with this bin dir first on PATH and
  # $BROWSER pointed here — covering both ways an app opens a link:
  #   * `firefox-work` — the value we set for $BROWSER
  #   * `xdg-open`      — a shim that sends only http/https to the work profile
  #                       and delegates every other URI to the real xdg-open
  # (Apps that call the org.freedesktop.portal.OpenURI portal directly bypass
  # both and still use the global default — that can't be overridden per-app.)
  work-browser = pkgs.symlinkJoin {
    name = "firefox-work-browser-shim";
    paths = [
      (pkgs.writeShellScriptBin "firefox-work" ''
        exec ${firefoxBin} -P work --name firefox-work "$@"
      '')
      (pkgs.writeShellScriptBin "xdg-open" ''
        case "$1" in
          http://*|https://*)
            exec ${firefoxBin} -P work --name firefox-work "$@" ;;
          *)
            exec ${pkgs.xdg-utils}/bin/xdg-open "$@" ;;
        esac
      '')
    ];
  };

  # Wraps an app binary so its links open in the Firefox work profile.
  openLinksInWork = name: exe: pkgs.writeShellScriptBin name ''
    export PATH=${work-browser}/bin:$PATH
    export BROWSER=firefox-work
    exec ${exe} "$@"
  '';

  slack-work-links = openLinksInWork "slack-work-links" "${pkgs.slack}/bin/slack";
  obsidian-work-links = openLinksInWork "obsidian-work-links" "${pkgs.obsidian}/bin/obsidian";

  # Nixpkgs can lag Codex's fast release cadence. Pin the official static
  # Linux binary so terminal Codex updates do not require a system-wide
  # nixpkgs refresh (which can break independently pinned desktop modules).
  codex-cli =
    let
      version = "0.153.2";
      codeModeHostSrc = pkgs.fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.zst";
        hash = "sha256-oOsgBcBsIkLerxQcS8O0PdIj9jCBvAWKb8Pag1OQLRA=";
      };
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "codex";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-6M0RYAcfcl0qEMq4EHPdaBj8iwljchJdJ+9uZv3wl54=";
      };

      dontUnpack = true;
      nativeBuildInputs = [
        pkgs.makeWrapper
        pkgs.zstd
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin" "$out/libexec"
        tar -xzf "$src"
        zstd -d "${codeModeHostSrc}" -o "$out/libexec/codex-code-mode-host"
        chmod 755 "$out/libexec/codex-code-mode-host"
        install -m755 codex-x86_64-unknown-linux-musl "$out/libexec/codex"
        makeWrapper "$out/libexec/codex" "$out/bin/codex" \
          --prefix PATH : ${
            lib.makeBinPath [
              pkgs.ripgrep
              pkgs.bubblewrap
            ]
          }
        runHook postInstall
      '';

      meta = {
        description = "OpenAI's terminal coding agent";
        homepage = "https://github.com/openai/codex";
        license = lib.licenses.asl20;
        mainProgram = "codex";
        platforms = [ "x86_64-linux" ];
      };
    };

  # Nixpkgs packages only Seanime's standalone server. Denshi is the official
  # desktop client: it embeds that server and adds the integrated libmpv player.
  seanime-denshi =
    let
      pname = "seanime-denshi";
      version = "3.10.2";
      src = pkgs.fetchurl {
        url = "https://github.com/5rahim/seanime/releases/download/v${version}/seanime-denshi-${version}_Linux_x86_64.AppImage";
        hash = "sha256-Appt2gh4mYyz1YMY4uvNmpXGkKVqxDimABNKMhTbZMA=";
      };
      appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
    in
    pkgs.appimageTools.wrapType2 {
      inherit pname version src;

      extraInstallCommands = ''
        install -Dm644 \
          "${appimageContents}/seanime-denshi.desktop" \
          "$out/share/applications/seanime-denshi.desktop"
        install -Dm644 \
          "${appimageContents}/usr/share/icons/hicolor/439x439/apps/seanime-denshi.png" \
          "$out/share/icons/hicolor/439x439/apps/seanime-denshi.png"
        substituteInPlace "$out/share/applications/seanime-denshi.desktop" \
          --replace-fail "Exec=AppRun" "Exec=seanime-denshi"
      '';

      meta = {
        description = "Electron-based desktop client for Seanime";
        homepage = "https://seanime.app";
        license = lib.licenses.gpl3Only;
        mainProgram = "seanime-denshi";
        platforms = [ "x86_64-linux" ];
      };
    };

  mcvcliCargo = builtins.fromTOML (builtins.readFile "${inputs.mcvcli}/Cargo.toml");
  mcvcli = pkgs.rustPlatform.buildRustPackage {
    pname = "mcvcli";
    version = mcvcliCargo.package.version;
    src = inputs.mcvcli;
    cargoLock.lockFile = "${inputs.mcvcli}/Cargo.lock";

    meta = {
      description = "Command-line interface for managing Minecraft servers";
      homepage = "https://github.com/mcjars/mcvcli";
      license = lib.licenses.mit;
      mainProgram = "mcvcli";
      platforms = lib.platforms.unix;
    };
  };

  # The upstream Nix package runs the whole launcher in steam-run, but that
  # environment does not include WebKitGTK. Xodus needs libwebkit2gtk-4.1 for
  # the separate Microsoft Store ownership sign-in, and its downloaded Debian
  # fallback is not loadable on NixOS. Extend the FHS environment with the
  # native Nixpkgs library and point the upstream wrapper at it.
  bedrock-steam-run = (pkgs.steam.override {
    extraPkgs = fhsPkgs: [
      fhsPkgs.glib-networking
      fhsPkgs.webkitgtk_4_1
    ];
    # steam-run normally clears GIO_EXTRA_MODULES. WebKitGTK then loads but
    # libsoup cannot find GLib's TLS backend and the Microsoft page reports
    # "TLS support is not available".
    extraProfile = ''
      umask 077
      export GIO_EXTRA_MODULES=${pkgs.glib-networking}/lib/gio/modules
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    '';
  }).run;
  bedrock-on-linux =
    inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        # Upstream's v2.2.1 tag still labels the derivation 2.1.3; the bundled
        # application code itself correctly reports 2.2.1.
        version = "2.2.1";
        __intentionallyOverridingVersion = true;
        postFixup = (old.postFixup or "") + ''
          substituteInPlace "$out/bin/bedrock-on-linux" \
            --replace-fail \
              "${pkgs.steam-run}/bin/steam-run" \
              "${bedrock-steam-run}/bin/steam-run"
        '';
      });

  # Paseo 0.3.1's runtime tracer looks for node-pty at the repository root,
  # but npm installs this version under the server workspace. The native addon
  # is built correctly and then omitted from the desktop output, causing the
  # daemon to crash as soon as terminal support loads. Preserve the upstream
  # package and copy only the missing native runtime directory into its traced
  # node-pty package. Its unpackaged Nix launcher can also miss Electron's
  # ready-to-show event after a GPU-process fallback, leaving a healthy window
  # permanently hidden, so explicitly show it once the bundled UI has loaded.
  # Remove these workarounds once fixed upstream.
  paseo-desktop = inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.desktop.overrideAttrs (_: {
    postInstall = ''
      sourceNodePty=packages/server/node_modules/node-pty
      runtimeNodePty=$out/share/paseo-desktop/packages/server/node_modules/node-pty

      for nativeDir in build prebuilds; do
        if [ -d "$sourceNodePty/$nativeDir" ]; then
          cp -a "$sourceNodePty/$nativeDir" "$runtimeNodePty/"
        fi
      done

      if ! find "$runtimeNodePty" -name pty.node -print -quit | grep -q .; then
        echo "Paseo's node-pty native module was not built" >&2
        exit 1
      fi

      desktopMain=$out/share/paseo-desktop/packages/desktop/dist/main.js
      sed -i '/await mainWindow\.loadURL(initialUrl);/a\        mainWindow.show();' "$desktopMain"
      if [ "$(grep -Fc 'mainWindow.show();' "$desktopMain")" -lt 2 ]; then
        echo "Paseo's post-load window fallback was not installed" >&2
        exit 1
      fi
    '';
  });
in
{
  imports = [
    inputs.illogical-flake.homeManagerModules.default
    inputs.codex-desktop-linux.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.spicetify
    ./easyeffects-rnnoise.nix
    ./spotify-ducking.nix
  ];

  home.username = "zephrynis";
  home.homeDirectory = "/home/zephrynis";
  # Matches the release era of system.stateVersion; never change afterwards.
  home.stateVersion = "26.05";

  programs.codexDesktopLinux.enable = true;

  # Codex keeps config.toml mutable so its CLI can persist project trust and
  # MCP settings. Enforce Auto-review on every switch without replacing the
  # rest of that stateful config with a read-only Home Manager symlink.
  home.activation.codexAutoReview = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codexConfig="$HOME/.codex/config.toml"
    mkdir -p "$(dirname "$codexConfig")"
    touch "$codexConfig"

    if ${pkgs.gnused}/bin/sed -n '1,/^\[/p' "$codexConfig" \
      | grep -q '^approval_policy[[:space:]]*='; then
      ${pkgs.gnused}/bin/sed -i \
        '0,/^approval_policy[[:space:]]*=.*/s//approval_policy = "on-request"/' \
        "$codexConfig"
    else
      ${pkgs.gnused}/bin/sed -i \
        '1i approval_policy = "on-request"' \
        "$codexConfig"
    fi

    if ${pkgs.gnused}/bin/sed -n '1,/^\[/p' "$codexConfig" \
      | grep -q '^approvals_reviewer[[:space:]]*='; then
      ${pkgs.gnused}/bin/sed -i \
        '0,/^approvals_reviewer[[:space:]]*=.*/s//approvals_reviewer = "auto_review"/' \
        "$codexConfig"
    else
      ${pkgs.gnused}/bin/sed -i \
        '1i approvals_reviewer = "auto_review"' \
        "$codexConfig"
    fi
  '';

  programs.illogical-impulse = {
    enable = true;
    # All default to true — listed for discoverability
    dotfiles = {
      fish.enable = true;
      kitty.enable = true;
      starship.enable = true;
    };
    # hyprland.plugins = [ ]; # listOf package, loaded via hyprland's plugin mechanism
  };

  # illogical-flake wipes and recopies ~/.config/hypr on every switch, so the
  # UK layout override must be re-appended after its copy step each time.
  # custom/general.lua is sourced after hyprland/general.lua (kb_layout = "us").
  home.activation.ukKeyboardLayout = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
    hyprCustomGeneral="$HOME/.config/hypr/custom/general.lua"
    if [ -f "$hyprCustomGeneral" ] && ! grep -q 'kb_layout = "gb"' "$hyprCustomGeneral"; then
      cat >> "$hyprCustomGeneral" << 'EOF'

    -- UK keyboard layout (appended by nix-flake, overrides hyprland/general.lua)
    hl.config({ input = { kb_layout = "gb" } })
    EOF
      echo "Appended UK keyboard layout to hypr/custom/general.lua"
    fi
  '';

  # Suppress the Hyprland update news popup (option lives under ecosystem
  # since Hyprland 0.46); re-appended after every recopy like the layout.
  home.activation.hyprlandNoUpdateNews = lib.hm.dag.entryAfter [ "ukKeyboardLayout" ] ''
    hyprCustomGeneral="$HOME/.config/hypr/custom/general.lua"
    if [ -f "$hyprCustomGeneral" ] && ! grep -q 'no_update_news' "$hyprCustomGeneral"; then
      cat >> "$hyprCustomGeneral" << 'EOF'

    -- Suppress update news popup (appended by nix-flake)
    hl.config({ ecosystem = { no_update_news = true } })
    EOF
      echo "Appended no_update_news to hypr/custom/general.lua"
    fi
  '';

  # Monitor layout (updated 2026-08-08): AOC CQ27G2S at 165Hz above,
  # with the Samsung Odyssey G9 OLED (G95SC) centered below it at
  # native 5120x1440@240.
  # Overrides the mode=preferred/position=auto catch-all in hyprland/general.lua.
  home.activation.hyprlandMonitorLayout = lib.hm.dag.entryAfter [ "hyprlandNoUpdateNews" ] ''
    hyprCustomGeneral="$HOME/.config/hypr/custom/general.lua"
    if [ -f "$hyprCustomGeneral" ] && ! grep -q 'hl.monitor' "$hyprCustomGeneral"; then
      cat >> "$hyprCustomGeneral" << 'EOF'

    -- Monitor layout (appended by nix-flake, updated 2026-08-08)
    hl.monitor({ output = "DP-2", mode = "2560x1440@165.0", position = "1280x0", scale = "1" })
    hl.monitor({ output = "DP-1", mode = "5120x1440@240.0", position = "0x1440", scale = "1" })

    -- Workspace 1 starts on the AOC, workspace 2 on the G9; cursor starts on the G9
    hl.workspace_rule({ workspace = "1", monitor = "DP-2", default = true })
    hl.workspace_rule({ workspace = "2", monitor = "DP-1", default = true })
    hl.on("hyprland.start", function ()
        hl.dispatch(hl.dsp.focus({ monitor = "DP-1" }))
        hl.dispatch(hl.dsp.cursor.move({ x = 2560, y = 2160 }))
    end)
    EOF
      echo "Appended monitor layout to hypr/custom/general.lua"
    fi
  '';

  # Tailscale tray icon in the bar's systray (daemon + package are system-side
  # in modules/tailscale.nix). custom/execs.lua is the dots' intended autostart
  # hook, but it's wiped and recopied every switch like the rest of ~/.config/hypr.
  home.activation.trayscaleAutostart = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
    hyprCustomExecs="$HOME/.config/hypr/custom/execs.lua"
    if [ -f "$hyprCustomExecs" ] && ! grep -q 'trayscale' "$hyprCustomExecs"; then
      cat >> "$hyprCustomExecs" << 'EOF'

    -- Tailscale tray icon (appended by nix-flake)
    hl.on("hyprland.start", function ()
        hl.exec_cmd("trayscale --hide-window")
    end)
    EOF
      echo "Appended trayscale autostart to hypr/custom/execs.lua"
    fi
  '';

  # illogical-flake's generated custom/env.lua forces QT_QPA_PLATFORMTHEME=qt6ct
  # (its workaround for plasma-integration not being installed). desktop.nix now
  # installs plasma-integration + Darkly, so restore upstream's "kde" — that
  # applies the matugen-generated kdeglobals (Material You colors, Darkly style)
  # to Qt apps like Prism Launcher. Appended after the regeneration each switch;
  # later hl.env calls win.
  home.activation.qtPlatformThemeKde = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
    hyprCustomEnv="$HOME/.config/hypr/custom/env.lua"
    if [ -f "$hyprCustomEnv" ] && ! grep -q 'kde-platform-theme' "$hyprCustomEnv"; then
      cat >> "$hyprCustomEnv" << 'EOF'

    -- kde-platform-theme: restore upstream platform theme (appended by nix-flake);
    -- plasma-integration + Darkly are installed system-side (desktop.nix)
    hl.env("QT_QPA_PLATFORMTHEME", "kde")
    EOF
      echo "Restored QT_QPA_PLATFORMTHEME=kde in hypr/custom/env.lua"
    fi
  '';

  # Same override for non-Hyprland entry points (illogical-flake's environment.nix
  # sets this to qt6ct)
  home.sessionVariables.QT_QPA_PLATFORMTHEME = lib.mkForce "kde";

  # Minecraft otherwise prefers X11 even when its GLFW supports both backends.
  # At the mouse receiver's 8 kHz report rate, GLFW's XWayland cursor warping
  # can produce a huge view delta during fast flicks.  Minecraft 26.x bundles
  # a matching GLFW snapshot with Wayland and its custom window/input API, so
  # use that instead of nixpkgs' older system GLFW and opt into native Wayland.
  # Keep the launcher-owned config writable and preserve other JVM arguments.
  home.activation.minecraftNativeWayland = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    prismConfig="$HOME/.local/share/PrismLauncher/prismlauncher.cfg"
    minecraftInstance="$HOME/.local/share/PrismLauncher/instances/Fabulously Optimized/instance.cfg"
    if [ -f "$prismConfig" ]; then
      if grep -q '^UseNativeGLFW=' "$prismConfig"; then
        ${pkgs.gnused}/bin/sed -i 's/^UseNativeGLFW=.*/UseNativeGLFW=false/' "$prismConfig"
      else
        printf '\nUseNativeGLFW=false\n' >> "$prismConfig"
      fi

      if ! grep -q '^JvmArgs=.*MC_DEBUG_PREFER_WAYLAND' "$prismConfig"; then
        if grep -q '^JvmArgs=$' "$prismConfig"; then
          ${pkgs.gnused}/bin/sed -i \
            's|^JvmArgs=$|JvmArgs=-DMC_DEBUG_ENABLED=true -DMC_DEBUG_PREFER_WAYLAND=true|' \
            "$prismConfig"
        elif grep -q '^JvmArgs=' "$prismConfig"; then
          ${pkgs.gnused}/bin/sed -i \
            's|^JvmArgs=|JvmArgs=-DMC_DEBUG_ENABLED=true -DMC_DEBUG_PREFER_WAYLAND=true |' \
            "$prismConfig"
        else
          printf 'JvmArgs=-DMC_DEBUG_ENABLED=true -DMC_DEBUG_PREFER_WAYLAND=true\n' >> "$prismConfig"
        fi
      fi
    fi

    # Pin this instance as well, so Prism's nixpkgs-native workaround cannot
    # silently re-enable the older system GLFW over the global setting.
    if [ -f "$minecraftInstance" ]; then
      if grep -q '^OverrideNativeWorkarounds=' "$minecraftInstance"; then
        ${pkgs.gnused}/bin/sed -i \
          's/^OverrideNativeWorkarounds=.*/OverrideNativeWorkarounds=true/' \
          "$minecraftInstance"
      else
        printf 'OverrideNativeWorkarounds=true\n' >> "$minecraftInstance"
      fi

      if grep -q '^UseNativeGLFW=' "$minecraftInstance"; then
        ${pkgs.gnused}/bin/sed -i \
          's/^UseNativeGLFW=.*/UseNativeGLFW=false/' \
          "$minecraftInstance"
      else
        printf 'UseNativeGLFW=false\n' >> "$minecraftInstance"
      fi
    fi
  '';

  # Super+W opens Firefox instead of Chrome. The dots' hyprland/keybinds.lua
  # binds it to $browser, which launch_first_available.sh resolves to the first
  # installed of google-chrome-stable, zen, firefox, ... — so with Chrome
  # installed it lands on Chrome. custom/keybinds.lua is sourced after the
  # default, so unbind + rebind wins; re-appended after every recopy.
  # Super+Shift+W is the "variant" pairing (Shift = variant throughout the dots)
  # for the Firefox work profile, matching the firefox-work shim/desktop entry.
  home.activation.browserKeybindFirefox = lib.hm.dag.entryAfter [ "hyprlandMonitorLayout" ] ''
    hyprCustomKeybinds="$HOME/.config/hypr/custom/keybinds.lua"
    if [ -f "$hyprCustomKeybinds" ] && ! grep -q 'App: Firefox' "$hyprCustomKeybinds"; then
      cat >> "$hyprCustomKeybinds" << 'EOF'

-- Super+W -> Firefox (appended by nix-flake, overrides the dots' browser bind)
hl.unbind("SUPER + W")
hl.bind("SUPER + W", hl.dsp.exec_cmd("firefox"), { description = "App: Firefox" })
-- Super+Shift+W -> Firefox work profile (matches the firefox-work shim/WM class)
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("firefox -P work --name firefox-work"), { description = "App: Firefox (Work)" })
EOF
      echo "Rebound Super+W to Firefox and Super+Shift+W to Firefox (Work) in hypr/custom/keybinds.lua"
    fi
  '';

  # The illogical-flake copy step deletes/recreates ~/.config/hypr while
  # Hyprland is running; its mid-copy reload fails ("cannot open hyprland.lua")
  # and the error banner sticks. Reload once the configs are back in place.
  home.activation.reloadHyprland = lib.hm.dag.entryAfter [ "browserKeybindFirefox" ] ''
    for instance in /run/user/$(id -u)/hypr/*/; do
      [ -d "$instance" ] || continue
      HYPRLAND_INSTANCE_SIGNATURE="$(basename "$instance")" \
        /run/current-system/sw/bin/hyprctl reload >/dev/null 2>&1 || true
    done
  '';

  # Disable the desktop background clock widget. config.json is only copied on
  # first install (user edits persist), so this mainly matters for fresh
  # installs; the guard keeps later manual edits to other keys untouched.
  home.activation.disableBackgroundClock = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
    iiConfig="$HOME/.config/illogical-impulse/config.json"
    if [ -f "$iiConfig" ] && [ "$(${pkgs.jq}/bin/jq '.background.widgets.clock.enable' "$iiConfig")" != "false" ]; then
      ${pkgs.jq}/bin/jq '.background.widgets.clock.enable = false' "$iiConfig" > "$iiConfig.tmp" \
        && mv "$iiConfig.tmp" "$iiConfig"
      echo "Disabled background clock widget in illogical-impulse config.json"
    fi
  '';

  # The dots swap terminal copy/interrupt conventions: foot binds Ctrl+C to
  # clipboard-copy and moves SIGINT (\x03) to Ctrl+Shift+C; kitty maps Ctrl+C
  # to copy_or_interrupt (copies whenever text is selected); foot also puts
  # paste on Ctrl+V. Restore standard behavior — Ctrl+C interrupts, copy/paste
  # on Ctrl+Shift+C/V — re-applied after every recopy like the hypr overrides.
  home.activation.footCtrlC = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
    footIni="$HOME/.config/foot/foot.ini"
    if [ -f "$footIni" ] && grep -q '^clipboard-copy=Control+c$' "$footIni"; then
      ${pkgs.gnused}/bin/sed -i \
        -e 's/^clipboard-copy=Control+c$/clipboard-copy=Control+Shift+c/' \
        -e 's/^clipboard-paste=Control+v$/clipboard-paste=Control+Shift+v/' \
        -e '/^\\x03=Control+Shift+c$/d' \
        "$footIni"
      echo "Restored default Ctrl+C/Ctrl+V in foot.ini"
    fi
  '';

  home.activation.kittyCtrlC = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
    kittyConf="$HOME/.config/kitty/kitty.conf"
    if [ -f "$kittyConf" ] && ! grep -q 'Restore default Ctrl+C' "$kittyConf"; then
      cat >> "$kittyConf" << 'EOF'

# Restore default Ctrl+C (appended by nix-flake); copy is Ctrl+Shift+C
map ctrl+c
EOF
      echo "Unmapped Ctrl+C in kitty.conf"
    fi
  '';

  # Point xdg-desktop-portal-hyprland at the preview share picker. xdph.conf
  # lives in ~/.config/hypr, which the recopy wipes, so recreate it each switch.
  home.activation.xdphSharePicker = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
    cat > "$HOME/.config/hypr/xdph.conf" << 'EOF'
    # Written by nix-flake (recreated every switch; the dots wipe this dir)
    screencopy {
      custom_picker_binary = ${share-picker-themed}
      # Reuse the first picker selection via a restore token so the portal
      # dialog isn't reopened for the stream itself. Without this, Chromium/
      # Electron (Vesktop) reopens the picker for the real stream after the
      # preview — the "picker appears 2-3 times" bug. See Vesktop#583.
      allow_token_by_default = true
    }
    EOF
  '';

  # GTK apps decide light/dark from this key (via the settings portal). The
  # dots' Arch installer sets it imperatively; the flake port never does, so
  # GTK apps came up light while the shell rendered dark.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # Share picker: single-click selection and Material-You styling. The colors
  # reference GTK named colors from ~/.config/gtk-4.0/gtk.css, which matugen
  # regenerates from the wallpaper — so the picker re-themes automatically.
  # (This dir isn't shipped by the dots, so plain xdg.configFile works.)
  xdg.configFile."hyprland-preview-share-picker/config.yaml".text = ''
    stylesheets:
      - generated.css
    windows:
      clicks: 1
    outputs:
      clicks: 1
  '';
  # Template for the wrapper above: @token@ placeholders are replaced with hex
  # values from matugen's colors.json (Material tokens, current light/dark set).
  xdg.configFile."hyprland-preview-share-picker/style.css.in".text = ''
    .window {
      background-color: @surface@;
      color: @on_surface@;
      border: 1px solid @outline_variant@;
      border-radius: 24px;
      padding: 10px;
      font-family: "Google Sans Flex", "Rubik", sans-serif;
      font-size: 15px;
    }
    .page,
    .notebook,
    .notebook stack {
      background: transparent;
    }
    .notebook header {
      background: transparent;
      border: none;
      margin-bottom: 6px;
    }
    .notebook header tab {
      border-radius: 9999px;
      padding: 6px 18px;
      margin: 4px 3px;
      background: transparent;
      color: @on_surface_variant@;
      transition: background-color 150ms ease;
      outline: none;
      box-shadow: none;
    }
    .notebook header tab:hover {
      background-color: @surface_container_high@;
    }
    .notebook header tab:checked {
      background-color: @primary_container@;
      color: @on_primary_container@;
    }
    .card {
      background-color: @surface_container@;
      color: @on_surface@;
      border: 2px solid transparent;
      border-radius: 18px;
      padding: 6px;
      transition: background-color 150ms ease, border-color 150ms ease;
    }
    .card:hover {
      background-color: @surface_container_high@;
      border-color: @primary@;
    }
    .card-loading {
      background-color: @surface_container@;
      border-radius: 18px;
    }
    .image {
      border-radius: 12px;
      background: transparent;
    }
    .image-label {
      color: @on_surface_variant@;
      font-size: 0.92em;
      margin-top: 4px;
    }
    /* The outputs view wraps each preview card in a classless GtkButton whose
       stock background shows as a white matte — neutralize it and let the
       inner .card carry the visuals. */
    .page button:not(.region-button) {
      background: none;
      border: none;
      box-shadow: none;
      padding: 0;
      outline: none;
    }
    .page button:not(.region-button):hover,
    .page button:not(.region-button):active {
      background: none;
    }
    /* `background` shorthand, not background-color: the theme's
       background-image gradient must be reset too. */
    .region-button {
      background: @primary_container@;
      color: @on_primary_container@;
      border: none;
      border-radius: 9999px;
      padding: 14px 32px;
      font-size: 1.1em;
      outline: none;
      box-shadow: none;
    }
    .region-button:hover {
      background: @secondary_container@;
    }
    .restore-button {
      background-color: @surface_container@;
      color: @on_surface_variant@;
      border: none;
      border-radius: 9999px;
      padding: 6px 14px;
      margin-top: 8px;
    }
    .restore-button check {
      background-color: @surface_container_highest@;
      border: 1px solid @outline@;
      border-radius: 6px;
    }
    .restore-button check:checked {
      background-color: @primary@;
      color: @on_primary@;
      border-color: @primary@;
    }
  '';

  # The illogical-flake fish module generates its own config.fish, dropping the
  # dots' `set fish_greeting` — so the "Welcome to fish" banner came back.
  programs.fish.interactiveShellInit = "set -g fish_greeting";

  programs.git = {
    enable = true;
    userName = "zephrynis";
    userEmail = "zephrynis.yt@gmail.com";
    # What `gh auth setup-git` would write, but can't — the HM-managed git
    # config lives read-only in the store.
    extraConfig = {
      credential."https://github.com".helper = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
    };
  };

  # The dots run `hyprctl setcursor Bibata-Modern-Classic 24` but don't install
  # the theme (an assumed system dependency on Arch)
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Two profiles: personal (default, purple) and work (blue). Firefox has no
  # native per-profile accent, so each profile tints its toolbars via
  # userChrome.css. Launch work with `firefox -P work` (desktop entry below).
  programs.firefox = {
    enable = true;
    profiles =
      let
        addons = pkgs.callPackage "${inputs.firefox-addons}/pkgs/firefox-addons" {
          # Same wiring as the upstream flake's overlay, but against the system
          # pkgs so nixpkgs.config (allowUnfree, for 1Password) applies
          buildMozillaXpiAddon =
            (import "${inputs.firefox-addons}/lib/mozilla.nix" { inherit lib; }).mkBuildMozillaXpiAddon
              { inherit (pkgs) fetchurl stdenv; };
        };
        settings = {
          # Load userChrome.css
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          # Auto-enable the declaratively installed extensions
          "extensions.autoDisableScopes" = 0;
        };
        accent = color: ''
          #navigator-toolbox {
            background-color: ${color} !important;
            color: #f4f2fa !important;
          }
        '';
      in
      {
        personal = {
          id = 0;
          isDefault = true;
          inherit settings;
          extensions.packages = [
            addons.ublock-origin
            addons.proton-pass
            addons.onepassword-password-manager
          ];
          userChrome = accent "#45256e";
        };
        work = {
          id = 1;
          inherit settings;
          extensions.packages = [
            addons.ublock-origin
            addons.onepassword-password-manager
          ];
          userChrome = accent "#1e3a6e";
        };
      };
  };

  # Launcher for the work profile; plain `firefox` opens personal (the default)
  xdg.desktopEntries.firefox-work = {
    name = "Firefox (Work)";
    genericName = "Web Browser";
    exec = "firefox -P work --name firefox-work %U";
    icon = "firefox";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.vscode.enable = true;

  # Spotify + Spicetify. The module installs its own wrapped Spotify, so
  # pkgs.spotify is intentionally absent from home.packages. spicyLyrics is a
  # first-class packaged extension (word-by-word karaoke lyrics view).
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        spicyLyrics
      ];
    };

  # File manager; gvfs/udisks2 backends are enabled system-side in desktop.nix.
  # xdg-open and apps use this for directories. The claude-cli handler was
  # registered imperatively by claude-code — kept here since HM now owns
  # mimeapps.list.
  # Keep an explicit Vesktop launcher entry so it remains distinct from the
  # regular Discord client in the app list.
  # HM writes ~/.local/share/applications/vesktop.desktop, which shadows the
  # package's own copy (user data dir wins in XDG_DATA_DIRS). Exec stays
  # `vesktop`; StartupWMClass stays Vesktop so window matching still works.
  xdg.desktopEntries.vesktop = {
    name = "Vesktop";
    genericName = "Internet Messenger";
    exec = "vesktop %U";
    icon = "vesktop";
    categories = [
      "Network"
      "InstantMessaging"
      "Chat"
    ];
    mimeType = [ "x-scheme-handler/discord" ];
    type = "Application";
    settings = {
      Keywords = "discord;vencord;electron;chat;";
      StartupWMClass = "Vesktop";
    };
  };

  # Route Slack's and Obsidian's outgoing links into the Firefox work profile
  # by shadowing their package .desktop files (user data dir wins in
  # XDG_DATA_DIRS) with copies whose Exec points at the openLinksInWork wrapper.
  # Every other field is kept identical to the upstream entry.
  xdg.desktopEntries.slack = {
    name = "Slack";
    genericName = "Slack Client for Linux";
    comment = "Slack Desktop";
    exec = "${slack-work-links}/bin/slack-work-links -s %U";
    icon = "slack";
    type = "Application";
    startupNotify = true;
    categories = [
      "GNOME"
      "GTK"
      "Network"
      "InstantMessaging"
    ];
    mimeType = [ "x-scheme-handler/slack" ];
    settings.StartupWMClass = "Slack";
  };
  xdg.desktopEntries.obsidian = {
    name = "Obsidian";
    comment = "Knowledge base";
    exec = "${obsidian-work-links}/bin/obsidian-work-links %u";
    icon = "obsidian";
    type = "Application";
    categories = [ "Office" ];
    mimeType = [ "x-scheme-handler/obsidian" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      # Keep Firefox (personal profile) as the browser for all links. Pinned
      # explicitly so google-chrome — installed below as an occasional-use app —
      # can never register itself as the default link handler (HM owns
      # mimeapps.list as a read-only symlink, so Chrome's first-run "make
      # default" prompt physically can't rewrite these).
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "text/html" = "firefox.desktop";
    };
  };

  home.packages = with pkgs; [
    # As a plain package, not programs.gh — the HM module symlinks a read-only
    # config.yml into the store, which breaks `gh auth login`'s first-run write.
    gh
    # sshm: TUI to manage and connect to SSH hosts (reads/writes ~/.ssh/config)
    sshm
    nautilus
    # Vesktop: Discord+Vencord with a real Wayland/PipeWire screenshare — a
    # sane WebRTC bitrate (the official `discord` client starved it into
    # macroblocks) and it streams desktop audio, which official Linux Discord
    # can't. Uses the same xdg-desktop-portal-hyprland picker wired up above.
    vesktop
    # Official Discord client, alongside Vesktop, to re-test its screenshare.
    discord
    slack
    # Obsidian: Markdown knowledge base / note-taking (unfree; allowUnfree
    # already enabled for the other proprietary apps above).
    obsidian
    # Iotas: lightweight Markdown-friendly notes app with optional Nextcloud sync.
    iotas
    # OBS Studio: screen recording and streaming.
    obs-studio
    # Chrome: occasional-use only. Firefox stays the default link handler —
    # the xdg.mimeApps http/https pins above keep Chrome from grabbing links.
    google-chrome
    claude-code
    # Codex CLI: OpenAI's terminal coding agent
    codex-cli
    # Node.js runtime and its bundled npm package manager.
    nodejs
    # Paseo desktop client; bundles and starts its local agent daemon.
    paseo-desktop
    # Minecraft server version manager, packaged from inputs.mcvcli above.
    mcvcli
    # GUI decompiler for browsing and inspecting Minecraft plugin JARs.
    (bytecode-viewer.overrideAttrs (old: {
      # BCV uses a SecurityManager for its inspection safeguards. Java 21
      # requires this opt-in before the application can install it.
      postFixup = (old.postFixup or "") + ''
        wrapProgram "$out/bin/bytecode-viewer" \
          --prefix JDK_JAVA_OPTIONS " " "-Djava.security.manager=allow"
      '';
    }))
    # Minecraft Bedrock for Windows, using the upstream Nix package.
    bedrock-on-linux
    # Seanime desktop client with its embedded server and libmpv player.
    seanime-denshi
    # Torrent client used by Seanime for managed and automatic downloads.
    qbittorrent
    ripgrep
    fd
    fzf
    jq
    btop
    eza
    bat
    tree
    nixfmt-rfc-style
    nil # Nix LSP
  ];
}
