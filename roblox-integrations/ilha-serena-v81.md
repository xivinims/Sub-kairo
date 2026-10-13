# Ilha Serena — atualização 81

Destino: universo `9421311218`, place `118064584465155`. Base publicada: 80. Branch: `roblox-publisher`, repositório `xivinims/Sub-kairo`. Publicação via projeto Vercel `overyard-place-publisher`.

As duas pontes preservam o arco de concreto claro, neon ciano, corrimãos dourados, quatro torres e esferas pulsantes da referência. O servidor considera todos os jogadores vivos: a aproximação a 130 studs mostra a ponte; sair além de 150 inicia a espera de 60 segundos. Uma nova aproximação cancela a espera. A montagem se repete; apenas as peças visuais são animadas. A colisão fica imóvel e desaparece junto com a ponte vazia.

O mapa recebe sete casas mobiliadas, 100 carvalhos de malha com raízes ajustadas ao solo, sete postes importados e um píer de madeira contínuo. A rampa segue o relevo da praia. As antigas vigas, estacas, corrimãos, postes e barco decorativo foram removidos. O barco importado oferece condutor e passageiro, controles para teclado, joystick e toque, verificação de água/obstáculos e retorno após 60 segundos vazio.

A pescaria oferece vara grátis no píer, linha e boia reais, janela de fisgada de três segundos, carpas com peso e venda por moedas na peixaria. O servidor valida água, distância, ferramenta, captura e venda. O cesto guarda até 12 peixes durante a sessão e mantém os peixes no respawn; venda-os antes de sair. Créditos de venda usam identificador único em `UpdateAsync`, sem pagamento duplicado em uma repetição após falha. As moedas e a maçã seguem o salvamento existente. A maçã custa 30 moedas, deixa o avatar invisível por três segundos e pode ser reutilizada a cada minuto.

A grama usa o modelo solicitado `87377915371959`, variante **Studio**, malha `80159239673273`, com verde RGB `(104,171,65)`. A cobertura contém **503 volumes e 44.994 raízes válidas**, distribuídos pelas áreas verdes da ilha; os pontos sobre areia, rocha, construções, caminhos ou água são excluídos. A posição de cada raiz acompanha a altura do terreno. O cliente carrega os volumes mais próximos primeiro e mantém a cobertura do mapa, com deformação por ossos, vento e recuperação após a passagem. Alcance visual: 215 studs em dispositivos de toque e 340 no desktop.

O vento usa os módulos **WindLines e WindShake do modelo solicitado `11946229834`**, com seus módulos auxiliares e créditos originais. A tela de demonstração do pacote não é instalada. Foram corrigidos a limpeza da inicialização, o tratamento de câmera ausente e a disputa com a antiga animação das folhas. Os módulos de SkinnedGrass preservam seus créditos, com correções para armazenamento, ajustes `false`, reaparecimento, alturas do terreno e deformação em distância zero. O contato parcial inclina as lâminas sem deslocar as raízes do solo.

ColorCorrection recebe contraste `.105` e saturação `.16` no sol, reduzida suavemente na chuva. SunRays ganha intensidade no amanhecer e pôr do sol. A água nativa utiliza transparência `.44`, reflexo `.38` e ondas de `.32` a `.60`, mais rápidas com chuva. O céu HD, o ciclo de dez minutos, a transição de oito segundos, o menu rolável e as escolhas pessoais de hora/clima são preservados.

## Modelos utilizados

| Modelo | Criador / créditos originais | Creator Store |
|---|---|---|
| Wind Effects | WindShake: boatbomber e CloneTrooper1019; octree: Quenty/howmanysmall | https://create.roblox.com/store/asset/11946229834/Wind-Effects |
| SkinnedGrass, variante Studio | módulo: xander22; octree: Quenty | https://create.roblox.com/store/asset/87377915371959/SkinnedGrass |
| Apple | kinglalu | https://create.roblox.com/store/asset/2759295720 |
| Streetlamp | AmirkhanMul | https://create.roblox.com/store/asset/14845961545 |
| Fishing Rod | BambooPandaTime | https://create.roblox.com/store/asset/75167845877982 |
| Boat | notorofkil | https://create.roblox.com/store/asset/9617142471 |
| Boat Dock | sSkyI4r | https://create.roblox.com/store/asset/17010090897 |
| Cottage House | paraghoul | https://create.roblox.com/store/asset/12346232595 |
| Log Cabin — Small, mobiliada | visionpsyche7 | https://create.roblox.com/store/asset/2109355142 |
| House Interior, móveis | BIond_e | https://create.roblox.com/store/asset/6319697240 |
| Realistic Oak Tree | Letaij | https://create.roblox.com/store/asset/128707014921507 |
| Fish, carpa | Biryuvignette | https://create.roblox.com/store/asset/9223655599 |

## Validação

Os modelos foram carregados no motor Roblox por `AssetService:LoadAssetAsync`. Geometria publicada: 4.960 partes, 407 MeshParts. O teste percorre 354 amostras nas pontes e no píer, verifica as sete entradas e os 100 carvalhos, confirma ferramentas sem ancoragem e sem colisão, e compila os 15 scripts de runtime.

Testes executam as fontes reais de cliente com tempo e entrada simulados em objetos nativos Roblox: clima pessoal, menu rolável, reconstrução das pontes, toque para lançar/puxar/vender, controles do barco, WindLines/WindShake e colisão/recuperação da grama. O carregador real da grama é executado sobre células da cobertura salva; a altura das raízes é conferida após a animação de entrada, durante o vento e no contato parcial. Os testes de servidor verificam prazo de desaparecimento, água, movimento, repetição de capturas/vendas, falha de salvamento sem duplicação de moedas, autoridade do condutor, obstáculos e retorno do barco.

O arquivo de instalação bloqueia a gravação se qualquer teste falhar. `verify81.luau` reabre a versão publicada e verifica a persistência dos modelos, configurações, scripts e cobertura. Não houve teste de imagem renderizada, FPS ou partida com jogadores reais no Roblox Studio/cliente nesta máquina; a comparação visual final e a condução física com avatar precisam desse ambiente.

As credenciais são lidas somente no servidor Vercel. Nenhum secret aparece no código ou nos relatórios. Os arquivos ficam em `roblox-integrations/` para não acionar o antigo workflow cujo secret não permite sessões Luau.
