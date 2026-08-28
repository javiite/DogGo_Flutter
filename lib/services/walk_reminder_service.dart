import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_preferences_service.dart';

class WalkReminderService {
  static const _idsKey = 'doggo_scheduled_walk_reminder_ids';
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> sync(List<Map<String, dynamic>> walks) async {
    try {
      await _sync(walks);
    } catch (_) {
      // Los recordatorios complementan la agenda: un fallo del sistema de
      // notificaciones nunca debe impedir que DogGo abra o cargue el Home.
    }
  }

  static Future<void> _sync(List<Map<String, dynamic>> walks) async {
    final preferences = await AppPreferencesService.load();
    await _initialize();
    await _cancelPrevious();
    if (!preferences.notificationsEnabled ||
        !preferences.walkRemindersEnabled) {
      return;
    }

    final now = DateTime.now();
    final scheduledIds = <String>[];
    final candidates =
        walks
            .map((walk) => (walk: walk, date: _date(walk)))
            .where((item) => item.date != null)
            .where((item) {
              final status = '${item.walk['estado'] ?? ''}'.toLowerCase();
              return !status.contains('cancel') &&
                  !status.contains('final') &&
                  !status.contains('rechaz');
            })
            .toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));

    for (final item in candidates.take(20)) {
      final reminderAt = item.date!.subtract(
        Duration(minutes: preferences.reminderMinutes),
      );
      if (!reminderAt.isAfter(now)) continue;
      final rawId = item.walk['id'] ?? item.walk['paseoId'];
      final walkId = int.tryParse('$rawId');
      if (walkId == null || walkId <= 0) continue;
      final notificationId = 920000 + (walkId % 70000);
      await _plugin.zonedSchedule(
        notificationId,
        'Tu paseo se acerca',
        '${_petNames(item.walk)} · ${_time(item.date!)}',
        tz.TZDateTime.from(reminderAt.toUtc(), tz.UTC),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'doggo_walk_reminders',
            'Recordatorios de paseos',
            channelDescription: 'Avisos antes de los paseos programados.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'walk:$walkId',
      );
      scheduledIds.add('$notificationId');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_idsKey, scheduledIds);
  }

  static Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> _cancelPrevious() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_idsKey) ?? const [];
    for (final raw in ids) {
      final id = int.tryParse(raw);
      if (id != null) await _plugin.cancel(id);
    }
    await prefs.remove(_idsKey);
  }

  static DateTime? _date(Map<String, dynamic> walk) {
    final raw = walk['fechaProgramada'] ?? walk['fechaInicio'];
    return raw == null ? null : DateTime.tryParse('$raw')?.toLocal();
  }

  static String _petNames(Map<String, dynamic> walk) {
    final pets = walk['perros'];
    if (pets is! List) return 'Paseo DogGo';
    final names = pets
        .whereType<Map>()
        .map((pet) => '${pet['nombre'] ?? ''}'.trim())
        .where((name) => name.isNotEmpty)
        .join(', ');
    return names.isEmpty ? 'Paseo DogGo' : names;
  }

  static String _time(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
