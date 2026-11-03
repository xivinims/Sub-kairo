# Ilha Serena — correção da grama, versão 82

Destino: universo 9421311218, place 118064584465155. Base publicada: 81. Branch roblox-publisher, repositório xivinims/Sub-kairo. Publicação pelo Vercel overyard-place-publisher.

A versão 81 colocava volumes de grama a cada 22 studs com base na largura externa da MeshPart (32 studs). A medição dos ossos no motor Roblox mostrou que as raízes ocupam apenas 4,492 × 4,511 studs. Isso produzia os vãos relatados pelo jogador.

A nova distribuição usa espaçamento de **4 studs**, com sobreposição de 0,492 e 0,511 nas bordas. Preserva a grama fina Studio do modelo 87377915371959, malha 80159239673273, cor RGB (104,171,65), o vento solicitado e a deformação ao caminhar.

A ilha recebe **15.124 posições de volumes e 1.372.773 raízes válidas**, comparadas com 503 volumes e 44.994 raízes na versão 81. A densidade da malha de distribuição aumenta 30,25 vezes. A cobertura respeita a superfície real do terreno e exclui água, caminhos, construções e rocha.

As alturas são armazenadas em 119 blocos compactos, com resolução de um centímetro e marcação de raízes excluídas. O cliente cria a grama fina por proximidade, sem clonar os 15 mil volumes de uma vez: raio de 48 studs em dispositivos de toque, 80 no desktop, com margem de descarregamento de seis studs. A cobertura está definida em toda a ilha e se carrega conforme o jogador se desloca. Limites de instâncias ativas: 640 volumes no toque e 1.600 no desktop. O teste mediu no máximo 577 volumes residentes no toque.

Ao descarregar um volume, o módulo libera seus ossos da árvore espacial, registros de contato e animações. A lógica original do SkinnedGrass e os créditos de xander22 e Quenty são preservados.

## Validação

- Medição dos limites reais das raízes, independente da caixa externa da peça.
- 54.908 amostras de terreno verde verificadas: nenhuma amostra ficou sem raiz de grama a até 1,25 stud; maior distância medida de 0,984 stud, junto a uma borda de obstrução.
- Fonte real do cliente executada em objetos nativos Roblox com entrada de toque simulada: três volumes adjacentes, 300 raízes, alinhamento ao solo e deformação ao caminhar.
- Trinta ciclos de saída e retorno: descarregamento completo, retorno dos volumes e nenhum osso ou registro de animação acumulado.
- Codificação e leitura das alturas sem perda; compilação dos 15 scripts de runtime.
- Preservação das 4.960 partes do mapa, pontes, casas, barco, pescaria, loja, vento e clima.

O instalador só grava depois dos testes. A verificação abre uma nova sessão da versão 82 e confere cobertura, fontes salvas, alturas e continuidade entre volumes.

Não houve comparação por imagem renderizada ou medição de FPS num cliente Roblox nesta máquina. Os limites de proximidade reduzem a carga de instâncias; o desempenho real no celular precisa ser conferido em partida.
