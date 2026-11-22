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

  # Some FHS/bubblewrap launchers (including Beyond All Reason) hide the
  # host's /etc/egl directory but retain /run/opengl-driver. Point GLVND at
  # the NVIDIA external-platform descriptors that remain visible so Wayland
  # does not fall back to software rendering.
  environment.sessionVariables.__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS =
    "/run/opengl-driver/share/egl/egl_external_platform.d";

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

  hardware.nvidia-container-toolkit.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;  # Enables nvidia-suspend/resume services + VRAM preservation
    # NVIDIA R615 (new_feature branch from upstream nixpkgs) — required for
    # DLSS 5 Neural Rendering (nvngx_dlssnr.dll / cooperative-vector NGX APIs);
    # nixos-26.05's built-in nvidiaPackages.beta is still on 595.45.04.
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "615.78.08";
      sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
      sha256_aarch64 = "sha256-UHYBE1AYHoGgMfD9AS/jX+S+N8eCDWUft6qolK9Eejc=";
      openSha256 = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
      settingsSha256 = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
      persistencedSha256 = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
    };
  };
}
