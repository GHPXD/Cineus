# Colecionáveis chibi — 22/10/2026

32 itens substituídos no aplicativo: 12 personagens de corpo inteiro, 14 molduras e 6 fundos. As duas prévias aprovadas foram reaproveitadas a partir dos originais exatos; as outras 30 artes foram criadas com o ImageGen integrado, uma geração por item.

Os arquivos finais ficam em `assets/collection/`. `MANIFEST.json` registra caminhos, hashes, inspirações e prompts. Nos dois originais aprovados, o texto é identificado como resumo de procedência, sem apresentá-lo como transcrição do prompt original. As fontes originais foram copiadas integralmente para `sources/`.

O conceito de herói mascarado não foi gerado pela ferramenta; seu espaço passou a Vitor Plano-Mestre, um mago de cinema. Os outros personagens seguem o elenco documentado. As artes e os nomes são alusões criativas; a revisão jurídica continua pendente no inventário de direitos, sem afirmar liberação de terceiros.

IDs de propriedade, itens iniciais, coleções, compras anteriores e equipamentos foram preservados. O catálogo passou à versão 6, com manifesto de conteúdo revisão 5. Downloads antigos não substituem as artes locais aprovadas. O pacote de conteúdo local foi atualizado e verificado; não foi publicado.

O catálogo conhecido do modo Cores e suas regiões editáveis permanecem intactos. As 20 fontes antigas das molduras e fundos saíram dos assets empacotados e foram arquivadas em `docs/artwork/collection-retired-v3/`.

Validação concluída:

- 46 testes Flutter aprovados: coleção, persistência dos itens, prévias, conteúdo assinado e exportação dos cartões. Cobertura de PT/EN/ES, 320 px e texto ampliado a 200%.
- Captura final da coleção aprovada separadamente, verificando o personagem selecionado e a distinção entre as três prévias.
- 11 testes do backend de conteúdo aprovados, incluindo suporte ao catálogo 6 e rejeição de versão futura/tipos inválidos.
- `flutter analyze --no-pub`: sem problemas.
- Validadores de arte, 50 sprites de Cores, uso dos arquivos, conteúdo gerado, conformidade de release e inventário de direitos aprovados. O último registra cinco grupos ainda pendentes de evidências jurídicas.

Galeria: `docs/preview/chibi-collection-2026-10-22/GALERIA.html`. Usa as artes finais e capturas de widgets/rotas reais do Flutter. Nenhum APK foi gerado e não houve nova instalação no celular.

Reprodução local: `python scripts/build_chibi_collection.py`, `flutter gen-l10n`. O construtor usa as fontes preservadas no projeto e não precisa acessar novamente o diretório pessoal de imagens geradas. O antigo construtor de retratos agora encaminha para este, evitando restaurar a arte rejeitada.
