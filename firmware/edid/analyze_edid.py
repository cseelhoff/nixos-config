#!/usr/bin/env python3
"""Analyze EDID for color-related fields."""

data = open("/home/caleb/nixos-config/firmware/edid/modified_edid.bin", "rb").read()

feat = data[0x18]
print(f"Base block features byte [0x18]: 0x{feat:02X} = {feat:08b}")
print(f"  Display color type (bits 4-3): {(feat>>3)&3}")
print(f"    0=RGB444 only, 1=RGB+YCbCr444, 2=RGB+YCbCr422, 3=RGB+both")
print()

# Parse CTA data blocks properly
print("=== CTA Data Blocks ===")
dtd_offset = data[130] + 128
offset = 132
while offset < dtd_offset:
    header = data[offset]
    tag = (header >> 5) & 0x07
    length = header & 0x1F
    tag_names = {1:'Audio',2:'Video',3:'Vendor Specific',4:'Speaker',7:'Extended'}
    name = tag_names.get(tag, f'Unknown({tag})')
    block_data = data[offset:offset+length+1]
    
    if tag == 3:
        oui = (data[offset+3] << 16) | (data[offset+2] << 8) | data[offset+1]
        if oui == 0x000C03:
            print(f"\n[0x{offset:02X}] HDMI 1.4 VSDB, len={length}")
            print(f"  Raw: {' '.join(f'{b:02X}' for b in block_data)}")
            if length >= 6:
                dcb = data[offset+6]
                print(f"  DC byte [0x{offset+6:02X}]: 0x{dcb:02X} = {dcb:08b}")
                print(f"    DC_48bit:{(dcb>>6)&1} DC_36bit:{(dcb>>5)&1} DC_30bit:{(dcb>>4)&1} DC_Y444:{(dcb>>3)&1}")
            if length >= 7:
                print(f"  Max TMDS clock [0x{offset+7:02X}]: {data[offset+7]} -> {data[offset+7]*5} MHz")
        elif oui == 0xC45DD8:
            print(f"\n[0x{offset:02X}] HDMI Forum VSDB, len={length}")
            print(f"  Raw: {' '.join(f'{b:02X}' for b in block_data)}")
            if length >= 5:
                print(f"  Max TMDS char rate: {data[offset+5]} -> {data[offset+5]*5} MHz")
            if length >= 6:
                scdc = data[offset+6]
                print(f"  SCDC byte: 0x{scdc:02X} = {scdc:08b}")
                print(f"    SCDC_Present:{(scdc>>7)&1} RR_Capable:{(scdc>>6)&1}")
            if length >= 7:
                flags = data[offset+7]
                print(f"  DC/420 flags: 0x{flags:02X} = {flags:08b}")
                print(f"    DC_420_48:{(flags>>2)&1} DC_420_36:{(flags>>1)&1} DC_420_30:{(flags>>0)&1}")
        else:
            print(f"\n[0x{offset:02X}] VSDB OUI=0x{oui:06X}, len={length}")
    elif tag == 7:
        ext_tag = data[offset+1]
        ext_names = {0:'Video Capability',5:'Colorimetry',6:'HDR Static Metadata',
                     13:'Video Format Pref',14:'YCbCr420 Video Data',15:'YCbCr420 Cap Map',
                     32:'Vendor Specific Audio'}
        ext_name = ext_names.get(ext_tag, f'ExtTag({ext_tag})')
        print(f"\n[0x{offset:02X}] Extended: {ext_name} (tag={ext_tag}), len={length}")
        print(f"  Raw: {' '.join(f'{b:02X}' for b in block_data)}")
        if ext_tag == 15:
            print(f"  *** YCbCr 4:2:0 Capability Map - this tells driver which modes can use 4:2:0!")
        if ext_tag == 14:
            print(f"  *** YCbCr 4:2:0 Video Data Block - lists 4:2:0 only modes!")
    else:
        print(f"\n[0x{offset:02X}] {name}, len={length}")
        print(f"  Raw: {' '.join(f'{b:02X}' for b in block_data)}")
    
    offset += length + 1

print(f"\n\n=== Key Summary ===")
print(f"Base EDID color type: {(feat>>3)&3} (should be 0 for RGB only)")
cta_flags = data[131]
print(f"CTA YCbCr444 support: {(cta_flags>>5)&1} (should be 0)")
print(f"CTA YCbCr422 support: {(cta_flags>>4)&1} (should be 0)")
