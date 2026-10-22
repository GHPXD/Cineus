'use strict';
(() => {
  const path = location.pathname.split('/').filter(Boolean);
  const code = path[path.length - 1] || '';
  const kind = path[path.length - 2];
  const valid = kind === 'challenge' ? /^CINP?-[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{4}$/.test(code)
    : kind === 'friend' && /^[A-Za-z0-9_-]{12}$/.test(code);
  document.getElementById(valid ? 'invitation' : 'invalid').hidden = false;
  if (!valid) return;
  document.getElementById('code').textContent = code;
  document.getElementById('kind').textContent = kind === 'friend' ? 'Confronto privado · 7 dias' : 'Desafio de filme';
  document.getElementById('open').href = `cineus://${kind}/${encodeURIComponent(code)}`;
  document.getElementById('copy').addEventListener('click', async () => {
    try { await navigator.clipboard.writeText(code); document.getElementById('status').textContent = 'Código copiado.'; }
    catch (_) { document.getElementById('status').textContent = 'Selecione e copie o código acima.'; }
  });
  fetch('/stores.json', {credentials:'omit',redirect:'error'}).then(r => r.ok ? r.json() : {}).then(config => {
    for (const [key, label, host] of [['android','Google Play','play.google.com'],['ios','App Store','apps.apple.com']]) {
      if (!config[key]) continue;
      const uri = new URL(config[key]);
      if (uri.protocol !== 'https:' || uri.hostname !== host || uri.username || uri.password) continue;
      const link = document.createElement('a'); link.href = uri.href; link.textContent = label; link.rel = 'noopener noreferrer';
      document.getElementById('stores').append(link);
    }
  }).catch(() => {});
})();
