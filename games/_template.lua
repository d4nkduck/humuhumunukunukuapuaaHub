-- humuhumunukunukuapuaaHub | example game module
-- This file is NOT registered to any real GameId/PlaceId by default.
-- Copy it to games/<your_game>.lua and add that path to registry.lua.
-- Modules receive the shared context and must return a function(context).

return function(ctx)
    local tab = ctx.Window:CreateTab({ Name = "DIAGNOSTICS" })
    tab:CreateSection("GAME MODULE // TEMPLATE")
    tab:CreateParagraph({
        Title = "SAFE DEBUGGING STARTER",
        Content = "This example only reads local session information and demonstrates UI controls. Replace it with diagnostics for your own experience.",
        Height = 110
    })

    local gameInfo = tab:CreateLabel({ Text = "GameId: " .. tostring(ctx.GameId) })
    local placeInfo = tab:CreateLabel({ Text = "PlaceId: " .. tostring(ctx.PlaceId) })

    tab:CreateButton({
        Name = "Refresh session info",
        Callback = function()
            gameInfo:SetText("GameId: " .. tostring(game.GameId))
            placeInfo:SetText("PlaceId: " .. tostring(game.PlaceId))
            ctx:Notify("Session IDs refreshed", "OK")
        end
    })

    tab:CreateToggle({
        Name = "Show extra debug messages",
        Flag = "template.verbose",
        Default = false,
        Callback = function(enabled)
            ctx:Log("Verbose debug messages: " .. tostring(enabled))
        end
    })

    tab:CreateDropdown({
        Name = "Diagnostics display",
        Flag = "template.display",
        Options = { "Basic", "Detailed", "Off" },
        Default = "Basic",
        Callback = function(selected)
            ctx:Log("Diagnostics display selected: " .. tostring(selected))
        end
    })

    tab:CreateButton({
        Name = "Show test notification",
        Callback = function()
            ctx.Window:Toast({
                Title = "HUMUHUMU HUB",
                Content = "Game module initialized and ReefFish UI is responding.",
                Duration = 4
            })
        end
    })

    -- Select this game's page when its module starts, instead of the System tab.
    ctx.Window:SelectTab(tab)
end
