# R6 cinematic menu + NPCs + Forsaken run selection (v11)

Esta é a experiência **privada de teste R6**, não os projetos antigos. Branch `dead-signal-publisher`, pasta `r6-test/`. Mantém os recursos existentes do Naruto (chakra nos pés) e a troca de posição Boogie Woogie.

## Menu fiel à referência enviada

O novo script `cinematic-menu-client.luau` instala, em `StarterPlayerScripts`, uma interface responsiva com:
- **Menu principal** com quatro botões estilizados (ícones à esquerda, faixas azuis inclinadas visualmente, borda clara), câmera 3D com parallax suave, arquitetura azul em blocos xadrez, piso preto e branco, corredor central azul brilhante.
- **Settings** em painel vidro escuro, barra branca fina e botão fechar rosa. Configurações: Camera Banking, Camera Tilt, High Quality Graphics, Music Volume, Neon Glow Pulse, Panel Bob e Realistic DOF. Cada toggle afeta seu recurso correspondente.
- **Credits** e **Update Log** em painéis transparentes, cabeçalho e botão rosa de fechar. Os créditos atribuem o novo menu ao projeto de teste e não fingem autoria dos materiais originais.
- **Play** com cobertura escura e barra de carregamento, fechando a cena 3D temporária e devolvendo a câmera ao avatar R6.
- **YOU DIED** com visual escuro, título em destaque e as opções **RESPAWN** (solicitação validada pelo servidor) e **RETURN TO MENU** (volta ao menu dinâmico). O ícone discreto ☰ reabre o menu após começar.
- Para manter a performance no celular, a cena xadrez é apenas local e removida da memória ao iniciar a partida, os tweens são limitados e a câmera só atualiza enquanto o menu está aberto.

O fundo da referência é produzido com geometria básica de Roblox e padrões em SurfaceGui, não com as próprias imagens das capturas. Isso permite um visual semelhante sem incluir indevidamente os controles e a barra do Roblox Studio que aparecem nas fotos. Os detalhes de iluminação e a perspectiva precisam de verificação visual no cliente para aferir fidelidade exata.

## Quatro NPCs andando pelo mapa

A arena recebe quatro NPCs **R6**, com Humanoid e Animator, animados por `npc-wander-server.luau` e usando `Humanoid:MoveTo` para caminhar por posições aleatórias próximas ao ponto de partida. O script fica no servidor e não faz animação de juntas por quadro. Os NPCs ficam dentro de `Workspace.NPCWanderers`, permitem troca de posição com a habilidade Boogie e não interferem com o avatar do jogador.

O alvo de teste Boogie original continua presente. Os novos NPCs aparecem **dentro da arena**, não na tela do menu.

## Corrida: os três IDs enviados

O teste tenta três IDs informados pelo usuário, nessa ordem:
- `72900620651167`: pacote Survivor/Forsaken de corrida (UGC).
- `107952007153363`: Chance R6/Forsaken de corrida (UGC).
- `93499989310243`: ID de corrida encontrado no script público Two Time.

Esses IDs podem estar hospedados como recursos de avatar ou serem de outro criador; **isso não garante que o AnimationTrack carregue** na experiência Roblox privada. Por isso, `run-probe-quick.mjs` tenta reproduzi-los em um boneco R6 por alguns segundos antes de escolher. Só aplica um ID com `AnimationTrack.Length > 0.07`. Caso a verificação falhe ou não haja permissão, mantém os IDs R6 de corrida já comprovados, sem prometer uma animação personalizada que não carregou.

## Validação e publicação

`repair-avatar.luau` reconstrói a experiência mantendo a foto/roupa do jogador, poderes e mapa de teste. `check.luau` valida scripts e objetos serializados. `verify.luau` inspeciona o estado publicado em Roblox, os objetos R6, os NPCs, a GUI e a autenticação do botão de respawn. `publish.mjs` salva backup do place privado antes de sobrescrever, publica e reverte se o teste nativo falhar.

Testes automatizados não reproduzem visualmente a câmera e a interface no app móvel: para confirmar equivalência às imagens de referência, é necessário abrir a experiência publicada e inspecionar o resultado.
