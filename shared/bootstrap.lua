-- humuhumunukunukuapuaaHub | shared/ bootstrap v0.1.0-alpha
-- Receives a loaded reefFish library; never fetches code itself.
local Bootstrap = {}

function Bootstrap.Start(ReefFish, info)
    assert(type(ReefFish) == "table" and type(ReefFish.CreateWindow) == "function", "Missing reefFish UI Lib")
    info = info or {}

    local window = ReefFish:CreateWindow({
        Title = "HUMUHUMU HUB",
        Theme = "MatrixInverse",
        BorderThickness = 5
    })

    local context = {
        Window = window,
        ReefFish = ReefFish,
        GameId = info.GameId or game.GameId,
        PlaceId = info.PlaceId or game.PlaceId,
        GameName = info.Name or "Unknown experience",
        Match = info.Match or "None",
        HubVersion = info.HubVersion or "development",
        _connections = {},
        _cleanup = {}
    }

    function context:Log(message)
        print("[HumuHub] " .. tostring(message))
    end

    function context:Notify(message, level)
        self.Window:Notify(tostring(message), level or "INFO")
    end

    function context:Connect(signal, callback)
        assert(signal and type(callback) == "function", "Connect requires a signal and callback")
        local connection = signal:Connect(callback)
        table.insert(self._connections, connection)
        return connection
    end

    function context:OnCleanup(callback)
        assert(type(callback) == "function", "OnCleanup expects a function")
        table.insert(self._cleanup, callback)
    end

    local originalDestroy = window.Destroy
    local cleaned = false
    function window:Destroy()
        if not cleaned then
            cleaned = true
            for _, connection in ipairs(context._connections) do
                pcall(function() connection:Disconnect() end)
            end
            for _, callback in ipairs(context._cleanup) do
                local ok, err = pcall(callback)
                if not ok then warn("[HumuHub] Cleanup error: " .. tostring(err)) end
            end
            table.clear(context._connections)
            table.clear(context._cleanup)
        end
        originalDestroy(self)
    end

    local system = window:CreateTab({ Name = "SYSTEM" })
    system:CreateSection("HUMUHUMUNUKUNUKUAPUA'A HUB")
    system:CreateLabel({ Text = "Status: " .. tostring(info.Status or "READY") })
    system:CreateLabel({ Text = "Experience: " .. tostring(context.GameName) })
    system:CreateLabel({ Text = "Universe GameId: " .. tostring(context.GameId) })
    system:CreateLabel({ Text = "PlaceId: " .. tostring(context.PlaceId) })
    system:CreateLabel({ Text = "Selected by: " .. tostring(context.Match) })
    system:CreateButton({
        Name = "Copy IDs",
        Callback = function()
            local ids = "GameId=" .. tostring(context.GameId) .. " PlaceId=" .. tostring(context.PlaceId)
            if type(setclipboard) == "function" then
                local ok = pcall(setclipboard, ids)
                if ok then context:Notify("Copied game and place IDs", "OK") return end
            end
            context:Notify(ids, "INFO")
            print("[HumuHub] " .. ids)
        end
    })
    system:CreateButton({
        Name = "Check Hub Version",
        Callback = function()
            context:Notify("Hub " .. context.HubVersion .. " | reefFish " .. tostring(ReefFish.Version), "INFO")
        end
    })
    context.SystemTab = system
    window:SelectTab(system)
    return context
end

return Bootstrap
