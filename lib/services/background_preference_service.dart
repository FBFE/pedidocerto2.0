import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Chave para persistir o plano de fundo escolhido (caminho asset ou URL).
const String kBackgroundPreferenceKey = 'app_background_path';

/// Chave para lista de URLs de planos de fundo enviados pelo admin (JSON array).
const String kBackgroundUrlsKey = 'app_background_urls';

/// Serviço para ler/gravar o plano de fundo selecionado (SharedPreferences).
class BackgroundPreferenceService {
  static Future<String?> getBackgroundPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kBackgroundPreferenceKey);
  }

  static Future<void> setBackgroundPath(String? pathOrUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      await prefs.remove(kBackgroundPreferenceKey);
    } else {
      await prefs.setString(kBackgroundPreferenceKey, pathOrUrl);
    }
  }

  static Future<List<String>> getCustomBackgroundUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(kBackgroundUrlsKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addCustomBackgroundUrl(String url) async {
    final list = await getCustomBackgroundUrls();
    if (list.contains(url)) return;
    list.add(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBackgroundUrlsKey, jsonEncode(list));
  }
}
