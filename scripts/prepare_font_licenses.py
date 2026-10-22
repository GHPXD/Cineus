"""Audit the bundled Fredoka/Nunito fonts and official OFL notices."""
import hashlib
import json
from pathlib import Path
from fontTools.ttLib import TTFont
ROOT=Path(__file__).resolve().parents[1]
audit=[]
for family in ['Fredoka','Nunito']:
 path=ROOT/f'assets/licenses/{family}-OFL.txt'
 assert 'SIL OPEN FONT LICENSE' in path.read_text(encoding='utf-8')
 audit.append({'family':family,'official_license_url':f'https://raw.githubusercontent.com/google/fonts/main/ofl/{family.lower()}/OFL.txt','license_sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
fonts=[]
for path in sorted((ROOT/'assets/fonts').glob('*.ttf')):
 with TTFont(path) as font:
  fonts.append({'file':path.relative_to(ROOT).as_posix(),'family':font['name'].getDebugName(1),'weight':font['OS/2'].usWeightClass,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'copyright':sorted({n.toUnicode() for n in font['name'].names if n.nameID==0})})
(ROOT/'docs/artwork/fonts.json').write_text(json.dumps({'upstream_licenses':audit,'bundled_fonts':fonts,'source':'https://github.com/google/fonts','decision':'Full glyph sets, static weight instances from official variable fonts; no subsetting or custom glyphs.'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'{len(fonts)} font instances audited; 2 official OFL notices included.')
