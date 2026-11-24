# Changelog

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
