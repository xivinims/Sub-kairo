const commands=[
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

const grid=document.querySelector('#grid');
const query=document.querySelector('#q');
const filters=document.querySelector('#filters');
const notice=document.querySelector('#copyNotice');
const count=document.querySelector('#commandCount');
let current='Todos';

const cats=['Todos',...new Set(commands.map(c=>c.cat))];
filters.innerHTML=cats.map(c=>'<button class="filter'+(c==='Todos'?' active':'')+'" data-cat="'+c+'">'+c+'</button>').join('');

function render(){
  const term=query.value.trim().toLowerCase();
  const list=commands.filter(c=>(current==='Todos'||c.cat===current)&&('/'+c.name+' '+c.desc+' '+c.cat).toLowerCase().includes(term));
  grid.innerHTML=list.map(c=>'<button class="command" data-command="/'+c.name+'" type="button"><code>/'+c.name+'</code><p>'+c.desc+'</p><small>'+c.cat+'</small></button>').join('');
  if(!list.length) grid.innerHTML='<p class="muted">Nenhum comando encontrado.</p>';
}

filters.addEventListener('click',e=>{
  const btn=e.target.closest('.filter');
  if(!btn)return;
  current=btn.dataset.cat;
  document.querySelectorAll('.filter').forEach(b=>b.classList.toggle('active',b===btn));
  render();
});

query.addEventListener('input',render);

grid.addEventListener('click',async e=>{
  const card=e.target.closest('.command');
  if(!card)return;
  const cmd=card.dataset.command;
  try{
    await navigator.clipboard.writeText(cmd);
    notice.textContent=cmd+' copiado.';
  }catch{
    notice.textContent='Comando: '+cmd;
  }
  clearTimeout(window.__noticeTimer);
  window.__noticeTimer=setTimeout(()=>notice.textContent='',1800);
});

const replies=['Oiie!','aoba!','eu?','que foi? 😭','tô aqui ué','me chamou? 👀','😠😠'];
let replyIndex=0;
document.querySelector('#demoButton').addEventListener('click',()=>{
  replyIndex=(replyIndex+1)%replies.length;
  document.querySelector('#demoReply').textContent=replies[replyIndex];
});

count.textContent=commands.length;
render();