# Fechamento na abertura do Android

Reprodução no Galaxy S23 Ultra (SM-S918B), Android 16, com o APK de teste
1.0.0, código 12. Instalação por USB e abertura da atividade principal
reproduziram `Unable to get provider androidx.startup.InitializationProvider`,
causado por `Failed to create an instance of androidx.work.impl.WorkDatabase`.
A falha ocorre antes da inicialização do Flutter.

O relatório de remoções do R8 lista o construtor público sem argumentos de
`androidx.work.impl.WorkDatabase_Impl` como removido. Room 2.2.5, dependência
transitiva de WorkManager 2.7.0, fornece uma regra que preserva a classe sem
preservar explicitamente esse construtor no modo completo do R8.

Foi adicionada a regra específica de construtores de subclasses de RoomDatabase
em `android/app/proguard-rules.pro`, seguindo a
[correção do AndroidX Room](https://android.googlesource.com/platform/frameworks/support/+/e4765e38e27a3f4d86188b996df97a52403dff46).
A otimização de release e os inicializadores Android permanecem ativos.
O banco de progresso do jogo não foi apagado nem teve seu esquema alterado.

`scripts/verify_android_startup.py` lê os DEX do APK/AAB real e confere que a
atividade principal e WorkDatabase_Impl mantêm construtores públicos concretos
sem argumentos. Esse teste falhou no APK 12 pelo construtor ausente. O CI passa
a executá-lo após a compilação do AAB, além dos testes Dart existentes.

## Validação concluída

- APK otimizado 1.0.0, código 13, compilado com a mesma assinatura de
  desenvolvimento do APK 12 e instalado por atualização (`adb install -r`).
- Verificador dos DEX: falhou no APK 12 e passou no APK 13.
- Três aberturas em novos processos, sem a falha nativa anterior. Tela inicial
  conferida com o aparelho desbloqueado; saldo e estatísticas existentes visíveis.
- Ida à tela inicial do Android e retorno ao Cineus: abertura HOT, mesmo processo,
  sem exceção fatal ou exceção Dart não tratada.
- Validador de compliance passou. Nenhum código Dart ou esquema de dados do jogo
  foi alterado nesta correção; não foi necessária uma nova regressão Dart completa.
- SHA-256 do APK: `4d09313fc250bbe3df3f32ed9b339558ac991d4e80394a8416dc5541af672fa0`.

Foi registrado separadamente um diagnóstico gráfico do Impeller
(`Contents::SetInheritedOpacity`), depois do desbloqueio. Não encerrou o processo
nem impediu a renderização da tela inicial e não foi tratado por esta alteração.
A verificação de abertura não deve ser interpretada como ausência de todos os
diagnósticos gráficos ou validação completa das integrações de monetização.

Evidências locais: `startup-crash-before-2026-10-15.log`,
`startup-fix-build-2026-10-15.log`, `startup-fixed-launches-2026-10-15.json`,
`startup-fixed-resume-2026-10-15.json` e `startup-fixed-device-2026-10-15.png`.
