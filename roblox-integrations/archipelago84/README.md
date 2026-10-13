# Arquipélago Serena — versão 84

Substitui a ilha anterior por duas ilhas públicas próximas e uma ilha secreta distante, mantendo os sistemas de avatar R6, clima individual, inventário e pescaria existentes.

Alvo: universe `9421311218`, place `118064584465155`. Repositório `xivinims/Sub-kairo`, branch `roblox-publisher`. Publicador: projeto Vercel `overyard-place-publisher`; a chave permanece somente no ambiente do servidor.

## Modelos reais utilizados

| Uso | Asset |
| --- | --- |
| Ilha pública do farol | 13138901447 — Low-Poly-Island |
| Ilha pública verde | 8143419396 — Island |
| Ilha escondida | 139196111 — The Sun's Island Map |
| Viajante R6 e arte do diálogo | 80608769509945 — NPC Dialogue System |
| Pedras de ativação | 110144096035671 — Mystical Spawn Point |
| Seis bancos com assentos | 741384218 — Generic Park Bench |
| Vara de pesca comprável | 11316383656 — Fishing Rod, @mamaJukerson |
| Arte do painel administrativo | 111176085924966 — o conteúdo entregue pelo asset se identifica como Admin Panel V6 |
| Grama preservada | 87377915371959 — SkinnedGrass / GrassCard |
| Vento preservado | 11946229834 — Wind Effects |

O URL usado para “pessoa” apontava novamente à ilha 8143419396, que não contém NPC humano. O personagem utilizado é o NPC R6 real do pacote de diálogo pedido, sentado sob um coqueiro importado.

## Como jogar

- Duas ilhas públicas alinhadas às praias com nível do mar Y=0. A ilha secreta fica distante do conjunto principal.
- Suba numa das duas pedras místicas na margem para montar a ponte de pedra em arco. O piso permanece fixo durante a animação. A ponte desaparece somente após 60 segundos sem pessoas na ponte nem sobre as pedras.
- Toque/clique duas vezes no Viajante, próximo ao coqueiro, em até 0,7 segundo. O diálogo oferece maçã, vara, venda dos peixes, acesso à ilha secreta e fechar. A ilha secreta tem uma opção de retorno.
- Maçã: 30 moedas, invisibilidade de 3 segundos, intervalo de 60 segundos. Vara: 20 moedas. Novos perfis começam com 50 moedas e recebem 10 moedas por minuto. Compras são persistidas quando o DataStore está disponível.
- O píer de madeira liga uma praia baixa ao embarque. O barco nasce em água livre; desembarcar perto do píer retorna à praia.
- Dia, Noite, Anoitecer e Chuva continuam individuais, todos com vento. Os menus e as escolhas do diálogo têm rolagem no celular.
- A grama usa a mesma cor do chão verde, malha real GrassCard, células a cada 4 studs e raízes ajustadas à superfície. Praia, água e construções não recebem grama. O carregamento é local: raio 48/80 studs e limite 640/1600 células para toque/desktop.

## Painel do proprietário

Exclusivo de `@ch_ckz2n`, UserId `8344738123`, confirmado pelo Roblox e igual ao criador da experiência.

O botão abre voo, seleção e deslocamento de árvores/bancos/objetos decorativos, desfazer, trazer jogador, ir ao jogador, expulsar, banir por 24 horas e remover banimento. A validação ocorre no servidor. Terreno, ponte e NPC ficam protegidos; o banimento não inclui contas alternativas.

O anúncio usa `TextChatService:SendAsync` e ganha prefixo “Adm:” somente quando o remetente tem o UserId do proprietário. Filtros, verificações de idade e permissões de comunicação do Roblox continuam valendo. Não há transmissão de texto livre por RemoteEvent nem desvio das restrições de chat.

Foram removidos os caminhos de execução dos modelos importados. O pacote administrativo mantém sua arte de interface, com comandos próprios vinculados ao proprietário; o diálogo conserva NPC/interface e usa uma adaptação com texto em português e limpeza dos eventos.

## Publicação e verificação

`install.luau` é autocontido e exige a versão 83 como base; instala e testa tudo antes de `SavePlaceAsync`. Não é para executar de novo em uma versão posterior. A versão 83 preserva o mapa anterior no histórico do Roblox.

`verify.luau` é somente leitura e verifica uma sessão nova da versão 84. `audit.json` registra os resultados nativos e a publicação.

Verificações executadas: geometria, água sob o embarque, pisos e inclinação da ponte, permanência de 60 segundos, gatilho sobre a pedra, diálogo por dois cliques, migração dos itens, vara sem peças ancoradas, comandos administrativos bloqueados para outras contas, interface real do proprietário e compilação dos 20 scripts ativos. Comandos reais de chat, expulsão e banimento não foram enviados durante os testes.

Limitação: estas são verificações no motor/objetos/scripts do Roblox por sessões Luau. Não houve renderização no Roblox Studio, teste visual em cliente real ou medição de FPS em telefone.
