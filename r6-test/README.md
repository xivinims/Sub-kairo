# Teste R6: somente FREE R6 Wall Run (v7)

O usuário pediu retirar todos os outros pacotes. O **único script personalizado em StarterCharacterScripts** é agora o `Wallrun` do arquivo original `FREE R6 Wall Run(4).rbxm`, com seus 10 ModuleScripts originais e suas quatro Animation IDs originais. Os hashes SHA-256 dos onze arquivos Luau foram extraídos diretamente do upload novo e conferidos antes da cópia. Nenhuma linha do código original foi editada.

Foram retirados do jogo de teste: R6Locomotion, Naruto Animate personalizado, animações de outros arquivos, ambos os botões de troca de grupos, emotes de outros pacotes, controles de sprint extras, scripts dos outros modelos, interfaces, ferramentas e seis NPCs de treinamento. Os componentes do mapa de teste e as paredes para wallrun foram preservados. O avatar do próprio jogador continua sendo criado em R6 pelo pequeno script de spawn no servidor. Nenhum outro controlador de animação é adicionado; o pacote original cobre apenas movimentos de parede, não caminhada normal.

**Atenção:** as quatro animações de parede desse pacote ainda fazem referência aos IDs privados/originais. Se o Roblox não autorizar esses assets no jogo, o código do Wallrun executará a movimentação, mas as poses não serão mostradas. Os IDs não foram falsificados nem substituídos por animações genéricas. Publicar ou liberar permissão para o universo seria necessário para usá-las com a implementação original.

Para reconstruir: `lune run r6-test/repair-avatar.luau` e depois `lune run r6-test/check.luau`. O CI publica apenas a experiência privada após salvar backup e oferece rollback se a verificação nativa falhar. O teste nativo registra a duração de cada uma das quatro animações, distinguindo assets acessíveis dos bloqueados.
