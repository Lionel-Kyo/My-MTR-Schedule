
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_mtr_schedule/Data/localized_string.dart';
import 'package:my_mtr_schedule/Data/mtr_data.dart';

const String defaultUpdateTime = "--:--:--";
const bool enableAutoRefetch = false;
const int refetechSeconds = 60;

class MtrResult {
  final Map<String, List<TrainSchedule>> schedules;
  final String sysTime;
  MtrResult(this.schedules, this.sysTime);
}

class ApiService {
  static const String normalRailUrl =
      "https://rt.data.gov.hk/v1/transport/mtr/getSchedule.php";
  static const String lightRailUrl =
      "https://rt.data.gov.hk/v1/transport/mtr/lrt/getSchedule";

  static Future<MtrResult> fetchNormalRail(
      String lineCode, String stationCode, AppLang lang) async {
    final langStr = lang == AppLang.en ? "en" : "tc";
    final response = await http.get(Uri.parse(
        "$normalRailUrl?line=$lineCode&sta=$stationCode&lang=$langStr"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final sysTimeRaw = data["sys_time"]as String? ?? "";
      final sysTime = sysTimeRaw.isNotEmpty ? sysTimeRaw.split(" ")[1] : defaultUpdateTime;

      if (data["status"] == 0) return MtrResult({}, sysTime);

      final scheduleData = data["data"]["$lineCode-$stationCode"];
      if (scheduleData == null) return MtrResult({}, sysTime);

      Map<String, List<TrainSchedule>> results = {};

      if (scheduleData["UP"] != null) {
        results["UP"] = _parseList(scheduleData["UP"], lang);
      }
      if (scheduleData["DOWN"] != null) {
        results["DOWN"] = _parseList(scheduleData["DOWN"], lang);
      }


      return MtrResult(results, sysTime);
    } else {
      throw Exception("Failed to load schedule");
    }
  }

  static List<TrainSchedule> _parseList(List<dynamic> list, AppLang lang) {
    return list.map<TrainSchedule>((item) {
      DateTime? arrivalTime;
      String timeDisplay = item["time"];
      
      try {
        if (timeDisplay.length > 10) {
           arrivalTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(timeDisplay);
           timeDisplay = DateFormat("HH:mm").format(arrivalTime);
        }
      } catch (_) { }

      String destName = item["dest"];
      if (stationCodeToName.containsKey(item["dest"])) {
        destName = stationCodeToName[item["dest"]]!.get(lang);
      }

      return TrainSchedule(
        plat: item["plat"],
        time: timeDisplay,
        destCode: item["dest"],
        destName: destName,
        trainLength: null,
        routeNum: "",
      );
    }).toList();
  }

  static Future<MtrResult> fetchLightRail(
      int stationId, AppLang lang) async {
    final response = await http
        .get(Uri.parse("$lightRailUrl?station_id=$stationId"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final sysTimeRaw = data["system_time"] as String? ?? "";
      final sysTime = sysTimeRaw.isNotEmpty ? sysTimeRaw.split(" ")[1] : defaultUpdateTime;
      if (data["status"] == 0) return MtrResult({}, sysTime);

      final platformList = data["platform_list"];
      if (platformList == null) return MtrResult({}, sysTime);

      Map<String, List<TrainSchedule>> results = {};

      for (var p in platformList) {
        String platId = p["platform_id"].toString();
        List<dynamic> routes = p["route_list"];
        
        List<TrainSchedule> trains = routes.map((r) {
          String dest = (lang == AppLang.en) 
              ? (r["dest_en"] ?? "") 
              : (r["dest_ch"] ?? "");
              
          String time = (lang == AppLang.en) 
            ? r["time_en"] 
            : r["time_ch"];

          return TrainSchedule(
            plat: platId,
            time: time,
            destCode: "",
            routeNum: r["route_no"],
            trainLength: r["train_length"],
            destName: dest,
          );
        }).toList();

        results[platId] = trains;
      }
      return MtrResult(results, sysTime);
    } else {
      throw Exception("Failed to load Light Rail schedule");
    }
  }
}
