"""Append forty distinct illustrated characters, preserving every original question."""
import colorsys,json,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/artwork/characters/expanded'
WORKS={
 'The Simpsons':{'pt':'Os Simpsons','es':'Los Simpson'},
 'Dragon Tales':{'pt':'Histórias de Dragões','es':'Dragon Tales'},
 'Winnie the Pooh':{'pt':'Ursinho Pooh','es':'Winnie the Pooh'},
 'The Amazing World of Gumball':{'pt':'O Incrível Mundo de Gumball','es':'El increíble mundo de Gumball'},
 'Family Guy':{'pt':'Uma Família da Pesada','es':'Padre de familia'},
 'Adventure Time':{'pt':'Hora de Aventura','es':'Hora de aventuras'},
 'SpongeBob SquarePants':{'pt':'Bob Esponja Calça Quadrada','es':'Bob Esponja'},
}

def main():
    baseline=ROOT/'test/fixtures/color_training_v1.json'
    if not baseline.exists():shutil.copyfile(ROOT/'assets/colors/training_v1.json',baseline)
    old=json.loads(baseline.read_text(encoding='utf8'))
    assert old['pack_version']=='training-1' and len(old['questions'])==50
    roster=json.loads((OUT/'ROSTER.json').read_text(encoding='utf8'))
    art={r['id']:r for r in json.loads((OUT/'MANIFEST.json').read_text(encoding='utf8'))}
    assert len(roster)==len(art)==40
    questions=list(old['questions'])
    for row in roster:
        assert row['id'] in art and row['target_hex'] and row['source_url']
        rgb=tuple(int(row['target_hex'][i:i+2],16) for i in [1,3,5])
        h,s,v=colorsys.rgb_to_hsv(*(c/255 for c in rgb))
        family=('warm' if h*360<65 or h*360>320 else 'green' if h*360<165 else 'blue' if h*360<255 else 'violet')
        hints={
          'warm':{'pt':'Lembre um tom quente; observe a intensidade sem incluir contornos ou sombras.','en':'Recall a warm tone; consider its intensity without outlines or shadows.','es':'Recuerda un tono cálido; piensa en su intensidad sin contornos ni sombras.'},
          'green':{'pt':'Pense na família dos verdes e no quanto esse tom é vivo.','en':'Think of the green family and how vivid the tone is.','es':'Piensa en la familia de verdes y en lo vivo que es el tono.'},
          'blue':{'pt':'Lembre um tom frio e ajuste o equilíbrio entre azul e verde.','en':'Recall a cool tone and balance its blue and green.','es':'Recuerda un tono frío y equilibra el azul y el verde.'},
          'violet':{'pt':'Pense na mistura de azul e vermelho e na intensidade da parte indicada.','en':'Think of the blue and red mixture and the intensity of the indicated part.','es':'Piensa en la mezcla de azul y rojo y en la intensidad de la zona indicada.'},
        }[family]
        copy={lang:{'character':row['names'][lang],'work':WORKS.get(row['work'],{}).get(lang,row['work']),'part':row['parts'][lang],'hint':hints[lang]} for lang in ['pt','en','es']}
        q=dict(id=row['id']+'_primary',character_id=row['id'],art_part='p0',target_hex=row['target_hex'],copy=copy,
            source_url=row['source_url'],reference_image=row['reference_image'],reference_edition=row.get('edition_note','Fixed published study or official reference image, reviewed 2026-10-13; Cineus illustration is presentation only'),
            validation='Reviewed fixed reference colour; never derived from generated artwork',reference_sha256=row['reference_sha256'])
        if row.get('sampling'):q['sampling']=row['sampling']
        questions.append(q)
    assert len(questions)==90 and len({q['id'] for q in questions})==90 and len({q['character_id'] for q in questions})==50
    assert questions[:50]==old['questions']
    pack=dict(schema_version=1,pack_version='training-2',status='local-training',checked_on='2026-10-13',
        reference_policy='50 distinct characters, 90 regions: original 50 regions preserved; new fixed published-study or official/existing-reference colours. Generated artwork never determines targets. Sessions pin their original catalogue edition.',questions=questions)
    (ROOT/'assets/colors/training_v1.json').write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('50 distinct characters / 90 live regions; original training-1 questions preserved in immutable fixture.')

if __name__=='__main__':main()
