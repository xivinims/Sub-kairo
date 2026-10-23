// Validate all scripts, then publish the entire map and interface in one saved version.
await import('./check-syntax.mjs');
await import('./publish-map.mjs');
await import('./asset-audit.mjs');
