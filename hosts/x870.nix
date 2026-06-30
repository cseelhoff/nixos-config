{ config, pkgs, lib, ... }:

{
  imports = [
    ../hardware/x870-hardware-configuration.nix
    ../modules/gui.nix
    ../modules/nvidia.nix
    ../modules/gaming.nix
    ../modules/vscode-tunnel.nix
    ../modules/foundryvtt.nix
    ../modules/ollama.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      editor = false;
      memtest86.enable = true;  # Adds Memtest86+ entry to the boot menu
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub.enable = false;
  };

  # Host-specific kernel params. NVIDIA-related params live in modules/nvidia.nix.
  boot.kernelParams = [
    "usbcore.autosuspend=-1"  # fix: mouse unresponsive at boot when game controllers are plugged in
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";

  # Disable all forms of sleep/suspend/hibernate (desktop, always-on).
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Prevent suspend on lid close (laptops) and idle.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    IdleAction = "ignore";
  };
}
