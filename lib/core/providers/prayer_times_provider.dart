import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _defaultLat = 24.7136;
const double _defaultLng = 46.6753;
const String _cacheLatKey = 'cached_prayer_lat';
const String _cacheLngKey = 'cached_prayer_lng';
const String _cacheCityKey = 'cached_prayer_city';

class PrayerState {
  final PrayerTimes? prayerTimes;
  final String city;
  final bool isFallback;

  PrayerState({
    this.prayerTimes,
    required this.city,
    this.isFallback = false,
  });
}

class PrayerTimesNotifier extends AsyncNotifier<PrayerState> {
  @override
  FutureOr<PrayerState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLat = prefs.getDouble(_cacheLatKey);
    final cachedLng = prefs.getDouble(_cacheLngKey);
    final cachedCity = prefs.getString(_cacheCityKey);

    if (cachedLat != null && cachedLng != null) {
      _fetchFreshLocationAndUpdate(prefs);
      return PrayerState(
        prayerTimes: _calculateTimes(cachedLat, cachedLng),
        city: cachedCity ?? "Riyadh",
        isFallback: false,
      );
    }

    return await _getFreshOrFallback();
  }

  Future<PrayerState> _getFreshOrFallback() async {
    try {
      final pos = await _determinePosition().timeout(const Duration(seconds: 5));
      final city = await _getCityName(pos.latitude, pos.longitude);
      await _cachePosition(pos.latitude, pos.longitude, city);
      return PrayerState(
        prayerTimes: _calculateTimes(pos.latitude, pos.longitude),
        city: city,
        isFallback: false,
      );
    } catch (e) {
      // If permission is denied or location fails, default to Riyadh
      return PrayerState(
        prayerTimes: _calculateTimes(_defaultLat, _defaultLng),
        city: "Riyadh", // Keep as raw string, UI will localize if it matches
        isFallback: true,
      );
    }
  }

  Future<void> _fetchFreshLocationAndUpdate(SharedPreferences prefs) async {
    try {
      final pos = await _determinePosition().timeout(const Duration(seconds: 5));
      final city = await _getCityName(pos.latitude, pos.longitude);
      await _cachePosition(pos.latitude, pos.longitude, city);
      state = AsyncData(PrayerState(
        prayerTimes: _calculateTimes(pos.latitude, pos.longitude),
        city: city,
        isFallback: false,
      ));
    } catch (e) {
      // Keep existing
    }
  }

  Future<String> _getCityName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return placemarks[0].locality ?? placemarks[0].subAdministrativeArea ?? "Unknown";
      }
    } catch (_) {}
    return "Unknown";
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

    return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
  }

  PrayerTimes _calculateTimes(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes.today(coordinates, params);
  }

  Future<void> _cachePosition(double lat, double lng, String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cacheLatKey, lat);
    await prefs.setDouble(_cacheLngKey, lng);
    await prefs.setString(_cacheCityKey, city);
  }
}

final prayerTimesProvider = AsyncNotifierProvider<PrayerTimesNotifier, PrayerState>(() {
  return PrayerTimesNotifier();
});

final hijriDateProvider = Provider<String>((ref) {
  HijriCalendar.setLocal('ar');
  final today = HijriCalendar.now();
  return '${today.hDay} ${today.longMonthName} ${today.hYear}';
});
