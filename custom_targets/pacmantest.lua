CPUS["Z80"] = true
CPUS["S2650"] = true
SOUNDS["NAMCO"] = true
SOUNDS["SAMPLES"] = true
SOUNDS["AY8910"] = true
SOUNDS["SN76496"] = true
MACHINES["GEN_LATCH"] = true
MACHINES["TTL74259"] = true
MACHINES["WATCHDOG"] = true
MACHINES["Z80DAISY"] = true

function createProjects_mame_pacmantest(_target, _subtarget)
    project ("mame_pacmantest")
    targetsubdir(_target .. "_" .. _subtarget)
    kind (LIBTYPE)
    uuid (os.uuid("drv-mame-pacmantest"))
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
        MAME_DIR .. "src/mame/pacman/pacman.cpp",
        MAME_DIR .. "src/mame/pacman/pacman.h",
        MAME_DIR .. "src/mame/pacman/pacman_m.cpp",
        MAME_DIR .. "src/mame/pacman/pacman_v.cpp",
        MAME_DIR .. "src/mame/pacman/pacplus.cpp",
        MAME_DIR .. "src/mame/pacman/jumpshot.cpp",
    }
end

function linkProjects_mame_pacmantest(_target, _subtarget)
    links {
        "mame_pacmantest",
    }
end