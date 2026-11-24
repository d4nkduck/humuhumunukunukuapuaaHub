# humuhumunukunukuāpuaʻaHub 🐟

A Roblox game-aware debugging hub powered by [reefFish UI Lib](https://github.com/d4nkduck/reefFish-UI-Lib).

## One universal loadstring

Use **this same loader for every supported game and every future game-module update**:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/d4nkduck/humuhumunukunukuapuaaHub/main/loader.lua"
))()
```

The loader automatically reads the current registry, detects `game.PlaceId` and `game.GameId`, then loads the corresponding game module. Place-specific matches take priority. If no game matches, it shows an unsupported-game screen instead.

There is **no need to change your loadstring** when adding a game or adjusting its tools. The loader adds a per-run cache-busting query to its dependency downloads to reduce stale GitHub copies. It cannot guarantee instantaneous GitHub CDN updates.

## Project structure

```text
loader.lua                       # Permanent entry point
registry.lua                     # GameId / PlaceId -> module lookup
shared/bootstrap.lua             # Shared ReefFish window
games/raise_a_floppa_2.lua       # Raise a Floppa 2 debug tools
games/_template.lua              # Starter for future games
examples/preview-template.lua    # Optional example
README.md
CHANGELOG.md
```

Only the **three primary routing paths** matter when updating game support: `loader.lua`, `registry.lua`, and `games/<game>.lua`. The loader is intended to stay unchanged; modify `registry.lua` to register games and edit their existing files to release updates.

## Currently supported

**Raise a Floppa 2** — exact PlaceId `9772878203`

- **Auto Fish:** choose Fishing Rod, Golden Fishing Rod or Diamond Fishing Rod (must be in inventory), then enable the toggle
- Fishing position: **(-25, 70, 22)** with the configured orientation
- The interface stays open while fishing; disabling stops the routine and restores anchoring
- **No Meteors:** local filter for matching meteor MeshParts
- **Check Fishing Setup:** reports whether the rod and `Notify` sound can be found

The game's fishing and meteor internals have not been verified in a live Xeno session. The local meteor filter may not affect server-controlled events.

## Add another game

Add a module such as `games/my_game.lua` that returns a function receiving the hub context:

```lua
return function(ctx)
    local tab = ctx.Window:CreateTab({ Name = "MY GAME" })
    tab:CreateButton({
        Name = "Test",
        Callback = function()
            ctx:Notify("Ready", "OK")
        end
    })
    ctx.Window:SelectTab(tab)
end
```

Then add the corresponding **numeric** ID to `registry.lua` under `Places` or `Games`:

```lua
Places = {
    [9772878203] = {Name = "Raise a Floppa 2", Module = "games/raise_a_floppa_2.lua"},
}
```

Keep `loader.lua` as-is. The active route must point to a file that exists under `games/`.

## Notes

This public source requires an environment supporting `game:HttpGet` and `loadstring`. Standard Roblox Studio LocalScripts should use local ModuleScripts and `require()` instead. Don't include secrets or tokens in public scripts. Use debugging tools only where authorized.
