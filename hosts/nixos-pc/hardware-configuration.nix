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

  # Large data/OS partitions on the other drives. Keep these read-only so
  # browsing them from NixOS cannot modify Windows or EndeavourOS. UUIDs are
  # stable if the kernel assigns the disks different /dev/sd* names.
  fileSystems."/mnt/main-hdd" = {
    device = "/dev/disk/by-uuid/9AA8DDB9A8DD93DB";
    fsType = "ntfs";
    options = [ "ro" "nofail" "nosuid" "nodev" "uid=1000" "gid=100" "umask=022" ];
    noCheck = true;
  };

  fileSystems."/mnt/work-windows" = {
    device = "/dev/disk/by-uuid/A6B66A73B66A4441";
    fsType = "ntfs";
    options = [ "ro" "nofail" "nosuid" "nodev" "uid=1000" "gid=100" "umask=022" ];
    noCheck = true;
  };

  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/01DC47994D38D1D0";
    fsType = "ntfs";
    options = [ "ro" "nofail" "nosuid" "nodev" "uid=1000" "gid=100" "umask=022" ];
    noCheck = true;
  };

  fileSystems."/mnt/endeavouros" = {
    device = "/dev/disk/by-uuid/8857c416-d0b4-422b-b837-29aef1ad4fdd";
    fsType = "ext4";
    options = [ "ro" "nofail" "nosuid" "nodev" ];
    noCheck = true;
  };

  swapDevices = [ ]; # 128GB RAM — no swap

  hardware.cpu.intel.updateMicrocode = true;
}
