import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/utils/app_config.dart';

// ⚠️ DEPRECATED: Utiliser AppConfig.baseUrl à la place
// Conservé pour compatibilité avec l'ancien code
@Deprecated('Use AppConfig.baseUrl instead')
String get baseUrl => AppConfig.baseUrl;

final storage = GetStorage();
