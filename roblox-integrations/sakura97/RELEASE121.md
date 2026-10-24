# Suvivers [ALFA] — build 121

## Mapas e exploração

- Bosque do Silêncio: Horror Map (79671648850902), ampliado em 20% em cada eixo horizontal.
- Base Abandonada: geometria jogável do MM2 MilBase (13967333450), sem volumes externos de moedas e bloqueios de demonstração.
- Fortaleza da Névoa: Alpine Fortress (8050959400), ampliada em 2×.
- Sorteio sem repetição imediata. Só a arena da rodada fica no Workspace; os outros modelos permanecem no ServerStorage.
- O construtor testa caminhos reais no PathfindingService, cria oito posições de chegada por cenário e separa o spawn do Jason.
- Lanternas de orientação, identificação da entrada e iluminação local diferente por cenário.
- Lobby editado pelo proprietário e logo original preservados. Scripts embutidos dos mapas são removidos antes da instalação.

## Interface das referências enviadas

- Menu central com cards, avatar, Jason original, logo, nível e pontos.
- Loja funcional do item Music com pontos; inventário visual dos equipamentos disponíveis.
- Ajustes em Áudio, Visual e Jogo: volumes separados, gráficos leves, sombras, nomes, menos movimento, campo de visão e tamanho dos controles.
- HUD com condição do sobrevivente, disponibilidade de kit/impulso, XP, pontos e botões circulares com feedback.
- Resultados com ranking rolável, recompensa real, golpes/quedas e prévia 3D da animação original de vitória do Jason.
- Carregamento por etapas; falha de mídia opcional não encerra uma rodada já iniciada.

## Correções de jogabilidade e desempenho

- Compatibilidade de animação tanto com Motor6D quanto com AnimationConstraint (Avatar Joint Upgrade).
- Reconstrução das ligações quando as juntas do avatar chegam por replicação. Poses estáticas também são aceitas.
- Agachar, ferimento e pose de caído são aplicados no momento correto da simulação; a animação padrão volta ao sair da rodada.
- Dados de poses compartilhados entre avatares, busca binária de keyframes e menos paradas repetidas de animação.
- Câmeras antigas de dano/introdução não retomam controle após reset ou morte.
- Cancelamento explícito da cena de morte no retorno ao lobby; recuperação de segurança em 12 segundos.
- Proteção de dez segundos na chegada. Jason prioriza alvos vivos e pode finalizar um caído após a janela inicial de ajuda.
- Limite de frequência no cálculo de caminhos; descarte de rotas antigas e recuperação de obstáculos.
- Ataques e execuções verificam paredes. Kit não pode interromper uma execução iniciada.
- Contagem de golpes inclui o golpe que derruba. Rodada encerra quando não há sobreviventes; não carrega mapa sem jogadores na fila.
- Pontos, XP e Cantor são salvos com tentativas idempotentes, proteção contra leitura falha, salvamento periódico e fechamento de servidor.

## Validação

O pipeline executa o código real em sessões isoladas do motor Roblox. Abrange perfis, controlador da rodada, Jason jogável, perseguição, interface, menu, animação e conteúdo dos três mapas. Os testes usam armazenamento simulado; não escrevem perfis de jogadores.

Inclui chegada de oito jogadores, entrada no meio da rodada, reset de personagem, revival próprio/de aliado, execução bloqueada por parede, kit durante execução, saída de Jason, câmera de espectador, preferências de música, menu em 812×375 e reprodução de poses no rig R15 criado pelo motor.

Publicação ocorre somente depois de todos os testes passarem, seguida de uma leitura independente da versão publicada. Não representa medição de FPS ou teste de toque em aparelho físico. Reprodução de áudio depende da disponibilidade e das permissões dos assets no Roblox.

## Referências técnicas

- https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint
- https://create.roblox.com/docs/reference/engine/classes/Motor6D
- https://create.roblox.com/docs/characters/pathfinding
- https://create.roblox.com/docs/cloud-services/data-stores/best-practices
