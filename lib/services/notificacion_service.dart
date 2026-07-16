import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  Future<void> init() async {
    if (_inicializado) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Lima'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    // 1. Primero inicializamos el plugin
    await _plugin.initialize(initSettings);

    // 2. Luego, ya con el plugin inicializado, pedimos los permisos
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _inicializado = true;
  }

  Future<int> programarNotificacion({
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
  }) async {
    final id = fechaHora.millisecondsSinceEpoch ~/ 1000 % 100000;

    final tzDateTime = tz.TZDateTime.from(fechaHora, tz.local);

    print('Hora actual del sistema: ${DateTime.now()}');
    print('Hora programada (original): $fechaHora');
    print('Hora programada (TZ): $tzDateTime');

    await _plugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      tzDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'riego_channel',
          'Recordatorios de riego',
          channelDescription: 'Notificaciones para recordar el riego de cultivos',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 👈 cambiado
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('Notificación programada con id: $id');

    return id;
  }

  Future<void> cancelarNotificacion(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> mostrarNotificacionInmediata({
    required String titulo,
    required String cuerpo,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000;

    await _plugin.show(
      id,
      titulo,
      cuerpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alertas_climaticas_channel',
          'Alertas climáticas',
          channelDescription:
              'Notificaciones de riesgo climático para tus cultivos',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}