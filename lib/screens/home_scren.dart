import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'parcelas/parcelas_screen.dart';
import 'cultivos/cultivos_screen.dart';
import 'riego/riego_screen.dart';
import 'fertilizantes/fertilizantes_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/riego_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalParcelas = 0;
  int _totalCultivos = 0;
  Map<String, double> _aguaPorMes = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    setState(() => _cargando = true);

    final parcelas = await DBHelper.instance.getParcelas();
    final cultivos = await DBHelper.instance.getCultivos();
    final aguaPorMes = await DBHelper.instance.getAguaPorMes();

    setState(() {
      _totalParcelas = parcelas.length;
      _totalCultivos = cultivos.length;
      _aguaPorMes = aguaPorMes;
      _cargando = false;
    });
  }


  // Al volver de cualquier módulo, refresca el resumen
  // (por si se agregaron/eliminaron parcelas o cultivos)
  Future<void> _navegarYRefrescar(Widget pantalla) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    );
    _cargarResumen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agro App')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarResumen,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Resumen general
                  Row(
                    children: [
                      Expanded(
                        child: _TarjetaResumen(
                          titulo: 'Parcelas',
                          valor: _totalParcelas.toString(),
                          icono: Icons.map,
                          color: AppColors.tierra,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TarjetaResumen(
                          titulo: 'Cultivos',
                          valor: _totalCultivos.toString(),
                          icono: Icons.eco,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  //gráfico de riego
                  const Text(
                    'Agua utilizada por mes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RiegoChart(datos: _aguaPorMes),
                
                  const SizedBox(height: 24),
                  const Text(
                    'Módulos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Navegación a los módulos
                  _TarjetaModulo(
                    titulo: 'Parcelas',
                    subtitulo: 'Gestiona tus terrenos',
                    icono: Icons.map,
                    color: AppColors.tierra,
                    onTap: () => _navegarYRefrescar(const ParcelasScreen()),
                  ),
                  _TarjetaModulo(
                    titulo: 'Cultivos',
                    subtitulo: 'Registra y da seguimiento a tus cultivos',
                    icono: Icons.eco,
                    color: AppColors.primary,
                    onTap: () => _navegarYRefrescar(const CultivosScreen()),
                  ),
                  _TarjetaModulo(
                    titulo: 'Riego',
                    subtitulo: 'Controla el riego por cultivo',
                    icono: Icons.water_drop,
                    color: AppColors.agua,
                    onTap: () => _navegarYRefrescar(const RiegoScreen()),
                  ),
                  _TarjetaModulo(
                    titulo: 'Fertilizantes',
                    subtitulo: 'Registra aplicaciones de fertilizante',
                    icono: Icons.science,
                    color: AppColors.fertilizante,
                    onTap: () =>
                        _navegarYRefrescar(const FertilizantesScreen()),
                  ),
                ],
              ),
            ),
    );
  }
}

// Widget reutilizable para las tarjetas de resumen (números)
class _TarjetaResumen extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _TarjetaResumen({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }
}

// Widget reutilizable para las tarjetas de navegación a módulos
class _TarjetaModulo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _TarjetaModulo({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icono, color: Colors.white),
        ),
        title: Text(titulo),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
