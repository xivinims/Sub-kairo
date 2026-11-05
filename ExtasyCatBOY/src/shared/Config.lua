-- ExtasyCatBOY: jogo independente, NPCs inspirados nos amigos (nunca fingir ser o amigo real).
return {
    MaxCompanionsPerPlayer = 1,
    FriendsPerPage = 200,
    MinActionInterval = 1.2,
    ChatReplyCooldown = 2.5,
    FollowDistance = 6,
    FollowUpdateInterval = 0.65,
    AutoBuildCozyWorld = true, -- somente quando nao existe mapa estabelecido
    SaveKeyPrefix = "extasycatboy_v1_",
    AllowedKinds = { cat = true, dog = true },
    AllowedPersonalities = {
        timido = true, tsundere = true, brincalhao = true,
        sonolento = true, bravo = true, gentil = true,
    },
}
