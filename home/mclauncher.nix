{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  mclauncherPkgs = import inputs.nixpkgs-mclauncher {
    inherit system;
    config.allowUnfree = true;
  };
  mclauncher = import ../packages/mclauncher.nix {
    pkgs = mclauncherPkgs;
  };
in
{
  home.packages = [ mclauncher ];
}
