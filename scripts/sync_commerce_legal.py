"""Keep the public HTML conditional commerce copy equal to the in-app text."""
import html
from pathlib import Path
import re
import shutil
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'lib/l10n/commerce_legal_copy.dart').read_text(encoding='utf-8')
source=re.sub(r'\s*=>\s*','=>',source)
for method,target in [('privacy','privacy'),('terms','terms')]:
    section=source.split(' '+method+'(String language)')[1].split('  };',1)[0]
    paragraphs={}
    for lang,next_marker in [('pt',"'es'=>"),('es','_=>'),('en',None)]:
        marker="'"+lang+"'=>" if lang!='en' else '_=>'
        block=section.split(marker,1)[1]
        if next_marker:block=block.split(next_marker,1)[0]
        rows=re.findall(r"\(\s*'([^']*)',\s*'([^']*)',?\s*\)",block)
        if not rows:raise ValueError('No localized commerce legal text')
        paragraphs[lang]='\n'.join('<h2 lang="'+lang+'">'+html.escape(title)+'</h2>\n<p lang="'+lang+'">'+html.escape(body)+'</p>' for title,body in rows)
    path=ROOT/'docs'/f'{target}.html';text=path.read_text(encoding='utf-8')
    text=re.sub(r'<!-- commerce-copy:.*?<!-- /commerce-copy -->\s*','',text,flags=re.S)
    parts=re.split(r'\s*<hr>\s*',text)
    if len(parts)!=3:raise ValueError('Expected three localized HTML sections')
    for i,lang in enumerate(['pt','en','es']):
        insert='\n<!-- commerce-copy:'+lang+' -->\n'+paragraphs[lang]+'\n<!-- /commerce-copy -->\n'
        if i==2:parts[i]=parts[i].replace('</main>',insert+'</main>')
        else:parts[i]+=insert
    path.write_text('  <hr>'.join(parts),encoding='utf-8')
    shutil.copyfile(path,ROOT/'web'/path.name)
print('Commerce privacy/terms synchronized for PT/EN/ES; not published')
