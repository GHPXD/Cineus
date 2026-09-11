import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

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

  const DatabaseBootstrap({
    super.key,
    required this.initialize,
    required this.repair,
    required this.child,
  });

  @override
  State<DatabaseBootstrap> createState() => _DatabaseBootstrapState();
}

class _DatabaseBootstrapState extends State<DatabaseBootstrap> {
  Object? _error;
  bool _working = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
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
    }
  }

  Future<void> _repair(BuildContext dialogContext) async {
    final strings = _BootstrapStrings.of(dialogContext);
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text(strings.repairTitle),
        content: Text(strings.repairWarning),
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
  }

  @override
  Widget build(BuildContext context) {
    if (!_working && _error == null) return widget.child;

    return MaterialApp(
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
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _working
                        ? _LoadingState(strings: strings)
                        : _ErrorState(
                            strings: strings,
                            onRetry: _initialize,
                            onRepair: () => _repair(bootstrapContext),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
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
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final _BootstrapStrings strings;
  final VoidCallback onRetry;
  final VoidCallback onRepair;

  const _ErrorState({
    required this.strings,
    required this.onRetry,
    required this.onRepair,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.storage_rounded,
            size: 56,
            color: AppColors.ruby300,
          ),
          const SizedBox(height: 20),
          Text(
            strings.errorTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            strings.errorBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(strings.retry),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRepair,
              icon: const Icon(Icons.build_circle_outlined),
              label: Text(strings.repairAction),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.repairHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
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
    errorTitle: 'Não foi possível abrir seus dados',
    errorBody:
        'Seus dados locais não foram alterados. Tente novamente antes de usar o reparo.',
    retry: 'Tentar novamente',
    repairAction: 'Reparar banco de dados',
    repairHint: 'O reparo é o último recurso e pode recriar os dados locais.',
    repairTitle: 'Reparar dados locais?',
    repairWarning:
        'O Cineus fará um backup do banco atual quando possível e reconstruirá uma cópia limpa. O progresso local pode precisar ser recuperado do backup.',
    cancel: 'Cancelar',
  );

  static const _en = _BootstrapStrings(
    preparing: 'Preparing Cineus…',
    errorTitle: 'Your data could not be opened',
    errorBody:
        'Your local data has not been changed. Try again before using repair.',
    retry: 'Try again',
    repairAction: 'Repair database',
    repairHint: 'Repair is a last resort and may recreate local data.',
    repairTitle: 'Repair local data?',
    repairWarning:
        'Cineus will back up the current database when possible and rebuild a clean copy. Local progress may need to be recovered from that backup.',
    cancel: 'Cancel',
  );

  static const _es = _BootstrapStrings(
    preparing: 'Preparando Cineus…',
    errorTitle: 'No se pudieron abrir tus datos',
    errorBody:
        'Tus datos locales no se han modificado. Inténtalo de nuevo antes de usar la reparación.',
    retry: 'Intentar de nuevo',
    repairAction: 'Reparar base de datos',
    repairHint:
        'La reparación es el último recurso y puede recrear los datos locales.',
    repairTitle: '¿Reparar los datos locales?',
    repairWarning:
        'Cineus hará una copia de seguridad de la base actual cuando sea posible y reconstruirá una copia limpia. Puede ser necesario recuperar el progreso local desde esa copia.',
    cancel: 'Cancelar',
  );
}
