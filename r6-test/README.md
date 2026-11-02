# Naruto R6 com animações completas: parado, andar, correr, pular (v9)

Os arquivos `WallWalkNarutoV1(5).rbxl` e `BoogieWoogieV1(5).rbxl` foram inspecionados. O **Naruto** oferece o chakra nos pés, o movimento na parede e o controlador R6 com a integração de gravidade. O **Boogie** traz candidatos diferentes de animação R6 para parado (`102425446560812`), andar (`17747141146`), correr (`11605590459`), pular (`17747185294`), cair (`17747187834`) e escalar (`11605578996`).

**Antes de construir**, o teste executa a rotina `animation-probe.mjs` diretamente no universo Roblox e mede `AnimationTrack.Length` em um boneco R6 real. O arquivo `animation-probe.json` registra os resultados. O construtor usa apenas animações com duração não zero; caso os IDs do Boogie estejam inacessíveis, escolhe os IDs R6 públicos efetivamente carregados. Não troca nenhum ID por uma referência inventada.

No avatar ficam somente **`Animate`**, **`ChakraWallWalk`** e **`NarutoSprintInput`**. O `Animate` mantém os scripts originais do Naruto e a integração do `GravityController`. A mudança é localizada no módulo R6 original: ele agora seleciona **run** de forma distinta de **walk** em velocidades acima de 19, inclusive quando o chakra está ativo, e usa as animações verificadas. O arquivo original Naruto continua preservado no histórico do Git.

O script `NarutoSprintInput` altera exclusivamente `Humanoid.WalkSpeed` entre 16 e 24 com Shift ou o botão mobile **CORRER**. Ele não reproduz tracks, não altera Motor6D e não usa RenderStepped. O botão de **CHAKRA** permanece disponível. Não são reinstalados o catálogo de animações, o Wall Run antigo, NPCs, arco nem outros pacotes.

A publicação ainda necessita de teste visual real em um cliente Roblox. A verificação nativa confirma que cada animação carrega e o avatar é R6, mas não simula uma sessão mobile.
