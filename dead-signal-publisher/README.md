# Still Here — mapa do hotel e GUI do Mistério

Publicado e verificado: **PlaceVersion 247**, workflow **41210827168**. Os servidores anteriores foram reiniciados. Evidências em `review/hotel-mystery-ui-verification.json`.

O mapa enviado e a interface da antiga mansão Mistério são pacotes independentes.

| Pacote | Arquivo | Destino no jogo |
| --- | --- | --- |
| GUI original da mansão | `assets/ui/mystery-interface.rbxm` | `ReplicatedStorage.MysteryInterface`, copiada para `PlayerGui` |
| Mapa enviado | `assets/hotel/1940sHotelLobby.rbxm` | `ServerStorage.HotelMap`, carregado em `Workspace.HotelMap` |

Os sete templates originais conservam imagens, posições e tipografia. A interface ativa usa HUD, vinheta e indicador de interação. Os botões originais de lanterna e interação funcionam sobre o mapa novo, com rótulos em português. As configurações usam as preferências já existentes. A câmera é em terceira pessoa, com tela de carregamento na entrada. Não há menu personalizado, botão de multiplayer, créditos visíveis ou armas. Os convites padrão do Roblox continuam disponíveis.

O cenário conserva 8.714 peças, os materiais incluídos, efeitos de iluminação, sons e dez pontos de nascimento. Os quatro conjuntos de porta que já traziam dobradiças recebem interação por botão, clique ou prompt. A arma e seu gerador são removidos do cenário montado. Scripts embutidos são substituídos pelo controlador revisado. Peças decorativas soltas ficam ancoradas; posições, dimensões, malhas e cores são preservadas.

O arquivo recebido contém quatro nomes de materiais sem definição: `Bricks 02`, `Marble Speckled`, `Metal` e `Wood Floor Rough MV`. As referências são mantidas e o Roblox usa o material nativo correspondente quando a definição falta.

## Montagem e conferência

- Universo `9421311218`; Place `118064584465155`; branch `dead-signal-publisher`.
- Build `still-here-hotel-mystery-ui-v1`.
- `node dead-signal-publisher/publish.mjs --dry-run` verifica fontes e hashes dos dois pacotes.
- `hotel-assemble.luau` monta o Place sem a geometria ou os controladores de história da antiga mansão. A GUI está salva no repositório e pode ser reutilizada em outro cenário.
- `hotel-file-verify.luau` compara o desenho da GUI com o original do Mistério, a geometria com o arquivo recebido e os controladores com as fontes da branch. Transformações admitem somente a precisão de serialização de 0,0001 stud/componente.
- `hotel-verify.luau` confere os pacotes, nascimentos e abertura/fechamento das portas em uma sessão isolada do motor Roblox.
- `asset-probe.trigger` com `hotel-preview` executa a conferência sem publicar.
- `release.trigger` inicia a publicação depois da revisão. O publicador guarda o Place anterior, verifica e baixa a versão publicada, confere seus arquivos e reinicia os servidores. Uma falha durante a publicação aciona recuperação.

A conferência no motor e nos arquivos não substitui uma avaliação visual em cliente Roblox ou celular.
