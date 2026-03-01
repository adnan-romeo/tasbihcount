import 'dart:convert';

import 'package:http/http.dart' as http;

class PrayerTimes {
  const PrayerTimes({required this.sehriTime, required this.iftarTime});

  final String sehriTime;
  final String iftarTime;
}

class PrayerTimeService {
  Future<PrayerTimes> fetchTodayTimes({
    String city = 'Dhaka',
    String country = 'Bangladesh',
  }) async {
    final Uri uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
      'city': city,
      'country': country,
      'method': '2',
    });

    final http.Response response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prayer times');
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> data =
        decoded['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> timings =
        data['timings'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final String fajrRaw = (timings['Fajr'] as String?) ?? '';
    final String maghribRaw = (timings['Maghrib'] as String?) ?? '';

    if (fajrRaw.isEmpty || maghribRaw.isEmpty) {
      throw Exception('Prayer timings not available in API response');
    }

    final String sehriAdjusted = _subtractMinutes(fajrRaw, 15);
    final String iftarAdjusted = _addMinutes(maghribRaw, 2);

    return PrayerTimes(
      sehriTime: _to12Hour(sehriAdjusted),
      iftarTime: _to12Hour(iftarAdjusted),
    );
  }

  String _addMinutes(String timeWithMeta, int minutesToAdd) {
    final String clean = timeWithMeta.split(' ').first.trim();
    final List<String> parts = clean.split(':');

    if (parts.length < 2) {
      return clean;
    }

    final int? hour24 = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour24 == null || minute == null) {
      return clean;
    }

    final DateTime baseline = DateTime(2026, 1, 1, hour24, minute);
    final DateTime adjusted = baseline.add(Duration(minutes: minutesToAdd));

    final String hh = adjusted.hour.toString().padLeft(2, '0');
    final String mm = adjusted.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _subtractMinutes(String timeWithMeta, int minutesToSubtract) {
    final String clean = timeWithMeta.split(' ').first.trim();
    final List<String> parts = clean.split(':');

    if (parts.length < 2) {
      return clean;
    }

    final int? hour24 = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour24 == null || minute == null) {
      return clean;
    }

    final DateTime baseline = DateTime(2026, 1, 1, hour24, minute);
    final DateTime adjusted = baseline.subtract(
      Duration(minutes: minutesToSubtract),
    );

    final String hh = adjusted.hour.toString().padLeft(2, '0');
    final String mm = adjusted.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _to12Hour(String timeWithMeta) {
    final String clean = timeWithMeta.split(' ').first.trim();
    final List<String> parts = clean.split(':');

    if (parts.length < 2) {
      return clean;
    }

    final int? hour24 = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour24 == null || minute == null) {
      return clean;
    }

    final bool isPm = hour24 >= 12;
    final int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final String hh = hour12.toString().padLeft(2, '0');
    final String mm = minute.toString().padLeft(2, '0');
    final String suffix = isPm ? 'PM' : 'AM';

    return '$hh:$mm $suffix';
  }
}
