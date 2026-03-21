/// Corrige l'affichage des caractères accentués mal encodés (mojibake).
/// Quand l'UTF-8 est interprété en Latin-1, "é" peut s'afficher "Ã©" (à + ©).
/// Cette fonction restaure les caractères français courants.
String fixUtf8Mojibake(String? text) {
  if (text == null || text.isEmpty) return text ?? '';
  String s = text;
  // UTF-8 interprété en Latin-1 : séquences courantes en français
  const replacements = {
    'Ã©': 'é',
    'à©': 'é',   // variante d'affichage du mojibake (à + ©)
    'Ã¨': 'è',
    'Ãª': 'ê',
    'Ã§': 'ç',
    'Ã®': 'î',
    'Ã´': 'ô',
    'Ã»': 'û',
    'Ã¯': 'ï',
    'Ã¼': 'ü',
    'Ã\u00A0': 'à',  // Ã + nbsp (UTF-8 à lu en Latin-1)
    'Ã¢': 'â',
    'Ã¹': 'ù',
    'Ã‰': 'É',
    'Ãˆ': 'È',
    'Ã‡': 'Ç',
    'Ã€': 'À',
  };
  for (final entry in replacements.entries) {
    s = s.replaceAll(entry.key, entry.value);
  }
  return s;
}
