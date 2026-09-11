{ pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;

    # Rootless containers can talk to each other by name (podman needs the
    # aardvark-dns backend, pulled in automatically with this default network).
    defaultNetwork.settings.dns_enabled = true;

    # Provide a `docker` alias + socket so docker-oriented tools/compose files
    # work unchanged. Drop this if the real Docker daemon is ever installed —
    # the two cannot both own the docker socket.
    dockerCompat = true;
  };

  environment.systemPackages = with pkgs; [
    podman-compose # `docker compose`-style multi-container workflows
  ];
}
