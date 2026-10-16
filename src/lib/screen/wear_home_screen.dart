import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:my_mtr_schedule/data/localized_string.dart';
import 'package:my_mtr_schedule/data/mtr_data.dart';
import 'package:my_mtr_schedule/data/ui_labels.dart';
import 'package:my_mtr_schedule/service/api_service.dart';
import 'package:my_mtr_schedule/service/preferences_service.dart';
import 'package:wearable_rotary/wearable_rotary.dart';

const wearPurpleColor = Color(0xFFD8B4FF);
const wearLrtColor = Color(0xFFD3A809);

enum RailMode { mtr, lightRail }

class WearHomeScreen extends StatefulWidget {
  final AppLang lang;
  final VoidCallback onLangToggle;

  const WearHomeScreen({
    super.key,
    required this.lang,
    required this.onLangToggle,
  });

  @override
  State<WearHomeScreen> createState() => _WearHomeScreenState();
}

class _WatchSelectionScreen<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) getName;
  final void Function(T) onSelected;

  const _WatchSelectionScreen({
    required this.title,
    required this.items,
    required this.getName,
    required this.onSelected,
  });

  @override
  State<_WatchSelectionScreen<T>> createState() =>
      _WatchSelectionScreenState<T>();
}

class _WatchSelectionScreenState<T> extends State<_WatchSelectionScreen<T>> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<RotaryEvent>? _rotarySub;

  @override
  void initState() {
    super.initState();
    _rotarySub = rotaryEvents.listen((event) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true &&
          _scrollController.hasClients) {
        final double delta = event.direction == RotaryDirection.clockwise
            ? 20.0
            : -20.0;
        final double target = (_scrollController.offset + delta).clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _rotarySub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Padding(
            padding: shape == WearShape.round
                ? const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0)
                : const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: wearPurpleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return InkWell(
                        onTap: () {
                          widget.onSelected(item);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            widget.getName(item),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WearHomeScreenState extends State<WearHomeScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = RotaryScrollController();
  StreamSubscription<RotaryEvent>? _rotarySub;

  RailMode _currentMode = RailMode.mtr;

  MtrLine? _normalLine;
  MtrStation? _normalStation;
  MtrStation? _lightStation;

  Future<MtrResult>? _futureSchedule;
  Timer? _timer;
  DateTime? _lastFetchedDt;
  String _lastFetchTime = defaultUpdateTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedAndFetch();

    _rotarySub = rotaryEvents.listen((event) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true &&
          _scrollController.hasClients) {
        final double delta = event.direction == RotaryDirection.clockwise
            ? 20.0
            : -20.0;
        final double target = (_scrollController.offset + delta).clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _rotarySub?.cancel();
    _scrollController.dispose();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(WearHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang) {
      _loadSchedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (enableAutoRefetch) {
      if (state == AppLifecycleState.resumed) {
        final lastFetched = _lastFetchedDt;
        if (lastFetched != null) {
          final diff = DateTime.now().toUtc().difference(lastFetched).inSeconds;
          if (diff >= refetechSeconds) {
            _loadSchedule();
          } else {
            _startTimer(Duration(seconds: refetechSeconds - diff));
          }
        } else {
          _loadSchedule();
        }
      } else {
        _timer?.cancel();
      }
    }
  }

  void _startTimer([Duration? duration]) {
    _timer?.cancel();
    _timer = Timer(duration ?? Duration(seconds: refetechSeconds), () {
      _loadSchedule();
    });
  }

  Future<void> _loadSavedAndFetch() async {
    // Load Normal Rail Preferences
    final savedNormal = await PreferencesService.loadNormalRail();
    if (savedNormal != null) {
      _normalLine = mtrLines.firstWhere(
        (l) => l.code == savedNormal['line'],
        orElse: () => mtrLines[2], // Default Tuen Ma Line
      );
      _normalStation = _normalLine!.stations.firstWhere(
        (s) => s.code == savedNormal['station'],
        orElse: () => _normalLine!.stations[0],
      );
    } else {
      _normalLine = mtrLines[2];
      _normalStation = mtrLines[2].stations.last;
    }

    // Load Light Rail Preferences
    // Default Tuen Mun 295
    final savedLightId = await PreferencesService.loadLightRail();
    if (savedLightId != null) {
      _lightStation = lightRailStations.firstWhere(
        (s) => s.id == savedLightId,
        orElse: () => lightRailStations.firstWhere((s) => s.id == 295),
      );
    } else {
      _lightStation = lightRailStations.firstWhere((s) => s.id == 295);
    }

    _loadSchedule();
  }

  void _loadSchedule() {
    _timer?.cancel();

    if (_currentMode == RailMode.mtr &&
        _normalLine != null &&
        _normalStation != null) {
      final future = ApiService.fetchNormalRail(
        _normalLine!.code,
        _normalStation!.code,
        widget.lang,
      );
      future
          .then((result) {
            if (mounted) {
              _lastFetchedDt = DateTime.now().toUtc();
              setState(() {
                _lastFetchTime = result.sysTime;
              });
              if (enableAutoRefetch) _startTimer();
            }
          })
          .catchError((_) {});

      setState(() {
        _futureSchedule = future;
      });
    } else if (_currentMode == RailMode.lightRail && _lightStation != null) {
      final future = ApiService.fetchLightRail(_lightStation!.id!, widget.lang);
      future
          .then((result) {
            if (mounted) {
              _lastFetchedDt = DateTime.now().toUtc();
              setState(() {
                _lastFetchTime = result.sysTime;
              });
              if (enableAutoRefetch) _startTimer();
            }
          })
          .catchError((_) {});

      setState(() {
        _futureSchedule = future;
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == RailMode.mtr
          ? RailMode.lightRail
          : RailMode.mtr;
    });
    _loadSchedule();
  }

  Future<void> _showSelectionScreen<T>({
    required String title,
    required List<T> items,
    required String Function(T) getName,
    required void Function(T) onSelected,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _WatchSelectionScreen<T>(
          title: title,
          items: items,
          getName: getName,
          onSelected: onSelected,
        ),
      ),
    );
  }

  void _showLineSelector() {
    _showSelectionScreen<MtrLine>(
      title: uiLabels["select_line"]!.get(widget.lang),
      items: mtrLines,
      getName: (line) => line.name.get(widget.lang),
      onSelected: (line) {
        setState(() {
          _normalLine = line;
          _normalStation =
              line.stations.first; // Reset station when line changes
        });
        PreferencesService.saveNormalRail(
          _normalLine!.code,
          _normalStation!.code,
        );
        _loadSchedule();
      },
    );
  }

  void _showStationSelector() {
    if (_currentMode == RailMode.mtr) {
      if (_normalLine == null) return;
      _showSelectionScreen<MtrStation>(
        title: uiLabels["select_station"]!.get(widget.lang),
        items: _normalLine!.stations,
        getName: (station) => station.name.get(widget.lang),
        onSelected: (station) {
          setState(() => _normalStation = station);
          PreferencesService.saveNormalRail(_normalLine!.code, station.code);
          _loadSchedule();
        },
      );
    } else {
      _showSelectionScreen<MtrStation>(
        title: uiLabels["select_lr_station"]!.get(widget.lang),
        items: lightRailStations,
        getName: (station) => station.name.get(widget.lang),
        onSelected: (station) {
          setState(() => _lightStation = station);
          PreferencesService.saveLightRail(station.id!);
          _loadSchedule();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return AmbientMode(
          builder: (context, mode, child) {
            final isAmbient = mode == WearMode.ambient;

            return Scaffold(
              backgroundColor: Colors.black,
              body: Padding(
                padding: shape == WearShape.round
                    ? const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 8.0,
                      )
                    : const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Header Bar (Mode Switcher, Line, Station Name, Settings)
                    _buildHeader(isAmbient),
                    const SizedBox(height: 6),
                    Divider(
                      color: isAmbient
                          ? Colors.white24
                          : wearPurpleColor.withValues(alpha: 0.3),
                      height: 1,
                    ),

                    // Main Schedule List
                    Expanded(
                      child: FutureBuilder<MtrResult>(
                        future: _futureSchedule,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: wearPurpleColor,
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                uiLabels["error"]!.get(widget.lang),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.redAccent,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.schedules.isEmpty) {
                            return Center(
                              child: Text(
                                uiLabels["no_schedule"]!.get(widget.lang),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return _buildTrainListView(snapshot.data!, isAmbient);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(bool isAmbient) {
    final currentStationName = _currentMode == RailMode.mtr
        ? _normalStation?.name.get(widget.lang) ?? ''
        : _lightStation?.name.get(widget.lang) ?? '';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mode Toggle
            if (!isAmbient)
              GestureDetector(
                onTap: _toggleMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _currentMode == RailMode.mtr
                        ? wearPurpleColor.withValues(alpha: 0.2)
                        : wearLrtColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _currentMode == RailMode.mtr
                          ? wearPurpleColor
                          : wearLrtColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _currentMode == RailMode.mtr ? 'MTR' : 'LRT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _currentMode == RailMode.mtr
                          ? wearPurpleColor
                          : wearLrtColor,
                    ),
                  ),
                ),
              ),

            // Line Selector (Only visible for MTR)
            if (!isAmbient &&
                _currentMode == RailMode.mtr &&
                _normalLine != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _showLineSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (_normalLine?.color ?? Colors.white).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _normalLine?.color ?? Colors.white,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _normalLine!.code,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _normalLine?.color ?? Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            if (!isAmbient) ...[
              const SizedBox(width: 6),
              // Language Toggle
              GestureDetector(
                onTap: widget.onLangToggle,
                child: const Icon(
                  Icons.language,
                  size: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 4),
              // Refresh Button
              GestureDetector(
                onTap: _loadSchedule,
                child: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: wearPurpleColor,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: isAmbient
                  ? null
                  : BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
              child: Text(
                _lastFetchTime,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Station Selector (Tappable Dropdown style)
            GestureDetector(
              onTap: isAmbient ? null : _showStationSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: isAmbient
                    ? null
                    : BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        currentStationName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isAmbient)
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrainListView(MtrResult data, bool isAmbient) {
    List<Widget> listItems = [];

    if (_currentMode == RailMode.mtr) {
      final upTrains = data.schedules["UP"] ?? [];
      final downTrains = data.schedules["DOWN"] ?? [];

      if (upTrains.isNotEmpty) {
        listItems.add(
          _buildSectionHeader(
            "${uiLabels["platform"]!.get(widget.lang)} ${upTrains.first.plat}",
            isAmbient,
          ),
        );
        listItems.addAll(
          upTrains.map(
            (t) => _buildTrainCard(t, isAmbient, _normalLine?.color),
          ),
        );
      }
      if (downTrains.isNotEmpty) {
        listItems.add(
          _buildSectionHeader(
            "${uiLabels["platform"]!.get(widget.lang)} ${downTrains.first.plat}",
            isAmbient,
          ),
        );
        listItems.addAll(
          downTrains.map(
            (t) => _buildTrainCard(t, isAmbient, _normalLine?.color),
          ),
        );
      }
    } else {
      final platforms = data.schedules.keys.toList()..sort();
      for (var platId in platforms) {
        final trains = data.schedules[platId]!;
        listItems.add(
          _buildSectionHeader(
            "${uiLabels["platform"]!.get(widget.lang)} $platId",
            isAmbient,
          ),
        );
        listItems.addAll(
          trains.map((t) => _buildTrainCard(t, isAmbient, wearLrtColor)),
        );
      }
    }

    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: listItems,
    );
  }

  Widget _buildSectionHeader(String title, bool isAmbient) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAmbient ? Colors.white70 : wearPurpleColor,
        ),
      ),
    );
  }

  Widget _buildTrainCard(
    TrainSchedule train,
    bool isAmbient,
    Color? accentColor,
  ) {
    final effectiveColor = accentColor ?? wearPurpleColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAmbient ? Colors.transparent : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: isAmbient
            ? Border.all(color: Colors.white38, width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              train.getRowTitle(widget.lang),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAmbient ? Colors.transparent : effectiveColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              train.time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isAmbient ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
