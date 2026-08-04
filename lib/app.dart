import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_l10n.dart';
import 'presentation/deep_link_handler.dart';
import 'presentation/providers/locale_notifier.dart';
import 'presentation/routes/app_router.dart';

class CineusApp extends ConsumerWidget {
  const CineusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return DeepLinkHandler(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppL10n.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,

        // `locale: null` follows the device; an explicit value overrides it.
        locale: locale,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,

        routerConfig: AppRouter.router,
      ),
    );
  }
}
