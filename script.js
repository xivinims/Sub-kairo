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
