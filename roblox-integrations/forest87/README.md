# Floresta única — versão 87

Destino: Universe 9421311218, Place 118064584465155. Base exigida: versão 86.

Pedido final: remover Mon Calamari e deixar somente uma floresta completa baseada nos quatro prints enviados. O usuário autorizou selecionar modelos reais semelhantes aos prints.

Modelos utilizados:

- Forest Pack oficial do Roblox: https://create.roblox.com/store/asset/6432306802/Forest-Pack
- SkinnedGrass original: https://create.roblox.com/store/asset/87377915371959/SkinnedGrass — variante GrassCard, mesh 117152506140384.
- Wind Effects escolhido anteriormente: https://create.roblox.com/store/asset/11946229834/Wind-Effects

Terreno nativo de 1.024 × 1.024 studs, construído em 64 regiões voxel: encostas, clareiras, morros rochosos, trilhas de terra, rio sinuoso e lago. Três zonas principais de vegetação: bosques de folhas largas, coníferas altas na encosta e margens com arbustos, samambaias, trevos e flores. Modelos variam em tamanho e orientação; o espaçamento das árvores impede uma disposição em filas. Bases das árvores são ajustadas ao piso real por raycasts. As passagens do rio usam troncos reais do mesmo pack e superfícies de colisão invisíveis.

Preparação aprovada: 490 árvores, 1.733 plantas, 145 pedras, 37 troncos/galhos, 30 tipos de props, 3.479 MeshParts com SurfaceAppearance, 16 pontos de borboletas/libélulas e duas passagens do rio. A distribuição inclui 915 colocações registradas em grupos de flores/arbustos floridos. Os 13 scripts de animais do pack foram inspecionados e retirados; a animação usa os mesmos IDs oficiais através de um controlador local limitado a quatro criaturas no celular e oito no computador.

Grama: o modelo original mantém 100 bones por instância e é tingido para combinar com o terreno. O índice cobre o mapa inteiro, com malhas de 28 studs sobrepostas a cada oito studs. Somente as cópias próximas do jogador são criadas: no máximo 160 no celular e 360 no computador. Cada raiz é projetada sobre Terrain Grass/LeafyGrass e é rejeitada em água, trilha ou colisores. O módulo corrige a preservação das raízes nas encostas, contato com o avatar, retorno suave e liberação dos registros de animação quando a malha é removida.

Iluminação nativa Realistic/PBR, sombras, Sky, Atmosphere, SunRaysEffect, BloomEffect e ColorCorrectionEffect. O módulo Visuals é aplicado no servidor e no cliente para ativar o renderer no início. A brisa varia suavemente; folhas, samambaias, grama, nuvens e água usam os efeitos nativos e o Wind Effects selecionado. Não se força a qualidade gráfica do aparelho.

`stage.luau` reconstrói e testa somente numa sessão temporária. `install.luau` executa os mesmos testes antes de SavePlaceAsync. `verify.luau` confirma a versão 87 numa nova sessão. `assemble.py` gera os três scripts a partir dos módulos legíveis. A execução exige a base 86 para impedir repetição sobre o mundo já publicado.

Verificação temporária: 899 amostras de terreno, 682 pontos verdes, 129 com água, 21 de trilha e 94,89 studs de variação de altura; 490 pontos de plantio conferidos; entrada livre; 300 raízes de grama conferidas em três zonas; preservação da raiz sob vento; emissão/limpeza do Wind Effects; 19 scripts/módulos compilados. Nenhum script estrangeiro está instalado no cenário. A verificação usa o motor nativo das sessões Open Cloud; não houve captura visual de um cliente Roblox nem medição de FPS.

Pesquisa de iluminação:

- https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments
- https://create.roblox.com/docs/environment/post-processing-effects
- https://create.roblox.com/docs/workspace/streaming

**Publicada em 2026-10-13T22:42:36Z; versão 87 confirmada em nova sessão às 22:42:37Z, com `ok=true` e `forestOnly=true`.** Todos os testes foram aprovados novamente a partir da versão salva. O relatório está em audit.json.

Execução: https://github.com/xivinims/Sub-kairo/actions/runs/38479564162. Fonte aprovada: commit 1008d1c99cd8938f4092eb711d8fb5efeda1cc4c; SHA-256 do instalador 54a359da78b1f46b02fafc34ee8e10201c87b22fdb61645c8de3adb9ad2f14fe. A publicação usou o workflow do GitHub já disponível, pois a Vercel atingiu a cota diária de deploys.
