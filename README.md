# Bramble’s Sprout — Dead Signal · Roblox

Port nativo em **Luau** do capítulo 1, com projeto Rojo e um arquivo de experiência para abrir no Roblox Studio. Esta branch foi substituída por este projeto a pedido do proprietário. O commit anterior continua no histórico do Git.

**Estado: base publicada; correção de assets em implantação.** A versão Roblox 155 foi publicada em 28/10/2026 no universo `9421311218`, place `118064584465155`, a experiência Dead Signal indicada pelo proprietário. Comprovante: https://github.com/xivinims/Sub-kairo/actions/runs/40710483531. Ainda não houve Play Test no Roblox Studio, teste em celular ou medição de duração. Não há garantia de uma hora, acabamento cinematográfico ou equivalência visual com Poppy Playtime.

## Abrir o jogo

1. Baixe [`dist/Brambles-Sprout.rbxlx`](dist/Brambles-Sprout.rbxlx) pelo botão **Download raw file** do GitHub.
2. No Roblox Studio, use **File → Open from File** e escolha o arquivo.
3. O mapa já aparece no modo de edição: **1.422 peças**, organizadas por setor, e **76 alvos interativos**. Aperte **Play** para iniciar a abertura e o menu.
4. Para salvar progresso entre sessões, publique em uma experiência sua e habilite o acesso a DataStores no ambiente de teste. Sem isso, os checkpoints permanecem nesta sessão e a interface informa a limitação.
5. Importe os áudios/logos e preencha os IDs em `ReplicatedStorage.Shared.Config`. Veja [ASSETS.md](ASSETS.md). O jogo usa texto quando esses IDs não estão configurados.

O workflow `roblox-build.yml` valida e gera o arquivo atualizado de Studio. `roblox-publish-base.yml` publica somente no destino acima quando seu script/workflow é alterado ou quando executado manualmente. A credencial permanece no secret `ROBLOX_API_KEY`. O `.rbxlx` versionado é o pacote inicial; os artefatos dos workflows contêm o build atualizado a partir dos fontes.

## O que está implementado

- Abertura em preto → Aurivane Works → pausa de 2 segundos → branco/fade → Bramble’s Sprout → carregamento real → menu.
- Menu com Continuar, Novo jogo com confirmação, Configurações, Créditos e Sair com confirmação. Tela de pausa, derrota, protocolos e final.
- Interface dimensionada para celular; movimento, câmera e pulo nativos do Roblox; botões próprios para as mãos, corrida, agachar e lanterna.
- Mãos azul e vermelha em primeira pessoa, lançamento/retração visual e cabos. A lógica de alcance, linha de visão, cor da mão, inventário e progressão é validada no servidor.
- Sete setores com checkpoints individuais: conservatório; arquivo de botânica; máquinas; labirinto; ecos; raízes; estação de transmissão.
- Crachá/fusível, terminais em ordem, poda, páginas/cofre, válvulas/pressão/células, seis sementes, sequência de tons, matriz de luzes, isolamento/corte e alinhamento das antenas.
- Labirinto determinístico com 160 salas conectadas e seis pontas mortas distintas para as sementes.
- Perseguidor por jogador: pathfinding, visão, audição da corrida, memória da última posição e captura. A configuração agora importa o Bramble do asset 77713813527653; o carregamento foi confirmado no motor Roblox.
- Cenas de entrada dos setores e encerramento com câmera móvel, legendas e botão de pular. O áudio configurado pode estender o plano para não ser cortado.
- Camadas de ambiente/perseguição e fala com redução da música quando os áudios estiverem configurados.

## Organização — cada sistema tem seu arquivo

| Arquivo | Responsabilidade |
|---|---|
| `src/shared/Config.luau` | Nomes, objetivos, protocolos, falas e IDs de assets |
| `src/shared/Campaign.luau` | Regras puras dos puzzles, progresso e restauração de saves |
| `src/shared/Maze.luau` | Geração do labirinto conectado |
| `src/server/World.luau` | Construção/hidratação do mapa e modelos |
| `src/server/Main.server.luau` | Remotes, validação, personagem, DataStore e perseguidor |
| `src/client/Main.client.luau` | Menus, HUD, toque/teclado, lanterna, áudio e cutscenes |
| `src/client/Hands.luau` | Modelos das mãos, movimento e cabos |
| `src/loading/Presentation.client.luau` | Apresentação e carregamento inicial |
| `assets/world/BramblesWorld.rbxmx` | Cenário editável, já construído |
| `studio/ImportBramble.command.luau` | Importação opcional do Bramble, sem scripts de terceiros |

## Controles

PC: **WASD**, mouse, **Espaço**, **E/clique esquerdo** (azul), **Q/clique direito** (vermelha), **Shift** (correr), **C** (agachar), **F** (lanterna), **P** (pausa). O prompt de proximidade usa a azul; use Q ou o botão vermelho nos alvos que exigem a vermelha.

Celular: joystick/câmera/pulo do Roblox e botões AZUL, VERMELHA, CORRER, AGACHAR, LUZ e pausa. A corrida de toque alterna ligada/desligada e respeita o fôlego do servidor.

## Desenvolvimento

Instale Rojo 7.7.1 e Luau 0.744. Em Linux x86_64, `python3 scripts/install-tools.py` instala os binários oficiais com verificação de hash.

```sh
python3 scripts/check.py --luau .tools/luau/luau --compiler .tools/luau/luau-compile --rojo .tools/rojo/rojo
.tools/rojo/rojo serve default.project.json
```

Abra o plugin Rojo no Studio para sincronizar os scripts. Para reconstruir a geometria a partir de `World.luau`, instale Lune 0.11.1 e execute:

```sh
rojo build default.project.json -o dist/Brambles-Sprout.rbxlx
lune run scripts/bake-world.luau
rojo build default.project.json -o dist/Brambles-Sprout.rbxlx
```

A reconstrução refaz `assets/world/BramblesWorld.rbxmx`; alterações manuais feitas somente nesse arquivo devem ser preservadas antes de reconstruir. O servidor reutiliza a geometria pré-construída em vez de apagá-la ao iniciar.

## Verificação e limites

- 47 assertivas de campanha, cores das mãos, itens duplicados, checkpoint, final e conectividade do labirinto.
- Todos os scripts compilam com `luau-compile`.
- O mesmo construtor do mapa foi executado com o modelo de dados do Lune, validando classes/propriedades e serialização. Isso não simula física, pathfinding, Humanoid, rede ou interface no Studio.
- Rojo gerou o `.rbxlx`; o pacote foi inspecionado para confirmar os scripts e alvos interativos.
- `dist/validation.json` e `dist/world-audit.json` registram o que foi conferido.
- As configurações de áudio, logo e sensibilidade são de sessão; o progresso da campanha é persistido quando DataStore estiver disponível.
- O mapa é original e simplificado. Os modelos de mãos, baterias, portas, painéis e cenário vêm dos kits indicados pelo proprietário, com IDs cadastrados. O Bramble solicitado é importado sem scripts de terceiros. Movimentos originais completos, falas Marcus e reprodução do layout das referências ainda não estão finalizados.

## Correção de assets e GrabPack

As imagens Aurivane Works e Dead Signal foram importadas sem alteração, com IDs 119097868099668 e 104036635112721. A apresentação usa ImageLabels e um flash branco entre as logos. As mãos usam as malhas ch4handsblue e SM_SimpleHand e suas texturas. O disparo usa raycast do servidor em qualquer direção, até 65 studs, incluindo paredes e espaço vazio; objetos marcados GrabMovable podem ser puxados e soltos com a mesma mão. Os prompts de proximidade ficam desativados.

`src/server/AssetModels.luau` importa modelos na conta proprietária, remove LuaSourceContainers antes de parentear e coloca as malhas no cenário. As superfícies recebem materiais de concreto e azulejo dos kits. As importações são verificadas no motor Roblox antes da publicação. Isso não comprova aparência, controles ou desempenho no cliente Android.

Os IDs estão em `assets/imported-asset-ids.json`. Origem: DetectivePikaC2/PlaytimeStarterKit em 8c453e7731866e34a0986e3f2c12e64dd9f8c703; TheDevvDude/GrabPack-Unity-Project-1.1 em 44d8f7a52b632dea8c554da62cee63fd5e4b59f7. Esses são assets disponíveis nos kits de terceiros, sem afirmação de autoria oficial da MOB. A licença MIT do starter kit está em assets/provenance. Não foi republicado o projeto Unity inteiro.
