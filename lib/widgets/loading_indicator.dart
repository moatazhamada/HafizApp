import 'package:flutter/material.dart';

/// A const loading indicator that wraps [CircularProgressIndicator] in a [Center].
///
/// Use this instead of inline `Center(child: CircularProgressIndicator())`
/// throughout the app for consistency and brevity.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
