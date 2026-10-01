# Kairo — Discord Bot

Landing page oficial do Kairo, construída em HTML, CSS e JavaScript puro e preparada para deploy na Vercel.

## Design

A interface segue uma direção editorial/mobile-first inspirada na referência visual enviada: hero em tela cheia, grid fino, paisagem abstrata, tipografia grande, detalhes em rosa, cards arredondados e seções claras/escuras com bastante contraste.

## Liquid Glass

O hero usa o pacote oficial [@ybouane/liquidglass](https://github.com/ybouane/liquidglass) diretamente pelo CDN, seguindo a integração documentada pelo repositório.

```js
import { LiquidGlass } from 'https://cdn.jsdelivr.net/npm/@ybouane/liquidglass/dist/index.js';

const instance = await LiquidGlass.init({
  root,
  glassElements
});
```

Não há shader modificado, configuração visual customizada nem imitação do efeito com `backdrop-filter` nos elementos Liquid Glass.

## Conteúdo

- Moderação
- Economia
- XP e ranking
- Missões e conquistas
- Perfil e utilidades
- Interações com o mascote Kairo
- Busca e filtro de comandos
- Layout responsivo para celular e desktop

## Convite do bot

https://discord.com/oauth2/authorize?client_id=1519161870815072286

## Deploy

O projeto continua compatível com Vercel usando o `vercel.json` existente.
