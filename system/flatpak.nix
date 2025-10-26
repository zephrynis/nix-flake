{ config, pkgs, ... }:

let
  grep = pkgs.gnugrep;
  
  # Declare the Flatpaks you want on your system
  desiredFlatpaks = [
    "io.github.zen_browser.zen"
    # Add more Flatpak apps here
    # "com.spotify.Client"
    # "com.discordapp.Discord"
  ];
in {
  # Enable Flatpak
  services.flatpak.enable = true;
  
  system.userActivationScripts.flatpakManagement = {
    text = ''
      # Ensure the Flathub repo is added
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo

      # Get currently installed Flatpaks
      installedFlatpaks=$(${pkgs.flatpak}/bin/flatpak list --app --columns=application)

      # Remove any Flatpaks that are NOT in the desired list
      for installed in $installedFlatpaks; do
        if ! echo ${toString desiredFlatpaks} | ${grep}/bin/grep -q $installed; then
          echo "Removing $installed because it's not in the desiredFlatpaks list."
          ${pkgs.flatpak}/bin/flatpak uninstall -y --noninteractive $installed
        fi
      done

      # Install or re-install the Flatpaks you DO want
      for app in ${toString desiredFlatpaks}; do
        echo "Ensuring $app is installed."
        ${pkgs.flatpak}/bin/flatpak install -y flathub $app
      done

      # Remove unused Flatpaks
      ${pkgs.flatpak}/bin/flatpak uninstall --unused -y

      # Update all installed Flatpaks
      ${pkgs.flatpak}/bin/flatpak update -y
    '';
  };
}
