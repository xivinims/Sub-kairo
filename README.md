# Bramble’s Sprout — Dead Signal · Roblox

Port nativo em **Luau** do capítulo 1, com projeto Rojo e um arquivo de experiência para abrir no Roblox Studio. Esta branch foi substituída por este projeto a pedido do proprietário. O commit anterior continua no histórico do Git.

**Estado: primeira versão do port.** A campanha e a construção foram verificadas fora do Studio. Ainda não houve Play Test no Roblox Studio, teste em celular ou medição de duração. Não há garantia de uma hora, acabamento cinematográfico ou equivalência visual com Poppy Playtime. Nenhuma experiência ao vivo foi alterada por este commit.

## Abrir o jogo

1. Baixe [`dist/Brambles-Sprout.rbxlx`](dist/Brambles-Sprout.rbxlx) pelo botão **Download raw file** do GitHub.
2. No Roblox Studio, use **File → Open from File** e escolha o arquivo.
3. O mapa já aparece no modo de edição: **1.422 peças**, organizadas por setor, e **76 alvos interativos**. Aperte **Play** para iniciar a abertura e o menu.
4. Para salvar progresso entre sessões, publique em uma experiência sua e habilite o acesso a DataStores no ambiente de teste. Sem isso, os checkpoints permanecem nesta sessão e a interface informa a limitação.
5. Importe os áudios/logos e preencha os IDs em `ReplicatedStorage.Shared.Config`. Veja [ASSETS.md](ASSETS.md). O jogo usa texto quando esses IDs não estão configurados.

O GitHub armazena o projeto; enviar arquivos para esta branch não publica o jogo no Roblox. O workflow novo somente valida e gera um artefato de Studio.

## O que está implementado

- Abertura em preto → Aurivane Works → pausa de 2 segundos → branco/fade → Bramble’s Sprout → carregamento real → menu.
- Menu com Continuar, Novo jogo com confirmação, Configurações, Créditos e Sair com confirmação. Tela de pausa, derrota, protocolos e final.
- Interface dimensionada para celular; movimento, câmera e pulo nativos do Roblox; botões próprios para as mãos, corrida, agachar e lanterna.
- Mãos azul e vermelha em primeira pessoa, lançamento/retração visual e cabos. A lógica de alcance, linha de visão, cor da mão, inventário e progressão é validada no servidor.
- Sete setores com checkpoints individuais: conservatório; arquivo de botânica; máquinas; labirinto; ecos; raízes; estação de transmissão.
- Crachá/fusível, terminais em ordem, poda, páginas/cofre, válvulas/pressão/células, seis sementes, sequência de tons, matriz de luzes, isolamento/corte e alinhamento das antenas.
- Labirinto determinístico com 160 salas conectadas e seis pontas mortas distintas para as sementes.
- Perseguidor por jogador: pathfinding, visão, audição da corrida, memória da última posição e captura. A criatura padrão é um modelo procedural provisório.
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
- O mapa é original e simplificado. O modelo exato de Bramble, seus movimentos próprios e os áudios Marcus não estão importados nesta experiência. Os arquivos-fonte disponíveis estão em `assets/`; os IDs Roblox ainda precisam ser cadastrados.
