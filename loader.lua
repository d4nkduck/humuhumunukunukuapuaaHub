-- humuhumunukunukuapuaaHub | UNIVERSAL LOADER
-- Permanent entry point: never change this URL when adding or updating games.
-- Requires game:HttpGet and loadstring (not available in normal Studio LocalScripts).

local HUB_VERSION = "universal"
local BASE = "https://raw.githubusercontent.com/d4nkduck/humuhumunukunukuapuaaHub/main/"
local REEFFISH_URL = "https://raw.githubusercontent.com/d4nkduck/reefFish-UI-Lib/main/dist/reefFish.lua"
-- Vary the request URL on each run to avoid old game-script CDN caches.
local REQUEST_NONCE = tostring(DateTime.now().UnixTimestampMillis) .. "_" .. tostring(math.random(100000,999999))

local function log(message)
    print("[HumuHub " .. HUB_VERSION .. "] " .. tostring(message))
end

local function loadRemote(url, name)
    assert(type(loadstring) == "function",
        "This loader needs loadstring. Use ModuleScripts with require() in Roblox Studio.")
    local separator = url:find("?", 1, true) and "&" or "?"
    local freshUrl = url .. separator .. "humu_cache=" .. REQUEST_NONCE
    local chunk
    local lastError

    -- Prefer a fresh fetch; plain URL is only a fallback if fetching or
    -- compiling the cache-busted version is unsupported by the client.
    for _, candidate in ipairs({freshUrl, url}) do
        local downloaded, source = pcall(function()
            return game:HttpGet(candidate)
        end)
        if downloaded and type(source) == "string" and #source > 0 then
            local compiled, compileError = loadstring(source)
            if type(compiled) == "function" then
                chunk = compiled
                break
            end
            lastError = compileError
        else
            lastError = source
        end
    end

    if not chunk then
        error("Failed to fetch or compile " .. tostring(name) .. ": " .. tostring(lastError))
    end

    local ran, value = pcall(chunk)
    if not ran then
        error("Failed to initialize " .. tostring(name) .. ": " .. tostring(value))
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
