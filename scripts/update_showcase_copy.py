import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
COPY=json.loads("{\"pt\":{\"showcaseAnimation\":\"Mundos de animação\",\"showcaseFantasy\":\"Além da imaginação\",\"showcaseClassics\":\"Clássicos em cartaz\",\"showcasePlay\":\"Escolher partidas\",\"showcasePractice\":\"Uma seleção para jogar no seu ritmo. Seu avanço fica salvo.\",\"showcaseRewards\":\"Os visuais entram na rotação das missões. O que você já conquistou continua seu.\",\"showcaseFilm\":\"Filme {number}\"},\"en\":{\"showcaseAnimation\":\"Animated worlds\",\"showcaseFantasy\":\"Beyond imagination\",\"showcaseClassics\":\"Classics on screen\",\"showcasePlay\":\"Choose games\",\"showcasePractice\":\"A selection to play at your own pace. Your progress is saved.\",\"showcaseRewards\":\"Looks rotate through mission rewards. Everything you already own stays yours.\",\"showcaseFilm\":\"Film {number}\"},\"es\":{\"showcaseAnimation\":\"Mundos animados\",\"showcaseFantasy\":\"Más allá de la imaginación\",\"showcaseClassics\":\"Clásicos en cartel\",\"showcasePlay\":\"Elegir partidas\",\"showcasePractice\":\"Una selección para jugar a tu ritmo. Tu avance se guarda.\",\"showcaseRewards\":\"Los estilos rotan entre las recompensas de misiones. Lo que ya tienes sigue siendo tuyo.\",\"showcaseFilm\":\"Película {number}\"}}")
for lang,copy in COPY.items():
    path=ROOT/f'lib/l10n/app_{lang}.arb'
    content=json.loads(path.read_text(encoding='utf8'))
    content.update(copy)
    content['@showcaseFilm']={'placeholders':{'number':{'type':'int'}}}
    path.write_text(json.dumps(content,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
