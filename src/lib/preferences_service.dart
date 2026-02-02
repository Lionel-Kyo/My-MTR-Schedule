import 'package:flutter/material.dart';
import 'package:my_mtr_schedule/Data/localized_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyLang = "pref_lang";
  static const String keyNrLine = "pref_mtr_line";
  static const String keyNrStation = "pref_mtr_station";
  static const String keyLrStationId = "pref_lrt_station_id";

  static Future<void> saveLanguage(AppLang lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLang, lang == AppLang.en ? "en" : "tc");
  }

  static Future<AppLang> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langStr = prefs.getString(keyLang);
    if (langStr == "tc") { 
      return AppLang.tc;
    } else if (langStr == "en") {
      return AppLang.en;
    } else {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      return getAppLang(locale);
    }
  }

  static AppLang getAppLang(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    // final countryCode = locale.countryCode?.toLowerCase();

    return languageCode == "zh" ? AppLang.tc : AppLang.en;
  }

  static Future<void> saveNormalRail(String lineCode, String stationCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyNrLine, lineCode);
    await prefs.setString(keyNrStation, stationCode);
  }

  static Future<Map<String, String>?> loadNormalRail() async {
    final prefs = await SharedPreferences.getInstance();
    final line = prefs.getString(keyNrLine);
    final station = prefs.getString(keyNrStation);
    if (line != null && station != null) {
      return { "line": line, "station": station };
    }
    return null;
  }

  static Future<void> saveLightRail(int stationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyLrStationId, stationId);
  }

  static Future<int?> loadLightRail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyLrStationId);
  }
}