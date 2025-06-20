import 'package:flutter/material.dart';

/// Custom page route that creates an iOS-style "slide away" transition
/// where the current screen slides out to the right, revealing the new screen underneath.
/// This follows the pattern documented in transition.md for proper iOS navigation.
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideRightRoute({required this.page})
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
            // This animates the new screen coming in. For this effect, we don't want the new screen to move.
            // So, we wrap it in a FadeTransition to have it gently appear.
            final newScreen = FadeTransition(
              opacity: animation,
              child: child,
            );

            // This animates the current (old) screen moving out to the right.
            final oldScreen = SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(1.0, 0.0),
              ).animate(secondaryAnimation),
              child: newScreen, // The new screen is the child of the old screen's transition
            );

            return oldScreen;
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route for iOS-style back navigation where the current screen
/// slides out to the right revealing the previous screen underneath
class SlideAwayRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideAwayRoute({required this.page})
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
            // For back navigation, we want the destination screen to fade in gently
            final destinationScreen = FadeTransition(
              opacity: animation,
              child: child,
            );

            // The current screen should slide out to the right when going back
            final currentScreen = SlideTransition(
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
