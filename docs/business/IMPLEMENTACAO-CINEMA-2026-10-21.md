# Implementação Cineus — cinema, coleções e monetização

21/10/2026 · alterações locais; sem APK, publicação, compra real ou ativação de anúncios.

## Escopo confirmado durante a implementação

Os personagens conhecidos do **modo Cores permanecem**. O novo elenco substitui exclusivamente os antigos mascotes de animais de avatares, missões, coleções e temporadas. A proposta anterior de trocar Cores por um piloto de personagens desconhecidos foi cancelada conforme a orientação do usuário.

A procedência foi conferida: os mesmos **50 personagens, 110 regiões editáveis e 160 SVGs** de Cores continuam correspondendo aos hashes registrados. Catálogo, paletas, perguntas, seleção diária, pontuação e histórico desse modo foram preservados.

## Elenco de homenagens

As 12 artes finais foram produzidas com o ImageGen integrado. Usam humor de bastidores, equipamentos de cinema, rostos, figurinos, paletas e silhuetas próprios. Não contêm nomes de franquias, marcas ou atores dentro dos desenhos. Os títulos abaixo são os exibidos no jogo; a coluna de inspiração documenta a direção criativa, sem afirmar associação ou autorização dos titulares.

| Avatar | Referência criativa |
| --- | --- |
| Íris, a Última Técnica | Ellen Ripley / Alien |
| Dante Rebobina | Neo / Matrix |
| Otto Corte-Final | Terminator |
| Vera Penumbra | Batman |
| Nara Estelar | Princesa Leia / Star Wars |
| Glifo Caça-Cenas | Ghostbusters |
| Maya Corte-Bruto | Rambo |
| Bento Rolo-Perdido | Indiana Jones |
| Raul Duplo-Corte | James Bond |
| Cora Maré-de-Cena | Jack Sparrow / Pirates of the Caribbean |
| Enzo Replay | Marty McFly / Back to the Future |
| Sol Última-Tomada | A Noiva / Kill Bill |

Prompts, imagens originais, transformações técnicas e hashes estão em [cinema-homages-v3](C:/Projects/Cineus/docs/artwork/cinema-homages-v3/MANIFEST.json). O processamento posterior apenas recorta a transparência, redimensiona e centraliza as imagens. Nenhuma arte desse elenco entra nas perguntas de Cores.

Os 12 IDs de propriedade antigos foram mantidos. Nomes internos como avatar_owl_v1 são identificadores de migração; o jogador vê as artes e nomes novos. A restauração não depende da aparência anterior.

O catálogo local passou à versão 5, e o manifesto comercial à revisão 4 com catálogo mínimo 5. Avatares antigos baixados do servidor não sobrepõem as novas artes locais. O servidor agora aceita explicitamente os catálogos 3, 4 e 5, rejeitando tipos incorretos e versões futuras. Foram removidos os 12 arquivos antigos de animais e nove origens que ficaram sem referência. Rascunhos descartados desta rodada também foram removidos.

## Produto e oferta comercial

- Tickets, ajuda por vídeo e anúncios continuam sendo o núcleo comercial. Os limites compartilhados de vídeo e a validação de recompensas pelo servidor foram preservados.
- Novas vendas de coleções e novas assinaturas do Clube estão pausadas na configuração de build. Direitos antigos, verificação de transações pendentes, restauração e reembolso permanecem suportados.
- Plus pode ser oferecido para remover anúncios comuns quando existirem nativos ou banners efetivamente configurados; não depende mais da presença de intersticiais. Sem anúncio coberto ou preço real de loja, não há oferta.
- Os itens de coleções anteriores entram na rotação das missões. Ofertas semanais já fixadas e recompensas já reclamadas não são substituídas retroativamente.
- A prévia da coleção destaca o avatar com tamanho maior. A arte pequena de identidade usada nos cartões compartilháveis mantém sua função de identificação.
- Temporadas passou a se chamar **Mostras de cinema**, com três seleções jogáveis: animação, fantasia e clássicos, cada uma com dez títulos do catálogo existente e escolha entre Dicas e Pôster.
- As Mostras são uma seleção de prática: não cobram entrada em tickets, não alteram a sequência dos estágios e mantêm sessões próprias por versão, modo e filme. Respostas e resultados são retomados; o botão Próximo avança dentro da seleção.
- Ganhar e equipar um visual continuam sendo ações distintas. Explorar uma prévia não concede propriedade.

Não foram modificados simultaneamente preços, cota diária, dificuldade ou saldos existentes. O teste econômico de bônus 10 versus 4 continua controlado pelo backend, com contratos por estágio preservados. A nova oferta precisa de medição com usuários reais; não há evidência nesta entrega de aumento de receita ou de conversão.

## Faixa etária e dados

O primeiro acesso solicita apenas uma faixa etária declarada. Não são coletados data de nascimento ou documento nesse fluxo.

| Estado | Anúncios | Novas compras | Métricas e testes comerciais |
| --- | --- | --- | --- |
| Desconhecido ou menor de 16 | SDK não inicializado | Bloqueadas | Desativados |
| 16–17 | Tratamento de adolescente, sem personalização | Bloqueadas e sem vitrine de preços | Desativados |
| 18+ declarado | Sujeitos à configuração e ao consentimento | Sujeitas à loja e verificação do servidor | Somente conforme configuração e consentimento |

A restauração de direitos existentes continua disponível. A declaração local **não é verificação de identidade nem garantia de idade**. Aferição etária, controles da loja e adequação regulatória precisam de revisão antes da disponibilização pública. Os textos de privacidade e termos descrevem os controles implementados e distinguem ofertas atuais de direitos antigos.

## Direitos e publicação

Mudar nomes, gerar imagens ou introduzir humor não equivale a obter licença nem garante que uma homenagem seja juridicamente permitida. O grupo das 12 homenagens foi registrado como **pendente de revisão**, com a referência criativa explícita. Não foi marcado como licenciado.

Permanecem pendentes a avaliação dessas artes e da marca, a procedência comercial de dados e pôsteres e a situação dos personagens conhecidos mantidos em Cores. A opção de preservar Cores não resolve essa pendência.

A validação pública continua recusando a liberação sem evidências:

```powershell
.\.venv\Scripts\python.exe scripts/validate_content_rights.py --public-release
```

Referências oficiais para a revisão: [Lei de Direitos Autorais](https://www.planalto.gov.br/ccivil_03/leis/l9610.htm), [política de propriedade intelectual do Google Play](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en), [diretrizes da Apple](https://developer.apple.com/app-store/review/guidelines/) e [condições de uso comercial do TMDB](https://developer.themoviedb.org/docs/faq).

IDs reais de AdMob, autenticação/consentimento nas plataformas, compras e restauração em Android/iOS, classificação indicativa e revisão jurídica não foram simulados como concluídos. Os espaços de anúncios não configurados continuam sendo placeholders, conforme solicitado.

## Verificação

- Análise estática Flutter sem erros.
- 32 fontes de arte de coleção verificadas, incluindo transparência e hashes dos 12 novos avatares.
- 50 personagens e 110 regiões de Cores validados sem substituição.
- Verificação de uso: 235 arquivos Dart de produção alcançáveis e 1.130 assets/origens registrados.
- Dez testes do servidor de conteúdo passaram, incluindo compatibilidade de versões e rejeição de conteúdo inválido.
- Uma execução completa percorreu 857 testes: 852 passaram inicialmente; cinco cenários foram corrigidos/atualizados para o novo comportamento e incluídos na reexecução focada de 45 testes, todos aprovados. Essa rodada inclui um teste novo adicional sobre dados de adolescentes.
- Capturas de widgets reais, com SQLite e fontes do app, foram realizadas para coleção, Mostras, seleção de filmes e faixa etária. Há também testes de telas compactas com texto a 200%.

[Galeria de artes e telas](C:/Projects/Cineus/docs/preview/cinema-rebrand-2026-10-21/GALERIA.html).
