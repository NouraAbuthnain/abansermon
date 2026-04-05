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
      title: 'Understand Every Khutbah',
      description:
          'Follow Friday Khutbahs in your language, live and in real time. Stay focused, connected, and engaged wherever you are.',
    ),
    _OnboardingSlide(
      image: 'assets/images/translator.png',
      title: 'Explore and Listen',
      description:
          'Choose a nearby mosque and listen to the Khutbah live from your phone. Switch languages, adjust volume, and follow easily.',
    ),
    _OnboardingSlide(
      image: 'assets/images/touch.png',
      title: 'Powered by Trusted Volunteers',
      description:
          'Enjoy reliable content or join as a volunteer and make a difference.',
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
              height: 48,
              child: !isLast
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: AppButton(
                          label: 'Skip',
                          onPressed: () => context.go('/login'),
                          variant: AppButtonVariant.tertiary,
                          isFullWidth: false,
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
                          height: 184,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 48),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
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
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accentGreen
                              : AppColors.slate.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started button
                  AppButton(
                    label: isLast ? 'Sign Up as Volunteer' : 'Next',
                    onPressed: _next,
                    variant: AppButtonVariant.primary,
                  ),

                  // Log In button on last slide
                  if (isLast) ...[
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Log In',
                      onPressed: () => context.go('/login'),
                      variant: AppButtonVariant.secondary,
                    ),
                  ],

                  // Guest button on last slide
                  if (isLast) ...[  
                    const SizedBox(height: 16),
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
