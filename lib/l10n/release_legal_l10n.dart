import 'package:flutter/material.dart';

class LegalDocumentCopy {
  final String title;
  final String effectiveDate;
  final List<(String, String)> sections;

  const LegalDocumentCopy({
    required this.title,
    required this.effectiveDate,
    required this.sections,
  });
}

/// Localized release/legal copy kept outside the widget tree.
///
/// This is intentionally separate from gameplay ARBs because these documents are
/// long-form legal/compliance text with their own review lifecycle. Player-facing
/// widgets consume this class exactly like AppL10n: by locale, with no hardcoded
/// Portuguese/Spanish copy in screens or widgets.
class ReleaseLegalL10n {
  static const tmdbNotice =
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  final String settingsSection;
  final String aboutLabel;
  final String privacyLabel;
  final String termsLabel;
  final String aboutTitle;
  final String appSummary;
  final String dataCreditsTitle;
  final String tmdbExplanation;
  final String legalTitle;
  final String contact;
  final LegalDocumentCopy privacy;
  final LegalDocumentCopy terms;

  const ReleaseLegalL10n({
    required this.settingsSection,
    required this.aboutLabel,
    required this.privacyLabel,
    required this.termsLabel,
    required this.aboutTitle,
    required this.appSummary,
    required this.dataCreditsTitle,
    required this.tmdbExplanation,
    required this.legalTitle,
    required this.contact,
    required this.privacy,
    required this.terms,
  });

  static ReleaseLegalL10n of(BuildContext context) =>
      forLanguage(Localizations.localeOf(context).languageCode);

  static ReleaseLegalL10n forLanguage(String language) => switch (language) {
        'pt' => _pt,
        'es' => _es,
        _ => _en,
      };

  static const _pt = ReleaseLegalL10n(
    settingsSection: 'Informações',
    aboutLabel: 'Sobre e créditos',
    privacyLabel: 'Política de Privacidade',
    termsLabel: 'Termos de Uso',
    aboutTitle: 'Sobre e créditos',
    appSummary:
        'Jogo de adivinhação de filmes, offline-first, com modos Dicas e Poster.',
    dataCreditsTitle: 'Dados e créditos',
    tmdbExplanation:
        'Parte dos metadados e imagens de filmes usados para preparar o catálogo do Cineus tem origem no The Movie Database (TMDB).',
    legalTitle: 'Legal',
    contact: 'Suporte e contato: github.com/GHPXD/Cineus/issues',
    privacy: LegalDocumentCopy(
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
    ),
    terms: LegalDocumentCopy(
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
    ),
  );

  static const _en = ReleaseLegalL10n(
    settingsSection: 'Information',
    aboutLabel: 'About & credits',
    privacyLabel: 'Privacy Policy',
    termsLabel: 'Terms of Use',
    aboutTitle: 'About & credits',
    appSummary:
        'An offline-first movie guessing game with Clues and Poster modes.',
    dataCreditsTitle: 'Data & credits',
    tmdbExplanation:
        'Some movie metadata and images used to prepare the Cineus catalogue originate from The Movie Database (TMDB).',
    legalTitle: 'Legal',
    contact: 'Support and contact: github.com/GHPXD/Cineus/issues',
    privacy: LegalDocumentCopy(
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
    ),
    terms: LegalDocumentCopy(
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
    ),
  );

  static const _es = ReleaseLegalL10n(
    settingsSection: 'Información',
    aboutLabel: 'Acerca de y créditos',
    privacyLabel: 'Política de Privacidad',
    termsLabel: 'Términos de Uso',
    aboutTitle: 'Acerca de y créditos',
    appSummary:
        'Juego de adivinanzas de películas, offline-first, con modos Pistas y Póster.',
    dataCreditsTitle: 'Datos y créditos',
    tmdbExplanation:
        'Parte de los metadatos e imágenes utilizados para preparar el catálogo de Cineus provienen de The Movie Database (TMDB).',
    legalTitle: 'Legal',
    contact: 'Soporte y contacto: github.com/GHPXD/Cineus/issues',
    privacy: LegalDocumentCopy(
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
    ),
    terms: LegalDocumentCopy(
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
    ),
  );
}
