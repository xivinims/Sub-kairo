const commands = [
  {name:'ajuda',desc:'Mostra a central completa de ajuda do Kairo',cat:'Perfil e informação'},
  {name:'ping',desc:'Mostra a latência do bot',cat:'Perfil e informação'},
  {name:'perfil',desc:'Gera o card completo de perfil',cat:'Perfil e informação'},
  {name:'rank',desc:'Mostra nível, XP e progresso',cat:'Perfil e informação'},
  {name:'ranking',desc:'Ranking de XP do servidor',cat:'Perfil e informação'},
  {name:'avatar',desc:'Mostra o avatar de alguém',cat:'Perfil e informação'},
  {name:'banner',desc:'Mostra o banner de alguém',cat:'Perfil e informação'},
  {name:'userinfo',desc:'Informações detalhadas de um usuário',cat:'Perfil e informação'},
  {name:'serverinfo',desc:'Informações detalhadas do servidor',cat:'Perfil e informação'},
  {name:'botinfo',desc:'Informações do Kairo',cat:'Perfil e informação'},
  {name:'status',desc:'Mostra o estado atual do Kairo',cat:'Perfil e informação'},
  {name:'uptime',desc:'Mostra há quanto tempo o bot está ligado',cat:'Perfil e informação'},
  {name:'estatisticas',desc:'Mostra estatísticas gerais do servidor no Kairo',cat:'Perfil e informação'},
  {name:'atividade',desc:'Mostra sua atividade registrada',cat:'Perfil e informação'},

  {name:'saldo',desc:'Mostra carteira, banco e patrimônio',cat:'Economia'},
  {name:'daily',desc:'Recebe a recompensa diária',cat:'Economia'},
  {name:'weekly',desc:'Recebe a recompensa semanal',cat:'Economia'},
  {name:'depositar',desc:'Deposita dinheiro no banco',cat:'Economia'},
  {name:'sacar',desc:'Saca dinheiro do banco',cat:'Economia'},
  {name:'transferir',desc:'Transfere dinheiro para alguém',cat:'Economia'},
  {name:'extrato',desc:'Mostra suas últimas movimentações',cat:'Economia'},
  {name:'loja',desc:'Mostra a loja do Kairo',cat:'Economia'},
  {name:'comprar',desc:'Compra um item',cat:'Economia'},
  {name:'vender',desc:'Vende um item de volta',cat:'Economia'},
  {name:'inventario',desc:'Mostra o inventário',cat:'Economia'},
  {name:'usar',desc:'Usa um item do inventário',cat:'Economia'},
  {name:'presentear',desc:'Entrega um item para alguém',cat:'Economia'},
  {name:'ricos',desc:'Ranking de patrimônio do servidor',cat:'Economia'},
  {name:'economia',desc:'Resumo econômico do servidor',cat:'Economia'},

  {name:'arrumar',desc:'Organize sua vida profissional',cat:'Carreira'},
  {name:'emprego',desc:'Veja e gerencie sua carreira',cat:'Carreira'},
  {name:'trabalhar',desc:'Faça um turno no emprego atual',cat:'Carreira'},
  {name:'treinar',desc:'Treine sua habilidade profissional',cat:'Carreira'},
  {name:'curriculo',desc:'Mostra seu currículo dentro do Kairo',cat:'Carreira'},
  {name:'carreira',desc:'Mostra seu progresso profissional detalhado',cat:'Carreira'},

  {name:'mascote',desc:'Interaja com o Kairo',cat:'Kairo'},
  {name:'amizade-kairo',desc:'Mostra seu vínculo com o Kairo',cat:'Kairo'},
  {name:'checkin',desc:'Faz seu check-in diário com o Kairo',cat:'Kairo'},
  {name:'missoes',desc:'Gerencia missões diárias',cat:'Kairo'},
  {name:'conquistas',desc:'Mostra conquistas desbloqueadas',cat:'Kairo'},
  {name:'carteirinha',desc:'Gera sua carteirinha em Canvas',cat:'Kairo'},
  {name:'recadinho',desc:'Cria um card de recado',cat:'Kairo'},
  {name:'titulo',desc:'Gerencia títulos cosméticos',cat:'Kairo'},
  {name:'perfil-config',desc:'Personalize detalhes do seu perfil',cat:'Kairo'},

  {name:'abracar',desc:'Dê um abraço em alguém',cat:'Social'},
  {name:'cafune',desc:'Faça cafuné em alguém',cat:'Social'},
  {name:'toca-aqui',desc:'Dê um toca-aqui',cat:'Social'},
  {name:'aplaudir',desc:'Aplauda alguém',cat:'Social'},
  {name:'cutucar',desc:'Cutuca alguém',cat:'Social'},
  {name:'rep',desc:'Dê reputação a alguém',cat:'Social'},

  {name:'dado',desc:'Rola um dado',cat:'Diversão'},
  {name:'ppt',desc:'Pedra, papel ou tesoura',cat:'Diversão'},
  {name:'bola8',desc:'Pergunte à bola 8',cat:'Diversão'},
  {name:'escolher',desc:'Kairo escolhe entre opções',cat:'Diversão'},
  {name:'reverter',desc:'Inverte um texto',cat:'Diversão'},
  {name:'moeda',desc:'Joga uma moeda sem apostas',cat:'Diversão'},
  {name:'numero',desc:'Escolhe um número',cat:'Diversão'},
  {name:'emoji',desc:'Escolhe um emoji aleatório',cat:'Diversão'},
  {name:'charada',desc:'Manda uma charada curta',cat:'Diversão'},
  {name:'frase',desc:'Manda uma frase aleatória do Kairo',cat:'Diversão'},
  {name:'quiz',desc:'Abre uma pergunta rápida de quiz',cat:'Diversão'},
  {name:'palavra',desc:'Embaralha uma palavra para você descobrir',cat:'Diversão'},

  {name:'enquete',desc:'Cria uma enquete',cat:'Utilidades'},
  {name:'lembrete',desc:'Cria um lembrete persistente',cat:'Utilidades'},
  {name:'calc',desc:'Calcula uma expressão matemática',cat:'Utilidades'},
  {name:'timestamp',desc:'Cria um timestamp do Discord',cat:'Utilidades'},
  {name:'servericon',desc:'Mostra o ícone do servidor',cat:'Utilidades'},
  {name:'id',desc:'Mostra IDs',cat:'Utilidades'},
  {name:'tempo-server',desc:'Mostra há quanto tempo está no servidor',cat:'Utilidades'},
  {name:'feedback',desc:'Envia feedback para a equipe',cat:'Utilidades'},
  {name:'sugestao',desc:'Envia uma sugestão ao canal configurado',cat:'Utilidades'},
  {name:'convite',desc:'Mostra o link de convite do Kairo',cat:'Utilidades'},
  {name:'cor',desc:'Mostra informações de uma cor HEX',cat:'Utilidades'},
  {name:'texto',desc:'Ferramentas rápidas de texto',cat:'Utilidades'},

  {name:'ticket-painel',desc:'Cria um painel de tickets',cat:'Moderação e admin'},
  {name:'ban',desc:'Bane um membro',cat:'Moderação e admin'},
  {name:'kick',desc:'Expulsa um membro',cat:'Moderação e admin'},
  {name:'timeout',desc:'Aplica timeout',cat:'Moderação e admin'},
  {name:'untimeout',desc:'Remove timeout',cat:'Moderação e admin'},
  {name:'warn',desc:'Registra um aviso',cat:'Moderação e admin'},
  {name:'warnings',desc:'Mostra avisos',cat:'Moderação e admin'},
  {name:'unwarn',desc:'Remove um aviso pelo ID',cat:'Moderação e admin'},
  {name:'clearwarnings',desc:'Limpa todos os avisos',cat:'Moderação e admin'},
  {name:'clear',desc:'Apaga mensagens recentes',cat:'Moderação e admin'},
  {name:'slowmode',desc:'Configura o modo lento',cat:'Moderação e admin'},
  {name:'lock',desc:'Bloqueia o canal atual',cat:'Moderação e admin'},
  {name:'unlock',desc:'Desbloqueia o canal atual',cat:'Moderação e admin'},
  {name:'nick',desc:'Altera o apelido de um membro',cat:'Moderação e admin'},
  {name:'role-add',desc:'Adiciona um cargo',cat:'Moderação e admin'},
  {name:'role-remove',desc:'Remove um cargo',cat:'Moderação e admin'},
  {name:'config',desc:'Configura o Kairo neste servidor',cat:'Moderação e admin'},
  {name:'painel',desc:'Resumo administrativo do Kairo',cat:'Moderação e admin'},
  {name:'anunciar',desc:'Envia um anúncio simples',cat:'Moderação e admin'}
];

const mentionReplies = [
  'Oiie!',
  'aoba!',
  '😠😠',
  'eu?',
  'que foi? 😭',
  'tô aqui ué',
  'me chamou? 👀',
  'hm?',
  'eu tava quietinho 😭',
  'cookie?'
];

const mascotReplies = [
  'O Kairo ficou quietinho recebendo cafuné. <strong>+5 vínculo</strong>',
  '<em>*boop*</em> — ele ficou te encarando por dois segundos. <strong>+3 vínculo</strong>',
  'Hora da soneca. <strong>+8 vínculo</strong>',
  'Vocês ficaram brincando até o Kairo cansar. <strong>+9 vínculo</strong>',
  'Você apareceu por aqui. <strong>+12 vínculo</strong> e <strong>+18 XP</strong>.'
];

const workReplies = [
  'Você corrigiu um bug que só aparecia quando ninguém estava olhando.',
  'Você fez deploy e, por algum milagre, nada explodiu.',
  'Você transformou um TODO antigo em código funcionando.',
  'Você revisou um PR e encontrou o ponto e vírgula que salvou a tarde.',
  'Você reduziu uma função enorme até ela finalmente parecer humana.',
  'Você limpou uma planilha com mais personalidade do que deveria.',
  'Você encontrou um padrão onde todo mundo só via números.',
  'Você treinou um modelo e ele não inventou uma coluna nova. Vitória.',
  'Você montou um dashboard que alguém realmente entendeu.',
  'Você resolveu um problema reiniciando algo. O clássico venceu de novo.',
  'Você descobriu que o cabo estava solto antes de abrir vinte tickets.',
  'Você explicou a diferença entre Wi‑Fi e internet pela milésima vez.'
];

const grid = document.querySelector('#grid');
const query = document.querySelector('#q');
const filters = document.querySelector('#filters');
const notice = document.querySelector('#copyNotice');
const count = document.querySelector('#commandCount');
const menuButton = document.querySelector('.menu-button');
const menuPanel = document.querySelector('.menu-panel');
const mentionButton = document.querySelector('#mentionButton');
const mentionReply = document.querySelector('#mentionReply');
const mascotButton = document.querySelector('#mascotButton');
const mascotReply = document.querySelector('#mascotReply');
const workButton = document.querySelector('#workButton');
const workReply = document.querySelector('#workReply');

let current = 'Todos';
const categories = ['Todos', ...new Set(commands.map(command => command.cat))];

filters.innerHTML = categories
  .map(cat => `<button class="filter${cat === 'Todos' ? ' active' : ''}" data-cat="${cat}" type="button">${cat}</button>`)
  .join('');

function renderCommands() {
  const term = query.value.trim().toLowerCase();
  const list = commands.filter(command => {
    const categoryMatches = current === 'Todos' || command.cat === current;
    const searchable = `/${command.name} ${command.desc} ${command.cat}`.toLowerCase();
    return categoryMatches && searchable.includes(term);
  });

  grid.innerHTML = list.length
    ? list.map(command => `
      <button class="command" data-command="/${command.name}" type="button">
        <code>/${command.name}</code>
        <p>${command.desc}</p>
        <small>${command.cat}</small>
      </button>
    `).join('')
    : '<p>Nenhum comando encontrado.</p>';
}

filters.addEventListener('click', event => {
  const button = event.target.closest('.filter');
  if (!button) return;
  current = button.dataset.cat;
  document.querySelectorAll('.filter').forEach(item => item.classList.toggle('active', item === button));
  renderCommands();
});

query.addEventListener('input', renderCommands);

grid.addEventListener('click', async event => {
  const card = event.target.closest('.command');
  if (!card) return;
  const command = card.dataset.command;

  try {
    await navigator.clipboard.writeText(command);
    notice.textContent = `${command} copiado.`;
  } catch {
    notice.textContent = `Comando: ${command}`;
  }

  clearTimeout(window.__copyTimer);
  window.__copyTimer = setTimeout(() => notice.textContent = '', 1800);
});

function closeMenu() {
  menuButton.classList.remove('is-open');
  menuPanel.classList.remove('is-open');
  menuButton.setAttribute('aria-expanded', 'false');
  menuPanel.setAttribute('aria-hidden', 'true');
}

menuButton.addEventListener('click', () => {
  const open = !menuButton.classList.contains('is-open');
  menuButton.classList.toggle('is-open', open);
  menuPanel.classList.toggle('is-open', open);
  menuButton.setAttribute('aria-expanded', String(open));
  menuPanel.setAttribute('aria-hidden', String(!open));
});

menuPanel.addEventListener('click', event => {
  if (event.target.closest('a')) closeMenu();
});

document.addEventListener('click', event => {
  if (!menuPanel.contains(event.target) && !menuButton.contains(event.target)) closeMenu();
});

let mentionIndex = 0;
mentionButton.addEventListener('click', () => {
  mentionIndex = (mentionIndex + 1) % mentionReplies.length;
  mentionReply.textContent = mentionReplies[mentionIndex];
});

let mascotIndex = 0;
mascotButton.addEventListener('click', () => {
  mascotIndex = (mascotIndex + 1) % mascotReplies.length;
  mascotReply.innerHTML = mascotReplies[mascotIndex];
});

let workIndex = 0;
workButton.addEventListener('click', () => {
  workIndex = (workIndex + 1) % workReplies.length;
  workReply.textContent = workReplies[workIndex];
});

count.textContent = `${commands.length} comandos`;
renderCommands();