import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pronostico_dia.dart';

class AlertaClimatica {
  final String tipo;
  final String mensaje;

  AlertaClimatica({required this.tipo, required this.mensaje});
}

class WeatherService {
  static final WeatherService instance = WeatherService._internal();
  WeatherService._internal();

  /// Consulta el pronóstico de 7 días usando Open-Meteo (gratis, sin API key)
  Future<List<PronosticoDia>> obtenerPronostico(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lng'
      '&daily=temperature_2m_min,temperature_2m_max,precipitation_sum'
      '&timezone=auto&forecast_days=7',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Error al consultar el clima');
    }

    final data = jsonDecode(response.body);
    final daily = data['daily'];

    final fechas = List<String>.from(daily['time']);
    final tempsMin = List<num>.from(daily['temperature_2m_min']);
    final tempsMax = List<num>.from(daily['temperature_2m_max']);
    final precipitaciones = List<num>.from(daily['precipitation_sum']);

    return List.generate(fechas.length, (i) {
      return PronosticoDia(
        fecha: DateTime.parse(fechas[i]),
        tempMin: tempsMin[i].toDouble(),
        tempMax: tempsMax[i].toDouble(),
        precipitacionMm: precipitaciones[i].toDouble(),
      );
    });
  }

  /// Revisa el pronóstico y detecta riesgos climáticos críticos
  List<AlertaClimatica> analizarAlertas(List<PronosticoDia> pronostico) {
    final alertas = <AlertaClimatica>[];

    for (final dia in pronostico) {
      // Helada: temperatura mínima muy baja
      if (dia.tempMin <= 2) {
        alertas.add(AlertaClimatica(
          tipo: 'Helada',
          mensaje:
              'Riesgo de helada el ${_formatearFecha(dia.fecha)} (mín. ${dia.tempMin.toStringAsFixed(1)}°C)',
        ));
      }

      // Lluvia fuerte: más de 20mm en un solo día
      if (dia.precipitacionMm > 20) {
        alertas.add(AlertaClimatica(
          tipo: 'Lluvia fuerte',
          mensaje:
              'Lluvia fuerte prevista el ${_formatearFecha(dia.fecha)} (${dia.precipitacionMm.toStringAsFixed(0)}mm)',
        ));
      }
    }

    // Sequía: 5 o más días sin lluvia significativa en la semana
    final diasSinLluvia =
        pronostico.where((d) => d.precipitacionMm < 1).length;
    if (diasSinLluvia >= 5) {
      alertas.add(AlertaClimatica(
        tipo: 'Sequía',
        mensaje:
            'Se prevén $diasSinLluvia días sin lluvia significativa esta semana',
      ));
    }

    return alertas;
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}';
  }
}