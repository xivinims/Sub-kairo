# Naruto R6 + Boogie Woogie (v10)

O pacote principal de movimento continua sendo `WallWalkNarutoV1(5).rbxl` com seu chakra nos pés, animações R6 verificadas, o botão **CHAKRA** e **CORRER**. Sem os antigos menus de seleção de animações nem um controlador que mova joints a cada quadro.

## Boogie Woogie do Jujutsu Kaisen

Adicionado a partir de `BoogieWoogieV1(5).rbxl`. A habilidade troca **as posições de dois personagens**, e não as roupas, avatares ou identidades.

- **Celular:** botão **BOOGIE** à direita, acima de CHAKRA. Olhe na direção de outro personagem e toque. Se não houver outro jogador, existe um único `BoogieTestDummy` R6 próximo ao spawn para testar sozinho.
- **Computador:** tecla **G**. O alvo mais próximo do centro da câmera tem prioridade.
- **Efeito:** reaproveita o `ClapAnimation`, o `ClapVFX` e o `SwapSound` originais do Boogie. As permissões do ID da animação de bater palmas ainda podem impedir a animação visual, mas a troca de posições funciona independentemente da animação de palmas.
- **Sem conflito:** dois novos scripts leves, `BoogieSwapInput` dentro do avatar e `BoogieSwapServer` no servidor. Não executam loops contínuos. Validação no servidor limita a troca a 65 studs, entre o jogador e outro personagem vivo ou o boneco de teste, com intervalo de 1,6 segundo. Não permite selecionar peças soltas do mapa.
- **Desempenho:** partículas com emissão limitada, sem câmera personalizada, sem catálogo de animações, sem extras de combate e sem outros scripts do Boogie que modificariam movimento ou animação.

Por que não copiamos literalmente o servidor inteiro do modelo: o código original aceita duas peças arbitrárias enviadas pelo cliente, sem limitar distância. Foi usada uma adaptação compacta e validada, preservando a habilidade e os recursos audiovisuais originais.

O arquivo original de Boogie está preservado pelo histórico do repositório. A verificação técnica de publicação confirma modelos R6, scripts e uma troca de posição entre dois modelos, mas **não substitui o teste visual jogando no celular**.

## Animações R6

O carregamento dos IDs Boogie originais de correr, caminhar e pular retornou duração zero na experiência de teste; o Naruto usa os R6 básicos que carregaram. A tentativa seguinte de conferir candidatos adicionais no Roblox expirou, então a publicação v10 reutiliza as animações R6 que haviam sido efetivamente verificadas, sem assumir que novos IDs funcionam.
