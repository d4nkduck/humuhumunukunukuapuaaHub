# Changelog

## Auto Fish Hook check

- Constant CFrame hold replaces physics forces
- Retry if the selected rod's Hook MeshPart has not anchored within 2 seconds
- Keep the universal loader unchanged

## Fishing anti-move update

- Replace root anchoring with BodyPosition and BodyGyro physics hold
- Restore previous anchored state and remove forces when Auto Fish stops
- Keep Y = 70 and the universal loader unchanged

## Universal loader consolidation

- Permanent, unchanged entry point: `loader.lua`
- Default registry: `registry.lua`
- One Raise a Floppa 2 module: `games/raise_a_floppa_2.lua`
- Remove redundant versioned loader, registry and game files
- Fresh dependency requests on each execution to reduce old cached builds
- Current Raise a Floppa 2 fishing position: **(-25, 70, 22)**; the UI stays open

## Earlier development

- Hub registry with exact PlaceId and GameId matching, shared ReefFish interface and unsupported-game fallback
- Raise a Floppa 2 Auto Fish, required rod selection, No Meteors and fishing diagnostics
- Iterations on fishing positioning and UX; the current game module is the source of truth
