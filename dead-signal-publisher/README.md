# Still Here — Hotel Mistério

Publicado e verificado: **PlaceVersion 249**, workflow **41228313035**. Os servidores foram reiniciados. Evidências em `review/hotel-gameplay-settings-verification.json`.

O ramo `dead-signal-publisher` monta o mapa de hotel e a interface original do Mistério como pacotes independentes. O mapa vem de `assets/hotel/1940sHotelLobby.rbxm`; a GUI reutilizada está em `assets/ui/mystery-interface.rbxm`.

| Pacote | Arquivo | Destino no jogo |
| --- | --- | --- |
| GUI do Mistério | `assets/ui/mystery-interface.rbxm` | `ReplicatedStorage.MysteryInterface`, clonada para `PlayerGui` |
| Mapa do hotel | `assets/hotel/1940sHotelLobby.rbxm` | `ServerStorage.HotelMap`, carregado em `Workspace.HotelMap` |

O Chapter 2 continua pausado e fora desta alteração. A geometria original do hotel permanece intacta. O botão de interação no canto ativa portas, luzes, sinuca, piano e recepcionista.

## Interações e interface

- A sinuca abre uma câmera dedicada sobre a mesa, mostra mira e taco animado, permite ajustar direção e força com toque, teclado ou mouse, e mantém as tacadas no servidor.
- O piano abre uma câmera dedicada, mostra um teclado responsivo e toca notas espaciais com reverberação. Há quatro melodias curtas originais.
- O recepcionista aparece ao lado da sinuca com avatar baseado no criador do jogo e as peças identificáveis nas imagens de referência. Ele responde: “Hola. Seja bem-vindo ao hotel.”
- Configurações ficam em um painel de altura total encostado à esquerda, sem a tela central. Categorias abrem páginas individuais; controles visuais e de áudio aplicam na hora e salvam automaticamente.
- O menu removeu a página de créditos e não adiciona um botão próprio de convite multiplayer.

O cenário conserva 8.688 peças, iluminação e dez pontos de nascimento. As estruturas órfãs de chuva foram retiradas e a arma foi removida do mapa montado. O controlador mantém velocidade 16 e não habilita primeira pessoa.

## Conferência e publicação

- Universo `9421311218`; Place `118064584465155`; branch `dead-signal-publisher`.
- Build publicado: `still-here-hotel-interactions-v3` (PlaceVersion 249).
- `preview.trigger` roda montagem, comparação de fontes, conferência geométrica e preflight isolado no Roblox sem publicar.
- `release.trigger` roda o mesmo preflight e publica só após ele passar. A rotina baixa e guarda a versão anterior, confere a versão publicada e reinicia os servidores; em falha, executa a recuperação.
- O preflight verifica script, mapa, portas, spawns, bolsos e registros das novas interações. Não renderiza a tela em um cliente real nem simula uma sessão de tacadas para avaliar sensação/latência visual.

Os dois verificadores comparam o mapa com o arquivo recebido, verificam a separação entre GUI e mapa e conferem que o Chapter 2 não foi incluído.
