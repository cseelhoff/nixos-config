# NixOS + Omarchy Config (Desktop + WSL Variants)

This is my personal declarative NixOS configuration using **flakes**, **home-manager**, and **omarchy-nix** (for Hyprland + desktop niceties).

- **desktop**: Native bare-metal/VM install (Hyprland desktop via Omarchy, systemd-boot for UEFI)
- **wsl**: WSL2 install (with NixOS-WSL module, Podman, CUDA env, nix-ld, etc.)

## Quick Install on Fresh Machine (NixOS Minimal ISO) – Cattle Style

Goal: Boot ISO → minimal steps → your full config → no per-machine git pushes.

1. **Boot the NixOS Minimal ISO**
   - Download latest minimal ISO: https://nixos.org/download (e.g. `nixos-25.11-minimal-x86_64-linux.iso`).
   - Boot → login as `nixos` (no password).

2. **Set up networking** (if needed)
   ```bash
   sudo systemctl start NetworkManager
   nmtui   # or wpa_supplicant + dhcpcd for Wi-Fi
   ```

3. **Partition, format, and mount disks** (UEFI example – adapt as needed)
   Identify disk with `lsblk` (e.g. `/dev/sda` or `/dev/nvme0n1`).

   ```bash
   sudo parted /dev/sda -- mklabel gpt
   sudo parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
   sudo parted /dev/sda -- set 1 esp on
   sudo parted /dev/sda -- mkpart root ext4 512MiB 100%

   sudo mkfs.fat -F 32 -n BOOT /dev/sda1
   sudo mkfs.ext4 -L nixos /dev/sda2

   sudo mount /dev/disk/by-label/nixos /mnt
   sudo mkdir -p /mnt/boot
   sudo mount /dev/disk/by-label/BOOT /mnt/boot
   ```
   (Add swap/LUKS/btrfs manually if desired – see NixOS manual.)

4. **Bootstrap your flake**
   ```bash
   sudo git clone https://github.com/cseelhoff/nixos-config.git /mnt/etc/nixos
   cd /mnt/etc/nixos
   sudo nixos-generate-config --root /mnt
   sudo git add hardware-configuration.nix
   sudo nixos-install --root /mnt --flake .#desktop
   ```
   - This:
     - Clones your repo to the target (`/mnt/etc/nixos` – writable!).
     - Generates `hardware-configuration.nix` **locally** on this machine (no git push needed!).
     - Installs from the **local flake path** (`--flake .#desktop`).
   - Use `#wsl` instead of `#desktop` for WSL bootstrap (after initial WSL tar install).
   - `--no-root-passwd` skips root password (set later with `passwd`).

5. **Reboot**
   ```bash
   reboot
   ```
   → Remove USB/ISO. Log in as `admin` (set password if needed).

After first boot, you're running your full declarative config. Future updates:
```bash
cd /etc/nixos   # or wherever you cloned it
git pull
sudo nixos-rebuild switch --flake .#$(hostname)   # or #desktop
```

**Note on direct GitHub install** (`--flake github:...`):  
It fails with "hardware-configuration.nix does not exist" because flakes evaluate purely from the committed repo contents — `nixos-generate-config` can't run during remote eval. Cloning locally + generating there solves this perfectly for cattle deploys.

## Post-Install Tweaks (if needed)

### Change hostname
```bash
sudo hostnamectl set-hostname mycoolhost
# Edit flake.nix to add/override networking.hostName = "mycoolhost";
# git commit & push (only if you want this host reusable from GitHub)
sudo nixos-rebuild switch --flake .#mycoolhost
```

### Change username
Hardcoded as `admin` — edit flake.nix (replace all `admin`), commit/push, rebuild.  
Better: keep `admin` as primary, add extras via `users.users.yourname = { ... };`.

## Everyday Usage (on running system)

```bash
cd /etc/nixos   # or your clone path
git pull
nix flake update               # optional: refresh inputs
sudo nixos-rebuild switch --flake .#$(hostname)   # or #desktop / #wsl
```

For WSL first setup:
- Install base NixOS in WSL (official tar/.wsl method).
- Then:
  ```bash
  git clone https://github.com/cseelhoff/nixos-config.git ~/nixos-config
  cd ~/nixos-config
  sudo nixos-rebuild switch --flake .#wsl
  ```

## Tips

- **Hardware per machine**: Lives locally in `/etc/nixos/hardware-configuration.nix` — never committed unless you want a "pet" machine.
- **Secrets**: Add sops-nix/agenix later.
- **Rollback**: Generations in bootloader.
- **Updates**: `nix flake update` + `--upgrade` for full upgrades.
- **Bootloader note**: Desktop uses systemd-boot (UEFI-only, fast & simple). WSL ignores bootloader.

Enjoy fast, declarative NixOS deploys! 🚀
