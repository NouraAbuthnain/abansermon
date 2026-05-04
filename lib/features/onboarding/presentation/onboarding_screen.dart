import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_language_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  List<_OnboardingSlide> get _slides {
    return [
      _OnboardingSlide(
        image: 'assets/images/mosque.png',
        title: 'onboarding.title_0'.tr(),
        description: 'onboarding.desc_0'.tr(),
      ),
      _OnboardingSlide(
        image: 'assets/images/translator.png',
        title: 'onboarding.title_1'.tr(),
        description: 'onboarding.desc_1'.tr(),
      ),
      _OnboardingSlide(
        image: 'assets/images/touch.png',
        title: 'onboarding.title_2'.tr(),
        description: 'onboarding.desc_2'.tr(),
      ),
    ];
  }


  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.push('/signup');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _currentIndex == _slides.length - 1;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  double page = _currentIndex.toDouble();
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    page = _pageController.page ?? _currentIndex.toDouble();
                  }

                  return SizedBox(
                    height: 224,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _MorphAccentPainter(page: page, isDark: isDark),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppLanguageButton(),
                          if (!isLast)
                            AppButton(
                              label: 'onboarding.skip'.tr(),
                              onPressed: () {
                                _pageController.animateToPage(
                                  _slides.length - 1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                );
                              },
                              variant: AppButtonVariant.tertiary,
                              isFullWidth: false,
                            )
                          else
                            const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              slide.image,
                              height: 192,
                              fit: BoxFit.contain,
                              color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                            ),
                            const SizedBox(height: 48),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final isActive = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: isActive ? 24 : 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.accentGreen
                                  : (isDark
                                      ? AppColors.doveGray.withOpacity(0.2)
                                      : AppColors.slate.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: isLast ? 'onboarding.signUpVolunteer'.tr() : 'onboarding.next'.tr(),
                        onPressed: _next,
                        variant: isLast ? AppButtonVariant.primary : AppButtonVariant.secondary,
                      ),
                      if (isLast) ...[
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'onboarding.logIn'.tr(),
                          onPressed: () => context.go('/login'),
                          variant: AppButtonVariant.secondary,
                        ),
                      ],
                      if (isLast) ...[
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'onboarding.continueGuest'.tr(),
                          onPressed: () => context.go('/home'),
                          variant: AppButtonVariant.tertiary,
                          isFullWidth: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contour shape data ────────────────────────────────────────────────────────
class _ContourShape {
  final List<Offset> points;

  const _ContourShape({required this.points});

  static _ContourShape lerp(_ContourShape a, _ContourShape b, double t) {
    return _ContourShape(
      points: List.generate(
        a.points.length,
        (i) => Offset.lerp(a.points[i], b.points[i], t)!,
      ),
    );
  }
}

// Slide 0
const _ContourShape _shape0 = _ContourShape(
  points: [
    Offset(0.00, 1.30),
    Offset(1.00, 0.90),
  ],
);

// Slide 1
const _ContourShape _shape1 = _ContourShape(
  points: [
    Offset(0.00, 0.90),
    Offset(1.20, 1.00),
  ],
);

// Slide 2
const _ContourShape _shape2 = _ContourShape(
  points: [
    Offset(0.00, 0.50),
    Offset(1.00, 1.20),
  ],
);
const List<_ContourShape> _shapes = [_shape0, _shape1, _shape2];

// ── Painter ───────────────────────────────────────────────────────────────────
class _MorphAccentPainter extends CustomPainter {
  final double page;
  final bool isDark;

  const _MorphAccentPainter({required this.page, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final clampedPage = page.clamp(0.0, (_shapes.length - 1).toDouble());
    final from = clampedPage.floor().clamp(0, _shapes.length - 1);
    final to = (from + 1).clamp(0, _shapes.length - 1);
    final t = (clampedPage - from).clamp(0.0, 1.0);

    final shape = _ContourShape.lerp(_shapes[from], _shapes[to], t);
    final path = _buildTopAccentPath(shape.points, size);

    canvas.drawPath(
      path,
      Paint()
        ..color = isDark 
            ? AppColors.primaryTeal.withOpacity(0.3) 
            : AppColors.greenMist
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = isDark 
            ? AppColors.accentGreen.withOpacity(0.08) 
            : AppColors.accentGreen.withOpacity(0.16)
        ..style = PaintingStyle.fill,
    );
  }

  Path _buildTopAccentPath(List<Offset> normalizedPoints, Size size) {
    final points = normalizedPoints
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(points.last.dx, points.last.dy);

    for (int i = points.length - 1; i > 0; i--) {
      final current = points[i];
      final previous = points[i - 1];
      final midX = (current.dx + previous.dx) / 2;

      path.cubicTo(
        midX, current.dy,
        midX, previous.dy,
        previous.dx, previous.dy,
      );
    }

    path
      ..lineTo(0, 0)
      ..close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _MorphAccentPainter oldDelegate) {
    return oldDelegate.page != page || oldDelegate.isDark != isDark;
  }
}

// ── Slide data ────────────────────────────────────────────────────────────────
class _OnboardingSlide {
  final String image;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.image,
    required this.title,
    required this.description,
  });
}