# Geração de localização

Os ARBs em `lib/l10n/` são a fonte dos textos. PT é o template; manter as chaves
e os placeholders correspondentes em PT/EN/ES. Isso não libera idiomas cujo
catálogo de gameplay ainda não esteja traduzido.

O projeto versiona os quatro arquivos `app_l10n*.dart` gerados. Eles devem
acompanhar os ARBs, usando a versão Flutter fixada em `.flutter-version`.

Após alterar um ARB:

```powershell
flutter gen-l10n
flutter analyze --fatal-infos
flutter test test/l10n_test.dart test/no_hardcoded_strings_test.dart
```

Incluir os ARBs alterados e seus arquivos gerados na mesma mudança. Não editar
manualmente o Dart gerado. O CI executa a geração e verifica se ela modificou
arquivos versionados; diferenças bloqueiam o check e precisam ser regeneradas.

Na Sprint 1, os arquivos gerados foram atualizados para representar as chaves
que os ARBs já possuíam, sem modificar os textos do catálogo ou liberar EN/ES.
