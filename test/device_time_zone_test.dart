import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:cineus/core/platform/device_time_zone.dart';

class _FakeTimeZoneProvider implements DeviceTimeZoneProvider {
  final String? identifier;

  const _FakeTimeZoneProvider(this.identifier);

  @override
  Future<String?> currentIdentifier() async => identifier;
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('preserva um identificador IANA válido do dispositivo', () async {
    const resolver = DeviceTimeZoneResolver(
      _FakeTimeZoneProvider('America/Sao_Paulo'),
    );

    final location = await resolver.resolve();

    expect(location.name, 'America/Sao_Paulo');
  });

  test('um identificador inválido degrada para UTC', () async {
    const resolver = DeviceTimeZoneResolver(
      _FakeTimeZoneProvider('Not/A_Real_Zone'),
    );

    expect((await resolver.resolve()).name, tz.UTC.name);
  });

  test('ausência de identificador degrada para UTC', () async {
    const resolver = DeviceTimeZoneResolver(_FakeTimeZoneProvider(null));

    expect((await resolver.resolve()).name, tz.UTC.name);
  });
}
