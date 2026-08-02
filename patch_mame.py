#!/usr/bin/env python3
import os
import sys

def patch_mame(mame_dir):
    mame_dir = os.path.abspath(mame_dir)
    print(f"[*] Patching MAME source in: {mame_dir}")

    # 1. Patch scripts/genie.lua
    genie_lua = os.path.join(mame_dir, "scripts", "genie.lua")
    if os.path.exists(genie_lua):
        with open(genie_lua, "r", encoding="utf-8") as f:
            content = f.read()
        content = content.replace('"-s USE_SDL_TTF=3"', '"-s USE_SDL=2",\n\t\t"-s USE_SDL_TTF=2"')
        content = content.replace('"-s USE_SDL=3"', '"-s USE_SDL=2"')
        with open(genie_lua, "w", encoding="utf-8") as f:
            f.write(content)
        print("   [+] Patched scripts/genie.lua for SDL2 compatibility.")

    # 2. Patch msxdos2.cpp
    msxdos2 = os.path.join(mame_dir, "src", "devices", "bus", "msx", "cart", "msxdos2.cpp")
    if os.path.exists(msxdos2):
        with open(msxdos2, "r", encoding="utf-8") as f:
            content = f.read()
        if "#undef PAGE_SIZE" not in content:
            content = content.replace(
                '#include "bus/generic/slot.h"',
                '#include "bus/generic/slot.h"\n#ifdef PAGE_SIZE\n#undef PAGE_SIZE\n#endif'
            )
            with open(msxdos2, "w", encoding="utf-8") as f:
                f.write(content)
            print("   [+] Patched msxdos2.cpp for PAGE_SIZE macro collision.")

if __name__ == "__main__":
    target_dir = sys.argv[1] if len(sys.argv) > 1 else "mame"
    patch_mame(target_dir)
