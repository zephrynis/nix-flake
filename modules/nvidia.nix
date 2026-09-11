{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam/Proton
  };

  hardware.nvidia = {
    modesetting.enable = true; # nvidia-drm.modeset=1 — mandatory for Wayland
    open = true; # RTX 3080 (Ampere): NVIDIA-recommended on driver >= 560
    nvidiaSettings = true;
    powerManagement.enable = true; # preserves VRAM across suspend — avoids Wayland resume corruption
    powerManagement.finegrained = false; # desktop GPU
    # 595.84 repeatedly exhausts NVKMS allocations under Wayland when VRAM is
    # pressured (especially when a window reallocates at 5120x1440 fullscreen),
    # freezing presentation while the application itself keeps running. Pin the
    # previous production branch until NVIDIA fixes the regression.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    # Fallbacks — only if symptoms appear (should be unnecessary with driver 560+ / explicit sync):
    # WLR_NO_HARDWARE_CURSORS = "1";          # invisible/glitchy cursor
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";   # Xwayland picks wrong GL vendor
  };
}
