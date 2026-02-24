import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localization.dart';

class FeatureOnboarding extends StatefulWidget {
  final String featureId;
  final Widget child;
  final String title;
  final String description;
  final VoidCallback? onDismiss;

  const FeatureOnboarding({
    super.key,
    required this.featureId,
    required this.child,
    required this.title,
    required this.description,
    this.onDismiss,
  });

  @override
  State<FeatureOnboarding> createState() => _FeatureOnboardingState();
}

class _FeatureOnboardingState extends State<FeatureOnboarding> {
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('onboarding_${widget.featureId}') ?? false;
    if (!hasShown) {
      if (mounted) setState(() => _showOverlay = true);
    }
  }

  Future<void> _markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_${widget.featureId}', true);
    if (mounted) setState(() => _showOverlay = false);
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay)
          Positioned.fill(
            child: Material(
              color: Colors.black54,
              child: InkWell(
                onTap: _markAsShown,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tips_and_updates,
                          size: 48,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _markAsShown,
                          child: Text('lbl_got_it'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
