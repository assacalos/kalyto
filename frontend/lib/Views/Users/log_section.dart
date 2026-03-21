import 'package:flutter/material.dart';

class LogsSection extends StatefulWidget {
  const LogsSection({super.key});

  @override
  State<LogsSection> createState() => _LogsSectionState();
}

class _LogsSectionState extends State<LogsSection> {
  final List<Map<String, String>> _allLogs = [
    {"user": "John Doe", "action": "Connexion", "date": "2025-09-18 10:00"},
    {"user": "Alice Smith", "action": "Création utilisateur", "date": "2025-09-18 10:30"},
    {"user": "Bob Johnson", "action": "Modification mot de passe", "date": "2025-09-18 11:00"},
  ];
  List<Map<String, String>> _logs = [];

  @override
  void initState() {
    super.initState();
    _logs = List.from(_allLogs);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Rechercher...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (query) {
              setState(() {
                if (query.isEmpty) {
                  _logs = List.from(_allLogs);
                } else {
                  final q = query.toLowerCase();
                  _logs = _allLogs
                      .where((log) =>
                          (log["user"] ?? '').toLowerCase().contains(q) ||
                          (log["action"] ?? '').toLowerCase().contains(q))
                      .toList();
                }
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(log["action"] ?? ''),
                  subtitle: Text("${log["user"]} • ${log["date"]}"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
