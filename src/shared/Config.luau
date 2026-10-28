local Config = {}
Config.Title = "Bramble’s Sprout"
Config.Chapter = "DEAD SIGNAL"
Config.Studio = "Aurivane Works"
Config.SaveKey = "BrambleSproutChapter1_v1"
Config.MaxReach = 65
Config.InteractionCooldown = 0.4
-- Upload the supplied files to the owning Roblox experience, then put the IDs here.
-- 0 deliberately disables an unconfigured asset; GitHub URLs are not Roblox content IDs.
Config.Assets = {
 StudioLogo = 0, ChapterLogo = 0,
 Ambient = 0, Pursuit = 0, Radio = 0, Relay = 0, OpeningVoice = 0,
 Voices = {},
}
Config.Sectors = {
 {Name="CONSERVATÓRIO", Goal="Encontre o crachá e o fusível. Restaure o circuito.", Protocol="Crachá e fusível na recepção. Ligue o quadro. Terminal 1: azul. Terminal 2: vermelha. Pode três flores, ligue 3 com azul. Libere a saída com a vermelha.", Lines={"23:17 / CONSERVATÓRIO AURORA", "SEGURANÇA: Não responda às vozes do rádio.", "VOCÊ: Eu só vim desligar a transmissão."}},
 {Name="ARQUIVO DE BOTÂNICA", Goal="Recupere três páginas e abra o cofre.", Protocol="O primeiro viveiro abriu em 1784. O cofre conserva esse ano. Recupere as três páginas antes de abrir.", Lines={"ARQUIVO DE BOTÂNICA", "ARQUIVISTA: Os nomes foram apagados. As páginas ainda lembram.", "VOCÊ: Mil setecentos e oitenta e quatro… o primeiro viveiro."}},
 {Name="CASA DAS MÁQUINAS", Goal="Equilibre válvulas, pressão e energia.", Protocol="Abra ENTRADA, RETORNO e RESERVA. DESVIO fechado. Pressão 6. Três células. Partida com a vermelha.", Lines={"CASA DAS MÁQUINAS", "SEGURANÇA: Entrada, retorno e reserva. O desvio fica fechado.", "VOCÊ: Isso não é só uma máquina. Está respirando."}},
 {Name="GALERIA DE PROPAGAÇÃO", Goal="Encontre seis sementes no labirinto.", Protocol="As sementes estão em pontas mortas. A quarta desperta o perseguidor. Correr faz barulho. Agache e quebre a linha de visão para despistá-lo.", Lines={"GALERIA DE PROPAGAÇÃO", "RÁDIO: Seis sementes. Não deixe nenhuma acordada.", "VOCÊ: Tem alguma coisa andando entre as cercas."}},
 {Name="ARQUIVO DE ECOS", Goal="Reconstrua o sinal e apague a matriz.", Protocol="Tons: 2, 4, 1, 3, 2, 1. Cada lâmpada inverte a si e as vizinhas. Apague todas. Os dois circuitos precisam estar resolvidos.", Lines={"ARQUIVO DE ECOS", "RÁDIO: Dois. Quatro. Um. Três. Dois. Um.", "VOCÊ: Essa gravação… ainda nem aconteceu."}},
 {Name="RAIZ CENTRAL", Goal="Isole e corte quatro raízes.", Protocol="Primeiro isole cada raiz com azul. Depois corte com vermelho. Quatro pares liberam o elevador. Cada corte acorda as raízes.", Lines={"RAIZ CENTRAL", "SEGURANÇA: Isole com azul. Corte com vermelho.", "RÁDIO: Você corta as flores. Eu fico com as raízes."}},
 {Name="ESTAÇÃO DE TRANSMISSÃO", Goal="Recolha quatro fusíveis e alinhe as antenas.", Protocol="Quatro fusíveis. Alinhe as antenas em 3, 1, 4. Desligue a chave mestre com a vermelha. Depois entre no elevador.", Lines={"ESTAÇÃO DE TRANSMISSÃO", "VOCÊ: O elevador não desligou o sinal. Preciso chegar à antena.", "RÁDIO: A última porta abre para os dois lados."}},
}
return Config
