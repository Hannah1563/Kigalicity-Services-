import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (handle already initialized case for hot restart)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized, ignore
  }
  
  runApp(
    const ProviderScope(
      child: KigaliCityServicesApp(),
    ),
  );
}

class KigaliCityServicesApp extends StatelessWidget {
  const KigaliCityServicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme matching the mockup design - deep blue header/nav, white content, yellow accent
    return MaterialApp(
      title: 'Kigali City Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryBlue,
          secondary: AppColors.accentYellow,
          surface: AppColors.cardWhite,
          onPrimary: AppColors.cardWhite,
          onSecondary: AppColors.textDark,
          onSurface: AppColors.textDark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.cardWhite,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: AppColors.cardWhite,
          surfaceTintColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.primaryBlue,
          selectedItemColor: AppColors.accentYellow,
          unselectedItemColor: AppColors.navUnselected,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardWhite,
          labelStyle: const TextStyle(color: AppColors.primaryBlue),
          selectedColor: AppColors.primaryBlue,
          secondarySelectedColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primaryBlue),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardWhite,
          hintStyle: TextStyle(color: AppColors.navUnselected),
          prefixIconColor: AppColors.navUnselected,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.navUnselected),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.navUnselected),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: AppColors.cardWhite,
            backgroundColor: AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: const BorderSide(color: AppColors.primaryBlue),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.cardWhite,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: AppColors.textDark,
          iconColor: AppColors.navUnselected,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accentYellow;
            }
            return AppColors.navUnselected;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accentYellow.withOpacity(0.5);
            }
            return AppColors.navUnselected.withOpacity(0.3);
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.primaryBlue,
          contentTextStyle: const TextStyle(color: AppColors.cardWhite),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use authNotifierProvider instead of authStateProvider for reactive updates
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) {
        debugPrint('AuthWrapper: user = '
            '${user?.uid ?? 'null'}, emailVerified = ${user?.emailVerified ?? 'null'}');
        if (user == null) {
          debugPrint('AuthWrapper: Showing LoginScreen');
          return const LoginScreen();
        }
        // Check email verification
        if (!user.emailVerified) {
          debugPrint('AuthWrapper: Showing EmailVerificationScreen');
          return const EmailVerificationScreen();
        }
        debugPrint('AuthWrapper: Showing HomeShell');
        return const HomeShell();
      },
      loading: () {
        debugPrint('AuthWrapper: Loading...');
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stack) {
        debugPrint('AuthWrapper: Error: $error');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(authNotifierProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
