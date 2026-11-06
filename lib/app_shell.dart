
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show BottomNavigationBarItem;

import 'models/sensor_data.dart';
import 'services/temperature_service.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final TemperatureService service =
      TemperatureService();

  int selectedTab = 0;
  int modeVersion = 0;
  int? lastSequence;

  bool demoMode = true;
  bool connected = false;
  bool loading = false;
  bool pendingRefresh = false;
  bool warningShown = false;

  String? error;
  SensorSnapshot? latest;
  DateTime? lastUpdated;

  Timer? timer;

  final List<TemperaturePoint> history1 = [];
  final List<TemperaturePoint> history2 = [];

  @override
  void initState() {
    super.initState();

    loadData();

    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => loadData(),
    );
  }

  Future<void> loadData() async {
    if (loading) {
      pendingRefresh = true;
      return;
    }

    loading = true;
    final version = modeVersion;

    try {
      final SensorSnapshot data = demoMode
          ? service.createDemoData()
          : await service.fetchRealData();

      if (!mounted || version != modeVersion) {
        return;
      }

      final now = DateTime.now();

      setState(() {
        connected = true;
        error = null;
        latest = data;

        final newSample =
            data.sequence == null ||
            data.sequence != lastSequence;

        if (newSample) {
          lastSequence = data.sequence;
          lastUpdated = now;

          if (data.sensor1.ok &&
              data.sensor1.temperature != null) {
            history1.add(
              TemperaturePoint(
                now,
                data.sensor1.temperature!,
              ),
            );
          }

          if (data.sensor2.ok &&
              data.sensor2.temperature != null) {
            history2.add(
              TemperaturePoint(
                now,
                data.sensor2.temperature!,
              ),
            );
          }
        }

        history1.removeWhere(
          (p) =>
              now.difference(p.time).inSeconds > 60,
        );

        history2.removeWhere(
          (p) =>
              now.difference(p.time).inSeconds > 60,
        );
      });

      if (data.anyDanger && !warningShown) {
        warningShown = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          showCupertinoDialog<void>(
            context: context,
            builder: (dialogContext) {
              return CupertinoAlertDialog(
                title: const Text('동파 위험 감지'),
                content: const Text(
                  '센서에서 위험한 온도 변화가 '
                  '감지되었습니다.\n'
                  '센서 모니터링 화면을 확인하세요.',
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('확인'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              );
            },
          );
        });
      } else if (!data.anyDanger) {
        warningShown = false;
      }
    } catch (e) {
      if (!mounted || version != modeVersion) {
        return;
      }

      setState(() {
        connected = false;
        error = e.toString();
      });
    } finally {
      loading = false;

      if (pendingRefresh && mounted) {
        pendingRefresh = false;
        scheduleMicrotask(loadData);
      }
    }
  }

  void changeMode(bool value) {
    setState(() {
      modeVersion++;
      demoMode = value;

      connected = false;
      latest = null;
      error = null;
      lastUpdated = null;
      lastSequence = null;
      warningShown = false;

      history1.clear();
      history2.clear();

      service.resetDemo();
    });

    loadData();
  }

  void openMenu() {
    setState(() {
      selectedTab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: selectedTab,
                children: [
                  HomePage(
                    connected: connected,
                    demoMode: demoMode,
                    data: latest,
                    lastUpdated: lastUpdated,
                    error: error,
                    onOpenMenu: openMenu,
                  ),

                  MenuPage(
                    connected: connected,
                    demoMode: demoMode,
                    data: latest,
                    error: error,
                    history1: history1,
                    history2: history2,
                    onModeChanged: changeMode,
                  ),
                ],
              ),
            ),

            CupertinoTabBar(
              currentIndex: selectedTab,
              backgroundColor:
                  const Color(0xEEFFFFFF),
              activeColor:
                  const Color(0xFF007AFF),
              inactiveColor:
                  const Color(0xFF8E8E93),
              onTap: (index) {
                setState(() {
                  selectedTab = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.house),
                  activeIcon: Icon(
                    CupertinoIcons.house_fill,
                  ),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    CupertinoIcons.waveform_path_ecg,
                  ),
                  activeIcon: Icon(
                    CupertinoIcons.waveform_path_ecg,
                  ),
                  label: '센서',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
