# NixOS + Omarchy Config (Desktop + WSL Variants)

This is my personal declarative NixOS configuration using **flakes**, **home-manager**, and **omarchy-nix** (for Hyprland + desktop niceties).

- **desktop**: Native bare-metal/VM install (Hyprland desktop via Omarchy)
- **wsl**: WSL2 install (with NixOS-WSL module, Podman, CUDA env, nix-ld, etc.)

Everything is unified where possible (shared user `admin`, same Omarchy name/email/theme, zsh setup, common packages).

## Quick Install on Fresh Machine (NixOS Minimal ISO)

1. **Boot the NixOS Minimal ISO**
   - Download the latest minimal ISO from https://nixos.org/download (e.g. `nixos-25.11-minimal-x86_64-linux.iso`).
   - Write to USB (e.g. `dd if=... of=/dev/sdX bs=4M status=progress && sync`).
   - Boot from it → login as user `nixos` (no password).

2. **Set up networking** (if needed)
   ```bash
   sudo systemctl start NetworkManager
   nmtui   # or wpa_supplicant + dhcpcd for Wi-Fi
   ```

3. **Partition, format, and mount disks**
   - Use `lsblk` to identify your target disk (e.g. `/dev/sda` or `/dev/nvme0n1`).
   - Partition (UEFI example – adapt for your setup or use `cfdisk`/`parted`):
     ```bash
     parted /dev/sda -- mklabel gpt
     parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
     parted /dev/sda -- set 1 esp on
     parted /dev/sda -- mkpart root ext4 512MiB 100%
     mkfs.fat -F 32 -n BOOT /dev/sda1
     mkfs.ext4 -L nixos /dev/sda2
     mount /dev/disk/by-label/nixos /mnt
     mkdir -p /mnt/boot
     mount /dev/disk/by-label/BOOT /mnt/boot
     ```
   - (Optional: add swap, LUKS, etc. – see NixOS manual.)

4. **Generate hardware config (one-time per machine)**
   ```bash
   sudo nixos-generate-config --root /mnt
   ```
   → This creates `/mnt/etc/nixos/hardware-configuration.nix` (filesystems, kernel modules, etc.).

5. **Install directly from GitHub flake (one-liner magic)**
   ```bash
   sudo nixos-install --no-root-passwd --root /mnt \
     --flake github:caleb-seelhoff/nixos-config#desktop
   ```
   - Replace `#desktop` with `#wsl` if installing in WSL (after initial WSL bootstrap).
   - `--no-root-passwd` skips root password prompt (set later with `passwd`).
   - This fetches your flake + lockfile, builds the system, and installs to `/mnt`.

6. **Reboot**
   ```bash
   reboot
   ```
   → Remove USB/ISO. Log in as `admin` (set password during first login or via `passwd` in live env before reboot).

## Post-Install Tweaks (if needed)

### Change hostname (after first boot)
If you want a different hostname than defined in the flake:
```bash
sudo hostnamectl set-hostname mycoolhost
# Then update flake.nix → add/override networking.hostName = "mycoolhost";
# Commit & push, then rebuild:
sudo nixos-rebuild switch --flake github:caleb-seelhoff/nixos-config#mycoolhost
```

### Change username (not recommended – rebuild required)
The flake hardcodes user `admin`. To use a different username:
1. Edit `flake.nix` → replace all `admin` with your desired name (in `users.users`, `home-manager.users`, etc.).
2. Commit & push.
3. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake .#desktop   # or path/to/local/clone
   ```
   → This recreates the user (old home dir stays; migrate data manually).

Better: keep `admin` and add extra users via `users.users.yourname = { ... };` in a per-host override.

## Everyday Usage (after install)

Clone once (optional – you can always use github: directly):
```bash
git clone https://github.com/caleb-seelhoff/nixos-config ~/.config/nixpkgs
cd ~/.config/nixpkgs
```

Update & rebuild:
```bash
git pull
nix flake update               # optional: refresh inputs
sudo nixos-rebuild switch --flake .#$(hostname)   # or #desktop / #wsl
```

For WSL-specific first setup:
- Install NixOS in WSL via official method first (tar or .wsl file).
- Then `sudo nixos-rebuild switch --flake github:caleb-seelhoff/nixos-config#wsl`

## Tips

- **Hardware per machine**: Commit a `hardware-configuration.nix` (or `hardware/desktop.nix`) per host if hardware differs significantly.
- **Secrets**: Use sops-nix/agenix later for passwords/API keys (not in this base flake).
- **Rollback**: NixOS generations are automatic – select older ones in bootloader if needed.
- **Updates**: `nix flake update` → `sudo nixos-rebuild switch --upgrade` for full system upgrade.

Enjoy declarative, reproducible NixOS! 🚀
