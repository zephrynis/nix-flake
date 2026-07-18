# PLACEHOLDER — on install day, overwrite this file with the one produced by
#   nixos-generate-config --root /mnt
# (it lands in /mnt/etc/nixos/hardware-configuration.nix), then `git add` it —
# flakes only evaluate tracked files. The generated file adds the correct
# boot.initrd.availableKernelModules for this machine.
#
# The labels below match the mkfs commands in README.md (mkfs.ext4 -L nixos,
# mkfs.fat -n NIXBOOT), so this stub is bootable even before replacement.
{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ]; # 128GB RAM — no swap

  hardware.cpu.intel.updateMicrocode = true;
}
