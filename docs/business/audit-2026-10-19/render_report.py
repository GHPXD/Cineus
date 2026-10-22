"""Build the offline HTML reading copy of this audit, without dependencies."""
from pathlib import Path
import html
import os
import re
import unicodedata

ROOT = Path(__file__).resolve().parent
source = (ROOT / 'RELATORIO.md').read_text(encoding='utf-8')


def target(value):
    value = html.unescape(value)
    if re.match(r'^[A-Za-z]:/', value):
        value = re.sub(r':\d+$', '', value)
        return os.path.relpath(value, ROOT).replace('\\', '/')
    return value


def inline(value):
    value = html.escape(value, quote=False)
    value = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', lambda m:
                   '<img loading="lazy" alt="' + html.escape(html.unescape(m[1]), quote=True)
                   + '" src="' + html.escape(target(m[2]), quote=True) + '">', value)
    value = re.sub(r'(?<!!)\[([^\]]+)\]\(([^)]+)\)', lambda m:
                   '<a href="' + html.escape(target(m[2]), quote=True) + '">'
                   + m[1] + '</a>', value)
    value = re.sub(r'`([^`]+)`', r'<code>\1</code>', value)
    value = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', value)
    return value


def slug(value):
    plain = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode()
    return re.sub(r'[^a-z0-9]+', '-', plain.lower()).strip('-')


lines = source.splitlines()
blocks = []
toc = []
i = 0
while i < len(lines):
    line = lines[i]
    if not line.strip():
        i += 1
        continue
    heading = re.match(r'^(#{1,3}) (.+)$', line)
    if heading:
        level = len(heading[1])
        identity = slug(heading[2])
        blocks.append(f'<h{level} id="{identity}">{inline(heading[2])}</h{level}>')
        if level == 2:
            toc.append(f'<a href="#{identity}">{inline(heading[2])}</a>')
        i += 1
        continue
    if line.startswith('|'):
        table = []
        while i < len(lines) and lines[i].startswith('|'):
            table.append([part.strip() for part in lines[i].strip().strip('|').split('|')])
            i += 1
        header = ''.join('<th scope="col">' + inline(v) + '</th>' for v in table[0])
        rows = ''.join('<tr>' + ''.join('<td>' + inline(v) + '</td>' for v in row)
                       + '</tr>' for row in table[2:])
        blocks.append('<div class="table-scroll"><table><thead><tr>' + header
                      + '</tr></thead><tbody>' + rows + '</tbody></table></div>')
        continue
    unordered = line.startswith('- ')
    ordered = bool(re.match(r'^\d+\. ', line))
    if unordered or ordered:
        tag = 'ul' if unordered else 'ol'
        pattern = r'^- (.*)' if unordered else r'^\d+\. (.*)'
        items = []
        while i < len(lines):
            match = re.match(pattern, lines[i])
            if not match:
                break
            items.append('<li>' + inline(match[1]) + '</li>')
            i += 1
        blocks.append(f'<{tag}>' + ''.join(items) + f'</{tag}>')
        continue
    paragraph = []
    while i < len(lines) and lines[i].strip():
        paragraph.append(lines[i])
        i += 1
    body = inline(' '.join(paragraph))
    blocks.append(('<figure>' + body + '</figure>') if body.startswith('<img ')
                  else '<p>' + body + '</p>')

css = '''
@font-face{font-family:Nunito;src:url('../../../assets/fonts/Nunito-400.ttf')}@font-face{font-family:Nunito;src:url('../../../assets/fonts/Nunito-600.ttf');font-weight:600}
@font-face{font-family:Fredoka;src:url('../../../assets/fonts/Fredoka-600.ttf');font-weight:600}
:root{color-scheme:dark;--bg:#060e19;--panel:#0d1c30;--line:#29405c;--text:#e6edf7;--muted:#aebfd9;--gold:#ffda69;--blue:#8fc9ff}
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:32px}body{margin:0;background:var(--bg);color:var(--text);font:17px/1.65 Nunito,system-ui,sans-serif}
.cover{padding:48px max(24px,calc((100vw - 1360px)/2));background:radial-gradient(ellipse at top right,#153153,transparent 70%),#091424;border-bottom:1px solid var(--line)}
.eyebrow{color:var(--gold);letter-spacing:2px;font-size:13px;text-transform:uppercase}.cover h1{font:600 clamp(30px,4vw,52px)/1.15 Fredoka,system-ui;margin:16px 0}.cover p{max-width:850px;color:var(--muted);margin:12px 0}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:22px}.chip{padding:6px 13px;background:#102339;border:1px solid #36506e;border-radius:100px;font-size:14px;color:var(--gold)}
.layout{display:grid;grid-template-columns:240px minmax(0,1fr);gap:38px;max-width:1408px;margin:auto;padding:36px 24px 80px}nav{position:sticky;top:20px;max-height:calc(100vh - 40px);overflow:auto;align-self:start;font-size:13px;border-right:1px solid var(--line);padding-right:16px}nav a{display:block;padding:7px 0;color:var(--muted);text-decoration:none}nav a:hover{color:var(--gold)}main{min-width:0}main h1{display:none}
h2{font:600 30px/1.25 Fredoka,system-ui;color:var(--gold);margin:58px 0 20px;border-top:1px solid var(--line);padding-top:28px}h2:first-of-type{margin-top:26px}h3{font:600 23px/1.3 Fredoka,system-ui;margin:34px 0 16px}p{margin:16px 0}strong{font-weight:600;color:#fff2bd}a{color:var(--blue);text-underline-offset:3px;overflow-wrap:anywhere}li{padding:4px 0}code{background:#142942;border-radius:4px;padding:1px 5px;font-size:.87em;color:var(--gold);overflow-wrap:anywhere}
.table-scroll{overflow-x:auto;border:1px solid var(--line);border-radius:14px;margin:22px 0;background:#0a1728}table{border-collapse:collapse;width:100%;font-size:15px;line-height:1.5;min-width:620px}th,td{text-align:left;vertical-align:top;padding:14px 15px;border-bottom:1px solid var(--line)}th{background:#122740;color:var(--gold);font-weight:600}tr:last-child td{border-bottom:0}tr:nth-child(even){background:#0e1d30}
figure{display:inline-block;width:calc(50% - 20px);margin:12px 16px 20px 0;vertical-align:top}figure img{width:100%;max-width:380px;border:1px solid var(--line);border-radius:16px;display:block}.toolbar{display:flex;flex-wrap:wrap;gap:12px;margin:24px 0}button,.toolbar a{font:600 15px Nunito,system-ui;border:1px solid #52667b;border-radius:10px;padding:10px 16px;color:var(--text);background:#13263f;cursor:pointer;text-decoration:none}.footer{border-top:1px solid var(--line);padding:30px 24px;color:var(--muted);text-align:center;font-size:14px}
@media(max-width:1000px){.layout{grid-template-columns:1fr;gap:20px}nav{position:static;max-height:230px;border:1px solid var(--line);padding:12px;border-radius:12px}figure{width:calc(50% - 20px)}}
@media(max-width:600px){body{font-size:16px}.cover{padding:30px 18px}.layout{padding:24px 18px}h2{font-size:26px}h3{font-size:21px}figure{display:block;width:100%;margin:16px 0}table{min-width:580px}}
@media print{:root{color-scheme:light}body{background:white;color:#1d2939;font-size:10pt;line-height:1.45}.cover{background:white;padding:0;border:0}.cover h1{font-size:28pt}.cover p,nav,.eyebrow,.chips,.toolbar,.footer{display:none}.layout{display:block;padding:0}.cover p:first-of-type{display:block;color:#334155}h2{font-size:18pt;color:#1d2939;margin-top:24pt;padding-top:12pt}h3{font-size:14pt}strong{color:#162239}a{color:#154a79}th{background:#eee;color:#1d2939}td,th{padding:7px;border-color:#ccc}.table-scroll{overflow:visible;border-color:#ccc;break-inside:auto}table{font-size:8pt;min-width:0}tr{break-inside:avoid}tr:nth-child(even){background:white}figure{width:42%;break-inside:avoid}code{color:#1d2939;background:#eee}}
'''
page = '''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cineus — análise completa · 19/10/2026</title><style>'''+css+'''</style></head><body>
<header class="cover"><div class="eyebrow">Cineus · produto e negócio · 19/10/2026</div><h1>O jogo tem base.<br>O próximo passo é provar o ciclo.</h1><p>Análise do código, conteúdo, experiência, mercado, retenção e receita dentro do jogo. Evidências, hipóteses e prioridades separadas para orientar as próximas decisões.</p><div class="chips"><span class="chip">500 filmes</span><span class="chip">50 personagens</span><span class="chip">803 testes Flutter</span><span class="chip">57 testes backend</span><span class="chip">14 pontos de atenção</span></div><div class="toolbar"><button onclick="window.print()">Imprimir / salvar PDF</button><a href="RELATORIO.md">Texto completo em Markdown</a><a href="evidencias.json">Evidências em JSON</a></div></header>
<div class="layout"><nav aria-label="Índice do relatório">'''+''.join(toc)+'''</nav><main>'''+''.join(blocks)+'''</main></div><footer class="footer">Análise e planejamento. Nenhuma regra de gameplay alterada. Cenários financeiros são hipóteses, não previsão de faturamento.</footer></body></html>'''
(ROOT / 'RELATORIO.html').write_text(page, encoding='utf-8')
print('HTML generated:', ROOT / 'RELATORIO.html')
