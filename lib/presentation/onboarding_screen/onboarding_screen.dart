import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hafiz_app/widgets/custom_elevated_button.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../injection_container.dart';
import 'bloc/onboarding_bloc.dart';
import 'models/onboarding_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<OnboardingBloc>(
      create: (context) =>
          OnboardingBloc(OnboardingState(onboardingModel: const OnboardingModel())),
      child: const OnboardingScreen(),
    );
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final networkInfo = sl<NetworkInfo>();
  bool isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _setupConnectivity();
    _setupAnimations();
  }

  void _setupConnectivity() {
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (mounted) {
        setState(() {
          isConnected = results.any((r) => r != ConnectivityResult.none);
        });
      }
    });
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
    _connectivitySubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.primary,
                    const Color(0xFF00332c), // Deep rich green for footer
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Internet Status Indicator
                  if (!isConnected)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        color: Colors.redAccent.withValues(alpha: 0.9),
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No Internet Connection',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                                    height: 350.adaptSize,
                                    width: 300.adaptSize,
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
                                color: const Color(0xFFE0F2F1), // Light Mint
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
                            SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: CustomElevatedButton(
                                  key: const ValueKey('get_started_key'),
                                  onPressed: () {
                                    NavigatorService.pushNamedAndRemoveUntil(
                                      AppRoutes.homeScreen,
                                    );
                                  },
                                  text: 'lbl_get_started'.tr,
                                  buttonStyle: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFAF6EB),
                                    foregroundColor: const Color(0xFF004B40),
                                    elevation: 5,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                  ),
                                  buttonTextStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF004B40),
                                  ),
                                  rightIcon: const Padding(
                                    padding: EdgeInsets.only(left: 12.0),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: Color(0xFF004B40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
