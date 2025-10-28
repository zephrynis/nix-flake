# NVIDIA Setup Notes

## Laptop Bus ID Configuration Required

**File to edit:** `/home/zeph/nix-flake/system/nvidia-laptop.nix`

### Steps:

1. Run this command on your **laptop**:
   ```bash
   sudo lshw -c display
   ```

2. Look for the `bus info` lines in the output:
   - **Intel GPU**: `bus info: pci@0000:00:02.0`
   - **NVIDIA GPU**: `bus info: pci@0000:01:00.0`

3. Convert the PCI addresses to NixOS format:
   - `pci@0000:00:02.0` → `PCI:0:2:0` (Intel)
   - `pci@0000:01:00.0` → `PCI:1:0:0` (NVIDIA)

4. Update the values in `nvidia-laptop.nix`:
   ```nix
   intelBusId = "PCI:0:2:0";    # Replace with your Intel bus ID
   nvidiaBusId = "PCI:1:0:0";   # Replace with your NVIDIA bus ID
   ```

5. Rebuild after updating:
   ```bash
   sudo nixos-rebuild switch --flake /home/zeph/nix-flake#laptop
   ```

### Format Conversion Example:
```
pci@0000:XX:YY.Z  →  PCI:XX:YY:Z
```
Remove the `0000:` prefix and convert the `.` to `:`

---

## Testing NVIDIA Setup

### Desktop (RTX 3080):
- `nvidia-smi` - Check if driver is loaded
- `nvtop` - Monitor GPU usage
- `glxinfo | grep NVIDIA` - Verify OpenGL

### Laptop (GTX 1050):
- `nvidia-smi` - Check if driver is loaded
- `nvidia-offload glxgears` - Test offload mode
- `nvtop` - Monitor both Intel and NVIDIA GPUs

### Using NVIDIA on Laptop:
- Normal apps use Intel iGPU (better battery)
- Prefix GPU-intensive apps with `nvidia-offload`:
  ```bash
  nvidia-offload <program>
  ```
