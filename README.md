# humuhumunukunukuāpuaʻaHub 🐟

**Version:** 0.2.2-alpha  
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
├── loader-v022.lua             # Fresh v0.2.2 loader (avoids old path caching)
├── loader-v0.2.lua             # Previous loader build
├── registry.lua                # Latest experience/PlaceId routing table
├── registry-v022.lua           # Fresh routing file for v0.2.2
├── shared/
│   └── bootstrap.lua          # ReefFish window, system tab and cleanup
├── games/
│   ├── _template.lua          # Example debug module (not registered)
│   ├── raise_a_floppa_2.lua   # Latest original game module
│   └── raise_a_floppa_2_v022.lua  # Freshly named v0.2.2 module
├── examples/
│   └── preview-template.lua   # Manually test template without registering a game
└── README.md
```

## Supported game: Raise a Floppa 2

**PlaceId:** `9772878203`  
**Module:** `games/raise_a_floppa_2_v022.lua`  
**Route:** `registry-v022.lua → Places[9772878203]` (no experience-wide GameId rule)

### Auto Fish

Choose **Fishing Rod**, **Golden Fishing Rod**, or **Diamond Fishing Rod** from your inventory, then enable **Auto Fish**. Your character fishes at **(-25, 71, 22)** and the original rotation, without minimizing the UI. Switch it off to stop and restore anchoring.

If fishing stalls, the module retries. Use **Check Fishing Setup** if the rod or sound isn't detected.

### No Meteors

**No Meteors** hides matching meteor MeshParts locally. It may not stop server-side effects.

### Versioned test loader

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/d4nkduck/humuhumunukunukuapuaaHub/main/loader-v022.lua"
))()
```

The v0.2.2 loader uses new paths for both the registry and Raise a Floppa 2 module to avoid stale GitHub raw-file caches. The game tab will read `FLOPPA 2 | v0.2.2`. Fishing stays visible (no automatic minimize), and the fishing height is `-25, 74, 22`.

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
