# ExtasyCatBOY

Jogo Roblox de companheiros virtuais **catboy/dogboy** construídos usando **somente avatares de pessoas da lista de amizades do jogador**. NPCs são personagens fictícios inspirados nos avatares, não mensagens da conta real.

## O que está implementado

- Menu mobile/desktop para buscar um amigo e escolher gatinho/cachorrinho.
- Validação de amizade no servidor com Player:IsFriendsWithAsync() antes de criar o NPC.
- Aparência R6 do amigo com HumanoidDescription, orelhas e cauda tridimensionais.
- Seis personalidades: tímido, tsundere, brincalhão, sonolento, bravinho, gentil.
- Caminhada com balanço de braços/pernas e cauda, inclinação da cabecinha, movimento de cabeça; sem depender de ID de asset externo.
- NPC segue o dono, volta quando se distancia e tem ProximityPrompt para conversar.
- Biblioteca local de 2.832 combinações possíveis: 16 categorias x 10 bases x 17 finais, mais 28 saudações x 4 finais = 2.832. Não são 2.832 respostas escritas manualmente; são composições das frases. Ao não saber responder, usa uma das 10 falas de desconhecimento.
- Chat pelo campo da interface, com suporte experimental a mensagens entregues pelo TextChatService quando a plataforma permite leitura.
- Conversas como bolhas locais sobre o NPC, sem replicar texto cru do jogador a outras pessoas.
- Persistência DataStore de amigo escolhido, espécie e personalidade; remove personagem quando amizade é desfeita.
- Jardim/praça/casinhas decorativas gerados automaticamente **apenas em lugares quase vazios**. Mapas com mais de 12 BaseParts são preservados.
- Nenhum código do jogo anterior é apagado nem modificado.

## Abrir e aplicar a uma experiência

Projeto Rojo em **ExtasyCatBOY/default.project.json**:

1. No Roblox Studio, abra a experiência de destino **como editor autorizado**.
2. Faça uma cópia de segurança do lugar.
3. Instale/abra Rojo, aponte para esta pasta e sincronize o projeto. Os scripts são instalados em ReplicatedStorage/ExtasyShared, ServerScriptService/ExtasyServer e StarterPlayer/StarterPlayerScripts/ExtasyClient.
4. Habilite acesso à API de serviços do Studio se quiser testar DataStore no Studio. Quando publicar, mantenha a experiência privada até concluir os testes.
5. No Play Test, teste amizades, carregar a aparência, caminhar, conversar, recriar o NPC, sair/entrar e mobile.

**Importante:** criar a branch GitHub **não publica nem modifica o universo Roblox**. O link compartilhado para a experiência é insuficiente para obter acesso de edição ou confirmar os IDs de Universe/Place. Para publicar por API, serão necessários IDs do universo e do lugar corretos e credenciais Roblox com permissão de escrita. Não associe esta branch à rotina de publicação de outra experiência.

### Animações pesquisadas

- R6 Movement Animations (Run, Walk, Etc.): https://create.roblox.com/store/asset/12177921457/
- Anim R6 Run Walk Idle Animation Pack: https://create.roblox.com/store/asset/114193651146315/
- Move Anim+ (R6 e R15): https://create.roblox.com/store/asset/129815376056645/

Esses são **modelos da Creator Store**, não IDs de AnimationTrack prontos para o jogo. Animações de terceiros exigem importação, inspeção de scripts e verificação de permissões de uso; **não foram implantadas automaticamente**. O jogo atualmente usa movimento R6 procedural próprio. Não foi verificada nenhuma autoria "3ppa".

## Segurança e limites

- O servidor valida amizade e opera em nome do dono do NPC.
- As falas são controladas por biblioteca fixa; não existe chatbot generativo conectado.
- O texto da interface não é mostrado em nenhuma tela compartilhada. O chat nativo respeita restrições da plataforma e pode não estar disponível para leitura por scripts em alguns modos.
- Ao reutilizar uma experiência Roblox, use somente lugares que você pode editar.
- Precisa de teste real no Roblox Studio para confirmar aparência de acessórios, colisões e comportamento no universo de destino.
