import 'package:flutter/material.dart';

/// Custom page route that creates a slide transition where the new page slides in from the right
/// and when going back, the current page slides out to the right.
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String? routeKey;

  SlideRightRoute({required this.page, this.routeKey})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // Create unique keys for this route instance
            final uniqueId = routeKey ?? DateTime.now().millisecondsSinceEpoch.toString();

            // For forward navigation (entering), slide in from right
            final enterTransition = SlideTransition(
              key: ValueKey('enter_$uniqueId'),
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), // Start from right
                end: Offset.zero, // End at normal position
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: child,
            );

            // For backward navigation (exiting), slide out to right
            final exitTransition = SlideTransition(
              key: ValueKey('exit_$uniqueId'),
              position: Tween<Offset>(
                begin: Offset.zero, // Start at normal position
                end: const Offset(1.0, 0.0), // End at right
              ).animate(
                CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: child,
            );

            // Stack both transitions with unique key
            return Stack(
              key: ValueKey('stack_$uniqueId'),
              children: [
                exitTransition,
                enterTransition,
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route for iOS-style back navigation where the current screen
/// slides out to the right revealing the previous screen underneath
class SlideAwayRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String? routeKey;

  SlideAwayRoute({required this.page, this.routeKey})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // Create unique keys for this route instance
            final uniqueId = routeKey ?? DateTime.now().millisecondsSinceEpoch.toString();

            // For back navigation, we want the destination screen to fade in gently
            final destinationScreen = FadeTransition(
              key: ValueKey('fade_$uniqueId'),
              opacity: animation,
              child: child,
            );

            // The current screen should slide out to the right when going back
            final currentScreen = SlideTransition(
              key: ValueKey('slide_$uniqueId'),
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(1.0, 0.0), // Slide out to the right
              ).animate(
                CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: destinationScreen,
            );

            return currentScreen;
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}
