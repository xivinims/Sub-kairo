# Animações de combate R6 + corrida Ninja (v13)

Atualização do **teste R6** (branch `dead-signal-publisher`, `r6-test/`). O pacote de combate foi integrado **como animações visuais**, sem dano ou novos scripts de física de combate. O avatar preserva `Animate`, corrida Ninja, Chakra opcional, escalada automática, Boogie Woogie, menu 3D e NPCs.

**Quatro socos em sequência:** M1 / toque em **SOCO** alterna as animações `10469493270`, `10469630950`, `10469639222`, `10469643643` se disponíveis. **Defesa** `10470389827` (F / DEF). **Esquiva** frente `10479335397` ou trás `10491993682` conforme direção (Q / ESQ). **Chutes** alternados `2515090838` e `13874028312` (E / CHUTE). **Especiais** ciclam uppercut `10503381238`, downslam `10470104242`, soco forte `12983333733` e socos consecutivos `10466974800` (R / ESP.).

Os **quatro links de pacotes completos** enviados pelo usuário ficam registrados no manifesto como referências para importação futura: `16663903306`, `75164220659481`, `125909948357929`, `114132474839078`. Não executamos scripts de terceiros contidos em modelos inteiros sem inspecioná-los; os 13 AnimationIds individuais são testados diretamente dentro do Roblox. Apenas tracks com `AnimationTrack.Length > 0.07` entram no `CombatAnimations`. IDs bloqueados recebem um gesto local e breve das juntas R6, claramente indicado no manifesto como **alternativa**, não a animação original. Não foram adicionadas animações R15 ou controles de seleção para a caminhada.

Os movimentos não interferem com a escalada natural: os comandos ficam indisponíveis enquanto `Climbing=true`. O menu e a tela de morte bloqueiam o combate, e a HUD no celular usa pequenos botões circulares no lado direito central para não cobrir os controles de corrida/chakra/boogie.

**Corrida:** preservada a `656118852` Ninja Run real, testada com duração positiva, diferente do `180426354` de caminhada. Os IDs fornecidos para Survivor `72900620651167`, Chance `107952007153363` e Two Time `93499989310243` foram testados e deram duração zero nessa experiência. Por isso não é correto ativá-los como corrida funcional sem permissão do criador.

A workflow `r6-test.yml` gera `combat-probe.json`, reconstrói `arena.rbxl`, valida o lugar com Lune, faz backup da experiência privada e confirma no Roblox os scripts e pistas de animação R6. A verificação automática não reproduz uma partida mobile completa; a aparência final das ações precisa ser observada pelo jogador.

---

# Escalada natural R6 + chakra opcional (v12)

O jogador **não recebe botão para escalar**. O sistema do arquivo `R15 & R6 Wall Climbing System.rbxl` foi adaptado apenas para R6: caminhe para a frente contra uma superfície vertical, com **joystick no celular ou WASD no PC**, para começar a escalar. Parar de avançar, se afastar da parede ou ficar sem energia termina a escalada. O sistema detecta paredes com raycast a cada 0,09 s, movimenta o personagem para cima e toca a animação R6 `Animate.climb.ClimbAnim`. Não instala a variante R15. O script `NaturalR6Climb` fica dentro do avatar junto ao módulo `StaminaBar` original, com 100 de energia, consumo de 15/s, recuperação de 12/s e recarga de 2 s quando esgota. A barra de energia aparece só durante a escalada ou recuperação, para não ficar poluindo o GUI.

O **CHAKRA** é opcional e continua com seu próprio botão `CHAKRA OFF` / `CHAKRA ON` no canto direito ou tecla **B**. Começa **desligado**. Ligá-lo ativa o sistema original `ChakraWallWalk` do Naruto, com efeitos e gravidade; ao mesmo tempo, `NaturalR6Climb` é desativado enquanto o chakra estiver ligado. Desligá-lo reativa a escalada natural sem precisar de um segundo botão.

Tudo o mais foi mantido: corrida R6 separada de caminhada, quatro NPCs na arena, Boogie Woogie, menu 3D e tela de morte. Não adicionamos scripts de R15, controles extras ou um segundo controlador de locomoção por quadro. Como antes, a verificação automatizada confere instalação e scripts; **só uma partida real no Roblox confirma a sensação física de escalada**.

---

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
