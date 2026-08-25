{ pkgs, ... }:

# QEMU/KVM guests, managed through libvirt + virt-manager.
#
# This module does NOT enable hardware acceleration — that is a firmware and
# kernel matter, and it is already live on x870 (verified 2026-08-25):
#   svm in /proc/cpuinfo      → AMD-V (SVM) enabled in UEFI
#   kvm_amd loaded, /dev/kvm  → KVM has claimed the CPU extension
#   kvm_amd npt=Y             → nested paging (SLAT), the big perf win
#   kvm_amd nested=1          → guests may themselves run hypervisors (WSL2/Hyper-V)
#   /sys/class/iommu/ivhd0    → AMD-Vi/IOMMU on, 36 groups (needed for passthrough)
# Re-check any time with: `ls -l /dev/kvm && cat /sys/module/kvm_amd/parameters/{npt,nested}`.
#
# qemu_kvm (not full `qemu`) is deliberate: it builds only the host
# architecture's system emulator, which is all a KVM-accelerated x86 guest
# needs, and avoids compiling ~30 foreign-target emulators.
#
# swtpm gives guests a software TPM 2.0, which Windows 11 refuses to install
# without. The matching UEFI half needs no option here: nixpkgs 25.11 removed
# `qemu.ovmf` because libvirt now sees every OVMF image QEMU ships (including
# the Secure Boot variants) through its firmware descriptors.
#
# First-run steps after the initial rebuild:
#   1. sudo virsh net-start default && sudo virsh net-autostart default
#      (the NAT network is defined by libvirtd but starts inactive)
#   2. Log out and back in so the libvirtd group membership below applies;
#      until then virt-manager and `virsh -c qemu:///system` get "permission
#      denied" from the daemon socket.
#
# Guests live in /var/lib/libvirt/images and are NOT part of this config.

{
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";      # don't auto-resume saved guests; start them by hand
    onShutdown = "shutdown"; # ask guests to power off cleanly instead of saving state

    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
      vhostUserPackages = [ pkgs.virtiofsd ]; # virtio-fs host directory sharing
    };
  };

  # GUI manager; also pulls in the dconf backend it stores its settings in.
  programs.virt-manager.enable = true;

  # Attach physical USB devices to a running guest from the SPICE console.
  virtualisation.spiceUSBRedirection.enable = true;

  users.users.caleb.extraGroups = [ "libvirtd" ];
  users.users.admin.extraGroups = [ "libvirtd" ];
}
