# EXACT RUN — teste integrado

Publicado: versão **317**, SHA-256 `86f8d059a1273992bb0e349fb2e67a9e48fb8475bcee654900b7e2acaddff1ab`. [Publicação confirmada](https://github.com/xivinims/Sub-kairo/actions/runs/41948519570). 8 mapas/variantes, 177 spawns conectados, 66 modelos de Nextbots e 19 emotes. A solicitação de publicação foi desativada após o envio.

Referência visual: telas IMG_2671–IMG_2690 fornecidas pelo proprietário. Experiência 9421311218, place 118064584465155; branch dead-signal-publisher. Intervalo solicitado de 90 segundos, rodadas de 180 segundos.

## Implementação

- Menu nativo responsivo, cartões ilustrados, navegação animada, fundo 3D da própria arena importada, loja e inventário com prévias do próprio avatar; tela de carregamento.
- Configurações persistentes de áudio, materiais, sombras, FOV, oscilação da câmera, braços em primeira pessoa e vinheta de proximidade.
- Entrada imediata na arena durante o intervalo e a rodada, retorno ao menu, votação de mapa, rodadas especiais (escuridão, velocidade, dobro de bots), espectador e HUD móvel.
- Nextbots com seleção aleatória por rodada, perseguição, navegação, detecção de obstáculos, atordoamento e sons disponíveis.
- Corrida, aceleração, agachamento, deslize e 18 sequências R6 importadas; atualização das juntas quando a aparência do avatar termina de carregar.
- Queda, prazo de reanimação, resgate, carregar/soltar, invulnerabilidade temporária, recompensas e nomes com nível.
- Perfis persistentes com moedas, XP, vitórias, resgates, missões, compras, seis espaços de emotes, dois de vantagens, luz/utilidade/poder e quatro usáveis.
- 19 emotes do arquivo enviado, incluindo poses de duração zero. Jumpstyle e Electro Shuffle têm acompanhamento musical; os demais 17 ainda não têm música associada.
- Lanterna, luz frontal, visão noturna, bússola, temporizador, rádio, radar, isca, bastão, barreira e cola; vantagens de reanimação, audição, XP, moedas, velocidade, aceleração, kit médico e limite de construções.
- Caixa de som com IDs validados como áudio, favoritos persistentes e controles de volume. A permissão de reprodução depende do ativo e da experiência.
- Portas reconhecidas nos mapas têm interação; bots podem abri-las. Spawns são filtrados por chão, espaço livre e caminho conectado.
- Streaming de cenário ativado; mapas inativos e modelos de bots ficam no servidor. As âncoras do menu acompanham o mapa importado; o foco de streaming acompanha a câmera do menu.

## Conteúdo importado do Creator Store

| Conteúdo | Asset |
| --- | --- |
| Rocket Arena | 124805122537927 |
| Construct | 123713126320438 |
| gm_construct | 10828666356 |
| Library | 10828618634 |
| Complex | 10844642277 |
| Elysium | 10828489513 |
| Backrooms | 10819434129 |
| Desert Bus | 13634611708 |
| Idle/Walk/Run/Jump/Fall R6 | 74987847468722 |
| Crawl R6 | 4951486910 |
| Pacote de Nextbots | 13028240941 |
| Freddy / Bobo / Eye | 11128061931 / 11448641842 / 10844522204 |
| R6 e locomoção | 14026023204 |
| Arte provisória do menu (imagem) | 93112717809068 |

Os modelos são versões públicas da comunidade, não arquivos oficiais certificados do Evade. Seus scripts externos são removidos e a lógica do projeto controla o jogo. O ativo Desert Bus 113165227370713 era apenas um decal e foi descartado.

## Validação

O workflow compila os scripts Luau, verifica políticas de configuração/equipamento/compra e os estados da rodada, salva uma versão de teste e executa verificações no motor Roblox através de Luau Execution. São verificados: mapas carregados, chão e conexão dos spawns, rigs, 19 emotes aplicando transformações reais nas juntas R6, vínculo da arte e inicialização dos serviços do servidor. O fluxo de entrada cobre admissão no intervalo, mapa e posição preservados ao zerar o contador, spawn e limpeza dos bots, entrada tardia e cancelamento de uma entrada durante o streaming. Os IDs de origem são comparados ao catálogo para detectar perda de precisão na serialização. O relatório `engine-test.json` contém resultados e versão exatos. A publicação, quando solicitada, exige esses testes e confirma o SHA-256 do arquivo baixado novamente.

Esses testes não executam um cliente Roblox com uma pessoa. Não comprovam equivalência visual pixel a pixel, toque no iPhone, física de uma partida multiplayer completa, persistência real entre duas sessões ou reprodução audível de todos os sons. A versão original 303 e a versão publicada imediatamente anterior são preservadas e seus hashes conferidos antes da publicação.

## Ainda não corresponde ao jogo completo original

Os oito mapas não são todos os mapas do Evade. O cenário de lobby gerado foi removido: o menu usa a arena importada. Cosméticos exclusivos, catálogo completo de emotes e músicas, eventos/passe, monetização Robux, todas as rodadas especiais, acessórios exatos e todas as animações contextuais permanecem incompletos. Alguns equipamentos têm representação visual provisória. A tabela de classificação é do servidor atual. Não existe certificação de réplica idêntica.

## Referências de comportamento

- https://www.roblox.com/games/9872472334/Evade
- https://evadewiki.org/wiki/cola/
- https://evadewiki.org/wiki/barrier/
- https://evadewiki.org/wiki/medkit/
- https://evadewiki.com/wiki/mil-grade-pack/
- https://evadewiki.org/wiki/hermes-shoes/
- https://evadewiki.org/wiki/stilts/
- https://evadewiki.org/wiki/stun-baton/
- https://create.roblox.com/docs/cloud/reference/features/luau-execution

## Correção de entrada

Ao entrar, o personagem vai imediatamente a um spawn válido da arena e pode andar durante o intervalo de 90 segundos. O mapa e a posição são preservados quando começam os 180 segundos de perseguição. Bots aparecem apenas após a contagem. A troca de mapa ocorre no início do próximo intervalo. O cenário de blocos criado por script foi removido; gm_construct (10828666356) é a arena inicial. A fonte pública não comprova que seja o arquivo oficial atual do Evade.

Os 20 grupos de verificações passaram no motor Roblox, sem mensagens de erro no registro da execução. O relatório permanente está em `validation-latest.json`. A validação usa os serviços de admissão e de bots reais com um rig R6 e um adaptador de atributos de jogador. Ela cobre contagem, entrada tardia, cancelamento, preservação de posição e limpeza de bots; não simula um toque real em um cliente.


## Motion and inventory correction, 2026-11-04

Original Hexagon/Evade scripts have not been obtained or verified. Community kits inspected: 16376131182, 14093641613, 114529668740179, 11965424282, 13483196074. They contain differing custom controllers, not an established original implementation. They were inspected and were not executed or installed. Down/fall animation references 10908416853 and 10910569163 are owned by PlxckyRad; delivery did not provide a downloadable source. No replacement downed animation has been claimed as original.

Existing imported movement pack 14026023204 (XtraMoldy) retains its keyframes. Playback now de-duplicates zero-weight helper poses, preserves source joint bases when avatar appearance recreates standard R6 joints, suppresses the competing default Animator, and retains that pack for crouch/slide. The later community pack supplies walk/run/jump/fall/idle. The duplicate hip lowering was removed. The existing acceleration controller now reads replicated horizontal velocity rather than non-replicated Humanoid.MoveDirection and uses elapsed frame time. Its numerical tuning remains an unverified custom implementation; the exact Evade friction/air acceleration/bunnyhop code is still missing.

Inventory selection now lists only owned, compatible, available items. Unresolved emotes are excluded from sale; the 19 owner-provided emotes remain. Mobile control positions and circular outlines follow the screenshots. Bag, crouch and POV icon drawings are recreated UI, not extracted original icons; health 18788900977 and speed 13492318225 are referenced from the public HUD pack 93848778681151. The speed readout shows measured horizontal velocity. Full visual equivalence, the original downed animation, all item models, music, and native mobile/client playtesting remain outstanding.

## Two-stage loading and additional community motion

The new ReplicatedFirst boot screen precedes StarterPlayerScripts. It waits for game load and menu-art preloading. The map screen then requests streaming around the imported map's menu camera, preloads nearby visible textures, and waits for the menu interface to initialize. A monotonically increasing map revision cancels stale loading callbacks. The menu and gameplay HUD stay hidden until the matching revision is ready. Both screens use a centered EXACT RUN wordmark; this is recreated typography, not the official Evade logo.

Community movement source: https://create.roblox.com/store/asset/74987847468722 by wifonn3 (SHA-256 a41ef524745b4c47e5d8979969f6e056a590469a344aac4ac014511903a1c4a4). Imported authored Idle, Walk, Run, Jump and Fall keyframes with their source rig's joint bindings.

Prone source: https://create.roblox.com/store/asset/4951486910 by Caterlink (SHA-256 77200224b0658cff0898d06b629f6bf507e9869a6ac2965a839cfd12ef7f0420). The authored Crawl sequence replaces the crouching placeholder for downed players. Moving plays the sequence; stopping holds its first authored pose. These are community assets, not verified official Evade animation files. Imported scripts are removed.

Additional map: https://create.roblox.com/store/asset/13634611708 by fishyifiyedn (SHA-256 5f343b5b702d324997cb28f6d8e006a5c64fc001f9aef932c2a39d573ef87b74), a community Desert Bus model with 261 parts. The previous road-only candidate 70623307240060 was rejected after testing because its only two connected spawn points were over 2 km apart. The replacement passed engine validation with six connected spawn points.

Native visual/mobile playtesting remains outstanding. Engine tests establish structural and behavioral checks, not a pixel-identical recreation or an exact match to Evade's movement speeds.
