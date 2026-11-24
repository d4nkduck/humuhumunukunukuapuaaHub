-- humuhumunukunukuapuaaHub | raise a floppa 2 diagnostics v0.2
-- PlaceId: 9772878203
-- Rod names and coordinates are intentionally exact to the requested workflow.
-- This module affects only the local client's character and visible instances.
-- Beware: client-side meteor destruction may not stop server-owned meteor logic.

return function(ctx)
    assert(game.PlaceId == 9772878203, "Raise a Floppa 2 module loaded in the wrong place")

    local Players = game:GetService("Players")
    local SoundService = game:GetService("SoundService")
    local player = Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    local tab = ctx.Window:CreateTab({ Name = "FLOPPA 2" })

    local RODS = { "Fishing Rod", "Golden Fishing Rod", "Diamond Fishing Rod" }
    local FISHING_CFRAME = CFrame.new(-25, 76, 22)
        * CFrame.Angles(math.rad(180), math.rad(-40), math.rad(180))
    local TIMEOUT = 10
    local RECAST_DELAY = 0.3
    local CHECK_INTERVAL = 0.05

    -- Declare controls before callbacks to preserve correct Luau closure scope.
    local rodPicker
    local fishToggle

    local fishing = {
        active = false,
        epoch = 0,
        awaiting = false,
        castAt = 0,
        nextCastAt = 0,
        anchoredRoot = nil,
        originalAnchored = false,
        initiallyMinimized = false,
        notifyConnections = {},
        watchedSounds = {},
        lastNotifyAt = 0,
        stopping = false
    }

    local function note(text, level)
        ctx:Notify(text, level or "INFO")
    end

    local function characterParts()
        local char = player.Character
        if not char then return nil end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root or humanoid.Health <= 0 then return nil end
        return char, humanoid, root
    end

    local function selectedRod()
        return rodPicker:Get()
    end

    local function findRod(name, character)
        if not name then return nil end
        local equipped = character and character:FindFirstChild(name)
        if equipped and equipped:IsA("Tool") then return equipped end
        local stored = backpack:FindFirstChild(name)
        if stored and stored:IsA("Tool") then return stored end
        return nil
    end

    local function restoreAnchor()
        if fishing.anchoredRoot and fishing.anchoredRoot.Parent then
            fishing.anchoredRoot.Anchored = fishing.originalAnchored
        end
        fishing.anchoredRoot = nil
    end

    local function anchorRoot(root)
        if fishing.anchoredRoot ~= root then
            restoreAnchor()
            fishing.anchoredRoot = root
            fishing.originalAnchored = root.Anchored
        end
        root.Anchored = true
        root.CFrame = FISHING_CFRAME
    end

    local function clickCenter()
        local camera = workspace.CurrentCamera
        if not camera then return false, "Camera not available" end
        local center = camera.ViewportSize / 2

        -- Prefer exact centre-of-viewport input where the runtime allows it.
        local okService, virtualInput = pcall(function()
            return game:GetService("VirtualInputManager")
        end)
        if okService and virtualInput then
            local sent = pcall(function()
                virtualInput:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
                virtualInput:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
            end)
            if sent then return true end
        end

        -- Optional executor input APIs vary between builds.
        if type(mousemoveabs) == "function" and type(mouse1click) == "function" then
            local sent = pcall(function()
                mousemoveabs(math.floor(center.X), math.floor(center.Y))
                mouse1click()
            end)
            if sent then return true end
        end

        -- Tool activation is the in-client equivalent if input injection is unavailable.
        local char = player.Character
        local equipped = findRod(selectedRod(), char)
        if equipped and char and equipped.Parent == char then
            local activated = pcall(function() equipped:Activate() end)
            if activated then return true end
        end

        return false, "No supported center-click or tool activation method"
    end

    local function stopFishing(reason, report)
        if fishing.stopping then return end
        fishing.stopping = true
        fishing.active = false
        fishing.epoch += 1
        fishing.awaiting = false
        for _, connection in ipairs(fishing.notifyConnections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(fishing.notifyConnections)
        table.clear(fishing.watchedSounds)
        restoreAnchor()
        if fishing.autoMinimized and not ctx.Window.destroyed then
            ctx.Window:SetMinimized(false)
        end
        fishing.autoMinimized = false
        if fishToggle and fishToggle:Get() then fishToggle:Set(false) end
        fishing.stopping = false
        if report then note(reason or "Auto Fish stopped", report) end
    end

    local function equipSelected(force)
        local char, humanoid, root = characterParts()
        if not char then return false, "Character not ready" end
        local choice = selectedRod()
        local tool = findRod(choice, char)
        if not tool then return false, choice .. " is not in Backpack or equipped" end

        -- Save the original anchored state once, and put the player in the
        -- intended fishing position and precise Euler-angle orientation.
        anchorRoot(root)

        local competingTool = false
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") and child ~= tool then competingTool = true break end
        end
        if force or competingTool or tool.Parent ~= char then
            local success = pcall(function()
                humanoid:UnequipTools()
                humanoid:EquipTool(tool)
            end)
            if not success then return false, "Couldn't equip " .. choice end
        end
        if tool.Parent ~= char then return false, "Rod did not equip: " .. choice end
        return true
    end

    local function cast()
        if not fishing.active then return end
        fishing.awaiting = true
        fishing.castAt = os.clock()
        local success, err = clickCenter()
        if not success then
            stopFishing(err, "ERROR")
        end
    end

    local function onNotify()
        if not fishing.active or not fishing.awaiting then return end
        local now = os.clock()
        -- A Sound.Played and Playing-change event may arrive together.
        if now - fishing.lastNotifyAt < 0.12 then return end
        fishing.lastNotifyAt = now
        fishing.awaiting = false

        -- Reel immediately upon the named Notify sound; next cast in 0.3 s.
        local success, err = clickCenter()
        if not success then
            stopFishing(err, "ERROR")
            return
        end
        fishing.nextCastAt = os.clock() + RECAST_DELAY
    end

    local function watchSound(instance)
        if not instance:IsA("Sound") or instance.Name ~= "Notify" then return end
        if fishing.watchedSounds[instance] then return end
        fishing.watchedSounds[instance] = true

        table.insert(fishing.notifyConnections, instance.Played:Connect(onNotify))
        table.insert(fishing.notifyConnections,
            instance:GetPropertyChangedSignal("Playing"):Connect(function()
                if instance.Playing then onNotify() end
            end))
    end

    local function listenForNotify()
        -- Existing sounds may be in the Tool, Workspace, PlayerGui or SoundService.
        -- We cannot assume a particular internal game hierarchy.
        local containers = {
            workspace, SoundService, backpack,
            player:WaitForChild("PlayerGui"),
            game:GetService("ReplicatedStorage")
        }
        if player.Character then table.insert(containers, player.Character) end
        for _, container in ipairs(containers) do
            for _, instance in ipairs(container:GetDescendants()) do
                watchSound(instance)
            end
        end
        table.insert(fishing.notifyConnections,
            game.DescendantAdded:Connect(watchSound))
    end

    local function resetRod(reason)
        fishing.awaiting = false
        local ok, err = equipSelected(true)
        if not ok then
            stopFishing(err, "ERROR")
            return false
        end
        fishing.nextCastAt = os.clock() + RECAST_DELAY
        if reason then print("[HumuHub/Floppa2] " .. reason) end
        return true
    end

    local function runFishing(epoch)
        -- All work stays inside one cancellable session loop.
        while fishing.active and fishing.epoch == epoch do
            local char, _, root = characterParts()
            if not char then
                stopFishing("Character lost; Auto Fish safely stopped", "WARN")
                break
            end

            if not findRod(selectedRod(), char) then
                stopFishing("Selected fishing rod left the inventory", "WARN")
                break
            end

            local selected = char:FindFirstChild(selectedRod())
            local otherEquipped = false
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Tool") and child.Name ~= selectedRod() then
                    otherEquipped = true
                    break
                end
            end

            if otherEquipped or not (selected and selected:IsA("Tool")) then
                if not resetRod("Re-equipping selected rod") then break end
            elseif root ~= fishing.anchoredRoot or not root.Anchored then
                anchorRoot(root)
            end

            local now = os.clock()
            if fishing.active and fishing.epoch == epoch then
                if fishing.awaiting and (now - fishing.castAt >= TIMEOUT) then
                    resetRod("No Notify sound after 10s; retrying")
                elseif not fishing.awaiting and now >= fishing.nextCastAt then
                    cast()
                end
            end
            task.wait(CHECK_INTERVAL)
        end
    end

    local function startFishing()
        if fishing.active then return end
        local char = player.Character
        local choice = selectedRod()
        if not choice or not findRod(choice, char) then
            note("Auto Fish requires " .. tostring(choice or "a fishing rod") .. " in your inventory", "ERROR")
            if fishToggle then fishToggle:Set(false) end
            return
        end

        fishing.active = true
        fishing.epoch += 1
        fishing.awaiting = false
        fishing.lastNotifyAt = 0
        fishing.nextCastAt = 0

        local equipped, err = equipSelected(false)
        if not equipped then
            stopFishing(err, "ERROR")
            return
        end

        listenForNotify()

        -- The UI is initially centered. Minimizing stops its buttons from
        -- capturing synthetic centre-screen fishing clicks.
        fishing.autoMinimized = not ctx.Window.minimized
        if fishing.autoMinimized then ctx.Window:SetMinimized(true) end

        note("Auto Fish started with " .. choice .. " (restore window to stop)", "OK")
        local epoch = fishing.epoch
        task.spawn(function() runFishing(epoch) end)
    end

    tab:CreateSection("FISHING")
    tab:CreateParagraph({
        Title = "AUTO FISH",
        Content = "You must own the selected rod. Auto Fish equips it, moves to the fishing position, anchors your character, and reels on the Notify sound. Turn the toggle off to unanchor.",
        Height = 116
    })

    rodPicker = tab:CreateDropdown({
        Name = "What rod will you use? (REQUIRED TO BE IN INVENTORY)",
        Flag = "floppa2.rod",
        Options = RODS,
        Default = "Fishing Rod",
        Callback = function()
            if fishing.active then
                resetRod("Fishing rod changed; restarting")
            end
        end
    })

    tab:CreateButton({
        Name = "Check Fishing Setup",
        Callback = function()
            local char = player.Character
            local rod = findRod(selectedRod(), char)
            local rodStatus = rod and ("FOUND (" .. (rod.Parent == char and "equipped" or "Backpack") .. ")") or "MISSING"
            local soundCount = 0
            local seen = {}
            for _, container in ipairs({
                workspace, SoundService, backpack,
                player:WaitForChild("PlayerGui"),
                game:GetService("ReplicatedStorage")
            }) do
                for _, instance in ipairs(container:GetDescendants()) do
                    if instance:IsA("Sound") and instance.Name == "Notify" and not seen[instance] then
                        seen[instance] = true
                        soundCount += 1
                        print("[HumuHub/Floppa2] Notify sound:", instance:GetFullName())
                    end
                end
            end
            if char then
                for _, instance in ipairs(char:GetDescendants()) do
                    if instance:IsA("Sound") and instance.Name == "Notify" and not seen[instance] then
                        seen[instance] = true
                        soundCount += 1
                        print("[HumuHub/Floppa2] Notify sound:", instance:GetFullName())
                    end
                end
            end
            note("Rod: " .. rodStatus .. " | Existing Notify sounds: " .. soundCount, rod and "OK" or "WARN")
            if soundCount == 0 then
                print("[HumuHub/Floppa2] Notify may be created dynamically when casting.")
            end
        end
    })

    fishToggle = tab:CreateToggle({
        Name = "Auto Fish",
         Default = false,
        Callback = function(on)
            if on then startFishing()
            else stopFishing("Auto Fish stopped; character unanchored", "INFO") end
        end
    })

    tab:CreateSection("WORLD")
    tab:CreateParagraph({
        Title = "NO METEORS",
        Content = "Locally removes MeshParts named Meteor (or inside meteor-named objects). Other MeshParts and collectible Meteorite items are left alone. Server-side impacts may still happen.",
        Height = 105
    })

    local meteorEnabled = false
    local meteorConnection

    local function meteorName(name)
        local compact = name:lower():gsub("[%s_%-]", "")
        if compact == "meteor" or compact == "meteors" then return true end
        return compact:match("^meteorpart%d*$") ~= nil
            or compact:match("^meteor%d+$") ~= nil
    end

    local function isMeteorMeshPart(instance)
        if not instance:IsA("MeshPart") then return false end
        if meteorName(instance.Name) then return true end
        local ancestor = instance.Parent
        while ancestor and ancestor ~= workspace do
            if (ancestor:IsA("Model") or ancestor:IsA("Folder")) and meteorName(ancestor.Name) then
                return true
            end
            ancestor = ancestor.Parent
        end
        return false
    end

    local function removeMeteor(instance)
        if not meteorEnabled then return end
        if not instance.Parent or not isMeteorMeshPart(instance) then return end
        -- Client-only deletion; does not claim to modify server authority.
        pcall(function() instance:Destroy() end)
    end

    local function stopMeteors()
        meteorEnabled = false
        if meteorConnection then
            meteorConnection:Disconnect()
            meteorConnection = nil
        end
    end

    tab:CreateToggle({
        Name = "No Meteors",
         Default = false,
        Callback = function(on)
            if not on then
                stopMeteors()
                note("Local meteor filter disabled")
                return
            end
            meteorEnabled = true
            for _, instance in ipairs(workspace:GetDescendants()) do
                removeMeteor(instance)
            end
            meteorConnection = workspace.DescendantAdded:Connect(removeMeteor)
            note("Local meteor MeshPart filter enabled", "OK")
        end
    })

    ctx:OnCleanup(function()
        stopFishing(nil, nil)
        stopMeteors()
    end)

    ctx.Window:SelectTab(tab)
    ctx:Log("Raise a Floppa 2 module ready | PlaceId=" .. tostring(ctx.PlaceId))
end
