# Kairo — Discord Bot

Landing page oficial do Kairo, construída em HTML, CSS e JavaScript puro e preparada para deploy na Vercel.

## Design

A interface segue uma direção editorial/mobile-first inspirada na referência visual enviada: hero em tela cheia, grid fino, paisagem abstrata, tipografia grande, detalhes em rosa, cards arredondados e seções claras/escuras com bastante contraste.

## Liquid Glass

O hero usa o projeto [@ybouane/liquidglass](https://github.com/ybouane/liquidglass) via CDN para aplicar refração WebGL real na barra superior e no card de status.

Import usado:

```js
import('https://cdn.jsdelivr.net/npm/@ybouane/liquidglass/dist/index.js')
```

Se WebGL ou o CDN não estiver disponível, o site mantém um fallback em CSS com `backdrop-filter`, então a interface continua utilizável.

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
