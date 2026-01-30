enum AppLang { en, tc }

class LocalizedString {
  final String en;
  final String tc;

  const LocalizedString(this.en, this.tc);

  String get(AppLang lang) => lang == AppLang.en ? en : tc;
}