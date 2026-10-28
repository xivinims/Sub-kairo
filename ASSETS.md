# Assets e importação

## Arquivos incluídos

- `assets/branding/aurivane-works.png`: logo fornecida pelo usuário.
- `assets/branding/dead-signal.png`: logo de capítulo fornecida pelo usuário.
- `assets/audio/security-original.mp3`: gravação de 33 segundos fornecida pelo usuário; a versão `.ogg` é uma conversão.
- `ambient.ogg`, `pursuit.ogg`, `radio.ogg`, `relay.ogg`: trilha/efeitos originais produzidos para este projeto.
- `assets/world/BramblesWorld.rbxmx`: geometria procedural original do port.

Esses arquivos não ganham automaticamente um ID Roblox ao entrar no GitHub. Importe as imagens/áudios pelo Creator Hub/Asset Manager na conta/grupo proprietário da experiência. Conceda à experiência acesso aos áudios. Depois preencha `Config.Assets` com os IDs numéricos retornados pelo Roblox e reconstrua o `.rbxlx`.

| Config | Arquivo |
|---|---|
| `StudioLogo` | `aurivane-works.png` |
| `ChapterLogo` | `dead-signal.png` (reservado para apresentação de capítulo) |
| `Ambient` | `ambient.ogg` |
| `Pursuit` | `pursuit.ogg` |
| `Radio` | `radio.ogg` |
| `Relay` | `relay.ogg` |
| `OpeningVoice` | `security-original.mp3` |

O valor 0 desliga o recurso; o port não inventa IDs, não transmite arquivos para Roblox nem usa URLs privadas. A abertura usa o nome do estúdio em texto até a imagem estar configurada.

## Falas Marcus

As gerações anteriores com Marcus — Classic Audiobook Narrator e os efeitos escolhidos pelo usuário (Old Radio, Call center, Tunnel, Longe) foram confirmadas no histórico do ElevenLabs, mas seus downloads não ficaram disponíveis no projeto. Elas não foram substituídas por outra voz aqui.

Depois de recuperar e importar cada áudio no Roblox, preencha `Config.Assets.Voices` com chaves `"1_1"`, `"1_2"` até `"7_1"`, `"7_2"`. 1 é arquivo de botânica; 2 máquinas; 3 galeria; 4 ecos; 5 raízes; 6 estação; 7 final. As frases estão em `Config.Sectors[].Lines` e no encerramento de `Main.client.luau`.

## Bramble exato

Asset solicitado: https://create.roblox.com/store/asset/77713813527653/Doors-outdoors-Bramble

Configurado em Config.Models.BrambleTemplate; seu carregamento com 68 malhas foi confirmado no motor Roblox. No Studio, em modo de edição, execute o conteúdo de `studio/ImportBramble.command.luau` na Command Bar. O Roblox precisa permitir a importação. O script remove código executável do contêiner antes de adicioná-lo ao `ServerStorage` e nunca publica a experiência. Confira orientação/escala no Play Test. O servidor usa `BrambleTemplate` se ele existir; caso contrário mostra a criatura procedural, identificada como placeholder.

A importação do modelo não garante direitos de publicação nem inclui automaticamente o rig/animações do jogo original. Não há conteúdo extraído de Poppy Playtime neste port; suas marcas e o conteúdo de terceiros permanecem de seus respectivos titulares.
# Áudio da versão base

Os IDs de ambiente `4745539237` (Winteran), perseguição `9039697342` — Much Fear (APMOfficial) e estática `8028069841` (NoobMatthew3) foram localizados no Creator Store. Reprodução no cliente Roblox ainda precisa ser verificada. Esses arquivos não são apresentados como trilha oficial de Poppy Playtime. As falas Marcus e as imagens ainda exigem upload e configuração de IDs.


## IDs importados

As duas imagens fornecidas pelo usuário foram importadas com conteúdo idêntico ao original. `assets/imported-asset-ids.json` lista logos, mãos, texturas, GrabPack, baterias, scanners, portas, painéis, tubos e armazenamento importados. O nome BrickWalls refere-se ao arquivo bricks.fbx do kit Unity, utilizado como entulho decorativo; não é um nível completo nem uma parede oficial identificada de Poppy Playtime. O cenário continua sendo montado para este capítulo, com materiais importados de concreto e piso.
