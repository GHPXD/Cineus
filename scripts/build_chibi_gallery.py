"""Review real generated collection art and real Flutter captures locally."""
import hashlib
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'docs/artwork/chibi-collection-v4'
OUT = ROOT / 'docs/preview/chibi-collection-2026-10-22'


def main():
    manifest = json.loads((ART / 'MANIFEST.json').read_text(encoding='utf8'))
    names = {
        '_collection': 'Minha coleção',
        'preview_premiere_avatar_cat_v1': 'Otto Corte-Final · prévia',
        'preview_mission_avatar_capybara_v1': 'Breno Efeito-Bruto · prévia',
        'preview_night_avatar_otter_v1': 'Ciro Maré-de-Cena · prévia',
        'catalog_avatar': 'Personagens na coleção',
        'catalog_frame': 'Molduras na coleção',
        'catalog_appearance': 'Fundos na coleção',
        '_seasons': 'Coleções disponíveis',
    }
    for name in names:
        assert (OUT / 'screens' / f'{name}.png').is_file(), name
    previews = [p for p in names if p.startswith('preview_')]
    assert len({hashlib.sha256((OUT / 'screens' / f'{p}.png').read_bytes()).hexdigest() for p in previews}) == 3
    cards = []
    for item in manifest:
        label = html.escape(item['name'])
        href = '../../../' + item['asset']
        cards.append(f'<a class="item" data-kind="{item["kind"]}" href="{href}"><img loading="lazy" src="{href}" alt="{label}"><span>{label}</span></a>')
    screenshots = ''.join(f'<figure><a href="screens/{key}.png"><img loading="lazy" src="screens/{key}.png" alt="{label}"></a><figcaption>{label}</figcaption></figure>' for key, label in names.items())
    page = '''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cineus · Coleção chibi</title><style>
:root{color-scheme:dark;font-family:system-ui,sans-serif;background:#07111e;color:#eef2f8}*{box-sizing:border-box}body{margin:auto;max-width:1400px;padding:30px 24px 70px}h1{font-size:clamp(30px,5vw,54px);margin-bottom:12px;color:#ffd571}p{color:#b7c5dd;line-height:1.65}a{color:#ffd571}nav{display:flex;flex-wrap:wrap;gap:10px;margin:26px 0}button{border:1px solid #3b526e;border-radius:24px;background:#102238;color:#d5e0f0;padding:12px 20px;cursor:pointer;font:inherit}button[aria-pressed=true]{background:#ffd05e;color:#07111e;border-color:#ffd05e}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:18px}.item{padding:12px;border:1px solid #2b3b50;border-radius:20px;background:#0d1b2b;text-decoration:none;text-align:center}.item img{width:100%;height:250px;object-fit:contain}.item span{display:block;padding:12px 0;overflow-wrap:anywhere}.screens{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:22px}figure{margin:0}figure img{width:100%;border-radius:18px;border:1px solid #2b3b50}figcaption{padding:14px;color:#bac8df}section{margin:45px 0}.sheet{display:block;width:100%;max-width:1200px;border-radius:18px}h2{margin:30px 0 18px;font-size:28px}
</style><h1>Cineus · Coleção chibi</h1><p>32 itens integrados: 12 personagens, 14 molduras e 6 fundos. Os dois personagens aprovados foram preservados. Itens já conquistados e equipados mantêm seus identificadores; o modo Cores permanece igual.</p>
<p>Artes criadas com o gerador de imagens integrado. <a href="../../artwork/chibi-collection-v4/MANIFEST.json">Originais, inspirações e conjunto de prompts</a>.</p>
<section><h2>Elenco completo</h2><a href="../../artwork/chibi-collection-v4/AVATAR.png"><img class="sheet" src="../../artwork/chibi-collection-v4/AVATAR.png" alt="Os doze personagens chibi"></a></section>
<section><h2>Todos os itens</h2><nav aria-label="Tipo de item"><button aria-pressed="true" data-filter="all">Todos · 32</button><button aria-pressed="false" data-filter="avatar">Personagens · 12</button><button aria-pressed="false" data-filter="frame">Molduras · 14</button><button aria-pressed="false" data-filter="appearance">Fundos · 6</button></nav><div class="grid">''' + ''.join(cards) + '''</div></section>
<section><h2>No aplicativo</h2><p>Capturas dos widgets e rotas reais do Flutter, com os arquivos usados no jogo.</p><div class="screens">''' + screenshots + '''</div></section>
<script>document.querySelectorAll('button[data-filter]').forEach(b=>b.addEventListener('click',()=>{document.querySelectorAll('button[data-filter]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));document.querySelectorAll('.item').forEach(x=>x.hidden=b.dataset.filter!=='all'&&x.dataset.kind!==b.dataset.filter)}));</script></html>'''
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'GALERIA.html').write_text(page, encoding='utf8')
    print(f'Gallery ready: {OUT / "GALERIA.html"}')


if __name__ == '__main__':
    main()
