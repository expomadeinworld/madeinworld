import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/location_provider.dart';
import 'presentation/screens/main/main_screen.dart';

void main() {
  // Add error handling for debugging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  runApp(const MadeInWorldApp());
}

class MadeInWorldApp extends StatelessWidget {
  const MadeInWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Made in World',
        theme: AppTheme.lightTheme,
        home: const SafeMainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Safe wrapper for MainScreen to catch any initialization errors
class SafeMainScreen extends StatefulWidget {
  const SafeMainScreen({super.key});

  @override
  State<SafeMainScreen> createState() => _SafeMainScreenState();
}

class _SafeMainScreenState extends State<SafeMainScreen> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.themeRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'App Initialization Error',
                  style: AppTextStyles.majorHeader,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      return const MainScreen();
    } catch (e, stackTrace) {
      debugPrint('Error in MainScreen: $e');
      debugPrint('Stack trace: $stackTrace');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Failed to initialize the app: ${e.toString()}';
          });
        }
      });

      // Return a loading screen while we update the state
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
