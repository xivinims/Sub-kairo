# Correção de andar, correr e pular no R6 (v16)

**Causa corrigida:** o `R6PoseController` colocava as poses diretamente em `Motor6D.C0`, enquanto o `Animator` original do Naruto continuava executando tracks. Agora ele aplica `Motor6D.Transform` no evento `RunService.PreSimulation`, após a avaliação do `Animator`. O Roblox recomenda essa propriedade para movimentos customizados sem alterar a posição estrutural das juntas.

As três sequências originais R6 (`Run1`, `Run2` e `Run3`) continuam **idênticas** aos keyframes recebidos. A corrida usa a `Run3` original, lida quadro a quadro; a caminhada utiliza balanço R6 real nas juntas; o pulo é mantido visualmente por 0,23 s ao sair do chão, passa para pose de queda e termina em pose curta de aterrissagem. O script de sprint aguarda até a criação do avatar ser atribuída a `Player.Character`, evitando uma condição de corrida na inicialização.

O Chakra e a escalada natural continuam prioritários; nesses modos o controlador libera as juntas para o sistema correspondente. Os sistemas Boogie, menu, NPCs e combate ficam preservados.

**Limite de verificação:** CI e executor Roblox conseguem validar o código, o rig e a propriedade Transform, mas não reproduzem uma sessão cliente móvel com movimento real. A confirmação visual requer abrir o jogo. O atributo `R6AnimationState` no avatar agora registra `idle`, `walk`, `run`, `jump`, `fall` ou `land` para facilitar a identificação de falhas futuras sem adicionar HUD.

---

# Corrida R6 original do Creator Store, sem edição (v15)

A corrida anterior era produzida por movimentos programados porque o ID Ninja era R15 e não movimentava corretamente um avatar R6. Agora a experiência usa **a sequência original `Run3 [by Newb1e27]`**, dentro do modelo gratuito [Best Run Animations R6](https://create.roblox.com/store/asset/136548520660837/Best-Run-Animations-R6). O modelo público contém exatamente três `KeyframeSequence`: `Run1 [by M0rsDev]` (40 keyframes), `Run2 [by Gusthabuo777]` (41) e `Run3 [by Newb1e27]` (17).

**Nenhum dos keyframes originais foi modificado.** O arquivo binário `free-r6-run-model.rbxm` é baixado do Creator Store e armazenado intacto no repositório, com SHA-256 salvo em `animation-manifest.json`. O `repair-avatar.luau` clona exatamente as três sequências para `StarterCharacterScripts.R6RunSource`. O script `R6PoseController` lê os keyframes da `Run3` e interpola as poses `Motor6D.C0` do avatar R6. Isso evita depender de um AnimationId privado que não funciona fora da conta original do criador. Os combates usam a mesma infraestrutura anterior, sem modificar `Run1`, `Run2` ou `Run3`.

O novo arquivo anexado pelo usuário, `Glider System.rbxl`, foi inspecionado: ele contém um `Glide` com `Gliding` (AnimationId `140674740609979`), um `GlideServer`, dez módulos e uma sequência local R6 `Gliding` com duas keyframes. Não há neste arquivo uma faca nem uma divisão em dois pacotes separados R6/R15. **Não acrescentamos objetos ausentes nem editamos esse código original.** A instalação desse sistema foi mantida fora da experiência para não alterar o arquivo nem supor o conteúdo de um pacote diferente.

Os testes verificam a presença e as quantidades dos keyframes originais do modelo, o controlador R6, a corrida selecionada e os poderes existentes. Não substituem uma inspeção visual em partida.

---

# Corrida R6 e luta com movimentos reais (v14)

**Motivo da tábua identificado:** `656118852` é a animação Ninja do catálogo **R15**, não um clipe R6. O teste antigo examinava só `AnimationTrack.Length`, o que não prova que um asset possui poses para o rig. Os 13 IDs individuais de combate também retornaram comprimento zero.

## Correção instalada

O avatar possui agora um **único** `R6PoseController` que atualiza suavemente as juntas reais R6 (`Right Shoulder`, `Left Shoulder`, `Right Hip`, `Left Hip`, `RootJoint`, `Neck`) com curvas interpoladas. Os movimentos foram criados para esse teste, **não são clipes copiados dos modelos**.

- **Parado:** respiração discreta, sem travar.
- **Andar:** braços alternados, inclinação e passos moderados.
- **Correr:** passadas maiores, braços fortes alternados, tronco inclinado e contraposição de cabeça. Diferente da caminhada, funciona diretamente no R6. A referência base `run.xml` volta para o movimento clássico R6 `180426354`, que não é uma animação R15 incompatível.
- **Pulo e queda:** poses adaptadas ao estado humanoide.
- **Combate:** quatro socos sequenciais com preparação, impacto visual e recuperação; defesa; duas esquivas; dois chutes; uppercut; downslam; golpe forte; sequência de golpes. Tudo **apenas visual**: sem dano, força de combate, ferramentas ou efeitos de violência.
- **Controle unificado:** `R6CombatInput` cuida só de toque e teclado; `R6PoseController` é o único script novo que manipula juntas. Nenhum `TweenService` concorrente, menu de animações ou controlador extra por golpe.
- **Segurança contra conflito:** o controlador libera imediatamente as juntas quando o chakra opcional ou a escalada natural estiverem ativos. Mantém Boogie Woogie, quatro NPCs, menu 3D e tela de morte.

## Opções de assets reais encontrados

Foram encontrados pacotes R6 editáveis que servem para substituição futura após importar seus `AnimSaves` e publicar os clipes na conta/grupo proprietário do jogo:
- `16663903306`: Free R6 Battleground Animations V7, com M1 4 hits, corrida, caminhada, dashes, uppercut e downslam.
- `136548520660837`: Best Run Animations R6.
- `74065807270952`: Free R6 Battle Punch Kick Idle Run Jump Anim Pack.

Eles foram **pesquisados, mas não importados** neste build. Os 13 IDs de luta antigos continuam registrados como referências não carregáveis, e não são anunciados como clips ativos. A nova animação motorizada R6 é reprodutível sem depender das permissões desses IDs.

Os testes da publicação verificam scripts, seis `Motor6D` em uma instância R6, atributos e carregamento do movimento clássico. A reprodução visual precisa ser validada em sessão real do cliente móvel.

---

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
