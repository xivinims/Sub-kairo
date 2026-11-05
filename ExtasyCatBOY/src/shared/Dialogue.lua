-- Falas originais. 16 contextos com 10 bases x 17 finais = 2720 combinacoes,
-- mais de 100 saudacoes originais x 4 finais. Total acima de 3.000 combinacoes possiveis.
-- O sistema NAO envia o texto do jogador a servicos externos e NAO imita falas reais do amigo.
local D = {}
local rng = Random.new()
local endings = {
    "", " :3", " hehe.", " ^^", " rsrs.", " tá?", " viu?", " ✨",
    " miau!", " au au!", " por favorzinho.", " eu acho.", " hihi.",
    " *balança a cauda*", " *pisca devagar*", " *inclina a cabecinha*", " ♪",
}
local helloEndings = {"", " :3", "!!", " hehe!"}
local hello = {
    "Oi",
    "Oie",
    "Oieee",
    "Oiiii",
    "Olá",
    "Oláá",
    "Hey",
    "Ei",
    "Opa",
    "Oi oi",
    "Oizinho",
    "Oie:3",
    "Hiii",
    "Bom dia",
    "Boa tarde",
    "Boa noite",
    "Oioi",
    "Heey",
    "Hêê",
    "Alô",
    "Tudo bem?",
    "Cheguei!",
    "Tcharam!",
    "Você apareceu!",
    "Eu tava te esperando!",
    "Eeeeei",
    "Ah, é você!",
    "Olha só quem chegou!",
    "Oiii, {user}!",
    "Oieee, {user}, tudo bem com você?",
    "Olá, {user}!",
    "Oi, oi, {user}!",
    "Êêê, {user} chegou!",
    "Oiê, {user}!",
    "Oi, humano!",
    "Meu humano favorito chegou!",
    "Cof cof... oi!",
    "Oi, foi mal, me distraí.",
    "H-hm... oi...",
    "O-oi...",
    "Oie, não me assusta assim!",
    "Oi, que surpresa!",
    "Opa, olha quem tá aqui!",
    "Oi, como foi seu dia?",
    "Oi, tudo certinho?",
    "Oi, quer conversar?",
    "Oi, vem cá!",
    "Oi, vamos passear?",
    "Oie, me conta uma novidade!",
    "Oie, tô ouvindo!",
    "Oiii, ouvi você chegando!",
    "Oi, você me chamou?",
    "Oi, pode falar!",
    "Oie, eu tava cochilando.",
    "Oi, acordei!",
    "O-olá, que vergonha...",
    "Oi, minhas orelhas te ouviram!",
    "Ei, o que aconteceu?",
    "Olha só, uma visita!",
    "Oie, faz tempo!",
    "Oi de novo!",
    "Olá de novo, {user}!",
    "Oizinho de novo!",
    "Oi, me dá atenção um pouquinho?",
    "Oi, dá pra brincar agora?",
    "Oi, posso acompanhar?",
    "Opa, que vento gostoso!",
    "Oie, eu tava olhando as nuvens.",
    "Opa, chegou na hora certa!",
    "Oi, que alegria te ver por aqui!",
    "Ei, quer ver uma coisa?",
    "Oiii, tenho uma ideia!",
    "Oi, tava pensando em você chegar.",
    "E aí, {user}?",
    "E aí, tudo bem?",
    "Opa, como você tá?",
    "Oi, tá me ouvindo?",
    "Oiii, meu humor melhorou!",
    "Olá, qual o plano de hoje?",
    "Oi, onde vamos hoje?",
    "Olá, gostei desse lugar!",
    "Ei, não vai embora tão cedo!",
    "Opa, bora explorar!",
    "Oie, dá um oi de volta!",
    "Oi, acabei de aparecer!",
    "Hm? Oi!",
    "Hã? Você me chamou?",
    "Oie... tava distraído.",
    "Ah, oi! Nem percebi você.",
    "Ei, ei, ei!",
    "Oi, olha minhas orelhas!",
    "Oie, *balança a cauda*",
    "Opa, *inclina a cabecinha*",
    "Oi, que dia bom!",
    "Olá, quer conhecer a praça?",
    "Oi, bora caminhar!",
    "Oi, eu tô aqui!",
    "Oi, eu não esqueci você!",
    "Oi, tenho uma história curtinha!",
    "Oiii, que saudade das nossas brincadeiras!",
    "Ei, vamos descobrir algo novo?",
    "Oi, tá tudo tranquilo?",
    "E aí, amigão?",
    "Oie, tá precisando de companhia?",
    "Oi, tô meio tímido hoje.",
    "Oi, hoje acordei animado!",
    "Opa, sem sustos dessa vez!",
    "Olha só quem apareceu por aqui!",
    "Oii, {user}, que bom te ver!",
    "Eeei, você voltou!",
    "Oi, quer jogar comigo?",
    "Olá, {user}, eu estava aqui!",
    "Oi, queria te dar um oi especial!",
    "Oieee, já decidiu o que vamos fazer?",
    "Oi, olha a hora!",
    "Oi, tem alguma novidade?",
    "Oie, fico feliz que apareceu!",
    "Oláá, eu estava passeando!",
    "Oie:3 Como tá indo?",
    "Oi, escolhe um caminho!",
    "Oi, quer explorar a casa?",
    "Oi, estou praticando minhas falas!",
    "Oi, quase esbarrei na porta!",
    "Opa, tenho uma pergunta boba!",
    "Oie, será que hoje tem petisco?",
    "Ei, olha aqui!",
    "Oi, agora somos uma equipe!",
}
local replies = {
    afirmacao = {
        "Claro!", "Uhum, claro que sim.", "Com certeza!", "Sim sim!", "Pode ser!",
        "Tá combinadinho.", "Eu topo!", "Acho que sim!", "Parece ótimo!",
        "Fechou, vamos nessa!",
    },
    negacao = {
        "Acho melhor não.", "Agora não, desculpinha.", "Hmm, não tenho certeza.",
        "Não consigo fazer isso.", "Eu prefiro outra coisa.", "Dessa vez não.",
        "Nããão, hehe.", "Talvez depois.", "Acho que não dá.", "Podemos tentar algo diferente?",
    },
    desconhecido = {
        "Hmm, não sei.", "Eu sou um gato ou cachorro, não sei de tudo não, hum.",
        "Essa você me pegou!", "Não faço ideia, pra falar a verdade.",
        "Acho que não aprendi isso ainda.", "Eu queria saber responder!",
        "Meu cérebro de bichinho travou.", "Desculpa, não sei explicar.",
        "Vou ficar te devendo essa.", "Hmm... essa pergunta é difícil pra mim.",
    },
    bemestar = {
        "Tô bem! E você?", "Tudo certinho por aqui!", "Tô de boas.",
        "Hoje estou bem animadinho.", "Tava quase dormindo, mas tô bem.",
        "Melhorei agora que tem companhia.", "Uma paz, sabe?",
        "Tô pensando em dar uma voltinha.", "Um pouquinho de sono, só.",
        "Tenho energia pra passear!",
    },
    agradecimento = {
        "De nada!", "Não precisa agradecer!", "Tamo junto.",
        "Fico feliz em ajudar!", "Imagina!", "Disponha.",
        "Ajudar foi bem legal.", "Foi nadinha.", "Sempre que eu puder!",
        "Obrigadinho você também.",
    },
    despedida = {
        "Tchauzinho!", "Até logo!", "Vai com cuidado.", "Volta depois!",
        "Foi legal conversar.", "Vou sentir falta da nossa conversa.",
        "Até a próxima!", "Bye bye!", "Vou ficar por aqui.",
        "Te vejo depois!",
    },
    brincadeira = {
        "Bora brincar!", "Eu quero participar!", "Qual brincadeira?",
        "Eu ganharia no pega-pega!", "Desafio aceito!", "Agora fiquei curioso.",
        "Vamos explorar?", "Pode ser esconde-esconde!", "Tenho uma ideia de jogo.",
        "Tenho um montão de energia!",
    },
    elogio = {
        "Valeu!!", "Você me deixa sem jeito.", "Eita, obrigadinho.",
        "Assim eu fico todo tímido.", "Eu me esforcei, viu?",
        "Você é muito gentil.", "Vou guardar esse elogio.",
        "Minha cauda até balançou.", "Agora fiquei feliz.",
        "Eu também gostei do resultado!",
    },
    humor = {
        "Kkkkk, essa foi boa!", "Eu não tava preparado!", "Hehehe.",
        "Essa piada me pegou.", "Tô rindo aqui!", "Você é engraçado.",
        "Aí não vale, hahaha!", "Que bobagem boa.", "Conta outra!",
        "Essa eu vou lembrar.",
    },
    comida = {
        "Será que tem petisco?", "Hmm, deu fome!", "Eu queria um lanchinho.",
        "Tem alguma coisa gostosa?", "Que cheirinho bom!", "Hora do lanche?",
        "Vou procurar uma tigelinha.", "Não esquece da água!", "Biscoitinho seria ótimo.",
        "Acho que ouvi minha barriga.",
    },
    sono = {
        "Tô quase cochilando.", "Um soninho não faz mal.", "Queria uma almofada.",
        "Mais cinco minutinhos...", "O sofá parece confortável.",
        "Vou tirar uma soneca logo.", "Hoje o sono venceu.",
        "Me acorda depois?", "Dormir é uma arte.", "Hora de descansar um pouco.",
    },
    clima = {
        "O céu parece bonito.", "Eu gosto de dias tranquilos.", "Queria ver as nuvens.",
        "Se chover, vamos pra dentro.", "Dia perfeito pra passear.",
        "Será que vai fazer sol?", "O vento mexe minhas orelhas.",
        "Não sei a previsão do tempo.", "Eu adoro uma sombra fresquinha.",
        "Vamos olhar pela janela?",
    },
    amizade = {
        "Amigos são muito importantes.", "Você tem amigos legais?",
        "É bom ter companhia.", "Eu gosto de brincar com a turma.",
        "Podemos chamar alguém para explorar.", "Amizade é ajudar um ao outro.",
        "O mundo é mais divertido com amigos.", "Que legal conhecer gente nova!",
        "Cada amigo tem seu jeitinho.", "É divertido passear junto.",
    },
    emocao = {
        "Parece um dia complicado.", "Quer conversar um pouquinho?",
        "Posso ficar aqui com você.", "Às vezes acontece.",
        "É bom descansar quando precisa.", "Obrigado por me contar.",
        "Espero que as coisas melhorem.", "Posso tentar te distrair.",
        "Vamos com calma.", "Tudo bem ficar quietinho agora.",
    },
    raiva = {
        "Hmph! Não gostei disso.", "Grr... brincadeirinha.", "Tô emburradinho.",
        "Vou cruzar os braços!", "Isso foi injusto!", "Eu queria reclamar.",
        "Tá, já passou.", "Não mexe nas minhas orelhas!",
        "Vou fazer cara de bravo.", "Eu vou contar até três.",
    },
    convite = {
        "Vamos lá!", "Eu te acompanho.", "Pode contar comigo.",
        "Bora dar uma volta!", "Eu sigo você!", "Onde vamos?",
        "Quero conhecer esse lugar.", "Tô pronto para sair.",
        "Só preciso ajeitar as orelhinhas.", "Vamos explorar juntos!",
    },
}
local order = {
    "afirmacao", "negacao", "desconhecido", "bemestar", "agradecimento", "despedida",
    "brincadeira", "elogio", "humor", "comida", "sono", "clima",
    "amizade", "emocao", "raiva", "convite",
}
local rules = {
    agradecimento = {"obrigad", "valeu", "thanks"},
    despedida = {"tchau", "adeus", "até logo", "bye", "fui"},
    bemestar = {"tudo bem", "como você", "como vc", "como cê", "como tá", "como ta"},
    comida = {"comida", "comer", "lanche", "fome", "petisco"},
    sono = {"dormir", "sono", "cansad", "cochilar", "descansar"},
    clima = {"clima", "chuva", "sol", "tempo hoje", "frio"},
    amizade = {"amizade", "amigo", "amiga", "amigos"},
    emocao = {"triste", "sozinh", "chatead", "chor", "ansios"},
    raiva = {"bravo", "raiva", "irritad", "grr", "odeio"},
    brincadeira = {"brincar", "jogar", "pega-pega", "esconde-esconde"},
    elogio = {"fofo", "lindo", "bonito", "legal", "adorável"},
    humor = {"kkkk", "haha", "piada", "engraçad", "rsrs"},
    convite = {"vamos", "vem comigo", "bora", "passear", "segue"},
    afirmacao = {"concorda", "aceita", "pode", "consegue"},
    negacao = {"não quer", "não pode", "recusa"},
}
local personal = {
    timido = {"E-eh... ", "", "A-ah... "},
    tsundere = {"N-não é que eu queira, mas... ", "Hmph! ", ""},
    brincalhao = {"Hehehe! ", "Eba! ", ""},
    sonolento = {"Zzz... ", "Hmm... ", ""},
    bravo = {"Hmph! ", "Grr... ", ""},
    gentil = {"", "Com calma: ", ""},
}
local recentByKey = {}
local function pick(options)
    return options[rng:NextInteger(1,#options)]
end
local function infer(message)
    local q = string.lower(string.sub(message or "", 1, 200))
    -- Saudacoes so quando a mensagem e curta; perguntas complexas caem no desconhecido.
    if #q < 32 then
        for _, prefix in ipairs({"oi", "olá", "ola", "oie", "hey", "opa", "bom dia", "boa noite", "boa tarde"}) do
            if string.sub(q, 1, #prefix) == prefix then return "saudacao" end
        end
    end
    for _, key in ipairs(order) do
        for _, word in ipairs(rules[key] or {}) do
            if string.find(q, word, 1, true) then return key end
        end
    end
    return "desconhecido"
end
function D.CountVariations()
    local total = #hello * #helloEndings
    for _, key in ipairs(order) do total += #replies[key] * #endings end
    return total
end
function D.Respond(message, species, personality, key, playerName)
    local kind = infer(message)
    local sentence
    for _ = 1, 5 do
        if kind == "saudacao" then
            sentence = pick(hello) .. pick(helloEndings)
        else
            sentence = pick(replies[kind]) .. pick(endings)
        end
        if sentence ~= recentByKey[key or ""] then break end
    end
    if playerName and type(playerName) == "string" then
        local shortName = string.sub(playerName, 1, 24)
        sentence = sentence:gsub("{user}", function() return shortName end)
    else
        sentence = sentence:gsub("{user}", "amigo")
    end
    recentByKey[key or ""] = sentence
    -- Substituir final incompatível com especie.
    if species == "cat" then sentence = sentence:gsub("au au!", "miau!")
    else sentence = sentence:gsub("miau!", "au au!") end
    -- Nao sobrepor saudacoes simples com prefixos longos.
    if personality and personal[personality] then
        if rng:NextNumber() < 0.23 then sentence = pick(personal[personality]) .. sentence end
    end
    return sentence, kind
end
return D
