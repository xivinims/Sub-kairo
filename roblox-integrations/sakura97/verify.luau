-- Verifica se o mapa sakura97 ficou como pedido
assert(game.GameId == 9421311218 and game.PlaceId == 118064584465155, "Place errado")

local runtime = game.ReplicatedStorage:FindFirstChild("SakuraRuntime")
assert(runtime, "SakuraRuntime não existe")
assert(runtime:GetAttribute("Version") == 97, "Versão errada")

local trees = workspace:FindFirstChild("SakuraTrees")
assert(trees, "Pasta SakuraTrees não encontrada")
local count = #trees:GetChildren()
assert(count >= 20 and count <= 35, "Quantidade de cerejeiras fora do esperado: " .. tostring(count))

local path = workspace:FindFirstChild("StonePath")
assert(path and #path:GetChildren() > 10, "Caminho de pedras não encontrado ou vazio")

local grass = workspace:FindFirstChild("SkinnedGrass")
assert(grass, "Grama skinned não encontrada")

local flowers = workspace:FindFirstChild("Wildflowers")
assert(flowers and #flowers:GetChildren() > 100, "Flores insuficientes")

-- não deve ter restos do forest antigo
assert(not workspace:FindFirstChild("ForestWorld"), "Ainda tem ForestWorld antigo")
assert(not game.ReplicatedStorage:FindFirstChild("ForestRuntime"), "Ainda tem ForestRuntime")

-- lighting de tarde
local Lighting = game:GetService("Lighting")
assert(Lighting.ClockTime > 16 and Lighting.ClockTime < 18.5, "Não está de tarde")

print("[Sakura97 Verify] OK — mapa parece correto")
return {ok = true, trees = count}
