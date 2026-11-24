# humuhumunukunukuāpuaʻaHub 🐟

**Version:** 0.2.0-alpha  
**Type:** Game-aware Roblox Luau debugging hub  
**UI library:** [reefFish UI Lib](https://github.com/d4nkduck/reefFish-UI-Lib) v0.3.0-alpha

The central hub detects the running Roblox experience, selects an exact game/place module from a registry, and opens a consistent ReefFish-powered debug window. The first registered module is Raise a Floppa 2; unknown games still cannot accidentally receive a script intended for a different experience.

## One-line central loader

For environments that support `loadstring` and `game:HttpGet`:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/d4nkduck/humuhumunukunukuapuaaHub/main/loader.lua"
))()
```

**Supported game:** [Raise a Floppa 2](https://www.roblox.com/games/9772878203/raise-a-floppa-2), matched by **PlaceId `9772878203`**. Other places still show an `UNSUPPORTED` system panel; the template is never loaded automatically.

The remote loading pattern is *not* supported by ordinary Roblox Studio LocalScripts. For Studio, use the ModuleScript-based pattern below instead.

## Repository layout

```text
humuhumunukunukuapuaaHub/
├── loader.lua                  # Public central entry point and error handling
├── loader-v0.2.lua             # Version-specific loader for cache diagnosis
├── registry.lua                # Experience/PlaceId routing table
├── shared/
│   └── bootstrap.lua          # ReefFish window, system tab and cleanup
├── games/
│   ├── _template.lua          # Example debug module (not registered)
│   └── raise_a_floppa_2.lua   # First registered game module
├── examples/
│   └── preview-template.lua   # Manually test template without registering a game
└── README.md
```

## Supported game: Raise a Floppa 2

**PlaceId:** `9772878203`  
**Module:** `games/raise_a_floppa_2.lua`  
**Route:** `registry.lua → Places[9772878203]` (no experience-wide GameId rule)

### Auto Fish

The FLOPPA 2 tab contains a required rod-selection prompt and dropdown:

- Fishing Rod
- Golden Fishing Rod
- Diamond Fishing Rod

The selected rod **must be equipped or in Backpack**. The Auto Fish toggle validates this before starting. When enabled, it equips the selected Tool, anchors the HumanoidRootPart, sets its position to `Vector3.new(-25,76,22)` and its Euler rotation to `(180,-40,180)` degrees, and tries a centre-screen click to cast.

The module listens for `Sound` instances **named exactly `Notify`** (including Tool, Workspace, PlayerGui, SoundService, and dynamically added sounds). When one plays while waiting, it performs the reel click immediately and casts again after **0.3 seconds**. If no `Notify` occurs within **10 seconds**, it unequips/re-equips the rod and retries. If the player equips a different Tool, the selected rod is restored and the cycle restarts.

Turning Auto Fish **off** cancels its loop, disconnects sound listeners, and restores the character's original `HumanoidRootPart.Anchored` state. Character loss or missing rod also stops the loop. The interface minimizes itself on start so automated centre-screen clicks do not hit the console; reopen the console using its title bar to switch the toggle off. The normal `RightShift` shortcut is still available.

**Troubleshooting:** A **Check Fishing Setup** button reports whether the requested rod exists and prints paths of currently found `Notify` sounds to the output console. Actual game internals and the exact executor input functions have not been verified; the module tries VirtualInputManager centre-click, optionally uses `mousemoveabs` with `mouse1click`, and finally attempts `Tool:Activate()`. No click method is guaranteed to work in every runtime.

### No Meteors

The **No Meteors** toggle examines existing and newly added Workspace `MeshPart` instances. It only deletes MeshParts with meteor-related names (or inside appropriately named meteor Models/Folders). It deliberately does **not** delete collectible `Meteorite` items or unrelated MeshParts.

This is **client-side deletion only**. It may hide an object without stopping a meteor impact or other server-side effect. If your game's meteor parts have unrelated internal names, the filter will need to be refined after inspecting those objects. It disconnects its listener when switched off.

The selected rod is configuration-persisted. The Auto Fish and No Meteors action toggles are intentionally **not** config-persisted, preventing a loaded profile from visually claiming an operation is running when its loop is inactive.

### Versioned test loader

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/d4nkduck/humuhumunukunukuapuaaHub/main/loader-v0.2.lua"
))()
```

Versioned URLs help distinguish this release from cached earlier loader content. Test on an authorized client and report the status label or output message if an action does not work.

## Game detection

Roblox uses two different identifiers:

- `game.GameId` is the experience/universe ID and normally covers every place belonging to that experience.
- `game.PlaceId` identifies one particular place inside an experience.

Routing order is **PlaceId exact match first**, then **GameId exact match**. When neither ID is registered, the loader creates a system tab and stops without executing any game-specific module.

To discover the identifiers of the game you're testing:

```lua
print("GameId:", game.GameId)
print("PlaceId:", game.PlaceId)
```

## How to register another game

1. Copy `games/_template.lua` to an appropriately named file, for example `games/my_test_game.lua`.
2. Put your own debugging controls into the new file. Each module returns `function(ctx) ... end` and receives `ctx.Window`, `ctx.ReefFish`, `ctx.GameId`, `ctx.PlaceId` and logging/cleanup helpers.
3. Add **one numeric** entry to `registry.lua`. For a whole experience, use `Games`. To target just one place, use `Places`.

Example registry **with fictional IDs, not configured in this project**:

```lua
return {
    Version = 1,
    Games = {
        [123456789] = {
            Name = "My Test Experience",
            Module = "games/my_test_game.lua"
        }
    },
    Places = {
        [987654321] = {
            Name = "Special Test Place",
            Module = "games/my_special_place.lua"
        }
    }
}
```

Adding or modifying games requires changing the registry and module files; you should not need to rewrite `loader.lua`. Modules may only be loaded from `games/*.lua` paths within the hub repository, not arbitrary remote URLs.

## Game module API

The loader first loads ReefFish v0.3.0-alpha, then `shared/bootstrap.lua`, then the matched game module.

```lua
return function(ctx)
    local tab = ctx.Window:CreateTab({ Name = "MY GAME" })

    tab:CreateButton({
        Name = "Show session IDs",
        Callback = function()
            ctx:Notify("GameId=" .. ctx.GameId .. " PlaceId=" .. ctx.PlaceId, "INFO")
        end
    })

    ctx.Window:SelectTab(tab)
end
```

Useful members:

| API | Meaning |
| --- | --- |
| `ctx.Window` | Active ReefFish window |
| `ctx.ReefFish` | Loaded UI library |
| `ctx.GameId` / `ctx.PlaceId` | Detected IDs |
| `ctx.GameName` / `ctx.Match` | Routing information |
| `ctx:Notify(message, level)` | Show a debug notice |
| `ctx:Log(message)` | Print a prefixed console message |
| `ctx:Connect(signal, callback)` | Track an event connection for cleanup |
| `ctx:OnCleanup(callback)` | Register a cleanup function for window shutdown |

The hub wraps the window's `:Destroy()` method to disconnect game-specific events and run cleanup callbacks when closed or replaced.

## Preview the template without registering a game

To manually test the UI and example diagnostics from a compatible Lua runtime:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/d4nkduck/humuhumunukunukuapuaaHub/main/examples/preview-template.lua"
))()
```

This is **opt-in preview mode** and does not alter `registry.lua`. It deliberately loads the template on the current experience, so only use it in an environment where you have permission to run your debugging code.

## Roblox Studio (local development)

Put the code from `src/reefFish.luau` (in the ReefFish repository) into a ModuleScript called `ReefFish` in `ReplicatedStorage`. Also make local ModuleScripts named `HumuBootstrap` and `HumuTemplate` containing `shared/bootstrap.lua` and `games/_template.lua`.

Then use a LocalScript:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage.ReefFish)
local Bootstrap = require(ReplicatedStorage.HumuBootstrap)
local Demo = require(ReplicatedStorage.HumuTemplate)

local ctx = Bootstrap.Start(UI, {
    Name = "Studio Preview",
    Match = "Manual test",
    GameId = game.GameId,
    PlaceId = game.PlaceId,
    HubVersion = "0.2.0-alpha"
})
Demo(ctx)
```

## Public repository and security

This repository is **public**. Anyone can read `loader.lua`, the registry, and every game module. Do not embed GitHub tokens, credentials, private endpoints, or sensitive configuration data.

- The loader only selects explicitly registered module paths. No arbitrary URL from a registry entry is executed.
- An unsupported game shows a harmless system status instead of running the template.
- Remote execution still requires trusting the current repository code and its dependencies. Only execute scripts you trust, and use game debugging tools in environments where you have authorization.
- This is an **alpha foundation**. GitHub file presence and static review are not substitutes for a live Roblox Studio or Xeno runtime test.
