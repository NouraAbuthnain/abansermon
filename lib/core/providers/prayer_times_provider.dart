import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _defaultLat = 24.7136;
const double _defaultLng = 46.6753;
const String _cacheLatKey = 'cached_prayer_lat';
const String _cacheLngKey = 'cached_prayer_lng';

class PrayerTimesNotifier extends AsyncNotifier<PrayerTimes?> {
  @override
  FutureOr<PrayerTimes?> build() async {
    // 1. Try to load cached coordinates immediately
    final prefs = await SharedPreferences.getInstance();
    final cachedLat = prefs.getDouble(_cacheLatKey);
    final cachedLng = prefs.getDouble(_cacheLngKey);
    
    if (cachedLat != null && cachedLng != null) {
      // Kick off background refresh
      _fetchFreshLocationAndUpdate(prefs);
      return _calculateTimes(cachedLat, cachedLng);
    }
    
    // 2. Fetch fresh location with timeout
    return await _getFreshOrFallback();
  }
  
  Future<PrayerTimes> _getFreshOrFallback() async {
    try {
      final pos = await _determinePosition().timeout(const Duration(seconds: 3));
      await _cachePosition(pos.latitude, pos.longitude);
      return _calculateTimes(pos.latitude, pos.longitude);
    } catch (e) {
      // Fallback
      return _calculateTimes(_defaultLat, _defaultLng);
    }
  }

  Future<void> _fetchFreshLocationAndUpdate(SharedPreferences prefs) async {
    try {
      final pos = await _determinePosition().timeout(const Duration(seconds: 3));
      await prefs.setDouble(_cacheLatKey, pos.latitude);
      await prefs.setDouble(_cacheLngKey, pos.longitude);
      state = AsyncData(_calculateTimes(pos.latitude, pos.longitude));
    } catch (e) {
      // Keep existing cached state
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return last;

    return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
  }

  PrayerTimes _calculateTimes(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes.today(coordinates, params);
  }

  Future<void> _cachePosition(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cacheLatKey, lat);
    await prefs.setDouble(_cacheLngKey, lng);
  }
}

final prayerTimesProvider = AsyncNotifierProvider<PrayerTimesNotifier, PrayerTimes?>(() {
  return PrayerTimesNotifier();
});

final hijriDateProvider = Provider<String>((ref) {
  HijriCalendar.setLocal('ar');
  final today = HijriCalendar.now();
  return '${today.hDay} ${today.longMonthName} ${today.hYear}';
});
