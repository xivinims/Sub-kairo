# R6 character motion

## R6 animation runtime repair (v6)

Fixed manual R6 character spawn to parent the rig into Workspace BEFORE assigning Player.Character (animation tracks require a character under Workspace). The local animation script waits for Workspace before loading assets. Raw embedded R6 KeyframeSequences now drive the avatar's Motor6D C0 while selected instead of relying on Transform updates. If an AnimationId loads but its visual pose is missing, a lightweight C0 movement overlay drives actual limb joints; inaccessible IDs use a bigger movement fallback. All 19 original emotes can also drive C0 in the Files bank. Both top buttons remain mutually exclusive. Native verification additionally checks genuine embedded limb poses and direct C0 editing, but real phone rendering still requires a playtest.


## R6 animation bank selector (v5)

**Dois botões no topo** do HUD (`R6 PADRÃO` e `R6 ARQUIVOS`) alternam os bancos, nunca tocando os dois simultaneamente. `AnimationBankGUI` só escolhe o banco, e o script `R6Locomotion` continua dentro do avatar, responsável por parar as tracks antigas e iniciar apenas as do banco selecionado. Padrão: animações R6 acessíveis do controlador original. Arquivos: animações `UploadedMotion` identificadas por movimento e, se uma animation ID não carregar, `KeyframeSequence` correspondente ao mesmo movimento em `Animations.Emotes`. Se ambos falharem, utiliza R6 padrão sem fingir que o arquivo importado funcionou. Os demais emotes em KeyframeSequence são acessíveis por `/r6 nome` apenas no banco ARQUIVOS, e param quando se escolhe PADRÃO.

Apenas os dois botões são criados: nenhum painel de catálogo. Os arquivos originais e 19 emotes continuam intactos. Para construir v5: `lune run r6-test/repair-avatar.luau`; a workflow automatiza a checagem e publicação apenas na experiência privada de teste.


## Correção do avatar R6 (v4)

O jogo agora inclui `R6Locomotion`, um LocalScript instalado **dentro de cada avatar** pelo `StarterCharacterScripts`. Ele executa idle, caminhada, corrida, pulo, queda, escalada e sentar automaticamente, conforme o Humanoid, sem catálogo ou botão de animações. Ele usa primeiro os objetos de animação do módulo R6 importado, depois os R6 públicos e, caso Roblox não carregue o ID, uma animação local de emergência por Motor6D. O controle original e todos os KeyframeSequences originais continuam preservados, com o Animate antigo desabilitado para não disputar as juntas.

Os emotes copiados dos arquivos ficam no próprio personagem, e `/r6` é opcional. Não são usados para substituir locomoção. O sprint continua acessível pela jogabilidade; não existe menu para escolher a animação.

Para reconstruir a versão v4 a partir do lugar existente: `lune run r6-test/repair-avatar.luau` e `lune run r6-test/check.luau`. A workflow de publicação faz isso antes de testar e publicar. As verificações em servidor não equivalem a assistir à animação num cliente Roblox, e o fallback procedural é local quando o asset estiver bloqueado.


The test now runs the original uploaded Naruto R6 Animate controller inside each player character. Its supplied public R6 defaults handle idle, walk, jump, fall, climb and sit automatically. The controller, R6 module and sprint/wallrun sources are unchanged. There is no animation preview GUI or catalog controller.

The avatar server builds each player from their own HumanoidDescription as R6 and clones StarterCharacterScripts, including the animation controller and Animations folder, into that character. Original motion Animation objects and the 19 original KeyframeSequences are copied into character.Animations. The archive retains the complete original emote package for hash comparisons.

The native diagnostic on version 275 found that the custom idle, walk, sprint, wallrun and Naruto demo IDs loaded tracks with Length=0 after six seconds. The public R6 idle/walk/jump IDs supplied by the Naruto R6 module loaded successfully in the same session. This is why the prior custom movement configuration could leave the avatar unanimated. These custom objects and IDs are retained unchanged; they are not claimed to work without asset access. Full Naruto wall walking remains inactive due to the original legacy camera incompatibility.

Sprint and wallrun controllers are installed on the character. Sprint uses its original double-W action or Shift / the native touch Correr action. Its custom run animation and wallrun custom animations remain subject to the loading failure above; normal R6 locomotion is still active.

Raw emotes live in character.Animations.Emotes and can be requested with /r6 CatDance, /r6 Idle Sit, etc.; /r6 parar stops playback. A separate character-owned reader uses the exact poses, timing, easing and weights. It does not change the imported sequences. Raw pose playback is local only, and movement/jumping stops it. It does not replace automatic movement with a dance.

Validation checks the original source hashes, character-owned controllers, absence of the preview UI and R15 controller, and unchanged emote archive. Native verification creates a real R6 character, clones the exact character contents, and requires idle/walk/jump/fall/climb tracks to load with nonzero duration. It records walk playback and joint samples; this is not a rendered phone playtest.

Rebuild with lune run r6-test/apply-character-motion.luau. The older clean-animation-build and animation-test-client files are retired and not installed. Publication continues to back up the private experience and roll back if native checks fail.
