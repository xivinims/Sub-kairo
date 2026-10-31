# Still Here — mapa do hotel e GUI do Mistério

Publicado e verificado: **PlaceVersion 248**, workflow **41225810899**. Os servidores anteriores foram reiniciados. Evidências em `review/hotel-gameplay-settings-verification.json`.

O mapa enviado e a interface da antiga mansão Mistério são pacotes independentes.

| Pacote | Arquivo | Destino no jogo |
| --- | --- | --- |
| GUI original da mansão | `assets/ui/mystery-interface.rbxm` | `ReplicatedStorage.MysteryInterface`, copiada para `PlayerGui` |
| Mapa enviado | `assets/hotel/1940sHotelLobby.rbxm` | `ServerStorage.HotelMap`, carregado em `Workspace.HotelMap` |

Os sete templates originais conservam imagens, posições e tipografia. A interface ativa usa HUD, vinheta e indicador de interação. O botão de interação no canto abre e fecha as portas, inicia a sinuca e alterna luzes próximas. Portas não têm mais clique do mouse, tecla E ou prompt. A sinuca monta 16 bolas e usa uma interface de ângulo, força, tacada, reinício e saída. A velocidade do personagem é 16.

As configurações agora ocupam a altura inteira da tela, alinhadas à esquerda, com páginas em português para Jogo, Controles, Tela, Áudio e Idioma. Há controles de brilho, campo de visão, sensibilidade, sombras, efeitos, volume e dicas. A tela ignora a margem superior do Roblox e se ajusta a retrato e paisagem.

O cenário conserva **8.688 peças**, materiais incluídos, efeitos de iluminação, sons e dez pontos de nascimento. As 14 estruturas repetidas de chuva que dependiam de scripts ausentes foram removidas; os efeitos das janelas e da lareira continuam. A arma e seu gerador são removidos do cenário montado. Scripts embutidos são substituídos pelo controlador revisado. Peças decorativas soltas ficam ancoradas; posições, dimensões, malhas e cores das peças mantidas são preservadas.

O arquivo recebido contém quatro nomes de materiais sem definição: `Bricks 02`, `Marble Speckled`, `Metal` e `Wood Floor Rough MV`. As referências são mantidas e o Roblox usa o material nativo correspondente quando a definição falta.

## Montagem e conferência

- Universo `9421311218`; Place `118064584465155`; branch `dead-signal-publisher`.
- Build `still-here-hotel-gameplay-settings-v2`.
- O Chapter 2 permaneceu inalterado. A branch não contém o mapa do labirinto do Chapter 1; por isso, as cartas dessa parede não entraram nesta versão.
- `node dead-signal-publisher/publish.mjs --dry-run` verifica fontes e hashes dos dois pacotes.
- `hotel-assemble.luau` monta o Place sem a geometria ou os controladores de história da antiga mansão. A GUI está salva no repositório e pode ser reutilizada em outro cenário.
- `hotel-file-verify.luau` compara o desenho da GUI com o original do Mistério, a geometria mantida com o arquivo recebido e os controladores com as fontes da branch. Transformações admitem somente a precisão de serialização de 0,0001 stud/componente.
- `hotel-verify.luau` confere os pacotes, nascimentos, portas, botões, bolas, caçapas e a presença da lógica de tacada em uma sessão isolada do motor Roblox.
- `asset-probe.trigger` com `hotel-preview` executa a conferência sem publicar.
- `release.trigger` inicia a publicação depois da revisão. O publicador guarda o Place anterior, verifica e baixa a versão publicada, confere seus arquivos e reinicia os servidores. Uma falha durante a publicação aciona recuperação.

A prévia isolada valida a montagem e os controladores, mas não renderiza a tela de configurações nem simula a física da tacada como um cliente Roblox ao vivo. Uma captura visual em cliente/celular não foi feita nesta publicação.

