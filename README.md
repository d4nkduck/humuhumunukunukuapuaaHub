# humuhumunukunukuāpuaʻaHub 🐟

A modular, game-aware Roblox Luau developer/debug UI hub powered by [reefFish UI Lib](https://github.com/d4nkduck/reefFish-UI-Lib).

**Status:** 0.1.0-alpha — architecture starter. This repository is public: all source and game modules are readable by anyone.

## Components

- `loader.lua` — stable central `loadstring` entry point, loads matching game module
- `registry.lua` — exact numeric `game.GameId` and `game.PlaceId` routing rules
- `shared/bootstrap.lua` — ReefFish window, system tab, notifications and cleanup helpers
- `games/_template.lua` — safe example game-specific diagnostics
- `examples/test-template.lua` — local opt-in demo of the template module

## Compatibility

Use `require()` with ModuleScripts for normal Roblox Studio work. The remote loader uses optional `loadstring` + `game:HttpGet` support, which is not available in ordinary Roblox Studio LocalScripts.

No real game is registered by default. Unsupported experiences will display game and place identifiers but never execute a game-specific module.

Do not embed GitHub personal access tokens, passwords or other secrets in this public code.
