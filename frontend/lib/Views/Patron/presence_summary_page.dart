import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';

/// Page pour le patron : nombre de présences par employé (semaine, mois ou année).
class PresenceSummaryPage extends StatefulWidget {
  const PresenceSummaryPage({super.key});

  @override
  State<PresenceSummaryPage> createState() => _PresenceSummaryPageState();
}

class _PresenceSummaryPageState extends State<PresenceSummaryPage> {
  final AttendancePunchService _attendanceService = AttendancePunchService();

  String _period = 'month'; // week | month | year
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  int _week = _isoWeek(DateTime.now());

  bool _loading = false;
  String? _error;
  String _periodLabel = '';
  String _dateDebut = '';
  String _dateFin = '';
  List<Map<String, dynamic>> _employees = [];

  static int _isoWeek(DateTime d) {
    final thursday = d.add(Duration(days: 4 - d.weekday % 7));
    final jan1 = DateTime(thursday.year, 1, 1);
    return 1 + (thursday.difference(jan1).inDays / 7).floor();
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _attendanceService.getPresenceSummary(
      period: _period,
      year: _year,
      month: _period == 'month' ? _month : null,
      week: _period == 'week' ? _week : null,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _periodLabel = result['period_label']?.toString() ?? '';
        _dateDebut = result['date_debut']?.toString() ?? '';
        _dateFin = result['date_fin']?.toString() ?? '';
        final list = result['employees'];
        _employees = list is List
            ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : <Map<String, dynamic>>[];
      } else {
        _error = result['message']?.toString() ?? 'Erreur inconnue';
      }
    });
  }

  void _changePeriod(String period) {
    setState(() {
      _period = period;
      final now = DateTime.now();
      _year = now.year;
      _month = now.month;
      _week = _isoWeek(now);
    });
    _loadSummary();
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
    });
    _loadSummary();
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) {
        _month = 1;
        _year++;
      } else if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
    _loadSummary();
  }

  void _changeWeek(int delta) {
    setState(() {
      _week += delta;
      if (_week > 53) {
        _week = 1;
        _year++;
      } else if (_week < 1) {
        _week = 53;
        _year--;
      }
    });
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Présences par employé'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadSummary,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPeriodSelector(),
          if (_periodLabel.isNotEmpty || _dateDebut.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _periodLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (_dateDebut.isNotEmpty && _dateFin.isNotEmpty)
                    Text(
                      'Du $_dateDebut au $_dateFin',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                ],
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune présence enregistrée sur cette période.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final e = _employees[index];
                          final nom = e['nom_complet'] ?? e['nom'] ?? 'Employé';
                          final count = (e['presence_count'] is int)
                              ? e['presence_count'] as int
                              : int.tryParse(e['presence_count']?.toString() ?? '0') ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0F172A).withOpacity(0.2),
                                child: Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              title: Text(nom),
                              subtitle: Text(
                                '$count jour${count > 1 ? 's' : ''} de présence',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: const Icon(Icons.calendar_today, color: Color(0xFF0F172A)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'week', label: Text('Semaine'), icon: Icon(Icons.view_week)),
              ButtonSegment(value: 'month', label: Text('Mois'), icon: Icon(Icons.calendar_month)),
              ButtonSegment(value: 'year', label: Text('Année'), icon: Icon(Icons.calendar_today)),
            ],
            selected: {_period},
            onSelectionChanged: (Set<String> selected) {
              if (selected.isNotEmpty) _changePeriod(selected.first);
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _loading
                    ? null
                    : () {
                        if (_period == 'week') _changeWeek(-1);
                        if (_period == 'month') _changeMonth(-1);
                        if (_period == 'year') _changeYear(-1);
                      },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _period == 'week'
                      ? 'S$_week $_year'
                      : _period == 'month'
                          ? '${DateFormat('MMMM', 'fr').format(DateTime(_year, _month))} $_year'
                          : '$_year',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _loading
                    ? null
                    : () {
                        if (_period == 'week') _changeWeek(1);
                        if (_period == 'month') _changeMonth(1);
                        if (_period == 'year') _changeYear(1);
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
