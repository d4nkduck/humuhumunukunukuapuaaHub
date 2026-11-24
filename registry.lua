-- humuhumunukunukuapuaaHub | registry v1
-- Add ONLY experiences/places you explicitly want to support.
-- Roblox game.GameId is the universe/experience ID; game.PlaceId is one place ID.
-- Exact place matches take priority over universe matches.
--
-- Example (replace the ID with your own real test game ID):
-- Games = {
--   [123456789] = {Name="My Test Experience", Module="games/my_test_game.lua"},
-- },
-- Places = {
--   [987654321] = {Name="Special Place", Module="games/special_place.lua"},
-- }
--
-- Keep module paths local to this repository (games/*.lua).
-- Do not put URLs, access tokens or executor secrets here.

return {
    Version = 1,
    Games = {
        -- [YOUR_REAL_UNIVERSE_ID] = {Name="My Game", Module="games/_template.lua"},
    },
    Places = {
        [9772878203] = {
            Name = "Raise a Floppa 2",
            Module = "games/raise_a_floppa_2_v022.lua"
        },
    }
}
