# Ilha Serena — atualização 80

Universe 9421311218 · Place 118064584465155 · branch roblox-publisher.

As duas pontes foram adaptadas do script fornecido pelo usuário: tablado em arco, concreto claro, neon ciano, corrimãos e anéis dourados, quatro torres por ponte, cabos principais, ancoragens, pendurais e esferas pulsantes. As proporções seguem o script, ajustadas ao vão existente de 62 studs e às alturas medidas nas margens.

A montagem começa para cada jogador quando a ponte entra em alcance (130 studs). As peças visuais descem em sequência usando TweenService com Back/Out e as esferas pulsam com Sine/InOut. Piso, proteções e torres possuem colisores fixos separados; a animação não desloca o piso de travessia. A flag AnimateConstruction permite mostrar a ponte pronta, mantendo as pulsações.

O ciclo automático agora dura 10 minutos; transições entre sol, nuvens e chuva duram 8 segundos. O botão CLIMA fica no canto superior direito, abaixo da loja. O painel ajusta seu tamanho à janela e usa ScrollingFrame com AutomaticCanvasSize e recorte dos itens.

Horário e tempo são escolhas independentes: automático, dia, noite, amanhecer, manhã, tarde, pôr do sol ou madrugada; tempo automático, sol, nublado ou chuva. É possível combinar noite com chuva. As preferências usam atributos locais do jogador e efeitos visuais próprios do cliente; nenhuma seleção muda os atributos de clima do mundo, os outros jogadores ou o saldo da loja. A chuva, a iluminação local, os postes e os vaga-lumes acompanham a seleção. Voltar a automático acompanha novamente o ciclo da ilha.

Validação no motor Roblox: 198 amostras de piso, verificação de inclinação e espaço para tronco/cabeça, colisores estáveis, compilação dos scripts, execução dos clientes com entrada e tempo simulados, rolagem, noite+chuva, dia, amanhecer, início e fim da montagem e pulsações. A simulação de TweenService verifica agendamento e alvos; não equivale a uma gravação visual do jogo nem mede desempenho em aparelhos reais. Total: 5.956 peças estáticas, com StreamingEnabled preservado. Maçã de 3 segundos/recarga de 60 segundos e céu HD permanecem na build.

O instalador autocontido bloqueia a execução fora do alvo e exige a versão 79 como base. A verificação da versão 80 não chama SavePlaceAsync. Publicação pelo projeto Vercel overyard-place-publisher, sem expor ROBLOX_API_KEY. Arquivos no diretório roblox-integrations evitam disparar o workflow antigo de roblox-publisher.
