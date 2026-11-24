# Changelog

## 0.2.2-alpha — Fishing height adjustment

- Change the Raise a Floppa 2 fishing position to (-25, 71, 22)
- Keep the UI open while fishing
- Publish a fresh loader → registry → module URL chain to avoid cached older builds
- Show `FLOPPA 2 | v0.2.2` in the game tab

## 0.2.1-alpha — Fishing position and cache-bypass hotfix

- Keep the hub visible when Auto Fish starts; no automatic minimizing
- Move fishing position two studs lower to (-25, 74, 22)
- Shorten user-facing explanations in the game tab
- Publish fresh loader, registry and game module filenames so previously cached files are not reused
- Display `FLOPPA 2 | v0.2.1` in the game tab as a visible build check

## 0.2.0-alpha — First supported game: Raise a Floppa 2

- Register exact PlaceId `9772878203` (no universe-wide wildcard).
- Add `games/raise_a_floppa_2.lua` with selectable Fishing Rod / Golden Fishing Rod / Diamond Fishing Rod.
- Auto Fish equips and re-equips the rod, anchors and positions the avatar at (-25, 76, 22) with Euler rotation (180, -40, 180), casts, reels when a Sound named `Notify` plays, waits 0.3 seconds, and retries after 10 seconds without a notification.
- Restores original character anchor state, disconnects sound listeners, and cancels the session when disabled or invalid.
- Add a diagnostic button to check rod inventory and discover `Notify` sound paths.
- Add **No Meteors**, which locally removes only targeted meteor MeshParts; it does not promise to disable server-side effects.
- Add versioned `loader-v0.2.lua` to distinguish builds while preserving `loader.lua`.
- Update README with configuration, limitations, and troubleshooting.

## 0.1.0-alpha — Hub architecture

- Central loader, exact GameId/PlaceId registry, ReefFish bootstrap, unsupported-game panel and example diagnostic module.
