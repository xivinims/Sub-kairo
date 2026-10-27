-- DEAD_SIGNAL_PUBLISHER
-- Dedicated publisher target:
-- Universe: 9421311218
-- Place: 118064584465155
--
-- This starter patch is intentionally VERIFY-ONLY.
-- Put future Dead Signal edits above the return block.
-- When you intentionally want to publish a modified data model, call:
-- game:GetService("AssetService"):SavePlaceAsync({PlaceId = game.PlaceId, SaveWithoutPublish = false})

local HttpService = game:GetService("HttpService")

assert(game.GameId == 9421311218, "DEAD SIGNAL SAFETY: wrong universe")
assert(game.PlaceId == 118064584465155, "DEAD SIGNAL SAFETY: wrong place")

return HttpService:JSONEncode({
    ok = true,
    mode = "verify-only",
    universeId = game.GameId,
    placeId = game.PlaceId,
    placeVersion = game.PlaceVersion,
})
