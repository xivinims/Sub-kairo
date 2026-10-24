# Mon Calamari City — versão 86

Destino exclusivo: Universe 9421311218, Place 118064584465155. Base exigida pelo instalador: versão 85.

Modelo completo: Mon Calamari City (UndoneBuilder's Maps), de @UndoneBuilder, asset 485800451. Todas as 1.906 peças, os materiais, cores, dimensões e orientações originais são preservados; só a posição global do cenário é normalizada. A importação remove os seis scripts antigos e a câmera do asset. As três portas originais recebem interação de clique e ProximityPrompt para celular.

Brookhaven, ilhas, Stud Pack, grama adicional, inventários, pescaria, loja, menus de clima e administração anteriores são retirados. Os módulos oficiais de câmera, controles e sons do avatar permanecem. A entrada é localizada num trecho livre da passarela original por testes de piso e espaço do avatar; o centro ocupado por um droid é evitado.

O entorno usa oceano Terrain, ondas nativas, nuvens dinâmicas e o Wind Effects 11946229834 já instalado e revisado, com brisa suave e Trails locais limitados a 7 emissões/s no celular e 12 no computador. A cidade usa streaming; os controles de raio que não são expostos pelo motor das sessões Open Cloud são preservados, sem afirmar que foram alterados.

Iluminação do motor Roblox: LightingStyle.Realistic, PrioritizeLightingQuality, sombras, EnvironmentDiffuseScale/SpecularScale 1, Atmosphere, Sky, SunRaysEffect, BloomEffect e ColorCorrectionEffect. Um módulo Visuals ativa o renderer no início do servidor e do cliente, porque a sessão de edição pode abrir com Soft mesmo após salvar Realistic. A configuração não força a qualidade gráfica do aparelho.

Pesquisa oficial realizada antes da implementação:

- https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments
- https://create.roblox.com/docs/environment/post-processing-effects
- https://create.roblox.com/docs/workspace/streaming

`stage.luau` instala e testa apenas na sessão temporária. `install.luau` executa a mesma preparação e os mesmos testes antes de SavePlaceAsync. `verify.luau` confirma a versão 86 numa nova sessão e testa a ativação do renderer salvo. `assemble.py` recompõe esses arquivos a partir dos módulos legíveis.

A sessão temporária passou: 1.906 peças, 542 unions, 331 wedges, nove verificações de piso, corpo do avatar livre, oceano Terrain, emissão e limpeza do Trail do vento, três portas e onze scripts/módulos compilados. Sem teste visual em Studio, cliente real ou medição de FPS.

**Publicação concluída em 2026-10-13T22:02:17Z; versão 86 confirmada em nova sessão às 22:02:19Z.** O relatório independente confirmou `ok=true`, asset 485800451 e todos os testes novamente aprovados, incluindo o bootstrap Realistic do renderer.

A Vercel atingiu o limite diário de deploys após a preparação aprovada. A publicação foi concluída pelo workflow existente do GitHub, usando somente o secret ROBLOX_API_KEY configurado, sem expor a chave. Execução: https://github.com/xivinims/Sub-kairo/actions/runs/38474945375. Fonte aprovada: commit 7f2b5e92d915f3f944a167ababbb1619e237b7b3, SHA-256 do instalador f4f3215d81335dacf528cfe7853734627d53bb0c4c1303c3abea9ea201393bbe.

O instalador também está em roblox-publisher/patch.luau e o publicador em roblox-publisher/publish.mjs. A instalação exige a base 85, portanto uma repetição sobre a versão 86 para antes de modificar ou salvar o jogo. Consulte audit.json para os relatórios de instalação e verificação.

