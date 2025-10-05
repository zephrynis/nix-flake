# Nix flake for PC and Laptop

This flake provides two NixOS hosts (pc and laptop) with shared modules and Home Manager.

## Layout

- `flake.nix` — Flake inputs/outputs, two `nixosConfigurations` (pc, laptop)
- `modules/common.nix` — Common NixOS settings for both hosts
- `hosts/pc` — PC host config + its `hardware-configuration.nix`
- `hosts/laptop` — Laptop host config + its `hardware-configuration.nix`
- `home/users/user/home.nix` — Home Manager configuration for the user

## Quick start

1) Update variables:

- In `flake.nix`, set `user = "<your-username>"`.
- Rename `home/users/user/` to `home/users/<your-username>/` and edit `home.nix` accordingly.
- In each host's `configuration.nix`, the Home Manager import uses `${user}` so it will follow automatically once the flake variable is set.
- Set `networking.hostName` per host if you want different names.

2) Generate real hardware configs on each device:

On each machine, clone this repo and inside that host folder run:

```bash
sudo nixos-generate-config --show-hardware-config > hosts/<host>/hardware-configuration.nix
```

Replace the placeholder UUIDs and modules in the template with the generated content.

3) Switch configuration on the machine:

From the repo root on the machine you are configuring:

```bash
sudo nixos-rebuild switch --flake .#pc
# or
sudo nixos-rebuild switch --flake .#laptop
```

If building from another machine for a remote target, add `--target-host` and optionally `--use-remote-sudo`.

4) Home Manager only (optional):

Home Manager is integrated as a NixOS module. If you want to apply only HM changes after login:

```bash
home-manager switch --flake .#<username>@<host>
```

5) Format the repo (optional):

```bash
nix fmt
```

## Notes

- This flake targets x86_64-linux only. If you need ARM support, you'll need to add an aarch64 system and review the inputs.
- Update `system.stateVersion` and `home.stateVersion` only when you deliberately accept new defaults.
- To pin a newer NixOS release, change inputs `nixpkgs` and `home-manager` to the latest stable branch and review release notes.
