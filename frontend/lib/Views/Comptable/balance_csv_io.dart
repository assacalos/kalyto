import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> writeBalanceCsvToFile(
  String csv,
  String dateDebut,
  String dateFin,
) async {
  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/balance_${dateDebut}_$dateFin.csv'.replaceAll(RegExp(r'[^\w\-.]'), '_');
  final file = File(path);
  await file.writeAsString(csv);
  return path;
}
