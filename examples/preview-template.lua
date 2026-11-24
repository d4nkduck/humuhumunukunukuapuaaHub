-- Preview the unregistered game template without editing registry.lua.
-- Run only in a Lua environment where game:HttpGet and loadstring exist.
-- Normal Studio LocalScripts should use local ModuleScripts via require() instead.
local base = "https://raw.githubusercontent.com/d4nkduck/humuhumunukunukuapuaaHub/main/"
local reefFishUrl = "https://raw.githubusercontent.com/d4nkduck/reefFish-UI-Lib/main/dist/reefFish-v0.3.lua"

local function loadFrom(url)
    local source = game:HttpGet(url)
    local chunk, err = loadstring(source)
    assert(chunk, err)
    return chunk()
end

local ui = loadFrom(reefFishUrl)
local bootstrap = loadFrom(base .. "shared/bootstrap.lua")
local gameModule = loadFrom(base .. "games/_template.lua")

assert(ui.Version == "0.3.0-alpha", "Unexpected ReefFish release")
assert(type(bootstrap) == "table" and type(bootstrap.Start) == "function")
assert(type(gameModule) == "function")

local ctx = bootstrap.Start(ui, {
    GameId = game.GameId,
    PlaceId = game.PlaceId,
    Name = "Template preview",
    Match = "Manual demo",
    Status = "PREVIEW",
    HubVersion = "0.1.0-alpha"
})
gameModule(ctx)
ctx:Notify("Unregistered template loaded for manual preview", "OK")
return ctx
