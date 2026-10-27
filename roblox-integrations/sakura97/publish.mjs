if(process.env.SURVIVERS_VERIFY_ONLY==='true') await import('./verify-published.mjs');
else await import('./publish-map.mjs');
