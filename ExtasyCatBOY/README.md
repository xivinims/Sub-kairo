# ExtasyCatBOY

## Universo de destino

**Roblox Universe ID: `9421505041`**

Dashboard: https://create.roblox.com/dashboard/creations/experiences/9421505041/overview

A branch `ExtasyCatBOY` contém o instalador `deploy/deploy.mjs` e o workflow `.github/workflows/extasycatboy-deploy.yml`, disparado em push de arquivos de implantação ou manualmente. O instalador procura o Place ID inicial pela API do Roblox, valida `game.GameId` e `game.PlaceId` dentro da experiência e **altera apenas as três pastas próprias do projeto**. Usa Luau Execution e `AssetService:SavePlaceAsync()`; não sobrescreve o mapa por upload de um `.rbxlx` vazio.

**Permissões:** a GitHub Secret `ROBLOX_API_KEY` precisa autorizar o universo `9421505041` para Luau Execution e para salvar o lugar. Uma chave restrita a outro universo não funciona. Não coloque a chave no código público nem envie no chat.

**Se o lugar não for identificado automaticamente:** acesse Creator Dashboard > Places > lugar inicial > Configure. Copie o número após `/places/` na URL e cadastre-o como variável GitHub Actions `EXTASYCATBOY_PLACE_ID`; o instalador validará esse ID dentro do Roblox antes de alterar qualquer objeto.

**Estado:** o alvo está configurado na branch; publicação e funcionamento dentro do jogo exigem retorno confirmado da Action e testes no Roblox Studio.

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

**Importante:** criar a branch GitHub não publica automaticamente uma experiência. A Action específica faz a tentativa de implantação, sujeita à resolução do Place ID e às permissões da chave. Nenhuma Action de outros jogos é modificada.

### Animações pesquisadas

- R6 Movement Animations (Run, Walk, Etc.): https://create.roblox.com/store/asset/12177921457/
- Anim R6 Run Walk Idle Animation Pack: https://create.roblox.com/store/asset/114193651146315/
- Move Anim+ (R6 e R15): https://create.roblox.com/store/asset/129815376056645/

Esses são **modelos da Creator Store**, não IDs de AnimationTrack prontos para o jogo. Animações de terceiros exigem importação, inspeção de scripts e verificação de permissões de uso; **não foram implantadas automaticamente**. O jogo atualmente usa movimento R6 procedural próprio. Não foi verificada nenhuma autoria "3ppa".

## Compilar sem computador local

A GitHub Action `.github/workflows/extasycatboy-check.yml` verifica a contagem de diálogos, instala o **Rojo 7.7.1** e tenta gerar o artefato **ExtasyCatBOY-place**, contendo `ExtasyCatBOY.rbxlx`. Na aba **Actions**, abra a execução desta branch e, se o build terminar com sucesso, use **Artifacts** para baixar o lugar.

Esse `.rbxlx` é um lugar independente para teste. **Não sobrescreva o lugar original apenas para instalá-lo**: para preservar um mapa existente, use a sincronização seletiva do projeto Rojo, configurada com `$ignoreUnknownInstances`. A Action nunca publica diretamente no Roblox.

## Segurança e limites

- O servidor valida amizade e opera em nome do dono do NPC.
- As falas são controladas por biblioteca fixa; não existe chatbot generativo conectado.
- O texto da interface não é mostrado em nenhuma tela compartilhada. O chat nativo respeita restrições da plataforma e pode não estar disponível para leitura por scripts em alguns modos.
- Ao reutilizar uma experiência Roblox, use somente lugares que você pode editar.
- Precisa de teste real no Roblox Studio para confirmar aparência de acessórios, colisões e comportamento no universo de destino.
