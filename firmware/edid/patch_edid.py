#!/usr/bin/env python3
"""Patch LG C2 EDID to force RGB 4:4:4 by fixing ALL color capability flags."""

with open("/home/caleb/nixos-config/firmware/edid/modified_edid.bin.orig", "rb") as f:
    data = bytearray(f.read())

print(f"EDID size: {len(data)} bytes")

# === FIX 1: Base block features byte (0x18) ===
# Bits 4-3 = display color type: 0=RGB only, 1=RGB+YCbCr444, 2=RGB+YCbCr422, 3=both
print(f"\n[FIX 1] Base features byte [0x18]: 0x{data[0x18]:02X} (color type = {(data[0x18]>>3)&3})")
data[0x18] = data[0x18] & ~0x18  # Clear bits 4-3 -> RGB only
print(f"  After: 0x{data[0x18]:02X} (color type = {(data[0x18]>>3)&3})")

# Recalculate Block 0 checksum
block0_sum = sum(data[0:127]) % 256
data[127] = (256 - block0_sum) % 256
print(f"  Block 0 checksum: 0x{data[127]:02X}")

# === FIX 2: CTA flags byte (0x83) - clear YCbCr support ===
print(f"\n[FIX 2] CTA flags byte [0x83]: 0x{data[0x83]:02X}")
data[0x83] = data[0x83] & ~0x30  # Clear YCbCr 4:4:4 (bit5) and 4:2:2 (bit4)
print(f"  After: 0x{data[0x83]:02X}")

# === FIX 3: HDMI 1.4 VSDB Deep Color byte (0xA6) ===
print(f"\n[FIX 3] HDMI 1.4 VSDB DC byte [0xA6]: 0x{data[0xA6]:02X}")
data[0xA6] = data[0xA6] & ~0x78  # Clear DC_48, DC_36, DC_30, DC_Y444
print(f"  After: 0x{data[0xA6]:02X}")

# === FIX 4: HDMI 1.4 VSDB Max TMDS clock (0xA7) ===
# Currently 68 (340 MHz) - too low for 4K@60 RGB!
# 4K@60 RGB 8-bit needs 594 MHz. Set to 119 (595 MHz).
print(f"\n[FIX 4] HDMI 1.4 Max TMDS [0xA7]: {data[0xA7]} ({data[0xA7]*5} MHz)")
data[0xA7] = 119  # 119 * 5 = 595 MHz
print(f"  After: {data[0xA7]} ({data[0xA7]*5} MHz)")

# === FIX 5: HDMI Forum VSDB 4:2:0 flags (0xB6) ===
print(f"\n[FIX 5] HDMI Forum VSDB flags [0xB6]: 0x{data[0xB6]:02X}")
data[0xB6] = data[0xB6] & ~0x07  # Clear DC 4:2:0 bits
print(f"  After: 0x{data[0xB6]:02X}")

# === Recalculate Block 1 checksum ===
block1_sum = sum(data[128:255]) % 256
data[255] = (256 - block1_sum) % 256
print(f"\nBlock 1 checksum: 0x{data[255]:02X}")

with open("/home/caleb/nixos-config/firmware/edid/modified_edid.bin", "wb") as f:
    f.write(data)

print("\n=== EDID patched successfully! ===")
print("Key changes:")
print("  - Base block: RGB only (was RGB+YCbCr444)")
print("  - HDMI 1.4 VSDB: Max TMDS 595 MHz (was 340 MHz)")
print("  - HDMI 1.4 VSDB: Deep color flags cleared")
print("  - HDMI Forum VSDB: 4:2:0 deep color flags cleared")
print("  - CTA: YCbCr flags confirmed cleared")
