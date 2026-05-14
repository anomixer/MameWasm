-- supracan.lua
-- Standalone build configuration for Super A'Can

-- 1. Specify required cores
CPUS["M680X0"] = true
CPUS["M6502"] = true

SOUNDS["UMC6611"] = true
SOUNDS["UMC6619"] = true
SOUNDS["SPEAKER"] = true

MACHINES["GEN_LATCH"] = true

-- 2. Specify driver list
drivlistfile = "src/mame/supracan.lst"

-- 3. Define Project Functions for Genie
function createProjects_mame_supracan(_target, _subtarget)
	project ("mame_supracan")
	targetsubdir(_target .."_" .. _subtarget)
	kind (LIBTYPE)
	uuid (os.uuid("drv-mame-supracan"))
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
		MAME_DIR .. "src/mame/umc/supracan.cpp",
		MAME_DIR .. "src/mame/umc/umc6650.cpp",
		MAME_DIR .. "src/mame/umc/umc6619_sound.cpp",
		MAME_DIR .. "src/devices/bus/supracan/rom.cpp",
		MAME_DIR .. "src/devices/bus/supracan/slot.cpp",
	}
end

function linkProjects_mame_supracan(_target, _subtarget)
	links {
		"mame_supracan",
	}
end
