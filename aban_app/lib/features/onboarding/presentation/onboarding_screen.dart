import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      image: 'assets/images/mosque.png',
      title: 'Discover Nearby Mosques',
      description:
          'Browse mosques around you and see which ones are live — all in real time.',
    ),
    _OnboardingSlide(
      image: 'assets/images/translator.png',
      title: 'Listen & Understand',
      description:
          'Follow live khutbahs with real-time transcription and translation in your language.',
    ),
    _OnboardingSlide(
      image: 'assets/images/touch.png',
      title: 'Join the Community',
      description:
          'Volunteer to capture khutbahs, add mosques, and connect communities everywhere.',
    ),
  ];

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            SizedBox(
              height: 52,
              child: !isLast
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'Skip',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon image
                        Image.asset(
                          slide.image,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 52),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.slate,
                            height: 1.6,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom: dots + button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryTeal
                              : AppColors.doveGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started button
                  AppButton(
                    label: isLast ? 'Get Started' : 'Next',
                    onPressed: _next,
                    variant: AppButtonVariant.primary,
                  ),

                  // Guest button on last slide
                  if (isLast) ...[  
                    const SizedBox(height: 4),
                    AppButton(
                      label: 'Continue as Guest',
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
    );
  }
}

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
