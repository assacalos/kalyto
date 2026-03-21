import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> writeTextToTemp(String filename, String content) async {
  try {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${filename.replaceAll(RegExp(r'[^\w\-.]'), '_')}';
    final file = File(path);
    await file.writeAsString(content);
    return path;
  } catch (_) {
    return null;
  }
}

Future<String?> writeBytesToTemp(String filename, List<int> bytes) async {
  try {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${filename.replaceAll(RegExp(r'[^\w\-.]'), '_')}';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  } catch (_) {
    return null;
  }
}
