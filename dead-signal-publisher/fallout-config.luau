local C = {
 Build = 'fallout-5v5-v1', RoundSeconds = 600, IntermissionSeconds = 90, ResultsSeconds = 12,
 MaxPlayers = 10, TeamSize = 5, SpawnProtection = 3, RespawnSeconds = 5,
 DownedHealth = 20, BleedSeconds = 20, HealDistance = 12, HealSeconds = 2.5,
 OwnerUserId = 8344738123, KillXP = 100, HeadshotXP = 50, ReviveXP = 60,
 KillCoins = 30, WinCoins = 120, ParticipationCoins = 40,
}
C.Catalog = {
 {id='compact', model='Compact_Pistol', name='Pistola compacta', kind='Gun', price=0, damage=24, head=2, rate=.28, mag=12, reserve=96, reload=1.6, spread=.007, range=400},
 {id='service', model='Standard_Service_Pistol', name='Pistola de serviço', kind='Gun', price=400, damage=27, head=2, rate=.26, mag=15, reserve=90, reload=1.8, spread=.006, range=450},
 {id='subcompact', model='Subcompact_Pistol', name='Pistola subcompacta', kind='Gun', price=350, damage=22, head=2, rate=.22, mag=10, reserve=100, reload=1.35, spread=.009, range=320},
 {id='longslide', model='Competition_Long_Slide_Pistol', name='Pistola de competição', kind='Gun', price=650, damage=31, head=2, rate=.32, mag=12, reserve=84, reload=1.8, spread=.003, range=600},
 {id='machine', model='Fully_Automatic_Machine_Pistol', name='Pistola automática', kind='Gun', price=850, damage=17, head=2, rate=.1, mag=24, reserve=144, reload=2.1, spread=.018, range=360, automatic=true},
 {id='smart', model='Futuristic_Smart_Pistol', name='Pistola futurista', kind='Gun', price=1100, damage=26, head=2, rate=.24, mag=18, reserve=108, reload=1.9, spread=.004, range=500},
 {id='heavy', model='Large_Caliber_Auto_Pistol', name='Pistola de alto calibre', kind='Gun', price=950, damage=43, head=2.4, rate=.52, mag=7, reserve=56, reload=2.3, spread=.006, range=600},
 {id='suppressed', model='Suppressed_Pistol', name='Pistola silenciada', kind='Gun', price=700, damage=25, head=2, rate=.28, mag=12, reserve=96, reload=1.7, spread=.005, range=420},
 {id='knife', model='Combat_Knife', name='Faca de combate', kind='Melee', price=0, damage=35, head=1.3, rate=.65, range=7},
 {id='axe', model='Fire_Axe', name='Machado', kind='Melee', price=600, damage=65, head=1.4, rate=1.1, range=8},
 {id='grenade', model='Fragmentation_Grenade', name='Granada', kind='Grenade', price=800, damage=90, radius=16, rate=1.2, charges=2},
 {id='mine', model='Anti_Personnel_Mine', name='Mina', kind='Mine', price=1000, damage=80, radius=12, rate=2, charges=1},
 {id='medkit', model='Small_First_Aid_Kit', name='Kit de primeiros socorros', kind='Heal', price=0, healing=40, charges=2},
 {id='syringe', model='Syringe', name='Seringa médica', kind='Heal', price=500, healing=65, charges=2},
}
C.ById = {}
for _,item in ipairs(C.Catalog) do C.ById[item.id]=item end
return C
