import sqlite3

conn = sqlite3.connect(r'c:\Projects\Cineus\assets\cineus_v1.db')
cur = conn.cursor()
cur.execute("SELECT id, title, year FROM movies ORDER BY title, year")
rows = cur.fetchall()

FRANCHISE_IDS = {
    "007": {293, 271, 138, 481},
    "A Bela e a Fera": {139, 333},
    "A Era do Gelo": {176, 355, 448},
    "Aladdin": {260, 335},
    "Alien": {132, 329, 213, 405},
    "Animais Fantásticos": {76, 277},
    "Anjos da Lei": {314, 477},
    "Avatar": {5, 185},
    "Batman": {469, 265, 42, 83, 4, 25},
    "Blade Runner": {159, 155},
    "Bourne": {371, 497},
    "Capitão América": {41, 72, 28},
    "Carros": {154, 484},
    "Cinquenta Tons": {246, 495},
    "Como Treinar o Seu Dragão": {173, 346},
    "Corpo Fechado": {382, 94, 428},
    "Crepúsculo": {172, 388, 414, 412, 406},
    "De Volta para o Futuro": {52, 188, 280},
    "Deadpool": {6, 81, 482},
    "Divergente": {206, 345},
    "Doutor Estranho": {33, 362},
    "Esquadrão Suicida": {48, 400},
    "Esqueceram de Mim": {244, 337},
    "Frozen": {106, 360},
    "Godzilla / Kong": {387, 301, 336},
    "Guardiões da Galáxia": {11, 39},
    "Harry Potter": {13, 30, 37, 47, 62, 60, 68, 50},
    "Homem de Ferro": {14, 43, 34},
    "Homem-Aranha": {63, 130, 153, 89, 180, 36, 116, 51, 111, 486},
    "Homem-Formiga": {58, 182},
    "Indiana Jones": {201, 369, 308, 437},
    "Invocação do Mal": {233, 421},
    "IT": {69, 396},
    "John Wick": {61, 179, 268},
    "Jogos Vorazes": {35, 91, 121, 210},
    "Jumanji": {291, 171, 408},
    "Jurassic Park": {104, 419, 54, 230},
    "Kill Bill": {86, 156},
    "Kingsman": {103, 303},
    "Liga da Justiça": {199, 328},
    "Matrix": {16, 264, 330},
    "Maze Runner": {97, 310, 494},
    "Meu Malvado Favorito": {140, 261, 304},
    "MIB - Homens de Preto": {166, 334, 315},
    "Missão: Impossível": {378, 332, 394, 424},
    "Monstros S.A.": {75, 288},
    "Mulher-Maravilha": {57, 432},
    "O Exterminador do Futuro": {170, 181, 440},
    "O Hobbit": {78, 183, 149},
    "O Poderoso Chefão": {40, 189},
    "O Rei Leão": {77, 331},
    "O Senhor dos Anéis": {19, 29, 21},
    "Onze Homens e um Segredo": {243, 454},
    "Os Incríveis": {85, 198},
    "Piratas do Caribe": {46, 113, 147, 158, 227},
    "Planeta dos Macacos": {231, 253, 392},
    "Procurando Nemo": {65, 234},
    "Quarteto Fantástico": {375, 493},
    "Se Beber, Não Case!": {99, 292, 418},
    "Sherlock Holmes": {167, 317},
    "Shrek": {88, 207, 385},
    "Star Trek": {344, 395},
    "Star Wars / Guerra nas Estrelas": {45, 93, 117, 143, 174, 161, 64, 129, 327, 127, 415},
    "Thor": {44, 95, 49, 474},
    "Top Gun": {401, 325},
    "Toy Story": {74, 162, 144, 341},
    "Transformers": {256, 422, 444, 461},
    "Truque de Mestre": {122, 273},
    "Venom": {110, 300},
    "Velozes e Furiosos": {326, 451, 299, 290, 323},
    "Vingadores": {3, 24, 8, 18},
    "Wolverine": {361, 67},
    "X-Men": {255, 320, 354, 294, 204, 133, 194},
}

FRANCHISE_NOTES = {
    "Alien": "Alien: O Oitavo Passageiro, Aliens: O Resgate, Prometheus, Alien: Covenant",
    "Batman": "Batman (1989), Batman Begins, Batman: O Cavaleiro das Trevas, Batman: O Cavaleiro das Trevas Ressurge, Batman vs Superman, Batman (2022)",
    "Bourne": "A Identidade Bourne, O Ultimato Bourne",
    "Corpo Fechado": "Corpo Fechado (Unbreakable), Fragmentado (Split), Vidro (Glass)",
    "Crepúsculo": "Crepúsculo, Lua Nova, Eclipse, Amanhecer Pt.1, Amanhecer Pt.2",
    "Godzilla / Kong": "Godzilla (2014), Kong: A Ilha da Caveira, Godzilla vs. Kong",
    "Homem-Aranha": "Trilogia Raimi + Espetacular Homem-Aranha + MCU + Aranhaverso (10 filmes)",
    "Meu Malvado Favorito": "Meu Malvado Favorito 1 e 2 + Minions",
    "Monstros S.A.": "Monstros S.A. + Universidade Monstros",
    "Onze Homens e um Segredo": "Ocean's Eleven (2001) + Ocean's 8 (2018)",
    "Star Wars / Guerra nas Estrelas": "Trilogia original + Prelogy + Sequel Trilogy + Rogue One + Han Solo (11 filmes)",
    "X-Men": "X-Men: O Filme, X-Men 2, O Confronto Final, Origens: Wolverine, Primeira Classe, Dias de um Futuro Esquecido, Apocalipse",
}

franchise_movie_ids = set()
for ids in FRANCHISE_IDS.values():
    franchise_movie_ids |= ids

id_to_row = {mid: (title, year) for mid, title, year in rows}
standalone = [(mid, title, year) for mid, title, year in rows if mid not in franchise_movie_ids]

lines = []
lines.append("# Mapeamento de Filmes — cineus_v1.db")
lines.append("")
lines.append(f"> **Total no DB:** 500 filmes  ")
lines.append(f"> **Franquias detectadas:** {len(FRANCHISE_IDS)}  ")
lines.append(f"> **Filmes únicos:** {len(standalone)}  ")
lines.append(f"> **Entradas únicas totais:** {len(FRANCHISE_IDS) + len(standalone)}")
lines.append("")
lines.append("---")
lines.append("")
lines.append("## Franquias")
lines.append("")
lines.append("*Para cada franquia é exibido apenas o nome base. A quantidade indica filmes presentes neste DB.*")
lines.append("")
lines.append("| # | Franquia | Filmes no DB | Observação |")
lines.append("|---|---------|:---:|------|")

for i, (fname, ids) in enumerate(sorted(FRANCHISE_IDS.items()), 1):
    note = FRANCHISE_NOTES.get(fname, "")
    lines.append(f"| {i} | **{fname}** | {len(ids)} | {note} |")

lines.append("")
lines.append("---")
lines.append("")
lines.append("## Filmes Únicos")
lines.append("")
lines.append("*Filmes que aparecem uma única vez no DB, sem outros títulos da mesma série.*")
lines.append("")

standalone_sorted = sorted(standalone, key=lambda x: x[1].lstrip("AEIOU áéíóú").lower())
for mid, title, year in sorted(standalone, key=lambda x: x[1].lower()):
    lines.append(f"- {title} *({year})*")

output = "\n".join(lines)

with open(r"c:\Projects\Cineus\filmes_mapeados.md", "w", encoding="utf-8") as f:
    f.write(output)

print("Arquivo gerado: filmes_mapeados.md")
print(f"Franquias: {len(FRANCHISE_IDS)} | Únicos: {len(standalone)} | Total entradas: {len(FRANCHISE_IDS) + len(standalone)}")


