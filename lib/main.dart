import 'package:flutter/material.dart';
import 'ephemeris.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSweph();
  runApp(const PlanetaryCalculatorApp());
}

class PlanetaryCalculatorApp extends StatelessWidget {
  const PlanetaryCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Planetaria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = DateTime.now().hour;
  int _selectedMinute = DateTime.now().minute;
  bool _isGeocentric = true;
  bool _isTropical = true;
  String _ayanamsa = 'lahiri';
  
  String _searchPlanet = 'Luna';
  int _searchDegree = 0;
  int _searchMinute = 0;
  DateTime _searchStartDate = DateTime.now();
  DateTime _searchEndDate = DateTime.now().add(const Duration(days: 365));
  bool _searchGeocentric = true;
  
  EphemerisResult? _positionResult;
  String? _searchResult;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculatePositions() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        final result = calculatePositions(
          year: _selectedDate.year,
          month: _selectedDate.month,
          day: _selectedDate.day,
          hour: _selectedHour,
          minute: _selectedMinute,
          heliocentric: !_isGeocentric,
          ayanamsa: _ayanamsa,
        );
        
        setState(() {
          _positionResult = result;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    });
  }

  void _searchDegreePlanet() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        double targetDegree = _searchDegree + _searchMinute / 60.0;
        
        DateTime? result = findDegreeCrossing(
          planetName: _searchPlanet,
          targetDegree: targetDegree,
          startDate: _searchStartDate,
          forward: true,
          maxDays: 365,
          heliocentric: !_searchGeocentric,
        );
        
        if (result != null) {
          List<dynamic> signInfo = degreesToSign(targetDegree);
          setState(() {
            _searchResult = 'Fecha: ${result.year}-${result.month.toString().padLeft(2, '0')}-${result.day.toString().padLeft(2, '0')}\n'
                'Grado: ${targetDegree.toStringAsFixed(4)}° (${_searchDegree.toString().padLeft(3, '0')}°${_searchMinute.toString().padLeft(2, '0')}\' ${signInfo[0]})';
            _isLoading = false;
          });
        } else {
          setState(() {
            _searchResult = 'No se encontró ningún cruce en el rango de 365 días.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Planetaria'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.public), text: 'Posiciones'),
            Tab(icon: Icon(Icons.search), text: 'Buscar Grado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPositionTab(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  Widget _buildPositionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fecha y Hora (UTC)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Hora: '),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: DropdownButtonFormField<int>(
                          value: _selectedHour,
                          items: List.generate(24, (i) => 
                            DropdownMenuItem(value: i, child: Text(i.toString().padLeft(2, '0')))),
                          onChanged: (v) => setState(() => _selectedHour = v!),
                        ),
                      ),
                      const Text(' : '),
                      SizedBox(
                        width: 80,
                        child: DropdownButtonFormField<int>(
                          value: _selectedMinute,
                          items: List.generate(60, (i) => 
                            DropdownMenuItem(value: i, child: Text(i.toString().padLeft(2, '0')))),
                          onChanged: (v) => setState(() => _selectedMinute = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modo de Cálculo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Geocéntrico'), icon: Icon(Icons.public)),
                      ButtonSegment(value: false, label: Text('Heliocéntrico'), icon: Icon(Icons.wb_sunny)),
                    ],
                    selected: {_isGeocentric},
                    onSelectionChanged: (s) => setState(() => _isGeocentric = s.first),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Tropical')),
                      ButtonSegment(value: false, label: Text('Sideral')),
                    ],
                    selected: {_isTropical},
                    onSelectionChanged: (s) => setState(() => _isTropical = s.first),
                  ),
                  if (!_isTropical) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _ayanamsa,
                      decoration: const InputDecoration(labelText: 'Ayanamsa'),
                      items: const [
                        DropdownMenuItem(value: 'lahiri', child: Text('Lahiri')),
                        DropdownMenuItem(value: 'fagan_bradley', child: Text('Fagan Bradley')),
                        DropdownMenuItem(value: 'raman', child: Text('Raman')),
                        DropdownMenuItem(value: 'krishnamurti', child: Text('Krishnamurti')),
                      ],
                      onChanged: (v) => setState(() => _ayanamsa = v!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          FilledButton.icon(
            onPressed: _isLoading ? null : _calculatePositions,
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.calculate),
            label: Text(_isLoading ? 'Calculando...' : 'Calcular Posiciones'),
          ),
          const SizedBox(height: 16),
          
          if (_positionResult != null) _buildPositionResults(),
        ],
      ),
    );
  }

  Widget _buildPositionResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultados - ${_positionResult!.datetime}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(_positionResult!.location, style: const TextStyle(fontSize: 12)),
            Text('Modo: ${_positionResult!.mode}', style: const TextStyle(fontSize: 12)),
            const Divider(),
            const Text('PLANETAS', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._positionResult!.planets.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text('${e.value.nameSpanish}:', 
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(child: Text(e.value.formatted)),
                ],
              ),
            )),
            if (_positionResult!.angles.isNotEmpty) ...[
              const Divider(),
              const Text('ÁNGULOS', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._positionResult!.angles.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text('${e.value.name}:', 
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Text(e.value.formatted)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Parámetros de Búsqueda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    value: _searchPlanet,
                    decoration: const InputDecoration(labelText: 'Planeta'),
                    items: const [
                      DropdownMenuItem(value: 'Sol', child: Text('Sol')),
                      DropdownMenuItem(value: 'Luna', child: Text('Luna')),
                      DropdownMenuItem(value: 'Mercurio', child: Text('Mercurio')),
                      DropdownMenuItem(value: 'Venus', child: Text('Venus')),
                      DropdownMenuItem(value: 'Marte', child: Text('Marte')),
                      DropdownMenuItem(value: 'Júpiter', child: Text('Júpiter')),
                      DropdownMenuItem(value: 'Saturno', child: Text('Saturno')),
                      DropdownMenuItem(value: 'Urano', child: Text('Urano')),
                      DropdownMenuItem(value: 'Neptuno', child: Text('Neptuno')),
                      DropdownMenuItem(value: 'Plutón', child: Text('Plutón')),
                    ],
                    onChanged: (v) => setState(() => _searchPlanet = v!),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      const Text('Grado: '),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: _searchDegree.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            suffixText: '°',
                          ),
                          onChanged: (v) => _searchDegree = int.tryParse(v) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: _searchMinute.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            suffixText: "'",
                          ),
                          onChanged: (v) => _searchMinute = int.tryParse(v) ?? 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _searchStartDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => _searchStartDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('Desde: ${_searchStartDate.year}-${_searchStartDate.month.toString().padLeft(2, '0')}-${_searchStartDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _searchEndDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => _searchEndDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('Hasta: ${_searchEndDate.year}-${_searchEndDate.month.toString().padLeft(2, '0')}-${_searchEndDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Geocéntrico')),
                      ButtonSegment(value: false, label: Text('Heliocéntrico')),
                    ],
                    selected: {_searchGeocentric},
                    onSelectionChanged: (s) => setState(() => _searchGeocentric = s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          FilledButton.icon(
            onPressed: _isLoading ? null : _searchDegreePlanet,
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.search),
            label: Text(_isLoading ? 'Buscando...' : 'Buscar'),
          ),
          const SizedBox(height: 16),
          
          if (_searchResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RESULTADO',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_searchResult!),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
