import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';

class MusaliTeaserScreen extends StatefulWidget {
  const MusaliTeaserScreen({super.key});

  static Widget builder(BuildContext context) {
    return const MusaliTeaserScreen();
  }

  @override
  State<MusaliTeaserScreen> createState() => _MusaliTeaserScreenState();
}

class _MusaliTeaserScreenState extends State<MusaliTeaserScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentSlide = 0;

  final List<Map<String, String>> _slides = [
    {
      'title_en': 'The name misled you. That\'s the point.',
      'title_ar': 'الاسم خدعك. وهذا هو السر.',
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en': "It's not what you think.",
      'title_ar': 'ليس كما تتخيل.',
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en':
          'The name promised one thing. You\'re about to get something entirely different.',
      'title_ar': 'الاسم وعد بشيء، لكنك ستحصل على شيء كلياً مختلف.',
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en': 'Musali',
      'title_ar': 'مُصَالي',
      'sub_en': 'Think again.',
      'sub_ar': 'فكر مجدداً.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAutoSlide();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _currentSlide < _slides.length - 1) {
        setState(() {
          _currentSlide++;
        });
        _animationController.forward(from: 0);
        _startAutoSlide();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentSlide = _slides[_currentSlide];

    return Scaffold(
      backgroundColor: _isArabic
          ? const Color(0xFF0D3B2C)
          : const Color(0xFF004B40),
      body: SafeArea(
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withValues(alpha: 0.9),
                colorScheme.primary,
                _isArabic ? const Color(0xFF0D3B2C) : const Color(0xFF00201A),
              ],
            ),
          ),
          child: Stack(
            children: [
              DecorativeBackgroundElement(isArabic: _isArabic),

              MainContent(
                currentSlide: currentSlide,
                fadeAnimation: _fadeAnimation,
                slideAnimation: _slideAnimation,
                isArabic: _isArabic,
                onDismiss: () {
                  NavigatorService.goBack();
                },
                onNext: () {
                  if (_currentSlide < _slides.length - 1) {
                    setState(() {
                      _currentSlide++;
                    });
                    _animationController.forward(from: 0);
                  }
                },
                onSkip: () {
                  NavigatorService.goBack();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DecorativeBackgroundElement extends StatelessWidget {
  final bool isArabic;

  const DecorativeBackgroundElement({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isArabic ? 0 : -30,
      right: isArabic ? -30 : 0,
      top: isArabic ? -30 : -20,
      child: Opacity(
        opacity: 0.08,
        child: Icon(
          isArabic ? Icons.mosque_rounded : Icons.grass_rounded,
          size: 200,
          color: Colors.white,
        ),
      ),
    );
  }
}

class MainContent extends StatelessWidget {
  final Map<String, String> currentSlide;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final bool isArabic;
  final VoidCallback onDismiss;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const MainContent({
    super.key,
    required this.currentSlide,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.isArabic,
    required this.onDismiss,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = currentSlide['sub_${isArabic ? 'ar' : 'en'}']!;

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Logo Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.1),
                  child: Center(
                    child: Text(
                      currentSlide['title_${isArabic ? 'ar' : 'en'}']!,
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isArabic ? 32 : 28,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontFamily: 'Poppins',
                  fontSize: isArabic ? 24 : 18,
                  height: 1.5,
                ),
              ),
            ],

            const Spacer(flex: 2),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'lbl_skip'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onNext,
                    child: Text(
                      'lbl_next'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
