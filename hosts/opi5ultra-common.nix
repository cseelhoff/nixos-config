{ pkgs, lib, ... }:

# Settings shared by the Orange Pi 5 Ultra systems on the SD card
# (hosts/opi5ultra.nix) and on the NVMe (hosts/opi5ultra-nvme.nix). The board
# flake (github:cseelhoff/orangepi5ultra-nixos) provides kernel, device tree,
# firmware and the hardware modules; the host files add only the disk layout.

{
  # The image was first installed as 26.05; base.nix pins 25.11 for older hosts.
  system.stateVersion = lib.mkForce "26.05";

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Pinned to what the SD card system assigned, so a fresh install (e.g. the
  # NVMe) gets the same owners for a copied /home.
  users.users.admin.uid = 1001;
  users.users.caleb = {
    uid = 1000;
    extraGroups = [ "render" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDexbF/Hyk975Dn0M5Y9455dXEMzkEtp3ksXVeGAhEbF"
    ];
  };

  # Hardware / performance testing.
  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    glmark2
    vkmark
    v4l-utils
    ffmpeg
    fio
    iperf3
    stress-ng
    htop
    pciutils
    usbutils
    # Installed (not nix shell) so `gh auth setup-git`'s credential helper path
    # survives garbage collection.
    gh
  ];
}
