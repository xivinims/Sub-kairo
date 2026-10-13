# Brookhaven Stud City — atualização 85

Repositório: xivinims/Sub-kairo, branch roblox-publisher.
Alvo: universe 9421311218, place 118064584465155.
Publicador: projeto Vercel overyard-place-publisher.

A cidade substitui por completo as ilhas, a ponte e os caminhos secretos do arquipélago. O mapa importado conserva as ruas, os prédios, os interiores, os assentos e os volumes de água da base fornecida.

| Conteúdo | Asset |
| --- | --- |
| Base urbana inteira | 115377891476033 — brookhaven map 2020 |
| Tema, materiais Studs, árvores, flores e loja | 128071741625902 — Stud pack V1 |
| Arte dos nametags | 92018365421220 — Nametags+ |
| Grama realista preservada | 87377915371959 — SkinnedGrass / GrassCard |
| Efeito de vento preservado | 11946229834 — Wind Effects |

## Resultado da montagem

- Material Studs real do pacote aplicado à cidade. Vidros, neon e letreiros mantêm a aparência necessária à leitura.
- 81 árvores substituídas por árvores de blocos do Stud Pack, apoiadas em superfícies verificadas do mapa.
- 29 canteiros do pacote e uma Loja Stud numa área livre perto da praça central.
- 227 assentos preservados; 28 portas recebem abertura e fechamento com validação de distância e cuidado para não prender personagens.
- Os cinco volumes Water Block da base são convertidos diretamente em água nativa do Terrain, respeitando suas posições originais.
- Spawn na praça central, acima de uma superfície seca real.
- Nametags usam a interface fornecida, nomes de conta do Roblox e título Dono exclusivamente para UserId 8344738123 (@ch_ckz2n). Ícones de assinatura/verificação só aparecem quando as propriedades reais da conta indicam isso. Não há título promocional nem badge manual para IDs do autor do pacote.

## Grama e vento

A malha GrassCard e a interação com os pés são preservadas. As células ficam a cada 4 studs, com raízes individuais ajustadas por raycast nativo. O índice cobre os 149 terrenos verdes da cidade inteira, incluindo bordas; ruas, construções e água são descartadas nas consultas de cada raiz.

A grama carrega somente perto de cada jogador: raio 48/80 studs para toque/desktop, limite 640/1600 células, geração distribuída entre frames e remoção de células distantes. As consultas são refeitas quando a geometria chega por streaming. Esse limite não representa uma medição de FPS em telefone.

A amplitude do movimento foi reduzida em 10% na grama e nas árvores. O Wind Effects original continua usado para as linhas de vento. Os quatro climas individuais — Dia, Noite, Anoitecer e Chuva — continuam disponíveis, todos com vento.

## Iluminação

LightingStyle Realistic e PrioritizeLightingQuality são configurados na edição publicada. Há sombras globais, sombras das luzes da cidade, céu do Stud Pack, Atmosphere, ColorCorrection, Bloom, SunRays e reflexos/ondas da água nativa.

Estes são efeitos reais do motor gráfico do Roblox. Não há injeção externa de shaders. A composição foi verificada por propriedades do motor; não houve renderização no Roblox Studio nem teste visual em cliente real.

## Sistemas preservados

Avatar e roupa dos jogadores, inventário persistente, maçã de invisibilidade, vara/pescaria e painel administrativo exclusivo do dono continuam. A loja foi movida para a cidade; os menus não oferecem mais o caminho da ilha secreta. O barco e a ponte antigos foram removidos com o arquipélago.

Os oito scripts dos pacotes importados e a câmera de miniatura foram descartados antes de inserir a geometria. As portas e os nametags usam os controladores revisados deste projeto. Os comandos administrativos continuam validados pelo servidor e o chat continua no TextChatService do Roblox.

## Validação e publicação

install.luau exige a versão 84 como base e executa verificações antes de SavePlaceAsync. Não execute novamente depois da publicação.

verify.luau exige uma sessão nova da versão 85. publisher.cjs executa o instalador e essa verificação adicional no mesmo deploy, mantendo ROBLOX_API_KEY somente no ambiente do servidor.

A montagem de teste passou com 9.105 partes, 6.612 partes restantes marcadas com o material Studs, 19 scripts compilados, 18.190 pontos verdes conferidos sem lacuna no índice, 1.987 raízes válidas conferidas em 28 células e 309 células sobre ruas/telhados descartadas. Nametags, spawn, portas, permissões do dono e configuração Realistic também passaram.

audit.json registra a publicação e a conferência em sessão nova. A versão 84 continua no histórico como recuperação.
