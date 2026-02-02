import 'package:flutter/material.dart';
import 'package:my_mtr_schedule/Data/localized_string.dart';
import 'package:my_mtr_schedule/Data/mtr_data.dart';
import 'package:my_mtr_schedule/Data/ui_labels.dart';
import 'package:my_mtr_schedule/api_service.dart';
import 'package:my_mtr_schedule/preferences_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLang _lang = AppLang.en;

  @override
  void initState() {
    super.initState();
    
    _loadLang();
  }

  void _loadLang() async {
    final savedLang = await PreferencesService.loadLanguage();
    setState(() {
      _lang = savedLang;
    });
  }

  void _toggleLang() {
    setState(() {
      _lang = _lang == AppLang.en ? AppLang.tc : AppLang.en;
    });
    PreferencesService.saveLanguage(_lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MTR Schedule",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // fontFamily: _lang == AppLang.tc ? "Noto Sans HK" : "Roboto", 
        fontFamily: "Noto Sans HK", 
      ),
      home: HomeScreen(lang: _lang, onLangToggle: _toggleLang),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AppLang lang;
  final VoidCallback onLangToggle;

  const HomeScreen({super.key, required this.lang, required this.onLangToggle});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _lastFetchTime = defaultUpdateTime;
  
  final GlobalKey<_NormalRailPageState> _normalRailKey = GlobalKey();
  final GlobalKey<_LightRailPageState> _lightRailKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _syncTimeOnTabChange();
      }
    });
  }

  void _handleManualRefresh() {
    if (_tabController.index == 0) {
      _normalRailKey.currentState?.loadSchedule();
    } else {
      _lightRailKey.currentState?.loadSchedule();
    }
  }

  void updateUpdateTime(String newTime) {
    setState(() {
      _lastFetchTime = newTime;
    });
  }

  void _syncTimeOnTabChange() {
    String? timeToDisplay;
    if (_tabController.index == 0) {
      timeToDisplay = _normalRailKey.currentState?.lastReceivedTime;
    } else {
      timeToDisplay = _lightRailKey.currentState?.lastReceivedTime;
    }

    if (timeToDisplay != null) {
      setState(() {
        _lastFetchTime = timeToDisplay!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          title: Text(
            uiLabels["app_title"]!.get(widget.lang),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      uiLabels["last_update"]!.get(widget.lang),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      _lastFetchTime,
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.blueGrey[800]
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _handleManualRefresh,
              tooltip: uiLabels["refresh"]!.get(widget.lang),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                onPressed: widget.onLangToggle,
                icon: const Icon(Icons.language, size: 20),
                label: Text(uiLabels["app_lang"]!.get(widget.lang), 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: Colors.blue[800]),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[800],
            tabs: [
              Tab(icon: const Icon(Icons.train), text: uiLabels["tab_mtr"]!.get(widget.lang)),
              Tab(icon: const Icon(Icons.tram), text: uiLabels["tab_light"]!.get(widget.lang)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            NormalRailPage(key: _normalRailKey, lang: widget.lang, onTimeUpdate: updateUpdateTime),
            LightRailPage(key: _lightRailKey, lang: widget.lang, onTimeUpdate: updateUpdateTime),
          ],
        ),
      ),
    );
  }
}

class NormalRailPage extends StatefulWidget {
  final AppLang lang;
  final Function(String) onTimeUpdate;

  const NormalRailPage({super.key, required this.lang, required this.onTimeUpdate});

  @override
  State<NormalRailPage> createState() => _NormalRailPageState();
}

class _NormalRailPageState extends State<NormalRailPage> with AutomaticKeepAliveClientMixin {
  MtrLine? _selectedLine;
  MtrStation? _selectedStation;
  Future<MtrResult>? _futureSchedule;
  String lastReceivedTime = defaultUpdateTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void didUpdateWidget(NormalRailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang) {
      loadSchedule();
    }
  }

  Future<void> _loadSavedSettings() async {
    final saved = await PreferencesService.loadNormalRail();
    
    if (saved != null) {
      final foundLine = mtrLines.firstWhere(
        (l) => l.code == saved["line"], 
        orElse: () => mtrLines[2] // Tuen Ma Line
      );
      
      final foundStation = foundLine.stations.firstWhere(
        (s) => s.code == saved["station"], 
        orElse: () => foundLine.stations[0]
      );

      setState(() {
        _selectedLine = foundLine;
        _selectedStation = foundStation;
      });
    } else {
      _selectedLine = mtrLines[2]; // Tuen Ma Line
      _selectedStation = mtrLines[2].stations[mtrLines[2].stations.length - 1]; // Tuen Mun
    }
    
    loadSchedule();
  }

  void loadSchedule() {
    if (_selectedLine != null && _selectedStation != null) {
      final future = ApiService.fetchNormalRail(
        _selectedLine!.code, 
        _selectedStation!.code, 
        widget.lang
      );

      future.then((result) {
        lastReceivedTime = result.sysTime;
        widget.onTimeUpdate(result.sysTime);
      }).catchError((_) {});

      setState(() {
        _futureSchedule = future;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
          ),
          child: Column(
            children: [
              // Line Selector
              DropdownButtonFormField<MtrLine>(
                decoration: InputDecoration(
                  labelText: uiLabels["select_line"]!.get(widget.lang),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                initialValue: _selectedLine,
                items: mtrLines.map((line) {
                  return DropdownMenuItem(
                    value: line,
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: line.color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(line.name.get(widget.lang), style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedLine = val;
                    _selectedStation = val!.stations[0];
                    loadSchedule();
                  });
                  final selectedLine = _selectedLine;
                  final selectedStation = _selectedStation;
                  if (selectedLine != null && selectedStation != null) {
                    PreferencesService.saveNormalRail(selectedLine.code, selectedStation.code);
                  }
                },
              ),
              const SizedBox(height: 12),
              // Station Selector
              DropdownButtonFormField<MtrStation>(
                decoration: InputDecoration(
                  labelText: uiLabels["select_station"]!.get(widget.lang),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                initialValue: _selectedStation,
                items: _selectedLine?.stations.map((sta) {
                  return DropdownMenuItem(
                    value: sta,
                    child: Text(sta.name.get(widget.lang), style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedStation = val;
                    loadSchedule();
                  });
                  final selectedLine = _selectedLine;
                  final selectedStation = _selectedStation;
                  if (selectedLine != null && selectedStation != null) {
                    PreferencesService.saveNormalRail(selectedLine.code, selectedStation.code);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => loadSchedule(),
            child: FutureBuilder<MtrResult>(
              future: _futureSchedule,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Text(uiLabels["loading"]!.get(widget.lang)));
                } else if (snapshot.hasError) {
                  return Center(child: Text("${uiLabels["error"]!.get(widget.lang)}: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.schedules.isEmpty) {
                  return Center(child: Text(uiLabels["no_schedule"]!.get(widget.lang)));
                }

                final data = snapshot.data!;
                final upTrains = data.schedules["UP"] ?? [];
                final downTrains = data.schedules["DOWN"] ?? [];

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (upTrains.isNotEmpty) ...[
                       _buildDirectionHeader("${uiLabels["platform"]!.get(widget.lang)} ${upTrains.first.plat}"),
                       ...upTrains.map((t) => TrainCard(train: t, color: _selectedLine?.color, lang: widget.lang)),
                    ],
                    const SizedBox(height: 16),
                    if (downTrains.isNotEmpty) ...[
                       _buildDirectionHeader("${uiLabels["platform"]!.get(widget.lang)} ${downTrains.first.plat}"),
                       ...downTrains.map((t) => TrainCard(train: t, color: _selectedLine?.color, lang: widget.lang)),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
            shadows: [Shadow(color: Colors.white.withValues(alpha: 0.5), offset: const Offset(1,1), blurRadius: 2)]
        ),
      ),
    );
  }
}

class LightRailPage extends StatefulWidget {
  final AppLang lang;
  final Function(String) onTimeUpdate;

  const LightRailPage({super.key, required this.lang, required this.onTimeUpdate});

  @override
  State<LightRailPage> createState() => _LightRailPageState();
}

class _LightRailPageState extends State<LightRailPage> with AutomaticKeepAliveClientMixin {
  MtrStation? _selectedStation;
  Future<MtrResult>? _futureSchedule;
  String lastReceivedTime = defaultUpdateTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void didUpdateWidget(LightRailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang) {
      loadSchedule();
    }
  }

  Future<void> _loadSavedSettings() async {
    final savedId = await PreferencesService.loadLightRail();
    
    if (savedId != null) {
      final foundStation = lightRailStations.firstWhere(
        (s) => s.id == savedId,
        // Default Tuen Mun 295
        orElse: () => lightRailStations.firstWhere((s) => s.id == 295)
      );
      
      setState(() {
        _selectedStation = foundStation;
      });
    } else {
      // Default Tuen Mun 295
      _selectedStation = lightRailStations.firstWhere((s) => s.id == 295);
    }
    
    loadSchedule();
  }

  void loadSchedule() {
    if (_selectedStation != null) {
      final future = ApiService.fetchLightRail(_selectedStation!.id!, widget.lang);

      future.then((result) {
        lastReceivedTime = result.sysTime;
        widget.onTimeUpdate(result.sysTime);
      }).catchError((_) { });
      setState(() {
        _futureSchedule = future;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sortedStations = List<MtrStation>.from(lightRailStations);
    // sortedStations.sort((a, b) => a.name.get(widget.lang).compareTo(b.name.get(widget.lang)));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
          ),
          child: DropdownButtonFormField<MtrStation>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: uiLabels["select_lr_station"]!.get(widget.lang),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.7),
              prefixIcon: const Icon(Icons.search),
            ),
            initialValue: _selectedStation,
            items: sortedStations.map((sta) {
              return DropdownMenuItem(
                value: sta,
                child: Text(sta.name.get(widget.lang), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedStation = val;
                loadSchedule();
              });
              if (val != null && val.id != null) {
                PreferencesService.saveLightRail(val.id!);
              }
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => loadSchedule(),
            child: FutureBuilder<MtrResult>(
              future: _futureSchedule,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Text(uiLabels["loading"]!.get(widget.lang)));
                } else if (snapshot.hasError) {
                  return Center(child: Text("${uiLabels["error"]!.get(widget.lang)}: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.schedules.isEmpty) {
                  return Center(child: Text(uiLabels["no_schedule"]!.get(widget.lang)));
                }

                final data = snapshot.data!;
                final platforms = data.schedules.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: platforms.length,
                  itemBuilder: (context, index) {
                    final platId = platforms[index];
                    final trains = data.schedules[platId]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            "${uiLabels["platform"]!.get(widget.lang)} $platId",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                                shadows: [Shadow(color: Colors.white.withValues(alpha: 0.5), offset: const Offset(1,1), blurRadius: 2)]
                            ),
                          ),
                        ),
                        ...trains.map((t) => TrainCard(train: t, color: Colors.orange, lang: widget.lang)),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class TrainCard extends StatelessWidget {
  final TrainSchedule train;
  final Color? color;
  final AppLang lang;

  const TrainCard({super.key, required this.train, this.color, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white.withValues(alpha: 0.9), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color?.withValues(alpha: 0.2) ?? Colors.blue.withValues(alpha: 0.2),
          child: Icon(Icons.train, color: color ?? Colors.blue, size: 20),
        ),
        title: Text(
          train.getRowTitle(lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color ?? Colors.blue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (color ?? Colors.blue).withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: Text(
            train.time,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}