import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

void main() {
  runApp(const ProviderScope(child: BolzplatzApp()));
}

class BolzplatzApp extends StatelessWidget {
  const BolzplatzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bolzplatz AG',
      home: ClubTablePage(),
    );
  }
}

class ClubTablePage extends ConsumerWidget {
  const ClubTablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubs = ref.watch(clubsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bolzplatz AG - Plattformtest')),
      body: clubs.when(
        data: (rows) => SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Verein')),
              DataColumn(label: Text('Ort')),
            ],
            rows: [
              for (final c in rows)
                DataRow(cells: [
                  DataCell(Text('${c.id}')),
                  DataCell(Text(c.name)),
                  DataCell(Text(c.place)),
                ]),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }
}
