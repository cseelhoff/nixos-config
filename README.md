# NixOS Config (GUI + Gaming + WSL Variants)

This is my personal declarative NixOS configuration using **flakes** and **home-manager**, with Hyprland as the Wayland compositor on graphical hosts.

Tracks the **NixOS 26.05 stable release**, with selected packages sourced from
`nixos-unstable`. `system.stateVersion` / `home.stateVersion` remain pinned to
`25.11` for data-format compatibility — do **not** bump them when updating.

Update discipline:
- `nix flake update` is a deliberate event, not a routine. Do it when you have time to fix breakage.
- Prefer `nix flake lock --update-input nixpkgs` over a blanket update so you can bisect regressions.
- systemd-boot keeps prior generations — use them to roll back if a rebuild misbehaves.

- **nixos-gui**: Native bare-metal/VM install — generic Wayland desktop, **no NVIDIA, no CUDA, no gaming stack**. Safe for Proxmox VMs and Intel/AMD machines.
- **x870**: My gaming rig — `nixos-gui` profile + NVIDIA drivers/CUDA + Steam/Proton/gamescope/PartyDeck.
- **wsl**: WSL2 install (with NixOS-WSL module, Podman, nix-ld, etc.). **No CUDA in the system closure** — the Windows driver is exposed at `/usr/lib/wsl/lib`; get CUDA per-project (devShell, container, or pip/uv wheels).

### Module layout (host opts in to features)

```
modules/
  base.nix     # truly host-agnostic: shells, podman, users
  gui.nix      # graphical host: graphics, fonts, GUI apps, Hyprland (effects-off), greetd
  nvidia.nix   # NVIDIA drivers + cudaSupport + cudatoolkit/cudnn + nvtop
  gaming.nix   # Steam/Proton/gamescope/PartyDeck (transitively pulls KDE+SDDM for KWin;
               # auto-overrides greetd from gui.nix when imported)
hosts/
  nixos-gui.nix  # base + gui  (Hyprland via greetd)
  x870.nix       # base + gui + nvidia + gaming  (Hyprland + KDE via SDDM)
  wsl.nix        # base + WSL-specific bits (no CUDA)
```

Features are **explicitly opted into per host** rather than auto-detected — Nix evaluation is hermetic and can't reliably probe live hardware, so this stays declarative and debuggable. To add NVIDIA/CUDA to a new host, add `../modules/nvidia.nix` to its `imports`.

## Quick Install on Fresh Machine (NixOS Minimal ISO) – Cattle Style

Goal: Boot ISO → minimal steps → your full config → no per-machine git pushes.

1. **Boot the NixOS Minimal ISO**
   - Download the latest minimal ISO from https://nixos.org/download (any recent release ISO works; the flake selects its pinned NixOS release on the first rebuild).
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

   # The flake imports hardware/<host>-hardware-configuration.nix,
   # so move the generated file into place (rename for the target host):
   sudo mv /mnt/etc/nixos/hardware-configuration.nix \
           /mnt/etc/nixos/hardware/nixos-gui-hardware-configuration.nix

   # Flakes only evaluate tracked files — stage AND commit it:
   sudo git add hardware/nixos-gui-hardware-configuration.nix
   sudo git -c user.email=install@localhost -c user.name=install \
        commit -m "nixos-gui hardware config"

   sudo nixos-install --root /mnt --flake '.#nixos-gui'
   ```
   - This:
     - Clones your repo to the target (`/mnt/etc/nixos` – writable!).
     - Generates `hardware-configuration.nix` **locally** on this machine (no git push needed!).
     - Renames it to the host-specific path your flake imports.
     - Commits it locally so the flake can see it (otherwise eval fails with `nixpkgs.hostPlatform not set`).
     - Installs from the **local flake path** (`--flake .#nixos-gui`).
   - WSL uses a different installation path: see [NixOS on Windows 11 / WSL2](#nixos-on-windows-11--wsl2) below. Do not partition disks, run `nixos-install`, or generate hardware configuration for WSL.
   - You may use `sudo nixos-install --root /mnt --flake .#nixos-gui --no-root-passwd` if you wish to skip interactive root password prompt at the end of install. Make sure your flake sets `users.users.admin.initialPassword` (or `initialHashedPassword`); otherwise log in as root via single-user mode and run `passwd admin` after first boot.

5. **Reboot**
   ```bash
   reboot
   ```
   → Remove USB/ISO. Log in as `admin` (set password if needed).

After first boot, you're running your full declarative config. Future updates:
```bash
cd /etc/nixos   # or wherever you cloned it
git pull
sudo nixos-rebuild switch --flake '.#nixos-gui'
```

**Note on direct GitHub install** (`--flake github:...`):  
For native hosts needing a new hardware configuration, remote evaluation cannot
see a locally generated file. Clone locally and add the host's hardware
configuration before installation. WSL already has a committed
`hardware/wsl-hardware-configuration.nix` stub specifying `x86_64-linux`;
NixOS-WSL supplies its filesystem and boot configuration.

## Post-Install Tweaks (if needed)

### Change hostname
```bash
sudo hostnamectl set-hostname mycoolhost
# Edit flake.nix to add/override networking.hostName = "mycoolhost";
# git commit & push (only if you want this host reusable from GitHub)
sudo nixos-rebuild switch --flake '.#mycoolhost'
```

### Change username
The shared base creates `admin` and `caleb`; the WSL profile selects `caleb` as
its default login in `hosts/wsl.nix`. To change that login, update
`wsl.defaultUser` and the corresponding user and Home Manager definitions.
Creating another user does not by itself change the WSL default.

## Everyday Usage (on running system)

```bash
cd /etc/nixos   # or your clone path
git pull
nix flake update               # optional: refresh inputs
sudo nixos-rebuild switch --flake ".#$(hostname)"   # or #nixos-gui / #wsl
```

## NixOS on Windows 11 / WSL2

This is the WSL deployment path, not the minimal-ISO installation above.
Preserve existing distributions: do not use `wsl --unregister`, overwrite an
existing installation, or format disks.

### 1. Check and install Windows prerequisites

In PowerShell, inspect the current state:

```powershell
wsl --status
wsl --list --verbose
```

If WSL is not installed, open PowerShell **as Administrator** and run:

```powershell
wsl --install --no-distribution
```

This installs WSL without installing Ubuntu. Approve the UAC prompt when opening
the elevated shell. Restart Windows if requested or if WSL2 remains unavailable
with a pending Windows restart. After restarting, recheck `wsl --status`.
WSL2 also requires firmware virtualization and the Virtual Machine Platform
Windows component; do not assume an installation exit code of zero means the
machine can start WSL2 before the restart.

### 2. Download, verify, and install the official image

Download `nixos.wsl` and its matching `nixos.wsl.sha256` from the same
[official NixOS-WSL release](https://github.com/nix-community/NixOS-WSL/releases/latest).
Use the x86-64 image for this repository's WSL host, not `nixos.aarch64.wsl`.
In a normal, non-elevated PowerShell under your intended Windows account, change
to the download directory and verify the checksum:

```powershell
Set-Location "$HOME\Downloads"
$expected = ((Get-Content .\nixos.wsl.sha256 -Raw).Trim() -split '\s+')[0]
$actual = (Get-FileHash .\nixos.wsl -Algorithm SHA256).Hash
if ($actual -ne $expected) { throw "NixOS image checksum mismatch" }
wsl --version
wsl --list --verbose
```

For WSL 2.4.4 or newer, if no distribution named `NixOS` already exists:

```powershell
wsl --install --from-file .\nixos.wsl --name NixOS --no-launch
wsl -d NixOS -u root
```

Keep the default storage location unless you deliberately need another drive.
If `NixOS` already exists, stop and decide whether to configure it or install
under a different name; do not overwrite it. See the
[upstream installation guide](https://nix-community.github.io/NixOS-WSL/install.html)
for older WSL versions and custom locations.

### 3. Bootstrap the repository as root

Run the following **inside the root NixOS shell**, not PowerShell:

```bash
cd /root
nix-channel --update
nix-shell -p git --run 'git clone https://github.com/cseelhoff/nixos-config.git /root/nixos-config'
cd /root/nixos-config
nixos-rebuild switch --flake '.#wsl'
```

The base image may not include Git, hence the temporary `nix-shell`. Keep the
clone root-owned for this initial root rebuild: Nix can reject a clone owned by
another user with `repository ... is not owned by current user`. Do not update
the flake lock as a bootstrap step; use the repository's pinned inputs.

The first build is substantial even without CUDA. On the November 2026 Windows
11 installation, the main build fetched 627 paths (1.7 GiB compressed / 7.1 GiB
unpacked), built 238 derivations, and took about 26 minutes, excluding the earlier
Git/bootstrap downloads. Allow ample disk space and time; inspect progress
before treating a long dependency download as a hang. Subsequent rebuilds reuse
the Nix store.

WSL 3 generates `wsl-mnt-guard.service`, which expects `/bin/true` and
`/bin/mount`. This profile provides both through `wsl.extraBin`. Without them,
activation can report exit code 4 and `203/EXEC` for the mount guard even though
the new system configuration has otherwise activated.

### 4. Finish the default-user transition

The rebuild removes the image's bootstrap user `nixos` and creates the configured
`caleb` and `admin` users. Using root for bootstrap avoids depending on the
removed account. Stay in the root shell and finish setup:

```bash
passwd caleb
mv /root/nixos-config /home/caleb/nixos-config
chown -R caleb:users /home/caleb/nixos-config
cd /root
git config --global --add safe.directory /home/caleb/nixos-config
exit
```

Enter the password interactively; do not put it in a command, script, or commit.
`caleb` needs it for `sudo`. The narrowly scoped root Git trust entry permits
future sudo rebuilds of this caleb-owned checkout without disabling ownership
checks globally. Run Git commands from a Linux directory, not an inherited
Windows worktree whose `.git` file may reference a Windows-only path.

Back in PowerShell, restart **only this distribution** after saving any work in
it, so WSL reads its new default-user and hostname configuration:

```powershell
wsl --terminate NixOS
wsl -d NixOS
```

### 5. Verify and maintain the installation

Inside NixOS:

```bash
whoami                         # caleb
hostname                       # wsl
nixos-version
systemctl is-system-running    # running
systemctl --failed             # no failed units
systemctl is-active wsl-mnt-guard home-manager-caleb podman.socket
podman info --format 'rootless={{.Host.Security.Rootless}}'  # rootless=true
sudo -v                        # verify your new password
```

For future updates, use the installed Linux checkout:

```bash
cd ~/nixos-config
git pull
sudo nixos-rebuild switch --flake '.#wsl'
```

No disk partitioning, `nixos-generate-config`, or hardware-file replacement is
needed for WSL. This path was verified with WSL 3.0.3 and the official
NixOS-WSL 2605.7.2 x86-64 image.

## Tips

- **Hardware per machine**: Native hosts use `hardware/<host>-hardware-configuration.nix` in their local clone. WSL uses the committed platform stub; do not replace it with an ISO-generated configuration.
- **Secrets**: Add sops-nix/agenix later.
- **Rollback**: Generations in bootloader.
- **Updates**: `nix flake update` + `--upgrade` for full upgrades.
- **Bootloader note**: nixos-gui hosts use systemd-boot (UEFI-only, fast & simple). WSL ignores bootloader.

Enjoy fast, declarative NixOS deploys! 🚀