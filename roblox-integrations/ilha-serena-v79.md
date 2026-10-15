# Ilha Serena — versão 79

Universe `9421311218` · Place `118064584465155` · branch `roblox-publisher`.

## Cenário

- 111 árvores com troncos enterrados e quatro raízes em contato com o terreno; uma árvore foi reposicionada para liberar uma entrada da ponte.
- Duas pontes reconstruídas a partir das alturas reais das margens: tablado contínuo, arco ajustado ao terreno, rampas, vigas, oito estacas por ponte e corrimãos.
- Píer e pavilhão do lago com apoios enterrados, bancos com pés ajustados, fonte com borda aberta e gotas animadas.
- Grama local com movimento por vento e pela passagem dos jogadores, recuperação gradual, raízes fixas, sem colisão e população limitada por dispositivo.
- Folhagem com movimento, barco com balanço e vaga-lumes ao anoitecer.

## Céu e clima

As seis texturas de [HD Sky Realistic](https://create.roblox.com/store/asset/11808837483/HD-Sky-Realistic) foram inspecionadas com `AssetService:LoadAssetAsync` e salvas diretamente no Sky. Nenhum script do modelo externo foi incorporado.

Nuvens dinâmicas, Atmosphere, ColorCorrection, Bloom e SunRays nativos do Roblox; transições de clima em 18 segundos, ciclo de dia em 30 minutos, vento com rajadas e ondas de água variáveis. LightingStyle Realistic e PrioritizeLightingQuality são reaplicados por ambos os scripts de ambiente ao iniciar, com proteção contra falhas de capacidade para não interromper outros sistemas. A API de publicação ainda reabre a sessão de edição com o estilo legado Soft; a verificação distingue a configuração salva da aplicação na inicialização.

## Maçã da Névoa

| Regra | Valor |
|---|---|
| Compra | 30 moedas da ilha |
| Saldo inicial | 50 moedas |
| Recompensa | 10 moedas por minuto no servidor |
| Invisibilidade | 3 segundos |
| Intervalo entre usos | 60 segundos |
| Propriedade | Reutilizável, restaura a ferramenta ao reaparecer |

Loja no canto superior e banca física na vila, com prévia 3D da maçã. As operações de saldo e propriedade usam DataStore UpdateAsync; quando a carga inicial de dados falha, a interface avisa que o progresso é temporário naquela sessão. Uma falha ao salvar uma compra persistente não cobra moedas. O cliente não escolhe preço, saldo, recompensa ou intervalo. A recarga também é salva para impedir o desvio por troca de servidor.

A invisibilidade mantém o avatar e suas colisões. Oculta corpo, acessórios, texturas, nome, luzes e efeitos visuais; recupera os valores originais depois de três segundos, inclusive para acessórios adicionados durante o efeito. Não utiliza Robux nem Developer Products.

## Verificação

No motor Roblox, antes de SavePlaceAsync: 189 pontos nas rotas, 152 nas pontes, 111 árvores, 21 combinações de horário e clima, compilação de todos os scripts, grama com contato/recuperação e limites de objetos para computador e toque. O código real do servidor da loja foi executado com jogadores, armazenamento e tempo simulados para testar compra, recarga, recompensas, restauração, troca de personagem e falhas de persistência. O código real dos clientes foi executado com objetos nativos e entrada simulada para verificar a loja, prévia 3D, grama, chuva e fonte.

Essas verificações não equivalem a um teste visual numa sessão jogável, nem medem FPS em aparelhos reais. O instalador bloqueia execução fora do alvo ou após a versão 78; a verificação de versão 79 é somente leitura e não publica.

## Publicação

O instalador autocontido está em `roblox-integrations/ilha-serena-upgrade-v79.luau`. A publicação é executada pelo projeto Vercel `overyard-place-publisher`, que usa ROBLOX_API_KEY apenas no servidor. O fluxo antigo em `roblox-publisher/**` não é acionado por estes arquivos.
