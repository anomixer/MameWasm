
CPUS["M6502"] = true
CPUS["Z80"] = true
CPUS["M6809"] = true
CPUS["G65816"] = true
CPUS["MCS48"] = true
CPUS["MCS51"] = true

SOUNDS["AY8910"] = true
SOUNDS["SN76496"] = true
SOUNDS["DAC"] = true
SOUNDS["SPEAKER"] = true
SOUNDS["SID6581"] = true
SOUNDS["SID8580"] = true
SOUNDS["VOLTAGE_REGULATOR"] = true

MACHINES["GEN_LATCH"] = true
MACHINES["TTL74259"] = true
MACHINES["WATCHDOG"] = true
MACHINES["6821PIA"] = true
MACHINES["6850ACIA"] = true
MACHINES["6522VIA"] = true
MACHINES["6526CIA"] = true

function createProjects_mame_apple(_target, _subtarget)
    project ("mame_apple")
    targetsubdir(_target .. "_" .. _subtarget)
    kind (LIBTYPE)
    uuid (os.uuid("drv-mame-apple"))
    addprojectflags()
    precompiledheaders_novs()

    includedirs {
        MAME_DIR .. "src/osd",
        MAME_DIR .. "src/emu",
        MAME_DIR .. "src/devices",
        MAME_DIR .. "src/mame/shared",
        MAME_DIR .. "src/lib",
        MAME_DIR .. "src/lib/util",
        MAME_DIR .. "3rdparty",
        GEN_DIR  .. "mame/layout",
    }

    files {
        -- Apple II Family
        MAME_DIR .. "src/mame/apple/apple2.cpp",
        MAME_DIR .. "src/mame/apple/apple2e.cpp",
        MAME_DIR .. "src/mame/apple/apple2gs.cpp",
        MAME_DIR .. "src/mame/apple/apple3.cpp",
        MAME_DIR .. "src/mame/apple/apple1.cpp",
        MAME_DIR .. "src/mame/apple/f108.cpp",
        MAME_DIR .. "src/mame/apple/tk2000.cpp",
        MAME_DIR .. "src/mame/apple/apple2common.cpp",
        MAME_DIR .. "src/mame/apple/apple2video.cpp",
        MAME_DIR .. "src/mame/apple/apple3_m.cpp",
        MAME_DIR .. "src/mame/apple/apple3_v.cpp",
        
        -- Acorn Family
        MAME_DIR .. "src/mame/acorn/bbcb.cpp",
        MAME_DIR .. "src/mame/acorn/bbcbp.cpp",
        MAME_DIR .. "src/mame/acorn/bbcm.cpp",
        MAME_DIR .. "src/mame/acorn/electron.cpp",
        MAME_DIR .. "src/mame/acorn/bbc_m.cpp",
        MAME_DIR .. "src/mame/acorn/bbc_v.cpp",
        
        -- Tandy / Dragon
        MAME_DIR .. "src/mame/trs/trs80.cpp",
        MAME_DIR .. "src/mame/trs/coco.cpp",
        MAME_DIR .. "src/mame/trs/dragon.cpp",
        
        -- Other 8-bit
        MAME_DIR .. "src/mame/commodore/c64.cpp",
        MAME_DIR .. "src/mame/tangerine/oric.cpp",
        MAME_DIR .. "src/mame/agat/agat.cpp",
        MAME_DIR .. "src/mame/vtech/laser3k.cpp",
    }
end

function linkProjects_mame_apple(_target, _subtarget)
    links {
        "mame_apple",
    }
end
