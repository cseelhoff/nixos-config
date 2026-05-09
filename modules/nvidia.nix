{ config, pkgs, ... }:

# NVIDIA discrete-GPU profile.
# Import this from a host that has a real NVIDIA card (e.g. hosts/x870.nix).
# Do NOT import from generic VM/Intel/AMD hosts — it enables cudaSupport
# globally, which causes many packages (ffmpeg, opencv, blender, ...) to
# rebuild with CUDA and pulls in cudatoolkit/cudnn.

{
  # Rebuild CUDA-aware packages with CUDA support.
  nixpkgs.config.cudaSupport = true;

  # CUDA userspace + GPU monitoring tools.
  environment.systemPackages = with pkgs; [
    cudatoolkit
    cudaPackages.cudnn
    nvtopPackages.full
  ];

  # X / Wayland driver selection.
  services.xserver.videoDrivers = [ "nvidia" ];

  # Kernel params for NVIDIA DRM modesetting (required for Wayland).
  boot.kernelParams = [
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # This is the big one for resume corruption
  ];

  # Graphics stack (32-bit needed for Steam/Proton).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;  # Enables nvidia-suspend/resume services + VRAM preservation
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
}
