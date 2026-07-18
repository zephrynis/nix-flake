# nixos-pc

NixOS flake for the desktop PC: Hyprland with [end-4's illogical-impulse](https://github.com/end-4/dots-hyprland) via [soymou/illogical-flake](https://github.com/soymou/illogical-flake), NVIDIA RTX 3080, Steam/gaming, dev tools.

- Host: `nixos-pc` · User: `zephrynis` · Channel: nixos-unstable
- Boot: systemd-boot on this install's **own ESP** on the 1TB WD SSD; **rEFInd** (on the 2TB NVMe's ESP) remains the top-level OS picker and auto-detects it.

```
hosts/nixos-pc/     host wiring, bootloader, user, hardware config
modules/            core, desktop (hyprland/sddm/fonts), nvidia, gaming
home/zephrynis.nix  illogical-impulse + git/direnv/vscode/CLI tools
```

Rebuild after changes: `sudo nixos-rebuild switch --flake .#nixos-pc`
Update inputs (one at a time is safer): `nix flake update <input>`

---

## Install procedure

Target: ~250GB shrunk from the work-Windows partition on the **1TB WD SA500 SATA SSD**. The work Windows on that disk and everything on the 2TB NVMe (other Windows, Arch, rEFInd's ESP) must not be touched.

### 1. Prep (from the work Windows)

1. Back up anything important. If BitLocker is enabled on C:, **export the recovery key** and suspend BitLocker before repartitioning.
2. Disable Fast Startup: `powercfg /h off` (admin) — otherwise NTFS is left dirty.
3. Shrink C: by ~256000 MB: Disk Management → right-click C: → Shrink Volume. If it won't shrink enough (unmovable files): temporarily disable pagefile + System Restore on C:, reboot, retry, re-enable after.
4. Push this repo somewhere reachable from the ISO (GitHub) or copy to a USB stick. **Flakes only evaluate git-tracked files** — commit everything.
5. BIOS: disable Secure Boot (stock NixOS bootloader is unsigned). F11 = one-time boot menu.

### 2. Partition & install (NixOS ISO, UEFI mode)

```sh
ls /sys/firmware/efi                      # must exist (UEFI mode)
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL     # identify disks
```

The 1TB WD (WDS100T1R0A) is likely `/dev/sda`. **Do not touch any NTFS partition, and nothing on the NVMe.** In the ~250G free space (parted `unit GiB`, `print free` to see exact bounds):

```sh
parted /dev/sda -- mkpart ESP fat32 <freeStart> <freeStart+1GiB>
parted /dev/sda -- set <N> esp on
parted /dev/sda -- mkpart root ext4 <freeStart+1GiB> 100%

mkfs.fat -F 32 -n NIXBOOT /dev/sdaX       # the new 1GiB partition
mkfs.ext4 -L nixos /dev/sdaY              # the new large partition

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=0077 /dev/disk/by-label/NIXBOOT /mnt/boot
```

Get the flake and the real hardware config:

```sh
git clone <this-repo-url> /mnt/etc/nixos      # or copy from USB
nixos-generate-config --root /mnt
mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/nixos-pc/hardware-configuration.nix
rm /mnt/etc/nixos/configuration.nix
git -C /mnt/etc/nixos add -A
```

Install (needs network — ethernet just works, else `nmtui`):

```sh
nixos-install --flake /mnt/etc/nixos#nixos-pc     # sets root password at the end
nixos-enter --root /mnt -c 'passwd zephrynis'
reboot
```

### 3. After first boot

1. rEFInd should show a new NixOS/systemd-boot entry (it scans all ESPs). Windows and Arch entries must still work.
2. If the firmware now boots straight into systemd-boot instead of rEFInd, fix the order from NixOS: `efibootmgr` to list, `sudo efibootmgr -o XXXX,YYYY,...` with rEFInd first.
3. Optional rEFInd polish (edit `refind.conf` on the NVMe ESP): a `menuentry` stanza for a custom NixOS name/icon, and `dont_scan_files`/`dont_scan_dirs` to hide duplicate auto-detected kernel entries from the NIXBOOT ESP.
4. Checks: `nvidia-smi`; `cat /sys/module/nvidia_drm/parameters/modeset` → `Y`; Hyprland session in SDDM; quickshell bar appears (Super for launcher); Steam runs a Proton title.
   - If the `qs` (quickshell) binary is missing, add `inputs.illogical-flake.inputs.quickshell.packages.x86_64-linux.default` to `home.packages` and rebuild.
   - Cursor invisible/glitchy: enable Hyprland `cursor:no_hardware_cursors = true`, or the commented `WLR_NO_HARDWARE_CURSORS` fallback in `modules/nvidia.nix`.

### Follow-up (someday): separate rEFInd entries for the two Windows installs

Both Windows currently share one Windows Boot Manager/BCD on the NVMe ESP, so rEFInd shows a single Windows entry with a second picker behind it. The new ESP on the 1TB SSD makes splitting easy:

1. From the **work Windows**, assign the NIXBOOT ESP a letter (e.g. `S:` via `diskpart` → `assign`), then:
   `bcdboot C:\Windows /s S: /f UEFI`
   This creates an independent Windows Boot Manager + BCD on the 1TB SSD's ESP that boots only the work OS. 1GiB is plenty for both this and NixOS's kernels.
2. rEFInd then shows two distinct Windows Boot Manager entries (one per ESP).
3. Remove the work OS's entry from the old shared BCD (`msconfig` → Boot tab, or `bcdedit /delete <id>`) so each menu boots exactly one Windows.
