local RuntimeEnv = getgenv and getgenv() or _G
local storageFolder = "HaoToolHub"
local storageFile = storageFolder .. "/autoload.lua"
local fluentFile = storageFolder .. "/fluent.lua"
local sourceSaved = false

if makefolder then
    pcall(function()
        if not isfolder or not isfolder(storageFolder) then makefolder(storageFolder) end
    end)
end

if writefile then
    sourceSaved = pcall(function() writefile(storageFile, HAOTOOL_SOURCE) end)
    pcall(function() writefile(fluentFile, HAOTOOL_FLUENT_SOURCE) end)
end
RuntimeEnv.HAOTOOL_SOURCE_SAVED = sourceSaved
RuntimeEnv.HAOTOOL_EMBEDDED_FLUENT_SOURCE = HAOTOOL_FLUENT_SOURCE

local function failStartup(message)
    RuntimeEnv.HAOTOOL_RUN_TOKEN = {}
    RuntimeEnv.HAOTOOL_RUNNING = nil
    RuntimeEnv.HAOTOOL_UI_READY = false
    RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = tostring(message)
    if type(RuntimeEnv.HAOTOOL_SHOW_STARTUP_ERROR) == "function" then
        pcall(RuntimeEnv.HAOTOOL_SHOW_STARTUP_ERROR, message)
    end
    if type(RuntimeEnv.HAOTOOL_DESTROY_UI) == "function" then
        pcall(RuntimeEnv.HAOTOOL_DESTROY_UI)
    end
    RuntimeEnv.HAOTOOL_TOGGLE_MENU = nil
    RuntimeEnv.HAOTOOL_DESTROY_UI = nil
end

local runner, compileError = loadstring(HAOTOOL_SOURCE)
if not runner then
    failStartup(compileError)
    warn("[HAOTOOL] Không biên dịch được tool: " .. tostring(compileError))
else
    local ok, runError = pcall(runner)
    if not ok then
        failStartup(runError)
        warn("[HAOTOOL] Tool gặp lỗi: " .. tostring(runError))
    elseif RuntimeEnv.HAOTOOL_UI_READY then
        RuntimeEnv.HAOTOOL_LAST_FATAL_ERROR = nil
    end
end
