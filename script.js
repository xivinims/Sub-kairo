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
  ['O Kairo ficou quietinho recebendo cafuné.', '+5 vínculo'],
  ['*boop* — ele ficou te encarando por dois segundos.', '+3 vínculo'],
  ['Hora da soneca.', '+8 vínculo'],
  ['Vocês ficaram brincando até o Kairo cansar.', '+9 vínculo'],
  ['Você apareceu por aqui.', '+12 vínculo e +18 XP']
];

const menuButton = document.querySelector('.menu-button');
const menuPanel = document.querySelector('.menu-panel');
const mentionButton = document.querySelector('#mentionButton');
const mentionReply = document.querySelector('#mentionReply');
const mascotButton = document.querySelector('#mascotButton');
const mascotReply = document.querySelector('#mascotReply');
const mascotExtra = document.querySelector('#mascotExtra');
const copyNotice = document.querySelector('#copyNotice');
const commandGrid = document.querySelector('.command-grid');

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
  mentionReply.animate(
    [{opacity:0, transform:'translateY(5px)'},{opacity:1, transform:'translateY(0)'}],
    {duration:180, easing:'ease-out'}
  );
  mentionReply.textContent = mentionReplies[mentionIndex];
});

let mascotIndex = 0;
if (mascotButton && mascotReply && mascotExtra) {
  mascotButton.addEventListener('click', () => {
    mascotIndex = (mascotIndex + 1) % mascotReplies.length;
    const [text, extra] = mascotReplies[mascotIndex];
    mascotReply.animate(
      [{opacity:0, transform:'translateY(7px)'},{opacity:1, transform:'translateY(0)'}],
      {duration:220, easing:'ease-out'}
    );
    mascotReply.textContent = text;
    mascotExtra.textContent = extra;
  });
}

commandGrid.addEventListener('click', async event => {
  const button = event.target.closest('.command-chip');
  if (!button) return;

  const command = button.dataset.command;

  try {
    await navigator.clipboard.writeText(command);
    copyNotice.textContent = `${command} copiado.`;
  } catch {
    copyNotice.textContent = `Comando: ${command}`;
  }

  clearTimeout(window.__copyTimer);
  window.__copyTimer = setTimeout(() => copyNotice.textContent = '', 1600);
});

function installRubberDrag(element) {
  let active = false;
  let startX = 0;
  let startY = 0;
  let dx = 0;
  let dy = 0;

  const damp = value => Math.sign(value) * Math.pow(Math.abs(value), 0.82) * 0.72;

  element.addEventListener('pointerdown', event => {
    active = true;
    startX = event.clientX;
    startY = event.clientY;
    dx = 0;
    dy = 0;

    element.setPointerCapture(event.pointerId);
    element.getAnimations().forEach(animation => animation.cancel());
  });

  element.addEventListener('pointermove', event => {
    if (!active) return;

    dx = damp(event.clientX - startX);
    dy = damp(event.clientY - startY);

    const distance = Math.min(Math.hypot(dx, dy), 140);
    const stretch = 1 + distance / 900;
    const squash = 1 - distance / 1400;
    const rotate = Math.max(-5, Math.min(5, dx / 24));

    element.style.transform = `translate(${dx}px, ${dy}px) rotate(${rotate}deg) scale(${stretch}, ${squash})`;
  });

  const release = event => {
    if (!active) return;
    active = false;

    try {
      element.releasePointerCapture(event.pointerId);
    } catch {}

    const from = element.style.transform || 'translate(0,0)';

    const animation = element.animate(
      [
        {transform: from},
        {transform: `translate(${-dx * 0.18}px, ${-dy * 0.18}px) rotate(${-dx / 80}deg) scale(.98, 1.02)`, offset:.5},
        {transform:'translate(0,0) rotate(0deg) scale(1,1)'}
      ],
      {
        duration:520,
        easing:'cubic-bezier(.2,.9,.25,1)'
      }
    );

    animation.onfinish = () => {
      element.style.transform = '';
    };
  };

  element.addEventListener('pointerup', release);
  element.addEventListener('pointercancel', release);
}

document.querySelectorAll('[data-rubber]').forEach(installRubberDrag);


function installMorphIcon() {
  const frames = [...document.querySelectorAll('.morph-frame')];
  if (!frames.length) return;

  let index = 0;
  let direction = 1;
  let timer = null;

  const HOLD_MS = 1100;
  const STEP_MS = 240;
  const keyFrames = new Set([0, 4, frames.length - 1]);

  const show = next => {
    frames.forEach((frame, i) => frame.classList.toggle('is-active', i === next));
  };

  const scheduleNext = () => {
    const delay = keyFrames.has(index) ? HOLD_MS : STEP_MS;

    timer = window.setTimeout(() => {
      if (index === frames.length - 1) direction = -1;
      else if (index === 0) direction = 1;

      index += direction;
      show(index);
      scheduleNext();
    }, delay);
  };

  show(0);

  if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    scheduleNext();
  }

  document.addEventListener('visibilitychange', () => {
    if (document.hidden && timer) {
      clearTimeout(timer);
      timer = null;
    } else if (!document.hidden && !timer && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      scheduleNext();
    }
  });
}

installMorphIcon();


async function setupLiquidGlass() {
  const root = document.body;
  const glassElements = [...document.querySelectorAll('[data-liquid-glass]')];

  if (!glassElements.length) return;

  try {
    const { LiquidGlass } = await import('https://cdn.jsdelivr.net/npm/@ybouane/liquidglass/dist/index.js');
    const instance = await LiquidGlass.init({
      root,
      glassElements
    });

    document.documentElement.dataset.liquidGlass = 'ready';
    window.__kairoLiquidGlass = instance;
  } catch (error) {
    console.warn('LiquidGlass não pôde ser inicializado; mantendo o fallback visual.', error);
  }
}

setupLiquidGlass();


function installRevealMotion() {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  const items = [
    ...document.querySelectorAll('.section-head, .feature, .command-chip, .about > *, .mention-card')
  ];

  if (!items.length) return;

  document.body.classList.add('motion-enhanced');
  items.forEach(item => item.classList.add('reveal-item'));

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add('is-visible');
      observer.unobserve(entry.target);
    });
  }, {
    rootMargin:'0px 0px -8% 0px',
    threshold:.12
  });

  items.forEach((item, index) => {
    item.style.transitionDelay = `${Math.min((index % 4) * 70, 210)}ms`;
    observer.observe(item);
  });
}

installRevealMotion();


function installNatureScene() {
  const leafLayer = document.querySelector('#leafLayer');
  const fireflyLayer = document.querySelector('#fireflyLayer');
  if (!leafLayer || !fireflyLayer) return;

  const leafData = [
    ['8%','18px','-3s','11s','-22deg','.72','#9fbd6a','#547e4c'],
    ['18%','14px','-7s','13s','30deg','.60','#c5cf78','#739058'],
    ['29%','21px','-5s','15s','-40deg','.68','#8aae63','#446f4a'],
    ['41%','12px','-1s','10s','18deg','.55','#d2d68a','#789258'],
    ['53%','17px','-9s','14s','-35deg','.66','#93b665','#527d4e'],
    ['64%','23px','-4s','16s','26deg','.62','#b6c977','#638b53'],
    ['73%','15px','-11s','12s','-28deg','.58','#d7d78c','#7a9156'],
    ['83%','19px','-6s','15s','38deg','.67','#8eaf62','#4c7649'],
    ['92%','13px','-2s','11s','-12deg','.52','#becd7d','#6d8b56'],
    ['35%','16px','-12s','17s','22deg','.48','#9eb86b','#5e7e50'],
    ['57%','11px','-8s','12s','-18deg','.50','#d2d98e','#7e955c'],
    ['76%','20px','-13s','18s','34deg','.54','#9fbd6d','#547c4c']
  ];

  leafData.forEach(([x,size,delay,duration,rot,opacity,a,b]) => {
    const leaf = document.createElement('i');
    leaf.className = 'flying-leaf';
    leaf.style.setProperty('--x', x);
    leaf.style.setProperty('--size', size);
    leaf.style.setProperty('--delay', delay);
    leaf.style.setProperty('--duration', duration);
    leaf.style.setProperty('--rot', rot);
    leaf.style.setProperty('--opacity', opacity);
    leaf.style.setProperty('--leaf-a', a);
    leaf.style.setProperty('--leaf-b', b);
    leafLayer.appendChild(leaf);
  });

  const fireflies = [
    ['8%','18%','5px','2.1s','6.2s','-.8s'],
    ['15%','43%','4px','2.7s','7.4s','-2.2s'],
    ['24%','67%','6px','2.3s','8.1s','-1.4s'],
    ['31%','32%','4px','3.1s','6.9s','-3.5s'],
    ['39%','76%','5px','2.5s','8.6s','-.3s'],
    ['47%','54%','4px','2.9s','7.1s','-4.1s'],
    ['55%','24%','6px','2.2s','7.8s','-2.8s'],
    ['62%','71%','5px','3.2s','8.4s','-1.7s'],
    ['69%','39%','4px','2.4s','6.7s','-3.2s'],
    ['77%','61%','6px','2.8s','9.1s','-.9s'],
    ['84%','28%','5px','2.1s','7.6s','-2.5s'],
    ['91%','73%','4px','3.0s','8.7s','-4.6s'],
    ['12%','83%','4px','2.5s','7.2s','-1.1s'],
    ['44%','88%','5px','2.6s','8.8s','-3.7s'],
    ['71%','86%','4px','2.2s','7.9s','-2.0s'],
    ['88%','49%','5px','2.7s','8.2s','-4.0s']
  ];

  fireflies.forEach(([x,y,size,blink,wander,delay]) => {
    const fly = document.createElement('i');
    fly.className = 'firefly';
    fly.style.setProperty('--x', x);
    fly.style.setProperty('--y', y);
    fly.style.setProperty('--size', size);
    fly.style.setProperty('--blink', blink);
    fly.style.setProperty('--wander', wander);
    fly.style.setProperty('--delay', delay);
    fireflyLayer.appendChild(fly);
  });

  let ticking = false;
  const updateNight = () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => {
      const maxScroll = Math.max(document.documentElement.scrollHeight - innerHeight, 1);
      const progress = Math.max(0, Math.min(1, scrollY / maxScroll));
      const night = Math.max(0, Math.min(1, (progress - .18) / .62));
      document.documentElement.style.setProperty('--night', night.toFixed(3));
      document.body.classList.toggle('night-mode', night > .42);
      ticking = false;
    });
  };

  addEventListener('scroll', updateNight, {passive:true});
  addEventListener('resize', updateNight, {passive:true});
  updateNight();
}

installNatureScene();
