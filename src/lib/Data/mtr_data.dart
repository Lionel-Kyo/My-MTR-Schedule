import 'package:flutter/material.dart';
import 'package:my_mtr_schedule/Data/localized_string.dart';
import 'package:my_mtr_schedule/Data/ui_labels.dart';

class MtrLine {
  final String code;
  final LocalizedString name;
  final Color color;
  final List<MtrStation> stations;

  MtrLine({
    required this.code,
    required this.name,
    required this.color,
    required this.stations,
  });
}

class MtrStation {
  // Normal Rail (e.g., "POK")
  final String code;
  final LocalizedString name;
  // Light Rail (e.g., 100)
  final int? id;

  MtrStation({required this.code, required this.name, this.id});
}

class TrainSchedule {
  final String plat;
  final String time;
  final String destCode;
  final String destName;
  final String routeNum;
  final int? trainLength;
  final bool isDelay;

  TrainSchedule({
    required this.plat,
    required this.time,
    required this.destCode,
    required this.destName,
    required this.routeNum,
    required this.trainLength,
    this.isDelay = false,
  });

  String getRowTitle(AppLang lang) {
    final buffer = StringBuffer();
    if (routeNum.isNotEmpty) {
      buffer.write(routeNum);
      buffer.write(" ");
    }
    buffer.write(destName);
    final lTrainLength = trainLength;
    if (lTrainLength != null) {
      buffer.write(" (");
      buffer.write(lTrainLength);
      if (lang == AppLang.en) {
        buffer.write(" ");
      }
      if (lTrainLength > 1) {
        buffer.write(uiLabels["cars_unit"]!.get(lang));
      } else {
        buffer.write(uiLabels["car_unit"]!.get(lang));
      }
      buffer.write(")");
    }
    return buffer.toString();
  }
}

final List<MtrLine> mtrLines = [
  MtrLine(
    code: "AEL",
    name: const LocalizedString("Airport Express", "機場快綫"),
    color: const Color(0xFF007078),
    stations: [
      MtrStation(code: "HOK", name: const LocalizedString("Hong Kong", "香港")),
      MtrStation(code: "KOW", name: const LocalizedString("Kowloon", "九龍")),
      MtrStation(code: "TSY", name: const LocalizedString("Tsing Yi", "青衣")),
      MtrStation(code: "AIR", name: const LocalizedString("Airport", "機場")),
      MtrStation(code: "AWE", name: const LocalizedString("AsiaWorld Expo", "博覽館")),
    ],
  ),
  MtrLine(
    code: "TCL",
    name: const LocalizedString("Tung Chung Line", "東涌綫"),
    color: const Color(0xFFF38B00),
    stations: [
      MtrStation(code: "HOK", name: const LocalizedString("Hong Kong", "香港")),
      MtrStation(code: "KOW", name: const LocalizedString("Kowloon", "九龍")),
      MtrStation(code: "OLY", name: const LocalizedString("Olympic", "奧運")),
      MtrStation(code: "NAC", name: const LocalizedString("Nam Cheong", "南昌")),
      MtrStation(code: "LAK", name: const LocalizedString("Lai King", "荔景")),
      MtrStation(code: "TSY", name: const LocalizedString("Tsing Yi", "青衣")),
      MtrStation(code: "SUN", name: const LocalizedString("Sunny Bay", "欣澳")),
      MtrStation(code: "TUC", name: const LocalizedString("Tung Chung", "東涌")),
    ],
  ),
  MtrLine(
    code: "TML",
    name: const LocalizedString("Tuen Ma Line", "屯馬綫"),
    color: const Color(0xFF923011),
    stations: [
      MtrStation(code: "WKS", name: const LocalizedString("Wu Kai Sha", "烏溪沙")),
      MtrStation(code: "MOS", name: const LocalizedString("Ma On Shan", "馬鞍山")),
      MtrStation(code: "HEO", name: const LocalizedString("Heng On", "恆安")),
      MtrStation(code: "TSH", name: const LocalizedString("Tai Shui Hang", "大水坑")),
      MtrStation(code: "SHM", name: const LocalizedString("Shek Mun", "石門")),
      MtrStation(code: "CIO", name: const LocalizedString("City One", "第一城")),
      MtrStation(code: "STW", name: const LocalizedString("Sha Tin Wai", "沙田圍")),
      MtrStation(code: "CKT", name: const LocalizedString("Che Kung Temple", "車公廟")),
      MtrStation(code: "TAW", name: const LocalizedString("Tai Wai", "大圍")),
      MtrStation(code: "HIK", name: const LocalizedString("Hin Keng", "顯徑")),
      MtrStation(code: "DIH", name: const LocalizedString("Diamond Hill", "鑽石山")),
      MtrStation(code: "KAT", name: const LocalizedString("Kai Tak", "啟德")),
      MtrStation(code: "SUW", name: const LocalizedString("Sung Wong Toi", "宋皇臺")),
      MtrStation(code: "TKW", name: const LocalizedString("To Kwa Wan", "土瓜灣")),
      MtrStation(code: "HOM", name: const LocalizedString("Ho Man Tin", "何文田")),
      MtrStation(code: "HUH", name: const LocalizedString("Hung Hom", "紅磡")),
      MtrStation(code: "ETS", name: const LocalizedString("East Tsim Sha Tsui", "尖東")),
      MtrStation(code: "AUS", name: const LocalizedString("Austin", "柯士甸")),
      MtrStation(code: "NAC", name: const LocalizedString("Nam Cheong", "南昌")),
      MtrStation(code: "MEF", name: const LocalizedString("Mei Foo", "美孚")),
      MtrStation(code: "TWW", name: const LocalizedString("Tsuen Wan West", "荃灣西")),
      MtrStation(code: "KSR", name: const LocalizedString("Kam Sheung Road", "錦上路")),
      MtrStation(code: "YUL", name: const LocalizedString("Yuen Long", "元朗")),
      MtrStation(code: "LOP", name: const LocalizedString("Long Ping", "朗屏")),
      MtrStation(code: "TIS", name: const LocalizedString("Tin Shui Wai", "天水圍")),
      MtrStation(code: "SIH", name: const LocalizedString("Siu Hong", "兆康")),
      MtrStation(code: "TUM", name: const LocalizedString("Tuen Mun", "屯門")),
    ],
  ),
  MtrLine(
    code: "TKL",
    name: const LocalizedString("Tseung Kwan O Line", "將軍澳綫"),
    color: const Color(0xFFA35EB5),
    stations: [
      MtrStation(code: "NOP", name: const LocalizedString("North Point", "北角")),
      MtrStation(code: "QUB", name: const LocalizedString("Quarry Bay", "鰂魚涌")),
      MtrStation(code: "YAT", name: const LocalizedString("Yau Tong", "油塘")),
      MtrStation(code: "TIK", name: const LocalizedString("Tiu Keng Leng", "調景嶺")),
      MtrStation(code: "TKO", name: const LocalizedString("Tseung Kwan O", "將軍澳")),
      MtrStation(code: "LHP", name: const LocalizedString("LOHAS Park", "康城")),
      MtrStation(code: "HAH", name: const LocalizedString("Hang Hau", "坑口")),
      MtrStation(code: "POA", name: const LocalizedString("Po Lam", "寶琳")),
    ],
  ),
  MtrLine(
    code: "EAL",
    name: const LocalizedString("East Rail Line", "東鐵綫"),
    color: const Color(0xFF53C3F1),
    stations: [
      MtrStation(code: "ADM", name: const LocalizedString("Admiralty", "金鐘")),
      MtrStation(code: "EXC", name: const LocalizedString("Exhibition Centre", "會展")),
      MtrStation(code: "HUH", name: const LocalizedString("Hung Hom", "紅磡")),
      MtrStation(code: "MKK", name: const LocalizedString("Mong Kok East", "旺角東")),
      MtrStation(code: "KOT", name: const LocalizedString("Kowloon Tong", "九龍塘")),
      MtrStation(code: "TAW", name: const LocalizedString("Tai Wai", "大圍")),
      MtrStation(code: "SHT", name: const LocalizedString("Sha Tin", "沙田")),
      MtrStation(code: "FOT", name: const LocalizedString("Fo Tan", "火炭")),
      MtrStation(code: "RAC", name: const LocalizedString("Racecourse", "馬場")),
      MtrStation(code: "UNI", name: const LocalizedString("University", "大學")),
      MtrStation(code: "TAP", name: const LocalizedString("Tai Po Market", "大埔墟")),
      MtrStation(code: "TWO", name: const LocalizedString("Tai Wo", "太和")),
      MtrStation(code: "FAN", name: const LocalizedString("Fanling", "粉嶺")),
      MtrStation(code: "SHS", name: const LocalizedString("Sheung Shui", "上水")),
      MtrStation(code: "LOW", name: const LocalizedString("Lo Wu", "羅湖")),
      MtrStation(code: "LMC", name: const LocalizedString("Lok Ma Chau", "落馬洲")),
    ],
  ),
  MtrLine(
    code: "SIL",
    name: const LocalizedString("South Island Line", "南港島綫"),
    color: const Color(0xFFB6BD00),
    stations: [
      MtrStation(code: "ADM", name: const LocalizedString("Admiralty", "金鐘")),
      MtrStation(code: "OCP", name: const LocalizedString("Ocean Park", "海洋公園")),
      MtrStation(code: "WCH", name: const LocalizedString("Wong Chuk Hang", "黃竹坑")),
      MtrStation(code: "LET", name: const LocalizedString("Lei Tung", "利東")),
      MtrStation(code: "SOH", name: const LocalizedString("South Horizons", "海怡半島")),
    ],
  ),
  MtrLine(
    code: "TWL",
    name: const LocalizedString("Tsuen Wan Line", "荃灣綫"),
    color: const Color(0xFFE2231A),
    stations: [
      MtrStation(code: "CEN", name: const LocalizedString("Central", "中環")),
      MtrStation(code: "ADM", name: const LocalizedString("Admiralty", "金鐘")),
      MtrStation(code: "TST", name: const LocalizedString("Tsim Sha Tsui", "尖沙咀")),
      MtrStation(code: "JOR", name: const LocalizedString("Jordan", "佐敦")),
      MtrStation(code: "YMT", name: const LocalizedString("Yau Ma Tei", "油麻地")),
      MtrStation(code: "MOK", name: const LocalizedString("Mong Kok", "旺角")),
      MtrStation(code: "PRE", name: const LocalizedString("Prince Edward", "太子")),
      MtrStation(code: "SSP", name: const LocalizedString("Sham Shui Po", "深水埗")),
      MtrStation(code: "CSW", name: const LocalizedString("Cheung Sha Wan", "長沙灣")),
      MtrStation(code: "LCK", name: const LocalizedString("Lai Chi Kok", "荔枝角")),
      MtrStation(code: "MEF", name: const LocalizedString("Mei Foo", "美孚")),
      MtrStation(code: "LAK", name: const LocalizedString("Lai King", "荔景")),
      MtrStation(code: "KWF", name: const LocalizedString("Kwai Fong", "葵芳")),
      MtrStation(code: "KWH", name: const LocalizedString("Kwai Hing", "葵興")),
      MtrStation(code: "TWH", name: const LocalizedString("Tai Wo Hau", "大窩口")),
      MtrStation(code: "TSW", name: const LocalizedString("Tsuen Wan", "荃灣")),
    ],
  ),
  MtrLine(
    code: "ISL",
    name: const LocalizedString("Island Line", "港島綫"),
    color: const Color(0xFF0071CE),
    stations: [
      MtrStation(code: "KET", name: const LocalizedString("Kennedy Town", "堅尼地城")),
      MtrStation(code: "HKU", name: const LocalizedString("HKU", "香港大學")),
      MtrStation(code: "SYP", name: const LocalizedString("Sai Ying Pun", "西營盤")),
      MtrStation(code: "SHW", name: const LocalizedString("Sheung Wan", "上環")),
      MtrStation(code: "CEN", name: const LocalizedString("Central", "中環")),
      MtrStation(code: "ADM", name: const LocalizedString("Admiralty", "金鐘")),
      MtrStation(code: "WAC", name: const LocalizedString("Wan Chai", "灣仔")),
      MtrStation(code: "CAB", name: const LocalizedString("Causeway Bay", "銅鑼灣")),
      MtrStation(code: "TIH", name: const LocalizedString("Tin Hau", "天后")),
      MtrStation(code: "FOH", name: const LocalizedString("Fortress Hill", "炮台山")),
      MtrStation(code: "NOP", name: const LocalizedString("North Point", "北角")),
      MtrStation(code: "QUB", name: const LocalizedString("Quarry Bay", "鰂魚涌")),
      MtrStation(code: "TAK", name: const LocalizedString("Tai Koo", "太古")),
      MtrStation(code: "SWH", name: const LocalizedString("Sai Wan Ho", "西灣河")),
      MtrStation(code: "SKW", name: const LocalizedString("Shau Kei Wan", "筲箕灣")),
      MtrStation(code: "HFC", name: const LocalizedString("Heng Fa Chuen", "杏花邨")),
      MtrStation(code: "CHW", name: const LocalizedString("Chai Wan", "柴灣")),
    ],
  ),
  MtrLine(
    code: "KTL",
    name: const LocalizedString("Kwun Tong Line", "觀塘綫"),
    color: const Color(0xFF00AF41),
    stations: [
      MtrStation(code: "WHA", name: const LocalizedString("Whampoa", "黃埔")),
      MtrStation(code: "HOM", name: const LocalizedString("Ho Man Tin", "何文田")),
      MtrStation(code: "YMT", name: const LocalizedString("Yau Ma Tei", "油麻地")),
      MtrStation(code: "MOK", name: const LocalizedString("Mong Kok", "旺角")),
      MtrStation(code: "PRE", name: const LocalizedString("Prince Edward", "太子")),
      MtrStation(code: "SKM", name: const LocalizedString("Shek Kip Mei", "石硤尾")),
      MtrStation(code: "KOT", name: const LocalizedString("Kowloon Tong", "九龍塘")),
      MtrStation(code: "LOF", name: const LocalizedString("Lok Fu", "樂富")),
      MtrStation(code: "WTS", name: const LocalizedString("Wong Tai Sin", "黃大仙")),
      MtrStation(code: "DIH", name: const LocalizedString("Diamond Hill", "鑽石山")),
      MtrStation(code: "CHH", name: const LocalizedString("Choi Hung", "彩虹")),
      MtrStation(code: "KOB", name: const LocalizedString("Kowloon Bay", "九龍灣")),
      MtrStation(code: "NTK", name: const LocalizedString("Ngau Tau Kok", "牛頭角")),
      MtrStation(code: "KWT", name: const LocalizedString("Kwun Tong", "觀塘")),
      MtrStation(code: "LAT", name: const LocalizedString("Lam Tin", "藍田")),
      MtrStation(code: "YAT", name: const LocalizedString("Yau Tong", "油塘")),
      MtrStation(code: "TIK", name: const LocalizedString("Tiu Keng Leng", "調景嶺")),
    ],
  ),
];

final List<MtrStation> lightRailStations = [
  MtrStation(id: 1, code: "001", name: const LocalizedString("Tuen Mun Ferry Pier", "屯門碼頭")),
  MtrStation(id: 10, code: "010", name: const LocalizedString("Melody Garden", "美樂")),
  MtrStation(id: 15, code: "015", name: const LocalizedString("Butterfly", "蝴蝶")),
  MtrStation(id: 20, code: "020", name: const LocalizedString("Light Rail Depot", "輕鐵車廠")),
  MtrStation(id: 30, code: "030", name: const LocalizedString("Lung Mun", "龍門")),
  MtrStation(id: 40, code: "040", name: const LocalizedString("Tsing Shan Tsuen", "青山村")),
  MtrStation(id: 50, code: "050", name: const LocalizedString("Tsing Wun", "青雲")),
  MtrStation(id: 60, code: "060", name: const LocalizedString("Kin On", "建安")),
  MtrStation(id: 70, code: "070", name: const LocalizedString("Ho Tin", "河田")),
  MtrStation(id: 75, code: "075", name: const LocalizedString("Choy Yee Bridge", "蔡意橋")),
  MtrStation(id: 80, code: "080", name: const LocalizedString("Affluence", "澤豐")),
  MtrStation(id: 90, code: "090", name: const LocalizedString("Tuen Mun Hospital", "屯門醫院")),
  MtrStation(id: 100, code: "100", name: const LocalizedString("Siu Hong", "兆康")),
  MtrStation(id: 110, code: "110", name: const LocalizedString("Kei Lun", "麒麟")),
  MtrStation(id: 120, code: "120", name: const LocalizedString("Ching Chung", "青松")),
  MtrStation(id: 130, code: "130", name: const LocalizedString("Kin Sang", "建生")),
  MtrStation(id: 140, code: "140", name: const LocalizedString("Tin King", "田景")),
  MtrStation(id: 150, code: "150", name: const LocalizedString("Leung King", "良景")),
  MtrStation(id: 160, code: "160", name: const LocalizedString("San Wai", "新圍")),
  MtrStation(id: 170, code: "170", name: const LocalizedString("Shek Pai", "石排")),
  MtrStation(id: 180, code: "180", name: const LocalizedString("Shan King (North)", "山景(北)")),
  MtrStation(id: 190, code: "190", name: const LocalizedString("Shan King (South)", "山景(南)")),
  MtrStation(id: 200, code: "200", name: const LocalizedString("Ming Kum", "鳴琴")),
  MtrStation(id: 212, code: "212", name: const LocalizedString("Tai Hing (North)", "大興(北)")),
  MtrStation(id: 220, code: "220", name: const LocalizedString("Tai Hing (South)", "大興(南)")),
  MtrStation(id: 230, code: "230", name: const LocalizedString("Ngan Wai", "銀圍")),
  MtrStation(id: 240, code: "240", name: const LocalizedString("Siu Hei", "兆禧")),
  MtrStation(id: 250, code: "250", name: const LocalizedString("Tuen Mun Swimming Pool", "屯門泳池")),
  MtrStation(id: 260, code: "260", name: const LocalizedString("Goodview Garden", "豐景園")),
  MtrStation(id: 265, code: "265", name: const LocalizedString("Siu Lun", "兆麟")),
  MtrStation(id: 920, code: "920", name: const LocalizedString("Sam Shing", "三聖")),
  MtrStation(id: 270, code: "270", name: const LocalizedString("On Ting", "安定")),
  MtrStation(id: 275, code: "275", name: const LocalizedString("Yau Oi", "友愛")),
  MtrStation(id: 280, code: "280", name: const LocalizedString("Town Centre", "市中心")),
  MtrStation(id: 295, code: "295", name: const LocalizedString("Tuen Mun", "屯門")),
  
  MtrStation(id: 300, code: "300", name: const LocalizedString("Pui To", "杯渡")),
  MtrStation(id: 310, code: "310", name: const LocalizedString("Hoh Fuk Tong", "何福堂")),
  MtrStation(id: 320, code: "320", name: const LocalizedString("San Hui", "新墟")),
  MtrStation(id: 330, code: "330", name: const LocalizedString("Prime View", "景峰")),
  MtrStation(id: 340, code: "340", name: const LocalizedString("Fung Tei", "鳳地")),
  
  MtrStation(id: 350, code: "350", name: const LocalizedString("Lam Tei", "藍地")),
  MtrStation(id: 360, code: "360", name: const LocalizedString("Nai Wai ", "泥圍")),
  MtrStation(id: 370, code: "370", name: const LocalizedString("Chung Uk Tsuen", "鍾屋村")),
  MtrStation(id: 380, code: "380", name: const LocalizedString("Hung Shui Kiu", "洪水橋")),
  MtrStation(id: 390, code: "380", name: const LocalizedString("Tong Fong Tsuen", "塘坊村")),
  MtrStation(id: 400, code: "400", name: const LocalizedString("Ping Shan", "屏山")),
  MtrStation(id: 425, code: "425", name: const LocalizedString("Hang Mei Tsuen", "坑尾村")),
  
  MtrStation(id: 430, code: "430", name: const LocalizedString("Tin Shui Wai", "天水圍")),
  MtrStation(id: 435, code: "435", name: const LocalizedString("Tin Tsz", "天慈")),
  MtrStation(id: 445, code: "445", name: const LocalizedString("Tin Yiu", "天耀")),
  MtrStation(id: 448, code: "448", name: const LocalizedString("Locwood", "樂湖")),
  MtrStation(id: 450, code: "450", name: const LocalizedString("Tin Wu", "天湖")),
  MtrStation(id: 455, code: "455", name: const LocalizedString("Ginza", "銀座")),
  MtrStation(id: 460, code: "460", name: const LocalizedString("Tin Shui", "天瑞")),
  MtrStation(id: 468, code: "468", name: const LocalizedString("Chung Fu", "頌富")),
  MtrStation(id: 480, code: "480", name: const LocalizedString("Tin Fu", "天富")),
  MtrStation(id: 490, code: "490", name: const LocalizedString("Chestwood", "翠湖")),
  MtrStation(id: 500, code: "500", name: const LocalizedString("Tin Wing", "天榮")),
  MtrStation(id: 510, code: "510", name: const LocalizedString("Tin Yuet", "天悅")),
  MtrStation(id: 520, code: "520", name: const LocalizedString("Tin Sau", "天秀")),
  MtrStation(id: 530, code: "530", name: const LocalizedString("Wetland Park", "濕地公園")),
  MtrStation(id: 540, code: "540", name: const LocalizedString("Tin Heng", "天恆")),
  MtrStation(id: 550, code: "550", name: const LocalizedString("Tin Yat", "天逸")),
  
  MtrStation(id: 560, code: "560", name: const LocalizedString("Shui Pin Wai", "水邊圍")),
  MtrStation(id: 570, code: "570", name: const LocalizedString("Fung Nin Road", "豐年路")),
  MtrStation(id: 580, code: "580", name: const LocalizedString("Hong Lok Road", "康樂路")),
  MtrStation(id: 590, code: "590", name: const LocalizedString("Tai Tong Road", "大棠路")),
  MtrStation(id: 600, code: "600", name: const LocalizedString("Yuen Long", "元朗")),
];

Map<String, LocalizedString> _createStationMap() {
  Map<String, LocalizedString> map = {};
  for (var line in mtrLines) {
    for (var sta in line.stations) {
      map[sta.code] = sta.name;
    }
  }
  return map;
}
final Map<String, LocalizedString> stationCodeToName = _createStationMap();