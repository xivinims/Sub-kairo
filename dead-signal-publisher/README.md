# Fallout 5×5 — versão publicada 253

Branch ativa: `dead-signal-publisher`  
Experiência: `9421311218` · Place: `118064584465155`  
Build: `fallout-5v5-v1`

O hotel antigo foi substituído no place publicado. A versão 250 permanece no histórico do Roblox para recuperação.

## Conteúdo atual

- Fallout Map (FPS): 680 peças, usado no combate.
- Floating Lobby: intervalo e área segura; 25 peças de grama escurecidas.
- Abandoned Shop: substitui a loja original do lobby, com 31 peças.
- Avatar atual de ch_ckz2n (8344738123) em R6 na loja.
- Quatro animações R6 do Dynamic NPC Animations V2, reproduzidas a partir dos keyframes do pacote.
- Interface e módulo do NPC Dialogue System com “Sobre o jogo”, “Loja” e “Itens”.
- 14 produtos do pacote de armas: oito armas de fogo, faca, machado, granada, mina, kit médico e seringa. Barco e avião do pacote não são armas e não fazem parte do catálogo.

## Partidas

Servidores de até 10 jogadores; equipes Azul e Vermelho, com até cinco em cada. São necessários dois jogadores para começar. Partida de 600 segundos; intervalo total de 90 segundos, incluindo 12 segundos de resultado após cada partida.

O placar superior mostra as fotos de até cinco jogadores de cada lado, pontuação, relógio e indicação de queda/morte. A tela de resultado mostra o time vencedor e seus jogadores, ordenados por abates, com quedas, mortes e cura.

Dano, munição, recarga, distância, linha de visão, fogo amigo, proteção ao nascer, compras e recompensas são validados pelo servidor. Chegar a 20 PV ou menos sem sofrer dano fatal causa queda. Companheiros têm 20 segundos para reanimar; dano fatal elimina diretamente.

## Progressão e controles

Eliminação: 100 XP e 30 moedas. Eliminação com tiro na cabeça: +50 XP. Reanimação: 60 XP e 20 moedas. Cura também recompensa a vida recuperada de dano inimigo. Vitória: 150 XP e 120 moedas; participação: 50 XP e 40 moedas.

XP, moedas, compras e equipamento ficam no DataStore `FalloutProfiles_v1`, com trava por sessão, salvamento periódico e ao sair. Compras usam moedas ganhas no jogo; não usam Robux. Pistola compacta, faca e kit médico são gratuitos.

PC: clique para atirar, botão direito para mirar, R para recarregar, G para curar um aliado próximo. No celular há botões de tiro, mira, recarga e cura, além dos controles padrão do Roblox.

## Publicação e verificações

O publicador atual está em `fallout-release.mjs`. Baixa versões de assets fixadas por SHA-256, monta a carga, compila Luau e verifica regras. Em seguida usa o motor nativo do Roblox para montar mapa/loja/avatar, confirmar chão nos 20 pontos de nascimento e iniciar o código do servidor em sessão isolada.

Publicação pela API nativa `AssetService:SavePlaceAsync()`, preservando as unions da loja. Após publicar, confere o conteúdo da nova versão, define `serverSize=10` e reinicia os servidores.

Execução confirmada: https://github.com/xivinims/Sub-kairo/actions/runs/41282505420

Essas verificações não substituem uma partida real em cliente Roblox: controles de celular, enquadramento das armas, áudio e fluxo visual da loja ainda precisam dessa validação.

## Nametags — versão 252

Base: [Custom Nametags System, Bconggs](https://create.roblox.com/store/asset/72094860266497/Custom-Nametags-System). Preserva as fontes e contornos do template, adaptando-o para nome, título e nível. A própria tag fica oculta para o dono durante o jogo; os demais jogadores a veem até 65 studs, sem atravessar paredes.

- Menos de 2 horas acumuladas conectado: **Iniciante**.
- De 2 horas até antes de 29 horas: nome e nível, sem título.
- A partir de 29 horas: **Veterano**.
- Nível = 1 + piso(XP / 1.000). XP anterior também conta.
- Tempo começa a ser registrado nesta versão; versões anteriores não guardavam esse dado. Tempo offline não conta. Lobby e partidas contam.
- Migração no mesmo `FalloutProfiles_v1`, preservando XP, moedas, inventário e equipamento. Salva a cada 45 segundos, em compras, na saída e no fechamento do servidor. A tag atualiza a cada segundo e acompanha o respawn.
- Se o perfil não carregar, mostra o nome e `Nível —`, sem inventar um título.

[Publicação 252 e testes](https://github.com/xivinims/Sub-kairo/actions/runs/41299522661): limites de 2h/29h, migração, múltiplos salvamentos, reentrada, tempo offline, falha temporária de gravação e saída durante carregamento. Verificação nativa do template, inicialização e transições. Assinatura do conteúdo protegido igual antes/depois (`6158:268125991`): mapa e scripts de combate preservados. Não houve teste visual com cliente/jogadores nesta atualização.

O patch usa `nametag-release.mjs`; a reconstrução completa em `fallout-release.mjs` também inclui o mesmo pacote. Plugins de IK e IA não foram necessários para tags.

## Ajustes visuais e da loja — versão 253

- Placar compacto de 430 × 42, centralizado na área da barra superior do Roblox. Retratos continuam visíveis; o estado de queda usa uma linha dourada, sem o `X` sobre a foto. Em telas estreitas, o placar passa para a área segura logo abaixo da barra.
- Saldo em moedas inteiras no canto superior direito, com ícone, nível e XP. A tela da loja mostra o saldo separado do título.
- As 14 armas e itens agora têm silhuetas desenhadas na interface que continuam visíveis mesmo quando a prévia 3D não carrega. As dependências de malha/textura verificadas da pistola retornam 403 no Asset Delivery; o jogo não tenta contornar a permissão do criador.
- NPC R6 recriado com o avatar atual e colocado atrás do balcão, centralizado na janela e com os pés alinhados ao chão. Mantém o diálogo e as animações.
- Compra/equipamento salva saldo e item juntos. Se a gravação falhar, nenhuma moeda é descontada. Recompensas recebidas durante a gravação são mantidas. Moedas e XP aparecem como inteiros.
- [Execução e testes da versão 253](https://github.com/xivinims/Sub-kairo/actions/runs/41305265341): layout para paisagem e retrato, 10 retratos, 14 ícones, enquadramento de cada malha na câmera quando disponível, posição do NPC, recompensa e falha de gravação simulada, salvamento e leitura do saldo em uma chave temporária removida ao final. Assinatura do restante do lugar igual antes/depois (`6033:140825198`). Servidores reiniciados; limite 10 conferido. O fluxo visual ainda não foi testado com clientes em uma partida pública.
