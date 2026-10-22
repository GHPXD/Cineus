import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_l10n.dart';
import 'screens/support_screen.dart';
import 'providers/external_links.dart';
import 'visuals/cineus_assets.dart';
import 'widgets/cineus_icon.dart';
import 'widgets/cineus_state_art.dart';

/// Owns database startup before the routed application is mounted.
///
/// The database used to be awaited before `runApp`, so any corruption, failed
/// asset copy or transient open error left the player on the native launch
/// screen with no recovery path. This shell always renders and keeps recovery
/// independent from providers that themselves require SQLite.
class DatabaseBootstrap extends StatefulWidget {
  final Future<void> Function() initialize;
  final Future<void> Function() repair;
  final Widget child;
  final ExternalLinks? support;

  const DatabaseBootstrap({
    super.key,
    required this.initialize,
    required this.repair,
    required this.child,
    this.support,
  });

  @override
  State<DatabaseBootstrap> createState() => _DatabaseBootstrapState();
}

class _DatabaseBootstrapState extends State<DatabaseBootstrap> {
  Object? _error;
  bool _working = true;
  bool _initializing = false;
  bool _repairDialogOpen = false;
  bool _repairAttempted = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initializing || _repairDialogOpen) return;
    _initializing = true;
    if (mounted) {
      setState(() {
        _working = true;
        _error = null;
      });
    }

    try {
      await widget.initialize();
      if (!mounted) return;
      setState(() => _working = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = error;
      });
    } finally {
      _initializing = false;
    }
  }

  Future<void> _repair(BuildContext dialogContext) async {
    if (_working || _repairDialogOpen) return;
    _repairDialogOpen = true;
    final strings = _BootstrapStrings.of(dialogContext);
    try {
      final confirmed = await showDialog<bool>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(strings.repairTitle),
          content: Text(
            '${strings.repairWarning}\n\n${kIsWeb ? strings.webBackup : strings.mobileBackup}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.repairAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() {
        _working = true;
        _error = null;
        _repairAttempted = true;
      });
      try {
        await widget.repair();
        if (!mounted) return;
        setState(() => _working = false);
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _working = false;
          _error = error;
        });
      }
    } finally {
      _repairDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_working && _error == null) return widget.child;

    return ProviderScope(
      overrides: [
        if (widget.support != null)
          externalLinksProvider.overrideWithValue(widget.support!),
      ],
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Builder(
          builder: (bootstrapContext) {
            final strings = _BootstrapStrings.of(bootstrapContext);
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: _working
                            ? _LoadingState(strings: strings)
                            : _ErrorState(
                                strings: strings,
                                repairAttempted: _repairAttempted,
                                onRetry: _initialize,
                                onRepair: () => _repair(bootstrapContext),
                                onSupport: () =>
                                    Navigator.of(bootstrapContext).push(
                                      MaterialPageRoute<void>(
                                        builder: (c) => SupportScreen(
                                          onBack: () => Navigator.of(c).pop(),
                                        ),
                                      ),
                                    ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final _BootstrapStrings strings;

  const _LoadingState({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: strings.preparing,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            strings.preparing,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            strings.loadingDetail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final _BootstrapStrings strings;
  final VoidCallback onRetry;
  final VoidCallback onRepair;
  final VoidCallback onSupport;
  final bool repairAttempted;

  const _ErrorState({
    required this.strings,
    required this.onRetry,
    required this.onRepair,
    required this.onSupport,
    required this.repairAttempted,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CineusStateArt(CineusStateKind.recovery),
          const SizedBox(height: 20),
          Text(
            strings.errorTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            repairAttempted ? strings.repairFailure : strings.errorBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const CineusIcon(CineusAssetId.retry),
              label: Text(strings.retry),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRepair,
              icon: const CineusIcon(CineusAssetId.repair),
              label: Text(strings.repairAction),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.repairHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton(
            onPressed: onSupport,
            child: Text(AppL10n.of(context).supportTitle),
          ),
        ],
      ),
    );
  }
}

/// Bootstrap copy cannot depend on the saved app locale because that preference
/// lives in the database we are trying to open. Use the device language as the
/// safe pre-database fallback, then the normal AppL10n takes over after startup.
class _BootstrapStrings {
  final String preparing;
  final String errorTitle;
  final String errorBody;
  final String retry;
  final String repairAction;
  final String repairHint;
  final String repairTitle;
  final String repairWarning;
  final String cancel;
  final String mobileBackup, webBackup, repairFailure;
  final String loadingDetail;

  const _BootstrapStrings({
    required this.preparing,
    required this.errorTitle,
    required this.errorBody,
    required this.retry,
    required this.repairAction,
    required this.repairHint,
    required this.repairTitle,
    required this.repairWarning,
    required this.cancel,
    required this.mobileBackup,
    required this.webBackup,
    required this.repairFailure,
    required this.loadingDetail,
  });

  static _BootstrapStrings of(BuildContext context) {
    final language = View.of(context).platformDispatcher.locale.languageCode;
    return switch (language) {
      'pt' => _pt,
      'es' => _es,
      _ => _en,
    };
  }

  static const _pt = _BootstrapStrings(
    preparing: 'Preparando o Cineus…',
    loadingDetail:
        'Abrindo o catálogo e preparando o progresso local. Aguarde.',
    errorTitle: 'Não foi possível abrir seus dados',
    errorBody:
        'Seus dados locais não foram alterados. Tente novamente antes de usar o reparo.',
    retry: 'Tentar novamente',
    repairAction: 'Reparar banco de dados',
    repairHint: 'O reparo é o último recurso e pode recriar os dados locais.',
    repairTitle: 'Reparar dados locais?',
    repairWarning:
        'O reparo reconstrói uma base limpa. Partidas, progresso dos estágios, tickets e preferências podem ser perdidos. Use como último recurso, depois de tentar novamente.',
    cancel: 'Cancelar',
    mobileBackup:
        'No dispositivo, uma cópia técnica do banco é criada antes da recriação, quando possível. Não há restauração automática dessa cópia.',
    webBackup: 'Na Web, o banco é recriado sem cópia técnica de recuperação.',
    repairFailure:
        'O reparo não foi concluído. Os dados podem ter sido recriados parcialmente. Tente novamente ou acesse o suporte.',
  );

  static const _en = _BootstrapStrings(
    preparing: 'Preparing Cineus…',
    loadingDetail:
        'Opening the catalogue and preparing local progress. Please wait.',
    errorTitle: 'Your data could not be opened',
    errorBody:
        'Your local data has not been changed. Try again before using repair.',
    retry: 'Try again',
    repairAction: 'Repair database',
    repairHint: 'Repair is a last resort and may recreate local data.',
    repairTitle: 'Repair local data?',
    repairWarning:
        'Repair rebuilds a clean database. Games, stage progress, tickets and preferences may be lost. Use it as a last resort after retrying.',
    cancel: 'Cancel',
    mobileBackup:
        'On devices, a technical copy is made before rebuilding when possible. This copy is not restored automatically.',
    webBackup:
        'On the Web, the database is rebuilt without a technical recovery copy.',
    repairFailure:
        'Repair did not finish. Data may have been partially recreated. Try again or contact support.',
  );

  static const _es = _BootstrapStrings(
    preparing: 'Preparando Cineus…',
    loadingDetail:
        'Abriendo el catálogo y preparando el progreso local. Espera.',
    errorTitle: 'No se pudieron abrir tus datos',
    errorBody:
        'Tus datos locales no se han modificado. Inténtalo de nuevo antes de usar la reparación.',
    retry: 'Intentar de nuevo',
    repairAction: 'Reparar base de datos',
    repairHint:
        'La reparación es el último recurso y puede recrear los datos locales.',
    repairTitle: '¿Reparar los datos locales?',
    repairWarning:
        'La reparación reconstruye una base limpia. Las partidas, el progreso de etapas, los tickets y las preferencias pueden perderse. Úsala como último recurso después de intentar de nuevo.',
    cancel: 'Cancelar',
    mobileBackup:
        'En el dispositivo se crea una copia técnica antes de reconstruir, cuando es posible. No se restaura automáticamente.',
    webBackup:
        'En la Web la base se reconstruye sin copia técnica de recuperación.',
    repairFailure:
        'La reparación no terminó. Los datos pueden haberse recreado parcialmente. Inténtalo de nuevo o accede al soporte.',
  );
}
