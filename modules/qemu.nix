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
# Managing guests needs NO sudo. The libvirtd module installs a polkit rule
# granting org.libvirt.unix.manage to the libvirtd group, and polkit resolves
# group membership from the user database rather than the calling process's
# credentials — so it works in already-open shells too, without a re-login.
# Just be explicit about the connection: `virsh -c qemu:///system`, or set
# LIBVIRT_DEFAULT_URI=qemu:///system.
#
# One-time bootstrap already done on x870 (both are per-state, not per-config):
#   virsh -c qemu:///system net-start default && net-autostart default
#   virsh -c qemu:///system pool-define-as default dir --target /var/lib/libvirt/images
#     then pool-build / pool-start / pool-autostart default
# The pool matters for unprivileged use: /var/lib/libvirt/images is 0750
# root:root, so virt-install can only create disks there by going through
# libvirtd's storage API, which requires the path to be inside a defined pool.
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

  # virt-install/virsh launch this for a guest console; without it they warn and
  # fall back to a blind `--wait -1`.
  environment.systemPackages = [ pkgs.virt-viewer ];

  # Without this the CLI tools silently default to qemu:///session, a separate
  # unprivileged libvirt instance with no `default` network and its own storage
  # — so `--network network=default` fails with "Network not found".
  environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";

  # Attach physical USB devices to a running guest from the SPICE console.
  virtualisation.spiceUSBRedirection.enable = true;

  users.users.caleb.extraGroups = [ "libvirtd" ];
  users.users.admin.extraGroups = [ "libvirtd" ];

  # Drop-box for installer ISOs. Home directories are 0700, which the
  # qemu-libvirtd account cannot traverse, so an ISO left in ~/Downloads fails
  # to open; this is group-writable by libvirtd members and world-traversable.
  #
  # The images rule is what lets qemu-libvirtd (uid 301) open guest disks at
  # all: libvirt chowns each disk file to that uid, but the file is
  # unreachable without search permission on the parent. 0711 is libvirt's
  # upstream default — traversable by anyone, listable by no one but root.
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/iso 0775 root libvirtd -"
    "d /var/lib/libvirt/images 0711 root root -"
  ];
}
