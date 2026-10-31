# Still Here — Hotel Mistério

Última versão publicada: **PlaceVersion 250**, build `still-here-hotel-instruments-v4`. As mudanças v5 estão em preparação na branch e ainda não foram publicadas.

O ramo `dead-signal-publisher` monta o mapa de hotel e a interface original do Mistério como pacotes independentes. O mapa vem de `assets/hotel/1940sHotelLobby.rbxm`; a GUI reutilizada está em `assets/ui/mystery-interface.rbxm`.

| Pacote | Arquivo | Destino no jogo |
| --- | --- | --- |
| GUI do Mistério | `assets/ui/mystery-interface.rbxm` | `ReplicatedStorage.MysteryInterface`, clonada para `PlayerGui` |
| Mapa do hotel | `assets/hotel/1940sHotelLobby.rbxm` | `ServerStorage.HotelMap`, carregado em `Workspace.HotelMap` |

O Chapter 2 continua pausado e fora desta alteração. A geometria original do hotel permanece intacta. O botão de interação no canto ativa portas, luzes, sinuca, piano e recepcionista.

## Interações e interface

- A sinuca leva a câmera para cima da mesa. Uma pequena roda circular de força fica no canto inferior esquerdo; segurar carrega e soltar executa a tacada física no servidor. Arrastar fora da roda mira; A/D ou as setas também ajustam a direção. O botão padrão de pulo do Roblox encerra a partida e continua habilitado.
- Ao falar com o recepcionista, a pessoa escolhe jogar com ele ou convidar um amigo. A opção de amigo abre o convite nativo do Roblox; um amigo escolhido que entrar no mesmo servidor é validado no servidor e aparece ao lado de quem convidou. As tacadas alternam entre os dois jogadores. Contra o recepcionista, o NPC responde com a própria tacada.
- O piano leva a câmera até as teclas físicas. Clique/toque nas teclas ou use A/W/S/E/D/F/T/G/Y/H/U/J/K para tocar notas; o songbook de madeira no piano inicia faixas em loop, e “PARAR” encerra a música. Há quatro melodias originais com acordes e uma faixa HEAVEN SAYS em loop.
- O recepcionista fica ao lado da sinuca, com aparência e nome visíveis. O rig usa as animações de proximidade do pacote Dynamic NPC Animations V2; a fala começa com “Hola” e oferece as duas formas de jogar.
- Configurações ficam em um painel de altura total encostado à esquerda, sem a tela central. Categorias abrem páginas individuais; controles visuais e de áudio aplicam na hora e salvam automaticamente.
- O menu removeu a página de créditos e não adiciona um botão próprio de convite multiplayer.

O cenário conserva 8.688 peças, iluminação e dez pontos de nascimento. As estruturas órfãs de chuva foram retiradas e a arma foi removida do mapa montado. O controlador mantém velocidade 16 e não habilita primeira pessoa.

## Conferência e publicação

- Universo `9421311218`; Place `118064584465155`; branch `dead-signal-publisher`.
- Último build publicado: `still-here-hotel-instruments-v4` (PlaceVersion 250). `still-here-hotel-instruments-v5` é a próxima versão preparada, ainda não publicada.
- `preview.trigger` roda montagem, comparação de fontes, conferência geométrica e preflight isolado no Roblox sem publicar.
- `release.trigger` roda o mesmo preflight e publica só após ele passar. A rotina baixa e guarda a versão anterior, confere a versão publicada e reinicia os servidores; em falha, executa a recuperação.
- O preflight verifica scripts, mapa, portas, spawns, bolsos, teclas, songbook, diálogo e o ponto de spawn do recepcionista perto da mesa. Ele não renderiza um cliente real nem toca o áudio; no ambiente de preflight, peças recém-criadas do NPC são estacionadas em `Y = -1.000.000`, então a aparência e a posição final precisam ser confirmadas dentro do Roblox.

Os dois verificadores comparam o mapa com o arquivo recebido, verificam a separação entre GUI e mapa e conferem que o Chapter 2 não foi incluído.
