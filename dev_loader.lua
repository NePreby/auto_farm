-- Chỉ dùng khi executor hỗ trợ readfile và bạn đã chép cả thư mục HAOTOOL_Modular
-- vào thư mục workspace của executor. Bản dist/main.lua vẫn là cách chạy ổn định nhất.
local ROOT = "HAOTOOL_Modular"
assert(type(readfile) == "function", "Executor không hỗ trợ readfile")

local manifest = readfile(ROOT .. "/manifest.txt")
local parts = {}
for relativePath in string.gmatch(manifest, "[^\r\n]+") do
    relativePath = string.gsub(relativePath, "^%s+", "")
    relativePath = string.gsub(relativePath, "%s+$", "")
    if relativePath ~= "" and string.sub(relativePath, 1, 1) ~= "#" then
        table.insert(parts, readfile(ROOT .. "/" .. relativePath))
    end
end

local env = getgenv and getgenv() or _G
env.HAOTOOL_EMBEDDED_FLUENT_SOURCE = readfile(ROOT .. "/vendor/fluent.lua")
local source = table.concat(parts)
local runner, compileError = loadstring(source, "@HAOTOOL_Modular")
assert(runner, compileError)
return runner()
