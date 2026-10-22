# Padronização das categorias — 21/10/2026

Solicitação: seis itens das capturas enviadas; o item 2 era apenas uma pergunta.

- Filmes, Pôsteres e Cores compartilham `CategoryBackdrop`, incluindo imagem, desfoque, máscara e cor da superfície.
- O aviso **Retomar grátis** foi mantido. Informa que continuar uma partida existente não desconta outro ticket; não é um botão.
- Estatísticas de Cores mantêm notas e rodadas reais, com a mesma grade, ordem visual dos ícones e cores das outras categorias. Os dois cards de cada linha têm a mesma altura, inclusive com rótulos de tamanhos diferentes.
- A inicial usa o componente nativo existente entre o contador e o cartão de continuação. Os espaços continuam como placeholders enquanto AdMob/backend não forem configurados; a interface respeita a supressão de anúncios dos benefícios comerciais.
- Filmes e Pôsteres compartilham `StageNavigationIndicator`, com chevron dourado e círculo de contorno, além do indicador de conclusão e cadeado.
- Jornada usa uma linha de três botões de largura igual: **Arquivo**, **Domínio**, **Amigos**. Leitores de tela e tooltips mantêm os nomes completos. Com texto ampliado, a faixa rola horizontalmente sem reduzir a fonte.

Galeria com capturas dos widgets reais: `docs/preview/category-consistency-2026-10-21/GALERIA.html`.

Os dados das capturas são fixtures locais. Não foi gerado APK nesta rodada.

Reprodução das capturas:

```powershell
flutter test --no-pub test/category_consistency_test.dart --concurrency=2 --dart-define=CINEUS_CAPTURE_CONSISTENCY=true
```

Validação: sete testes de interface próprios desta alteração, incluindo navegação dos três atalhos em português, inglês e espanhol com texto em 200%, mais 75 testes dos fluxos relacionados; todos passaram. A análise estática não apontou problemas. Os logs estão em `build/ui-consistency-tests.log`, `build/ui-consistency-regression.log` e `build/ui-consistency-analyze.log`. A galeria possui 14 capturas locais verificadas.
