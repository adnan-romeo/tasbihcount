import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../services/counter_service.dart';
import '../services/prayer_time_service.dart';
import '../widgets/outlined_action_button.dart';

class MainCounterScreen extends StatefulWidget {
  const MainCounterScreen({super.key});

  @override
  State<MainCounterScreen> createState() => _MainCounterScreenState();
}

class _MainCounterScreenState extends State<MainCounterScreen>
    with WidgetsBindingObserver {
  static const String _todayCountPrefix = 'today_count';
  static const String _weekCountPrefix = 'week_count';
  static const String _monthCountPrefix = 'month_count';
  static const String _lifetimeCountPrefix = 'lifetime_count';
  static const String _lastUpdatedPrefix = 'last_updated_timestamp';
  static const String _locationCityPrefix = 'location_city';
  static const String _locationCountryPrefix = 'location_country';
  static const String _offlineBucket = 'offline';
  static const String _legacyTodayKey = 'today_count';
  static const String _legacyWeekKey = 'week_count';
  static const String _legacyMonthKey = 'month_count';
  static const String _legacyMigrationDoneKey = 'counter_keys_migrated_v1';

  final AuthService _authService = AuthService();
  final CounterService _counterService = CounterService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final List<String> _bangladeshZillaPresets = const [
    'Dhaka',
    'Chattogram',
    'Rajshahi',
    'Khulna',
    'Barishal',
    'Sylhet',
    'Rangpur',
    'Mymensingh',
    'Cumilla',
    'Bogura',
    'Narayanganj',
    'Cox\'s Bazar',
  ];

  int currentCount = 0;
  int todayCount = 0;
  int weekCount = 0;
  int monthCount = 0;
  int lifetimeCount = 0;
  String selectedCity = 'Dhaka';
  String selectedCountry = 'Bangladesh';
  String sehriText = 'Last: 05:03 AM';
  String iftarText = 'Start: 06:07 PM';
  bool isLoading = true;
  bool _isSaving = false;
  bool _hasPendingSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCounts();
    _loadLocationAndPrayerTimes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveCounts();
    }
  }

  String _scopedKey(String prefix, String bucket) => '${prefix}_$bucket';

  Future<void> _cleanupLegacyGlobalKeys(SharedPreferences prefs) async {
    final bool hasMigrated = prefs.getBool(_legacyMigrationDoneKey) ?? false;

    if (hasMigrated) {
      return;
    }

    await prefs.remove(_legacyTodayKey);
    await prefs.remove(_legacyWeekKey);
    await prefs.remove(_legacyMonthKey);
    await prefs.setBool(_legacyMigrationDoneKey, true);
  }

  Future<void> _loadCounts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _cleanupLegacyGlobalKeys(prefs);

    final String? uid = _authService.currentUser?.uid;
    final String localBucket = uid ?? _offlineBucket;

    int? lastUpdatedMillis =
        prefs.getInt(_scopedKey(_lastUpdatedPrefix, localBucket));

    int loadedToday =
        prefs.getInt(_scopedKey(_todayCountPrefix, localBucket)) ?? 0;
    int loadedWeek =
        prefs.getInt(_scopedKey(_weekCountPrefix, localBucket)) ?? 0;
    int loadedMonth =
        prefs.getInt(_scopedKey(_monthCountPrefix, localBucket)) ?? 0;
    int loadedLifetime =
        prefs.getInt(_scopedKey(_lifetimeCountPrefix, localBucket)) ?? 0;

    // Apply local time-based resets (for offline support)
    if (lastUpdatedMillis != null) {
      final DateTime lastUpdated =
          DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);
      final DateTime now = DateTime.now();

      // 1. Daily Reset
      if (!_isSameDay(now, lastUpdated)) {
        loadedToday = 0;
      }

      // 2. Weekly Reset (Friday)
      final DateTime lastFriday = _getLastFriday(now);
      if (lastUpdated.isBefore(lastFriday)) {
        loadedWeek = 0;
      }

      // 3. Monthly Reset
      if (!_isSameMonth(now, lastUpdated)) {
        loadedMonth = 0;
      }
    }

    if (uid != null) {
      try {
        final Map<String, int> cloudCounts =
            await _counterService.loadUserCounts(uid);
        loadedToday = cloudCounts['today'] ?? 0;
        loadedWeek = cloudCounts['week'] ?? 0;
        loadedMonth = cloudCounts['month'] ?? 0;
        loadedLifetime = cloudCounts['lifetime'] ?? 0;
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    setState(() {
      currentCount = 0;
      todayCount = loadedToday;
      weekCount = loadedWeek;
      monthCount = loadedMonth;
      lifetimeCount = loadedLifetime;
      isLoading = false;
    });

    await _saveCounts();
  }

  Future<void> _saveCounts() async {
    if (_isSaving) {
      _hasPendingSave = true;
      return;
    }

    _isSaving = true;

    try {
      do {
        _hasPendingSave = false;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? uid = _authService.currentUser?.uid;
        final String localBucket = uid ?? _offlineBucket;

        final int todayToSave = todayCount;
        final int weekToSave = weekCount;
        final int monthToSave = monthCount;
        final int lifetimeToSave = lifetimeCount;

        await prefs.setInt(
          _scopedKey(_lastUpdatedPrefix, localBucket),
          DateTime.now().millisecondsSinceEpoch,
        );

        await prefs.setInt(
          _scopedKey(_todayCountPrefix, localBucket),
          todayToSave,
        );
        await prefs.setInt(
          _scopedKey(_weekCountPrefix, localBucket),
          weekToSave,
        );
        await prefs.setInt(
          _scopedKey(_monthCountPrefix, localBucket),
          monthToSave,
        );
        await prefs.setInt(
          _scopedKey(_lifetimeCountPrefix, localBucket),
          lifetimeToSave,
        );

        if (uid != null) {
          await _counterService.saveUserCounts(
            uid,
            today: todayToSave,
            week: weekToSave,
            month: monthToSave,
            lifetime: lifetimeToSave,
          );
        }
      } while (_hasPendingSave);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not sync counter to cloud right now.'),
          ),
        );
      }
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _loadLocationAndPrayerTimes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? uid = _authService.currentUser?.uid;
    final String localBucket = uid ?? _offlineBucket;

    final String loadedCity =
        prefs.getString(_scopedKey(_locationCityPrefix, localBucket)) ??
            'Dhaka';
    final String loadedCountry =
        prefs.getString(_scopedKey(_locationCountryPrefix, localBucket)) ??
            'Bangladesh';

    if (!mounted) {
      return;
    }

    setState(() {
      selectedCity = loadedCity;
      selectedCountry = loadedCountry;
    });

    await _loadPrayerTimes();
  }

  Future<void> _saveLocation({
    required String city,
    required String country,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? uid = _authService.currentUser?.uid;
    final String localBucket = uid ?? _offlineBucket;

    await prefs.setString(_scopedKey(_locationCityPrefix, localBucket), city);
    await prefs.setString(
      _scopedKey(_locationCountryPrefix, localBucket),
      country,
    );
  }

  Future<void> _loadPrayerTimes({bool showError = false}) async {
    try {
      final PrayerTimes times = await _prayerTimeService.fetchTodayTimes(
        city: selectedCity,
        country: selectedCountry,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        sehriText = 'Last: ${times.sehriTime}';
        iftarText = 'Start: ${times.iftarTime}';
      });
    } catch (_) {
      if (showError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not fetch prayer times for this location.'),
          ),
        );
      }
    }
  }

  Future<void> _showLocationDialog() async {
    final TextEditingController cityController =
        TextEditingController(text: selectedCity);
    final TextEditingController countryController =
        TextEditingController(text: selectedCountry);

    final ({String city, String country})? result =
        await showDialog<({String city, String country})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white70),
              ),
              title: const Text(
                'Select Location',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bangladesh Zilla Presets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bangladeshZillaPresets.map((zilla) {
                        return OutlinedButton(
                          onPressed: () {
                            setDialogState(() {
                              cityController.text = zilla;
                              countryController.text = 'Bangladesh';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(zilla),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: cityController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(hintText: 'City'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: countryController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(hintText: 'Country'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                ),
                FilledButton(
                  onPressed: () {
                    final String city = cityController.text.trim();
                    final String country = countryController.text.trim();

                    if (city.isEmpty || country.isEmpty) {
                      return;
                    }

                    Navigator.pop(context, (city: city, country: country));
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    cityController.dispose();
    countryController.dispose();

    if (result == null) {
      return;
    }

    setState(() {
      selectedCity = result.city;
      selectedCountry = result.country;
    });

    await _saveLocation(city: selectedCity, country: selectedCountry);
    await _loadPrayerTimes(showError: true);
  }

  Widget _locationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$selectedCity, $selectedCountry',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _showLocationDialog,
            child: const Text(
              'Change',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSessionKeys.offlineMode, false);

    await _authService.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _incrementCounter() {
    setState(() {
      currentCount += 1;
      todayCount += 1;
      weekCount += 1;
      monthCount += 1;
      lifetimeCount += 1;
    });

    _saveCounts();
  }

  void _resetCounter() {
    setState(() {
      currentCount = 0;
    });
  }

  Widget _timeCard(
    String title,
    String subtitle, {
    required double titleFontSize,
    required double subtitleFontSize,
    required double verticalPadding,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterCard(
    String label,
    int value, {
    required double titleFontSize,
    required double valueFontSize,
    required double verticalPadding,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;
            final bool compact = width <= 400 || height <= 760;

            final double pagePadding = compact ? 12 : 20;
            final double smallGap = compact ? 8 : 12;
            final double mediumGap = compact ? 12 : 18;
            final double counterNumberSize = compact ? 64 : 80;
            final double circleSize = (width * (compact ? 0.62 : 0.68))
                .clamp(compact ? 210 : 230, 280)
                .toDouble();
            final double plusFontSize = compact ? 72 : 90;
            final double resetWidth = compact ? 170 : 200;

            return SingleChildScrollView(
              padding: EdgeInsets.all(pagePadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      _timeCard(
                        'SEHRI TODAY',
                        sehriText,
                        titleFontSize: compact ? 16 : 20,
                        subtitleFontSize: compact ? 14 : 18,
                        verticalPadding: compact ? 8 : 10,
                      ),
                      SizedBox(width: smallGap),
                      _timeCard(
                        'IFTAR TODAY',
                        iftarText,
                        titleFontSize: compact ? 16 : 20,
                        subtitleFontSize: compact ? 14 : 18,
                        verticalPadding: compact ? 8 : 10,
                      ),
                      PopupMenuButton<String>(
                        color: const Color(0xFF141419),
                        iconColor: Colors.white,
                        onSelected: (value) {
                          if (value == 'stats') {
                            Navigator.pushNamed(context, AppRoutes.statistics);
                          } else if (value == 'logout') {
                            _logout();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'stats',
                            child: Text('All time statistics'),
                          ),
                          PopupMenuItem(
                            value: 'logout',
                            child: Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: smallGap),
                  _locationSection(),
                  SizedBox(height: mediumGap),
                  Row(
                    children: [
                      _counterCard(
                        'Today',
                        todayCount,
                        titleFontSize: compact ? 16 : 20,
                        valueFontSize: compact ? 22 : 26,
                        verticalPadding: compact ? 6 : 8,
                      ),
                      SizedBox(width: smallGap),
                      _counterCard(
                        'This Week',
                        weekCount,
                        titleFontSize: compact ? 16 : 20,
                        valueFontSize: compact ? 22 : 26,
                        verticalPadding: compact ? 6 : 8,
                      ),
                      SizedBox(width: smallGap),
                      _counterCard(
                        'This Month',
                        monthCount,
                        titleFontSize: compact ? 16 : 20,
                        valueFontSize: compact ? 22 : 26,
                        verticalPadding: compact ? 6 : 8,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 26 : 36),
                  Text(
                    '$currentCount',
                    style: TextStyle(
                      fontSize: counterNumberSize,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  GestureDetector(
                    onTap: _incrementCounter,
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+1',
                        style: TextStyle(
                          fontSize: plusFontSize,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 24 : 36),
                  SizedBox(
                    width: resetWidth,
                    child: OutlinedActionButton(
                      label: 'Reset',
                      height: compact ? 50 : 56,
                      onPressed: _resetCounter,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  DateTime _getLastFriday(DateTime date) {
    // weekday: Mon=1, ... Fri=5, ... Sun=7
    final int daysToSubtract = (date.weekday - DateTime.friday + 7) % 7;
    final DateTime lastFri = date.subtract(Duration(days: daysToSubtract));
    return DateTime(lastFri.year, lastFri.month, lastFri.day); // Strip time
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}
