import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/prayer_times_provider.dart';
import '../../../../core/theme/app_theme.dart';

class PrayerTimesCard extends ConsumerStatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  ConsumerState<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends ConsumerState<PrayerTimesCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  static const double _prayerCardOverlap = 50;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time, bool isFallback) {
    final format = DateFormat.jm(context.locale.languageCode);
    if (!isFallback) {
      return format.format(time);
    }
    // Force Riyadh Time (UTC+3)
    final riyadhTime = time.toUtc().add(const Duration(hours: 3));
    final displayTime = DateTime(2000, 1, 1, riyadhTime.hour, riyadhTime.minute);
    return format.format(displayTime);
  }

  @override
  Widget build(BuildContext context) {
    final prayerStateAsync = ref.watch(prayerTimesProvider);
    final hijriDate = ref.watch(hijriDateProvider);

    return prayerStateAsync.when(
      data: (state) {
        if (state.prayerTimes == null) return _buildErrorState(context);
        return _buildDataState(context, state, hijriDate);
      },
      loading: () => _buildLoadingState(context),
      error: (_, __) => _buildErrorState(context),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top + 260,
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.cloud),
      child: const Center(
        child: SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top + 200,
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.cloud),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.slate, size: 28),
            const SizedBox(height: 8),
            Text(
              'Prayer times unavailable',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataState(BuildContext context, PrayerState state, String hijriDate) {
    final prayerTimes = state.prayerTimes!;
    final nextPrayer = prayerTimes.nextPrayer();
    final nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);
    final isFriday = _now.weekday == DateTime.friday;

    String nextName = _getPrayerName(nextPrayer, isFriday);

    if (nextPrayer == Prayer.none) {
      nextName = "home.prayers.fajr".tr();
    }

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHeroHeader(context, state, nextName, nextPrayerTime, hijriDate),
            Positioned(
              left: 20,
              right: 20,
              bottom: -_prayerCardOverlap,
              child: _buildDailyPrayerRow(context, state, nextPrayer, isFriday),
            ),
          ],
        ),
        const SizedBox(height: _prayerCardOverlap + 20),
        if (isFriday)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildJumuahCard(context),
          ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context, PrayerState state, String nextName, DateTime? nextTime, String hijriDate) {
    final timeStr = nextTime != null ? _formatTime(nextTime, state.isFallback) : "--:--";

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: _prayerCardOverlap + 10,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/icons/mosque.png',
                width: 200,
                height: 200,
                color: AppColors.pureWhite,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 20,
              24,
              _prayerCardOverlap + 60,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.pureWhite),
                            const SizedBox(width: 4),
                            Text(
                              state.city,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.pureWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hijriDate,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.pureWhite.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'home.prayers.nextPrayer'.tr(),
                            style: TextStyle(
                              color: AppColors.pureWhite.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$nextName • $timeStr',
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'home.prayers.mission'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'home.prayers.missionSub'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.pureWhite.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPrayerRow(BuildContext context, PrayerState state, Prayer nextPrayer, bool isFriday) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prayerTimes = state.prayerTimes!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E20) : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDailyItem(context, 'home.prayers.fajr'.tr(), prayerTimes.fajr, 'assets/icons/moon.png', nextPrayer == Prayer.fajr, state.isFallback),
          _buildDailyItem(context, isFriday ? 'home.prayers.jumuah'.tr() : 'home.prayers.dhuhr'.tr(), prayerTimes.dhuhr, 'assets/icons/sun.png', nextPrayer == Prayer.dhuhr, state.isFallback),
          _buildDailyItem(context, 'home.prayers.asr'.tr(), prayerTimes.asr, 'assets/icons/sea.png', nextPrayer == Prayer.asr, state.isFallback),
          _buildDailyItem(context, 'home.prayers.maghrib'.tr(), prayerTimes.maghrib, 'assets/icons/sunset.png', nextPrayer == Prayer.maghrib, state.isFallback),
          _buildDailyItem(context, 'home.prayers.isha'.tr(), prayerTimes.isha, 'assets/icons/night.png', nextPrayer == Prayer.isha, state.isFallback),
        ],
      ),
    );
  }

  Widget _buildDailyItem(BuildContext context, String name, DateTime time, String iconPath, bool isActive, bool isFallback) {
    final timeStr = _formatTime(time, isFallback);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = isDark ? AppColors.accentGreen : AppColors.primaryTeal;
    final inactiveColor = isDark ? AppColors.doveGray.withValues(alpha: 0.8) : AppColors.slate;
    final inactiveTimeColor = isDark ? AppColors.pureWhite.withValues(alpha: 0.7) : AppColors.ink;

    final activePillColor = isDark 
        ? AppColors.accentGreen.withValues(alpha: 0.2) 
        : AppColors.accentGreen.withValues(alpha: 0.1);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? activePillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 22,
              height: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isActive ? activeColor : inactiveColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isActive ? activeColor : inactiveTimeColor,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJumuahCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.prayers.jumuahMubarak'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'home.prayers.prepareForKhutbah'.tr(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPrayerName(Prayer prayer, bool isFriday) {
    switch (prayer) {
      case Prayer.fajr: return 'home.prayers.fajr'.tr();
      case Prayer.sunrise: return 'home.prayers.sunrise'.tr();
      case Prayer.dhuhr: return isFriday ? 'home.prayers.jumuah'.tr() : 'home.prayers.dhuhr'.tr();
      case Prayer.asr: return 'home.prayers.asr'.tr();
      case Prayer.maghrib: return 'home.prayers.maghrib'.tr();
      case Prayer.isha: return 'home.prayers.isha'.tr();
      case Prayer.none: return 'home.prayers.fajr'.tr();
    }
  }
}
