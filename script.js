const commands = [
  {name:'ajuda',desc:'Central de ajuda interativa.',cat:'Geral'},
  {name:'ping',desc:'Mostra a latência do bot.',cat:'Geral'},
  {name:'perfil',desc:'Card de perfil em Canvas.',cat:'Perfil'},
  {name:'rank',desc:'Mostra seu progresso de XP.',cat:'Perfil'},
  {name:'ranking',desc:'Ranking de XP do servidor.',cat:'Perfil'},
  {name:'avatar',desc:'Mostra o avatar de um usuário.',cat:'Utilidades'},
  {name:'userinfo',desc:'Informações de um usuário.',cat:'Utilidades'},
  {name:'serverinfo',desc:'Informações do servidor.',cat:'Utilidades'},
  {name:'mascote',desc:'Interaja com o Kairo.',cat:'Kairo'},
  {name:'amizade-kairo',desc:'Veja seu nível de amizade.',cat:'Kairo'},
  {name:'checkin',desc:'Faça seu check-in diário.',cat:'Kairo'},
  {name:'missoes',desc:'Veja e resgate missões.',cat:'Kairo'},
  {name:'conquistas',desc:'Veja suas conquistas.',cat:'Kairo'},
  {name:'carteirinha',desc:'Gera sua carteirinha em Canvas.',cat:'Kairo'},
  {name:'recadinho',desc:'Cria um card de recado.',cat:'Kairo'},
  {name:'saldo',desc:'Veja carteira e banco.',cat:'Economia'},
  {name:'daily',desc:'Receba sua recompensa diária.',cat:'Economia'},
  {name:'trabalhar',desc:'Trabalhe e ganhe coins.',cat:'Economia'},
  {name:'depositar',desc:'Deposite coins no banco.',cat:'Economia'},
  {name:'sacar',desc:'Saque coins do banco.',cat:'Economia'},
  {name:'transferir',desc:'Transfira coins para alguém.',cat:'Economia'},
  {name:'loja',desc:'Abra a lojinha do Kairo.',cat:'Economia'},
  {name:'comprar',desc:'Compre um item da loja.',cat:'Economia'},
  {name:'inventario',desc:'Veja seus itens.',cat:'Economia'},
  {name:'ricos',desc:'Ranking de coins.',cat:'Economia'},
  {name:'abracar',desc:'Dê um abraço virtual.',cat:'Social'},
  {name:'cafune',desc:'Faça cafuné em alguém.',cat:'Social'},
  {name:'toca-aqui',desc:'Dê um toca-aqui.',cat:'Social'},
  {name:'rep',desc:'Dê reputação a alguém.',cat:'Social'},
  {name:'dado',desc:'Role um dado.',cat:'Diversão'},
  {name:'ppt',desc:'Pedra, papel ou tesoura.',cat:'Diversão'},
  {name:'bola8',desc:'Faça uma pergunta à bola 8.',cat:'Diversão'},
  {name:'escolher',desc:'Deixe o Kairo escolher.',cat:'Diversão'},
  {name:'reverter',desc:'Inverte um texto.',cat:'Diversão'},
  {name:'enquete',desc:'Crie uma enquete.',cat:'Utilidades'},
  {name:'lembrete',desc:'Crie um lembrete.',cat:'Utilidades'},
  {name:'ticket-painel',desc:'Crie um painel de tickets.',cat:'Utilidades'},
  {name:'ban',desc:'Bane um membro.',cat:'Moderação'},
  {name:'kick',desc:'Expulsa um membro.',cat:'Moderação'},
  {name:'timeout',desc:'Aplica timeout.',cat:'Moderação'},
  {name:'warn',desc:'Registra um aviso.',cat:'Moderação'},
  {name:'warnings',desc:'Mostra os avisos de alguém.',cat:'Moderação'},
  {name:'clearwarnings',desc:'Limpa avisos registrados.',cat:'Moderação'},
  {name:'clear',desc:'Apaga mensagens.',cat:'Moderação'},
  {name:'slowmode',desc:'Configura o modo lento.',cat:'Moderação'},
  {name:'lock',desc:'Bloqueia o canal.',cat:'Moderação'},
  {name:'unlock',desc:'Desbloqueia o canal.',cat:'Moderação'},
  {name:'config',desc:'Configura recursos do servidor.',cat:'Configuração'}
];

const grid = document.querySelector('#grid');
const query = document.querySelector('#q');
const filters = document.querySelector('#filters');
const notice = document.querySelector('#copyNotice');
const count = document.querySelector('#commandCount');
const menuButton = document.querySelector('.menu-button');
const menuPanel = document.querySelector('.menu-panel');
const demoButton = document.querySelector('#demoButton');
const demoReply = document.querySelector('#demoReply');

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

const replies = [
  'me chamou? :3',
  'oi oi, tô aqui ✦',
  'manda, eu vejo pra você',
  'aoba! chegou alguém',
  'hmm... gostei dessa ideia',
  'já tô cuidando daqui',
  'não mexe muito que eu organizei tudo'
];

let replyIndex = 0;
demoButton.addEventListener('click', () => {
  replyIndex = (replyIndex + 1) % replies.length;
  demoReply.animate(
    [{opacity:0,transform:'translateY(6px)'},{opacity:1,transform:'translateY(0)'}],
    {duration:220,easing:'ease-out'}
  );
  demoReply.textContent = replies[replyIndex];
});

count.textContent = `${commands.length} comandos`;
renderCommands();