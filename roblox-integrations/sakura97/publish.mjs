// Parse scripts in Roblox, then publish map and UI in order.
await import('./check-syntax.mjs');
await import('./publish-map.mjs');
await import('./publish-menu.mjs');
