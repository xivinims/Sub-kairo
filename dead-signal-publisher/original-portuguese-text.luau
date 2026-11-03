-- Lightweight client-side Portuguese text pass for the mansion UI and world prompts.
local Players=game:GetService('Players')
local player=Players.LocalPlayer
local gui=player:WaitForChild('PlayerGui')
local words={
 ['play']='Jogar',['play alone']='Jogar',['new game']='Novo jogo',['continue']='Continuar',['continue game']='Continuar jogo',['resume']='Continuar',
 ['main menu']='Menu principal',['menu']='Menu',['exit to menu']='Voltar ao menu',['mystery']='Mistério',['chapter']='Capítulo',['episode']='Episódio',
 ['settings']='Configurações',['options']='Opções',['controls']='Controles',['graphics']='Gráficos',
 ['audio']='Áudio',['music']='Música',['ambience']='Ambiente',['ambient sound']='Som ambiente',
 ['sound effects']='Efeitos sonoros',['language']='Idioma',['english']='Inglês',
 ['brazilian portuguese']='Português do Brasil',['fullscreen']='Tela cheia',
 ['resolution']='Resolução',['quality']='Qualidade',['ultra']='Ultra',
 ['apply']='Aplicar',['reset to defaults']='Restaurar padrões',['restore defaults']='Restaurar padrões',
 ['back']='Voltar',['quit']='Sair',['exit']='Sair',
 ['yes']='Sim',['no']='Não',['on']='Ligado',['off']='Desligado',['enabled']='Ativado',['disabled']='Desativado',
 ['loading']='Carregando',['loading...']='Carregando…',['loading settings...']='Carregando configurações…',
 ['mission']='Missão',['objective']='Objetivo',['objectives']='Objetivos',
 ['open']='Abrir',['close']='Fechar',['unlock']='Destrancar',['insert key']='Colocar a chave',
 ['pick up']='Pegar',['drop']='Soltar',['interact']='Interagir',['use']='Usar',
 ['read']='Ler',['sit']='Sentar',['chair']='Cadeira',['door']='Porta',
 ['press e to interact']='Pressione E para interagir',
 ['hold to interact']='Segure para interagir',
 ['press e to open']='Pressione E para abrir',
 ['press e to sit']='Pressione E para sentar',
 ['start']='Iniciar',['save']='Salvar',['save game']='Salvar jogo',['discard']='Descartar',
 ['health']='Vida',['stamina']='Fôlego',['inventory']='Inventário',['pause']='Pausar',
 ['walk']='Andar',['run']='Correr',['sprint']='Correr',['crouch']='Agachar',['jump']='Pular',
 ['mission complete']='Missão concluída',['mission failed']='Missão falhou',
 ['brightness']='Brilho',['field of view']='Campo de visão',
 ['mouse sensitivity']='Sensibilidade do mouse',['shadows']='Sombras',['bloom']='Bloom',
 ['loading hints']='Dicas de carregamento',['volume']='Volume',
 ['apply settings']='Aplicar configurações',['reset defaults']='Restaurar padrões'
}
local function translated(value)
 if typeof(value)~='string' or value=='' then return value end
 local trimmed=value:match('^%s*(.-)%s*$') or value
 local key=string.lower(trimmed)
 local suffix=''
 local bare=key
 if key:sub(-3)=='...' then bare=key:sub(1,-4);suffix='…'
 elseif key:sub(-3)=='…' then bare=key:sub(1,-4);suffix='…'
 elseif key:sub(-1)==':' then bare=key:sub(1,-2);suffix=':'
 end
 local result=words[key] or words[bare]
 if not result then return value end
 if value==string.upper(value) then result=string.upper(result) end
 return result..suffix
end
local function update(instance)
 if instance:IsA('TextLabel') or instance:IsA('TextButton') or instance:IsA('TextBox') then
  local ok,current=pcall(function() return instance.Text end)
  if ok then
   local target=translated(current)
   if target~=current then pcall(function() instance.Text=target end) end
   pcall(function() instance:GetPropertyChangedSignal('Text'):Connect(function()
    local now=instance.Text;local nextText=translated(now)
    if nextText~=now then instance.Text=nextText end
   end) end)
  end
 elseif instance:IsA('ProximityPrompt') then
  local function translatePromptProperty(property)
   local current=instance[property];local target=translated(current)
   if target~=current then instance[property]=target end
  end
  translatePromptProperty('ActionText');translatePromptProperty('ObjectText')
  instance:GetPropertyChangedSignal('ActionText'):Connect(function() translatePromptProperty('ActionText') end)
  instance:GetPropertyChangedSignal('ObjectText'):Connect(function() translatePromptProperty('ObjectText') end)
 end
end
local function watch(root)
 for _,instance in ipairs(root:GetDescendants()) do update(instance) end
 root.DescendantAdded:Connect(function(instance) task.defer(update,instance) end)
end
watch(workspace)
watch(gui)
