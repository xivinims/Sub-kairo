# Ilha Serena — GrassCard e quatro climas, versão 83

Destino: universo 9421311218, place 118064584465155. Base: versão 82. Repositório xivinims/Sub-kairo, branch roblox-publisher. Publicação via Vercel overyard-place-publisher.

A grama passa da variante Studio para **GrassCard**, a outra variante do pacote SkinnedGrass 87377915371959. Malha utilizada: 117152506140384. Preserva a SurfaceAppearance original, sua transparência e os mapas PBR, sem alterar os arquivos de textura.

A cor da MeshPart e a tonalidade de SurfaceAppearance usam diretamente a cor do material Grass do Terrain: **RGB (90,142,64)**. A cor também é registrada no modelo/mapa.

Os 100 ossos da GrassCard têm posições iguais aos da variante anterior após a escala de 0,32. A cobertura de **15.124 volumes e 1.372.773 raízes**, espaçamento de quatro studs e carregamento por proximidade são mantidos. O template Studio anterior é removido; o cliente usa apenas GrassCard. Permanecem vento, deformação ao caminhar e limpeza das cópias distantes.

O sistema anterior de horário e tempo separados e o ciclo automático são substituídos por uma seleção individual com apenas quatro modos:

| Modo | Hora | Chuva | Vento |
|---|---:|---|---|
| Dia | 12:00 | Não | Brisa contínua |
| Noite | 23:00 | Não | Brisa contínua |
| Anoitecer | 18:18 | Não | Brisa contínua |
| Chuva | 15:12 | Sim | Vento mais forte |

O estado inicial da ilha é Dia. As escolhas mudam somente o ambiente local do jogador e permanecem durante respawns. O menu fica no canto superior direito, contém quatro botões e mantém rolagem e ajuste ao tamanho da tela. Chuva deixa de aparecer ao selecionar um modo seco. O Wind Effects 11946229834 é preservado em todos os modos.

## Verificação

- Igualdade das posições dos 100 ossos e da cor da grama/terreno.
- Auditoria da cobertura sobre 54.908 pontos de terreno verde.
- Fonte real do cliente da GrassCard executada em malhas/ossos nativos: 300 raízes adjacentes, alinhamento e reação à passagem, 30 ciclos de descarregamento e retorno.
- Fontes reais do menu e renderizador executadas em objetos Roblox com entrada simulada: exatamente quatro opções, seleção, rolagem, abertura/fechamento, iluminação/hora, chuva, vento em todos os modos e independência do estado do servidor.
- Compilação dos 15 scripts e preservação das 4.960 partes do mapa.
- Reabertura da versão publicada para conferir modelos, cores, cobertura e fontes.

Os testes são realizados no motor Roblox. Não houve comparação visual renderizada nem medição de FPS em um cliente/Studio nesta máquina.
