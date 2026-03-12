#!/usr/bin/env python3
"""Patch LG C2 EDID to force RGB 4:4:4 by removing deep color and 4:2:0 flags."""

import sys

with open("/home/caleb/nixos-config/firmware/edid/modified_edid.bin.orig", "rb") as f:
    data = bytearray(f.read())

print(f"EDID size: {len(data)} bytes")

# --- Block 1 CTA header (offset 0x83) ---
print(f"\nCTA flags byte [0x83]: 0x{data[0x83]:02X}")
print(f"  YCbCr 4:4:4 (bit 5): {(data[0x83] >> 5) & 1}")
print(f"  YCbCr 4:2:2 (bit 4): {(data[0x83] >> 4) & 1}")
# Already 0, but force clear just in case
data[0x83] = data[0x83] & ~0x30
print(f"  After clear: 0x{data[0x83]:02X}")

# --- HDMI 1.4 VSDB Deep Color byte (offset 0xA6) ---
# VSDB starts at 0xA0, OUI is bytes 1-3, deep color is byte 6 (0xA0+6=0xA6)
dc_byte = 0xA6
print(f"\nHDMI 1.4 VSDB Deep Color byte [0x{dc_byte:02X}]: 0x{data[dc_byte]:02X}")
print(f"  DC_36bit: {(data[dc_byte] >> 6) & 1}")
print(f"  DC_30bit: {(data[dc_byte] >> 5) & 1}")
print(f"  DC_Y444:  {(data[dc_byte] >> 3) & 1}")
# Clear all deep color bits (bits 3-6): keep only non-DC bits
data[dc_byte] = data[dc_byte] & ~0x78  # Clear bits 3,4,5,6
print(f"  After clear: 0x{data[dc_byte]:02X}")

# --- HDMI Forum VSDB 4:2:0 flags ---
# HDMI Forum VSDB starts at 0xAF, byte[6] is at 0xAF+1+6 = 0xB6
hf_flags = 0xB6
print(f"\nHDMI Forum VSDB byte[6] [0x{hf_flags:02X}]: 0x{data[hf_flags]:02X}")
print(f"  DC_4:2:0_48bit (bit 2): {(data[hf_flags] >> 2) & 1}")
print(f"  DC_4:2:0_36bit (bit 1): {(data[hf_flags] >> 1) & 1}")
print(f"  DC_4:2:0_30bit (bit 0): {(data[hf_flags] >> 0) & 1}")
data[hf_flags] = data[hf_flags] & ~0x07  # Clear bits 0-2
print(f"  After clear: 0x{data[hf_flags]:02X}")

# --- Recalculate checksum for Block 1 ---
block1_sum = sum(data[128:255]) % 256
new_checksum = (256 - block1_sum) % 256
print(f"\nBlock 1 checksum: 0x{data[255]:02X} -> 0x{new_checksum:02X}")
data[255] = new_checksum

with open("/home/caleb/nixos-config/firmware/edid/modified_edid.bin", "wb") as f:
    f.write(data)

print("\nEDID patched and saved!")
