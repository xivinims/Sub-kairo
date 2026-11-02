# Naruto R6 | chakra nos pés (v8)

**Pacote selecionado:** `WallWalkNarutoV1(5).rbxl`. O arquivo enviado é idêntico ao `WallWalkNarutoV1(4).rbxl`, já preservado integralmente na versão v6 do jogo. A montagem recupera o original daquele arquivo salvo no Git, e verifica os hashes dos scripts `WallWalk`, `GravityController`, `DrawClass`, `RbxCharacterSounds` e `Animate`.

O pacote anterior `FREE R6 Wall Run` e todos os controladores e botões da versão anterior são removidos. Dentro do avatar R6 ficam apenas `Animate` e `ChakraWallWalk`, que executa o algoritmo original para caminhar em superfícies e aplicar o efeito `ChakraFeet` nas pernas. No `ReplicatedStorage`, apenas dependências do Naruto (`GravityController`, `DrawClass` e `VFX`). O servidor mantém o script mínimo que cria o avatar pessoal do jogador em R6. Não entram arco, sprint, BoogieWoogie nem os demais arquivos.

A única alteração no script WallWalk original é tornar a ação da tecla **B** acessível também por botão de toque **CHAKRA**, sem introduzir outro controlador de animação. O carregador legado de câmera de 2020 é incompatível com a versão moderna do Roblox; por isso foi substituído apenas por um `Loaded` valor de compatibilidade, mantendo o PlayerModule nativo. A rotação da câmera ao ficar de cabeça para baixo precisa ser testada no celular.

**Limites:** o sistema original executa raycasts quando o chakra está ativo e requer um teste visual em partida para confirmar a física da parede no cliente. A verificação em servidor valida estrutura, dependências e spawn R6, não demonstra movimento real na parede.
