/// Display helpers for the course language.
///
/// Keyed by the manifest's BCP-47 `targetLanguage` so region-specific
/// courses (pt-PT vs pt-BR) resolve to the right flag.
class LanguageDisplay {
  const LanguageDisplay._();

  static const Map<String, String> _flags = {
    'es-ES': '🇪🇸',
    'fr-FR': '🇫🇷',
    'de-DE': '🇩🇪',
    'nl-NL': '🇳🇱',
    'pt-PT': '🇵🇹',
    'pt-BR': '🇧🇷',
    'ja-JP': '🇯🇵',
    'zh-CN': '🇨🇳',
  };

  static const Map<String, String> _names = {
    'es-ES': 'Spanish',
    'fr-FR': 'French',
    'de-DE': 'German',
    'nl-NL': 'Dutch',
    'pt-PT': 'Portuguese',
    'pt-BR': 'Portuguese',
    'ja-JP': 'Japanese',
    'zh-CN': 'Chinese',
  };

  /// Flag emoji for a BCP-47 code, falling back to the language subtag
  /// (so an unlisted region like es-MX still resolves to a Spanish flag).
  static String flag(String targetLanguage) {
    final exact = _flags[targetLanguage];
    if (exact != null) return exact;
    final subtag = targetLanguage.split('-').first.toLowerCase();
    for (final entry in _flags.entries) {
      if (entry.key.split('-').first.toLowerCase() == subtag) {
        return entry.value;
      }
    }
    return '🌍';
  }

  /// Short language name, e.g. "Spanish" rather than the manifest's
  /// full "Spanish for English Speakers".
  static String name(String targetLanguage) {
    final exact = _names[targetLanguage];
    if (exact != null) return exact;
    final subtag = targetLanguage.split('-').first.toLowerCase();
    for (final entry in _names.entries) {
      if (entry.key.split('-').first.toLowerCase() == subtag) {
        return entry.value;
      }
    }
    return targetLanguage;
  }
}
