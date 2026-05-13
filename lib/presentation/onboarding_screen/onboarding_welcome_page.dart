import 'package:flutter/material.dart';
import 'package:hafiz_app/core/network/connectivity_cubit.dart';
import 'package:hafiz_app/core/theme/app_colors.dart';
import '../../core/app_export.dart';
import 'widgets/onboarding_buttons.dart';
import 'widgets/onboarding_scaffold.dart';

class OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingWelcomePage({super.key, required this.onContinue});

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OnboardingScaffold(
      maxContentWidth: 800,
      child: Stack(
        children: [
          // Internet Status Indicator
          BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connState) {
              if (connState.isOnline) return const SizedBox.shrink();
              return Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'msg_no_internet_connection'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          // Decorative Background Element
          Positioned(
            left: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: CustomImageView(
                imagePath: ImageConstant.imgGroupCircles,
                height: 150.adaptSize,
                width: 150.adaptSize,
                color: Colors.white,
              ),
            ),
          ),

          // Main Content
          LayoutBuilder(
            builder: (context, constraints) {
              final isLarge = constraints.maxWidth > 900;
              final imageHeight = isLarge ? 450.adaptSize : 350.adaptSize;
              final imageWidth = isLarge ? 400.adaptSize : 300.adaptSize;

              Widget content = Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLarge ? 48.0 : 24.0,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // Hero Image Card
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.1),
                              child: CustomImageView(
                                imagePath: ImageConstant.imgQuranOnboarding,
                                height: imageHeight,
                                width: imageWidth,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Title
                        Text(
                          'app_name'.tr,
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: AppColors.of(context).primaryLight,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 16.adaptSize),

                        // Subtitle
                        Text(
                          'lbl_learn_quran'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontFamily: 'Poppins',
                            height: 1.5,
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Action Button
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLarge ? 64.0 : 32.0,
                          ),
                          child: OnboardingPrimaryButton(
                            text: 'lbl_get_started'.tr,
                            onPressed: widget.onContinue,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );

              return content;
            },
          ),
        ],
      ),
    );
  }
}
