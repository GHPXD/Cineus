// Daily reminder (D4), minus the plugin.
//
// The scheduling itself needs a platform channel, so `NotificationService` is an
// interface and this exercises the parts that decide *whether* and *when* —
// which is where the logic actually lives.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/utils/daily_reminder_time.dart';
import 'package:cineus/data/datasources/notification_service.dart';
import 'package:cineus/domain/repositories/app_meta_repository.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/reminder_notifier.dart';

/// Records what was asked of the OS, and answers however the test wants.
class FakeNotificationService implements NotificationService {
  bool permissionGranted = true;
  bool permissionCurrentlyHeld = true;

  int scheduleCalls = 0;
  int cancelCalls = 0;
  int permissionPrompts = 0;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionPrompts++;
    return permissionGranted;
  }

  @override
  Future<bool> hasPermission() async => permissionCurrentlyHeld;

  @override
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
  }) async {
    scheduleCalls++;
    lastTitle = title;
    lastBody = body;
  }

  @override
  Future<void> cancelDailyReminder() async => cancelCalls++;
}

class InMemoryMeta implements AppMetaRepository {
  final Map<String, String> store = {};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String value) async => store[key] = value;

  @override
  Future<bool> hasSeenOnboarding() async => store['onboarding_seen'] == 'true';

  @override
  Future<void> markOnboardingSeen() async => store['onboarding_seen'] = 'true';
}

void main() {
  group('DailyReminderTime', () {
    test('agenda para as 9h do mesmo dia quando ainda é de manhã', () {
      final next = DailyReminderTime.nextOccurrence(
        DateTime(2026, 8, 10, 7, 30),
      );
      expect(next, DateTime(2026, 8, 10, 9, 0));
    });

    test('pula para amanhã quando as 9h já passaram', () {
      final next = DailyReminderTime.nextOccurrence(
        DateTime(2026, 8, 10, 9, 1),
      );
      expect(next, DateTime(2026, 8, 11, 9, 0));
    });

    test('exatamente às 9h agenda para o dia seguinte, não para agora', () {
      // Evita disparar imediatamente no instante do agendamento.
      final next = DailyReminderTime.nextOccurrence(
        DateTime(2026, 8, 10, 9, 0),
      );
      expect(next, DateTime(2026, 8, 11, 9, 0));
    });

    test('atravessa fim de mês e de ano', () {
      expect(
        DailyReminderTime.nextOccurrence(DateTime(2026, 8, 31, 23, 0)),
        DateTime(2026, 9, 1, 9, 0),
      );
      expect(
        DailyReminderTime.nextOccurrence(DateTime(2026, 12, 31, 23, 0)),
        DateTime(2027, 1, 1, 9, 0),
      );
    });

    test('sempre no futuro', () {
      for (var hour = 0; hour < 24; hour++) {
        final from = DateTime(2026, 8, 10, hour, 17);
        expect(DailyReminderTime.nextOccurrence(from).isAfter(from), isTrue);
      }
    });
  });

  group('ReminderNotifier', () {
    late FakeNotificationService service;
    late InMemoryMeta meta;

    Future<ReminderNotifier> build() async {
      final notifier = ReminderNotifier(
        service: service,
        meta: meta,
        l10n: () => AppL10n.delegate.load(const Locale('pt')),
      );
      // Deixa o _restore() do construtor terminar.
      await Future<void>.delayed(Duration.zero);
      return notifier;
    }

    setUp(() {
      service = FakeNotificationService();
      meta = InMemoryMeta();
    });

    test('começa desligado e NÃO pede permissão na inicialização', () async {
      final notifier = await build();
      expect(notifier.state.enabled, isFalse);
      expect(
        service.permissionPrompts,
        0,
        reason: 'pedir permissão sem o jogador pedir converte mal',
      );
      expect(service.scheduleCalls, 0);
    });

    test('ligar pede permissão e agenda', () async {
      final notifier = await build();
      await notifier.toggle(true);

      expect(service.permissionPrompts, 1);
      expect(service.scheduleCalls, 1);
      expect(notifier.state.enabled, isTrue);
      expect(meta.store['daily_reminder_enabled'], 'true');
    });

    test('a notificação sai no idioma escolhido', () async {
      final notifier = await build();
      await notifier.toggle(true);

      final pt = await AppL10n.delegate.load(const Locale('pt'));
      expect(service.lastTitle, pt.reminderTitle);
      expect(service.lastBody, pt.reminderBody);
    });

    test('permissão negada deixa desligado e sinaliza o motivo', () async {
      service.permissionGranted = false;
      final notifier = await build();
      await notifier.toggle(true);

      expect(notifier.state.enabled, isFalse);
      expect(notifier.state.permissionDenied, isTrue);
      expect(service.scheduleCalls, 0, reason: 'não agenda sem permissão');
      expect(meta.store['daily_reminder_enabled'], 'false');
    });

    test('desligar cancela e persiste', () async {
      final notifier = await build();
      await notifier.toggle(true);
      await notifier.toggle(false);

      expect(notifier.state.enabled, isFalse);
      expect(service.cancelCalls, greaterThanOrEqualTo(1));
      expect(meta.store['daily_reminder_enabled'], 'false');
    });

    test('reagenda no próximo lançamento quando estava ligado', () async {
      meta.store['daily_reminder_enabled'] = 'true';
      final notifier = await build();

      expect(notifier.state.enabled, isTrue);
      expect(
        service.scheduleCalls,
        1,
        reason: 'o SO descarta agendamentos ao reiniciar',
      );
      expect(
        service.permissionPrompts,
        0,
        reason: 'permissão já concedida: não reperguntar',
      );
    });

    test('permissão revogada nas configurações desliga o switch', () async {
      meta.store['daily_reminder_enabled'] = 'true';
      service.permissionCurrentlyHeld = false;
      final notifier = await build();

      expect(notifier.state.enabled, isFalse);
      expect(service.scheduleCalls, 0);
      expect(meta.store['daily_reminder_enabled'], 'false');
    });

    test('refreshCopy reagenda só quando está ligado', () async {
      final notifier = await build();

      await notifier.refreshCopy();
      expect(service.scheduleCalls, 0);

      await notifier.toggle(true);
      final before = service.scheduleCalls;
      await notifier.refreshCopy();
      expect(service.scheduleCalls, before + 1);
    });
  });
}
