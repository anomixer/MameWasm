
---------------------------------------------------------------------------
--
--   ample.lua
--
--   AmpleWeb Subtarget (Cloned from mame.lua with Bug Filter)
--
---------------------------------------------------------------------------

local function selectors_get(path)
    local selector = ""
    local f = io.open(path, "r")
    if f then
        for l in f:lines() do
            if l:sub(1, 3) == "--@" then
                local pos = l:find(",")
                if pos then
                    local name = l:sub(pos+1)
                    if not name:find("MCS96") and not name:find("I8X9X") then
                        selector = selector .. name .. "\n"
                    end
                end
            end
        end
        f:close()
    end
    return selector
end

-- Enable EVERYTHING except broken stuff
local selectors =
        selectors_get(MAME_DIR .. "scripts/src/cpu.lua") ..
        selectors_get(MAME_DIR .. "scripts/src/sound.lua") ..
        selectors_get(MAME_DIR .. "scripts/src/video.lua") ..
        selectors_get(MAME_DIR .. "scripts/src/machine.lua") ..
        selectors_get(MAME_DIR .. "scripts/src/bus.lua") ..
        selectors_get(MAME_DIR .. "scripts/src/formats.lua")

load(selectors)()

---------------------------------------------------------------------------

function linkProjects_mame_ample(_target, _subtarget)
    local projects = {}
    for x, dir in pairs(os.matchdirs(path.join(MAME_DIR, "src", _target, "*"))) do
        local name = path.getname(dir)
        if name ~= "shared" then
            if 0 < #os.matchfiles(path.join(dir, "**.cpp")) then
                table.insert(projects, name)
            end
        end
    end
    table.sort(projects)
    table.insert(projects, "shared")
    links(projects)
end

function createMAMEProjects(_target, _subtarget, _name)
    project (_name)
    targetsubdir(_target .."_" .. _subtarget)
    kind (LIBTYPE)
    uuid (os.uuid("drv-" .. _target .."_" .. _subtarget .. "_" .._name))
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

    includedirs {
        ext_includedir("asio"),
        ext_includedir("flac"),
        ext_includedir("glm"),
        ext_includedir("jpeg"),
        ext_includedir("rapidjson"),
        ext_includedir("zlib")
    }
end

function createProjects_mame_ample(_target, _subtarget)
    for x, dir in pairs(os.matchdirs(path.join(MAME_DIR, "src", _target, "*"))) do
        local name = path.getname(dir)
        local sources = {}
        if 0 < #os.matchfiles(path.join(dir, "**.cpp")) then
            table.insert(sources, MAME_DIR .. "src/" .. _target .. "/" .. name .. "/**.cpp")
            if 0 < #os.matchfiles(path.join(dir, "**.h")) then
                table.insert(sources, MAME_DIR .. "src/" .. _target .. "/" .. name .. "/**.h")
            end
            createMAMEProjects(_target, _subtarget, name)
            table.sort(sources)
            files(sources)
        end
    end
end
