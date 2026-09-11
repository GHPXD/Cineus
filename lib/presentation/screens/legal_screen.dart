import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum LegalDocument { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final copy = _LegalCopy.of(context, document);

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(copy.title, style: AppTypography.headlineMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    copy.effectiveDate,
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...copy.sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.$1,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.gold300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              section.$2,
                              style: AppTypography.bodySmall.copyWith(height: 1.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalCopy {
  final String title;
  final String effectiveDate;
  final List<(String, String)> sections;

  const _LegalCopy({
    required this.title,
    required this.effectiveDate,
    required this.sections,
  });

  static _LegalCopy of(BuildContext context, LegalDocument document) {
    final language = Localizations.localeOf(context).languageCode;
    return switch ((language, document)) {
      ('pt', LegalDocument.privacy) => _privacyPt,
      ('es', LegalDocument.privacy) => _privacyEs,
      (_, LegalDocument.privacy) => _privacyEn,
      ('pt', LegalDocument.terms) => _termsPt,
      ('es', LegalDocument.terms) => _termsEs,
      _ => _termsEn,
    };
  }

  static const _privacyPt = _LegalCopy(
    title: 'Política de Privacidade',
    effectiveDate: 'Vigente desde 11 de setembro de 2026',
    sections: [
      (
        'Resumo',
        'O Cineus não exige conta e não possui backend próprio para sincronizar seu jogo. O progresso é mantido localmente no dispositivo.',
      ),
      (
        'Dados locais',
        'Partidas, tickets, conquistas, preferências, idioma, lembretes e demais estados do jogo são armazenados localmente. O reparo do banco pode criar uma cópia de recuperação dentro do sandbox do aplicativo.',
      ),
      (
        'Notificações',
        'Se você ativar o lembrete diário, o Cineus solicita a permissão do sistema e agenda a notificação localmente. O aplicativo não envia seu horário de lembrete para um servidor do Cineus.',
      ),
      (
        'Compartilhamento e links',
        'Ao compartilhar um desafio, o Cineus entrega o texto/código à folha de compartilhamento do sistema. O serviço que você escolher para enviar esse conteúdo possui sua própria política de privacidade.',
      ),
      (
        'Dados de filmes',
        'Parte dos metadados e imagens do catálogo foi preparada a partir do TMDB. Durante o jogo normal, o Cineus não autentica você no TMDB nem envia seu progresso de jogo para o TMDB.',
      ),
      (
        'Exclusão e contato',
        'Você pode remover os dados locais desinstalando o aplicativo. Para dúvidas, use github.com/GHPXD/Cineus/issues.',
      ),
    ],
  );

  static const _privacyEn = _LegalCopy(
    title: 'Privacy Policy',
    effectiveDate: 'Effective September 11, 2026',
    sections: [
      (
        'Summary',
        'Cineus does not require an account and does not operate its own backend to synchronize your game. Progress is kept locally on the device.',
      ),
      (
        'Local data',
        'Games, tickets, achievements, preferences, language, reminder settings and other game state are stored locally. Database repair may create a recovery copy inside the app sandbox.',
      ),
      (
        'Notifications',
        'If you enable the daily reminder, Cineus asks for system permission and schedules the notification locally. The app does not send your reminder time to a Cineus server.',
      ),
      (
        'Sharing and links',
        'When you share a challenge, Cineus hands the text/code to the operating system share sheet. The service you choose to send it through has its own privacy policy.',
      ),
      (
        'Movie data',
        'Some catalogue metadata and images were prepared using TMDB. During normal gameplay, Cineus does not authenticate you with TMDB or send your gameplay progress to TMDB.',
      ),
      (
        'Deletion and contact',
        'You can remove local data by uninstalling the app. For questions, use github.com/GHPXD/Cineus/issues.',
      ),
    ],
  );

  static const _privacyEs = _LegalCopy(
    title: 'Política de Privacidad',
    effectiveDate: 'Vigente desde el 11 de septiembre de 2026',
    sections: [
      (
        'Resumen',
        'Cineus no requiere una cuenta y no opera un backend propio para sincronizar tu juego. El progreso se mantiene localmente en el dispositivo.',
      ),
      (
        'Datos locales',
        'Partidas, tickets, logros, preferencias, idioma, recordatorios y otros estados del juego se almacenan localmente. La reparación de la base puede crear una copia de recuperación dentro del sandbox de la aplicación.',
      ),
      (
        'Notificaciones',
        'Si activas el recordatorio diario, Cineus solicita permiso al sistema y programa la notificación localmente. La aplicación no envía tu horario de recordatorio a un servidor de Cineus.',
      ),
      (
        'Compartir y enlaces',
        'Al compartir un desafío, Cineus entrega el texto/código al panel de compartir del sistema. El servicio elegido para enviarlo tiene su propia política de privacidad.',
      ),
      (
        'Datos de películas',
        'Parte de los metadatos e imágenes del catálogo se prepararon con TMDB. Durante el juego normal, Cineus no te autentica en TMDB ni envía tu progreso de juego a TMDB.',
      ),
      (
        'Eliminación y contacto',
        'Puedes eliminar los datos locales desinstalando la aplicación. Para consultas, usa github.com/GHPXD/Cineus/issues.',
      ),
    ],
  );

  static const _termsPt = _LegalCopy(
    title: 'Termos de Uso',
    effectiveDate: 'Vigente desde 11 de setembro de 2026',
    sections: [
      (
        'Uso do Cineus',
        'O Cineus é um jogo de entretenimento. Você pode usar os recursos disponibilizados no aplicativo de acordo com estes termos e com as regras da plataforma em que o instalou.',
      ),
      (
        'Conteúdo de terceiros',
        'Nomes de filmes, imagens, marcas e outros materiais de terceiros pertencem aos respectivos titulares. Parte dos metadados e imagens do catálogo utiliza TMDB como fonte.',
      ),
      (
        'Disponibilidade',
        'O aplicativo é fornecido no estado em que se encontra. Recursos, catálogo e compatibilidade podem mudar em versões futuras, e não há garantia de disponibilidade contínua de qualquer conteúdo específico.',
      ),
      (
        'Compartilhamento',
        'Códigos de desafio são destinados ao compartilhamento voluntário entre jogadores. Você é responsável pelo serviço externo escolhido para transmitir o código.',
      ),
      (
        'Contato',
        'Questões sobre estes termos podem ser encaminhadas por github.com/GHPXD/Cineus/issues.',
      ),
    ],
  );

  static const _termsEn = _LegalCopy(
    title: 'Terms of Use',
    effectiveDate: 'Effective September 11, 2026',
    sections: [
      (
        'Using Cineus',
        'Cineus is an entertainment game. You may use the features made available in the app subject to these terms and the rules of the platform where you installed it.',
      ),
      (
        'Third-party content',
        'Movie names, images, trademarks and other third-party materials belong to their respective owners. Some catalogue metadata and images use TMDB as a source.',
      ),
      (
        'Availability',
        'The app is provided as available. Features, catalogue content and compatibility may change in future versions, and no specific item of content is guaranteed to remain available.',
      ),
      (
        'Sharing',
        'Challenge codes are intended for voluntary sharing between players. You are responsible for the external service you choose to transmit a code through.',
      ),
      (
        'Contact',
        'Questions about these terms can be sent through github.com/GHPXD/Cineus/issues.',
      ),
    ],
  );

  static const _termsEs = _LegalCopy(
    title: 'Términos de Uso',
    effectiveDate: 'Vigente desde el 11 de septiembre de 2026',
    sections: [
      (
        'Uso de Cineus',
        'Cineus es un juego de entretenimiento. Puedes utilizar las funciones disponibles de acuerdo con estos términos y con las reglas de la plataforma donde lo instalaste.',
      ),
      (
        'Contenido de terceros',
        'Los nombres de películas, imágenes, marcas y otros materiales de terceros pertenecen a sus respectivos titulares. Parte de los metadatos e imágenes del catálogo usa TMDB como fuente.',
      ),
      (
        'Disponibilidad',
        'La aplicación se ofrece tal como está disponible. Las funciones, el catálogo y la compatibilidad pueden cambiar en futuras versiones y no se garantiza la disponibilidad continua de contenido específico.',
      ),
      (
        'Compartir',
        'Los códigos de desafío están destinados al intercambio voluntario entre jugadores. Eres responsable del servicio externo que elijas para transmitir un código.',
      ),
      (
        'Contacto',
        'Las consultas sobre estos términos pueden enviarse mediante github.com/GHPXD/Cineus/issues.',
      ),
    ],
  );
}
