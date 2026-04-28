import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import 'package:hafiz_app/core/theme/app_text_styles.dart';
import 'bloc/musali_teaser_bloc.dart';

class MusaliTeaserScreen extends StatefulWidget {
  const MusaliTeaserScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider(
      create: (context) => MusaliTeaserBloc()..add(NextSlidePressed()),
      child: const MusaliTeaserScreen(),
    );
  }

  @override
  State<MusaliTeaserScreen> createState() => _MusaliTeaserScreenState();
}

class _MusaliTeaserScreenState extends State<MusaliTeaserScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    context.read<MusaliTeaserBloc>().startAutoSlide();
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

  @override
  void dispose() {
    _animationController.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  List<Map<String, String>> get _slides => [
    {
      'title_en': 'musali_teaser_slide1_title'.tr,
      'title_ar': 'musali_teaser_slide1_title_ar'.tr,
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en': 'musali_teaser_slide2_title'.tr,
      'title_ar': 'musali_teaser_slide2_title_ar'.tr,
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en': 'musali_teaser_slide3_title'.tr,
      'title_ar': 'musali_teaser_slide3_title_ar'.tr,
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en': 'musali_app_name'.tr,
      'title_ar': 'musali_app_name'.tr,
      'sub_en': 'musali_teaser_slide4_sub'.tr,
      'sub_ar': 'musali_teaser_slide4_sub_ar'.tr,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = context.read<MusaliTeaserBloc>().state;
    final currentSlideIndex = state is TeaserSlideUpdated
        ? state.slideIndex
        : 0;
    final isLastSlide = currentSlideIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: _isArabic
          ? AppColors.of(context).primaryDark
          : AppColors.of(context).bismillahColor,
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
                _isArabic
                    ? AppColors.of(context).primaryDark
                    : AppColors.of(context).primaryDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              DecorativeBackgroundElement(isArabic: _isArabic),
              MainContent(
                currentSlideIndex: currentSlideIndex,
                fadeAnimation: _fadeAnimation,
                slideAnimation: _slideAnimation,
                isArabic: _isArabic,
                isLastSlide: isLastSlide,
                onDismiss: () {
                  _finishTeaser(context);
                },
                onNext: () {
                  if (isLastSlide) {
                    _finishTeaser(context);
                  } else {
                    context.read<MusaliTeaserBloc>().add(NextSlidePressed());
                  }
                },
                onSkip: () {
                  _finishTeaser(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finishTeaser(BuildContext context) {
    context.read<MusaliTeaserBloc>().add(Dismissed());

    NavigatorService.pushNamedAndRemoveUntil(AppRoutes.homeScreen);
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
  final int currentSlideIndex;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final bool isArabic;
  final bool isLastSlide;
  final VoidCallback onDismiss;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const MainContent({
    super.key,
    required this.currentSlideIndex,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.isArabic,
    required this.isLastSlide,
    required this.onDismiss,
    required this.onNext,
    required this.onSkip,
  });

  List<Map<String, String>> get _slides => [
    {
      'title_en': 'musali_teaser_slide1_title'.tr,
      'title_ar': 'musali_teaser_slide1_title_ar'.tr,
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en': 'musali_teaser_slide2_title'.tr,
      'title_ar': 'musali_teaser_slide2_title_ar'.tr,
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en': 'musali_teaser_slide3_title'.tr,
      'title_ar': 'musali_teaser_slide3_title_ar'.tr,
      'sub_en': '',
      'sub_ar': '',
    },
    {
      'title_en': 'musali_app_name'.tr,
      'title_ar': 'musali_app_name'.tr,
      'sub_en': 'musali_teaser_slide4_sub'.tr,
      'sub_ar': 'musali_teaser_slide4_sub_ar'.tr,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSlide = _slides[currentSlideIndex];
    final subtitle = currentSlide['sub_${isArabic ? 'ar' : 'en'}']!;

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
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
                  fontFamily: AppTextStyles.latinFont,
                  fontSize: isArabic ? 24 : 18,
                  height: 1.5,
                ),
              ),
            ],
            const Spacer(flex: 2),
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
                  if (!isLastSlide)
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
                    )
                  else
                    TextButton(
                      onPressed: onNext,
                      child: Text(
                        'lbl_continue'.tr,
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
