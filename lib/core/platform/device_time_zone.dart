import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

abstract class DeviceTimeZoneProvider {
  Future<String?> currentIdentifier();
}

class MethodChannelDeviceTimeZoneProvider implements DeviceTimeZoneProvider {
  static const channelName = 'dev.cineus/device';
  static const _channel = MethodChannel(channelName);

  @override
  Future<String?> currentIdentifier() async {
    try {
      final identifier = await _channel.invokeMethod<String>('getTimeZoneIdentifier');
      final value = identifier?.trim();
      return value == null || value.isEmpty ? null : value;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

/// Converts the OS-provided IANA identifier into a timezone package location.
///
/// Android returns values such as `America/Sao_Paulo`; iOS exposes
/// `TimeZone.current.identifier`. Falling back to UTC is intentionally safer
/// than manufacturing an `Etc/GMT` location from today's offset: a fixed offset
/// would silently schedule the wrong wall-clock time after a future DST change.
class DeviceTimeZoneResolver {
  final DeviceTimeZoneProvider provider;

  const DeviceTimeZoneResolver(this.provider);

  Future<tz.Location> resolve() async {
    final identifier = await provider.currentIdentifier();
    if (identifier == null) return tz.UTC;

    try {
      return tz.getLocation(identifier);
    } catch (_) {
      return tz.UTC;
    }
  }
}
