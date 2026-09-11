{ pkgs }:

let
  placeholderWordmark = pkgs.writeText "mclauncher-wordmark.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720 160" role="img" aria-labelledby="title">
      <title id="title">MCLauncher placeholder wordmark</title>
      <rect width="720" height="160" rx="28" fill="#17131f"/>
      <circle cx="82" cy="80" r="46" fill="#8e32f3"/>
      <path d="M62 56h14l14 22 14-22h14v48h-14V78L90 99 76 78v26H62z" fill="#fff"/>
      <text x="150" y="101" font-family="sans-serif" font-size="58" font-weight="700" fill="#fff">MCLauncher</text>
    </svg>
  '';

  placeholderIcon = pkgs.writeText "mclauncher-icon.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" role="img" aria-labelledby="title">
      <title id="title">MCLauncher placeholder icon</title>
      <rect width="512" height="512" rx="112" fill="#17131f"/>
      <circle cx="256" cy="256" r="170" fill="#8e32f3"/>
      <path d="M150 162h52l54 85 54-85h52v188h-52V247l-54 82-54-82v103h-52z" fill="#fff"/>
    </svg>
  '';

  # Keep the upstream pname here: Nixpkgs' Gradle dependency cache resolves
  # the package by that attribute name. Only the final wrapped package below
  # is renamed to mclauncher.
  mclauncher-unwrapped = pkgs.modrinth-app-unwrapped.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.imagemagick ];

    # Keep Nixpkgs' dependency fetching/build machinery intact and only apply
    # the small downstream changes after the upstream source has been unpacked.
    postPatch = (old.postPatch or "") + ''
      ${pkgs.python3}/bin/python3 - <<'PY'
      from pathlib import Path

      root = Path('.')

      def replace_once(relative, old, new):
          path = root / relative
          text = path.read_text()
          if old not in text:
              raise SystemExit(f"{path}: expected MCLauncher patch target was not found; upstream changed")
          path.write_text(text.replace(old, new, 1))

      replace_once(
          'apps/app-frontend/src/App.vue',
          """const showAd = computed(\n\t() => sidebarVisible.value && !hasPlus.value && credentials.value !== undefined,\n)""",
          """// Downstream MCLauncher build: advertising is intentionally disabled.\nconst showAd = computed(() => false)""",
      )

      variables = root / 'packages/assets/styles/variables.scss'
      text = variables.read_text()
      replacements = [
          (
              "\t--color-brand: var(--color-green);\n\t--color-brand-highlight: var(--color-green-highlight);\n\t--color-brand-shadow: rgba(0, 175, 92, 0.7);",
              "\t--color-brand: var(--color-purple);\n\t--color-brand-highlight: var(--color-purple-highlight);\n\t--color-brand-shadow: rgba(142, 50, 243, 0.7);",
          ),
          (
              "\t--color-brand: var(--color-green);\n\t--color-brand-highlight: rgba(27, 217, 106, 0.25);\n\t--color-brand-shadow: rgba(27, 217, 106, 0.7);",
              "\t--color-brand: var(--color-purple);\n\t--color-brand-highlight: var(--color-purple-highlight);\n\t--color-brand-shadow: rgba(199, 138, 255, 0.7);",
          ),
      ]
      for old, new in replacements:
          if old not in text:
              raise SystemExit(f"{variables}: expected brand colour block was not found; upstream changed")
          text = text.replace(old, new, 1)
      variables.write_text(text)

      tauri = root / 'apps/app/tauri.conf.json'
      text = tauri.read_text()
      replacements = [
          ('\t"productName": "Modrinth App",', '\t"productName": "MCLauncher",'),
          ('\t"mainBinaryName": "Modrinth App",', '\t"mainBinaryName": "MCLauncher",'),
          ('\t"identifier": "ModrinthApp",', '\t"identifier": "dev.zephrynis.mclauncher",'),
          ('\t\t\t\t"title": "Modrinth App",', '\t\t\t\t"title": "MCLauncher",'),
      ]
      for old, new in replacements:
          if old not in text:
              raise SystemExit(f"{tauri}: expected branding entry {old.strip()} was not found; upstream changed")
          text = text.replace(old, new, 1)
      tauri.write_text(text)
      PY

      mkdir -p apps/app-frontend/public
      install -Dm644 ${placeholderWordmark} apps/app-frontend/public/mclauncher-wordmark.svg

      cat > packages/ui/src/components/brand/TextLogo.vue <<'EOF'
      <template>
        <img
          src="/mclauncher-wordmark.svg"
          alt="MCLauncher"
          class="block object-contain"
        />
      </template>
      EOF

      # Linux bundles use the PNG icons. Keep the source SVG around too so the
      # placeholder is easy to replace with final artwork later.
      install -Dm644 ${placeholderIcon} apps/app/icons/mclauncher.svg
      ${pkgs.imagemagick}/bin/magick -background none apps/app/icons/mclauncher.svg \
        -resize 128x128 apps/app/icons/128x128.png
      ${pkgs.imagemagick}/bin/magick -background none apps/app/icons/mclauncher.svg \
        -resize 256x256 apps/app/icons/128x128@2x.png
    '';

    # Nixpkgs' upstream package edits the generated Modrinth desktop entry.
    # Our productName changes that filename, so target the downstream one.
    postInstall = ''
      desktop-file-edit \
        --set-comment "MCLauncher — downstream Minecraft launcher" \
        --set-key="StartupNotify" --set-value="true" \
        --set-key="Categories" --set-value="Game;ActionGame;AdventureGame;Simulation;" \
        --set-key="Keywords" --set-value="game;minecraft;mc;" \
        --set-key="StartupWMClass" --set-value="MCLauncher" \
        "$out/share/applications/MCLauncher.desktop"
    '';

    meta = (old.meta or { }) // {
      description = "Downstream Modrinth-based Minecraft launcher with ads disabled and purple branding";
      homepage = "https://github.com/zephrynis/mclauncher";
      mainProgram = "MCLauncher";
    };
  });

  wrapped = pkgs.modrinth-app.override {
    modrinth-app-unwrapped = mclauncher-unwrapped;
  };
in
wrapped.overrideAttrs (old: {
  pname = "mclauncher";

  # The Nixpkgs wrapper targets the upstream binary name. The Tauri config
  # above changes it to MCLauncher, so point the wrapper at that binary too.
  postBuild = builtins.replaceStrings
    [ "ModrinthApp" ]
    [ "MCLauncher" ]
    (old.postBuild or "")
    + ''
      ln -s "$out/bin/MCLauncher" "$out/bin/mclauncher"
    '';

  meta = (old.meta or { }) // {
    description = "Downstream Modrinth-based Minecraft launcher with ads disabled and purple branding";
    homepage = "https://github.com/zephrynis/mclauncher";
    mainProgram = "MCLauncher";
  };
})
