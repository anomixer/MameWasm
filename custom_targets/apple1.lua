
CPUS["M6502"] = true
SOUNDS["SPEAKER"] = true

function createProjects_mame_apple1(_target, _subtarget)
    project ("mame_apple1")
    targetsubdir(_target .. "_" .. _subtarget)
    kind (LIBTYPE)
    uuid (os.uuid("drv-mame-apple1"))
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
        MAME_DIR .. "src/mame/apple/apple1.cpp",
    }
end

function linkProjects_mame_apple1(_target, _subtarget)
    links {
        "mame_apple1",
    }
end
