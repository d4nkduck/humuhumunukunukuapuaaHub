-- humuhumunukunukuapuaaHub | loader v0.2.0-alpha
-- Main public entry point for Lua environments supporting game:HttpGet + loadstring.
-- This loader never guesses IDs or runs a game module on an unsupported experience.

local HUB_VERSION = "0.2.0-alpha"
local BASE = "https://raw.githubusercontent.com/d4nkduck/humuhumunukunukuapuaaHub/main/"
local REEFFISH_URL = "https://raw.githubusercontent.com/d4nkduck/reefFish-UI-Lib/main/dist/reefFish-v0.3.lua"

local function log(message)
    print("[HumuHub " .. HUB_VERSION .. "] " .. tostring(message))
end

local function loadRemote(url, name)
    assert(type(loadstring) == "function", "This loader requires loadstring; use ModuleScripts with require() in Roblox Studio")
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(source) ~= "string" or #source == 0 then
        error("Unable to download " .. tostring(name) .. ": " .. tostring(source))
    end

    local chunk, compileError = loadstring(source)
    if type(chunk) ~= "function" then
        error("Failed to compile " .. tostring(name) .. ": " .. tostring(compileError))
    end

    local ran, value = pcall(chunk)
    if not ran then
        error("Failed to initialise " .. tostring(name) .. ": " .. tostring(value))
    end
    return value
end

local function loadHubFile(path)
    -- Only load Lua files from this hub repository. No dynamic remote URLs in the registry.
    assert(type(path) == "string"
        and path:match("^[%w_/%-]+%.lua$")
        and not path:find("..", 1, true),
        "Invalid hub module path")
    return loadRemote(BASE .. path, path)
end

local function getEntry(registry, gameId, placeId)
    assert(type(registry) == "table" and registry.Version == 1, "Unsupported hub registry schema")
    local places = type(registry.Places) == "table" and registry.Places or {}
    local games = type(registry.Games) == "table" and registry.Games or {}
    local selected = places[placeId] or places[tostring(placeId)]
    if selected then return selected, "PlaceId" end
    selected = games[gameId] or games[tostring(gameId)]
    if selected then return selected, "GameId" end
    return nil, "Unsupported"
end

local function launch()
    if not game:IsLoaded() then game.Loaded:Wait() end

    local gameId, placeId = game.GameId, game.PlaceId
    log("Checking GameId=" .. tostring(gameId) .. " PlaceId=" .. tostring(placeId))

    local registry = loadHubFile("registry.lua")
    local entry, matchedBy = getEntry(registry, gameId, placeId)
    if entry then
        assert(type(entry) == "table" and type(entry.Module) == "string", "Invalid registry entry")
        assert(entry.Module:match("^games/[%w_/%-]+%.lua$") and not entry.Module:find("..", 1, true),
            "Game module must use a games/*.lua path")
    end

    local ReefFish = loadRemote(REEFFISH_URL, "reefFish UI Lib")
    assert(type(ReefFish) == "table" and type(ReefFish.CreateWindow) == "function",
        "reefFish returned an invalid library")

    local bootstrap = loadHubFile("shared/bootstrap.lua")
    assert(type(bootstrap) == "table" and type(bootstrap.Start) == "function",
        "Invalid hub bootstrap")

    local ctx = bootstrap.Start(ReefFish, {
        GameId = gameId,
        PlaceId = placeId,
        Name = entry and entry.Name or "Unregistered experience",
        Match = matchedBy,
        Status = entry and "SUPPORTED" or "UNSUPPORTED",
        HubVersion = HUB_VERSION
    })

    if not entry then
        ctx:Notify("No game-specific module registered for this experience", "WARN")
        log("Unsupported game. Add this GameId or PlaceId to registry.lua to enable a module.")
        return ctx
    end

    log("Match via " .. matchedBy .. " -> " .. entry.Module)
    local okModule, moduleOrError = pcall(loadHubFile, entry.Module)
    if not okModule then
        ctx:Notify("Module download/compile failed; check console", "ERROR")
        warn("[HumuHub] " .. tostring(moduleOrError))
        return ctx
    end
    if type(moduleOrError) ~= "function" then
        ctx:Notify("Game module must return function(context)", "ERROR")
        return ctx
    end

    local okStart, startError = pcall(moduleOrError, ctx)
    if not okStart then
        ctx:Notify("Game module startup failed; check console", "ERROR")
        warn("[HumuHub] " .. tostring(startError))
    else
        ctx:Notify("Loaded " .. tostring(entry.Name or "game debug module"), "OK")
    end
    return ctx
end

local ok, result = pcall(launch)
if not ok then
    warn("[HumuHub] Loader failed: " .. tostring(result))
    return nil
end
return result
