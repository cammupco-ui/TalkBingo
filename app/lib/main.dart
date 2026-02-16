import 'dart:ui'; // For PointerDeviceKind
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/globals.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/splash_screen.dart';
import 'package:talkbingo_app/services/deep_link_service.dart';
import 'package:talkbingo_app/services/sound_service.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/utils/dev_config.dart';
import 'package:talkbingo_app/widgets/dev_navigation_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⚡ CRITICAL: Capture password recovery flag from URL BEFORE Supabase.initialize()
  // Supabase PKCE flow will consume and remove the hash tokens during init.
  if (kIsWeb) {
    final fullUrl = Uri.base.toString();
    final fragment = Uri.base.fragment;
    if (fragment.contains('type=recovery') || fullUrl.contains('type=recovery')) {
      isPasswordRecoveryFromUrl = true;
      debugPrint('🔑 MAIN: Password recovery detected in URL before Supabase init');
    }
  }
  
  // Fire and forget - don't block app startup
  AdState.initialize(); 
  AdState.loadBannerAd(); // Load banner ad on startup
  SoundService().init(); 
  DeepLinkService().init(); // Initialize Deep Link Listener Globally
  
  
  // Supabase Config: 3-tier fallback
  // 1. --dart-define (Web Release, CI/CD)
  // 2. .env file (Local Dev)
  // 3. Hardcoded defaults (Android Release fallback - anon key is public/safe)
  const String _defaultSupabaseUrl = 'https://jmihbovtywtwqdjrmuey.supabase.co';
  const String _defaultSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptaWhib3Z0eXd0d3FkanJtdWV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyMDI2MjMsImV4cCI6MjA3OTc3ODYyM30.x7zgRAetwwOKgneFeFIDaFTwlfIG_FU0A3nB_3UNfqQ';

  String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    try {
      await dotenv.load(fileName: ".env");
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    } catch (e) {
      debugPrint("Warning: No .env found, using hardcoded defaults.");
    }
  }

  // Final fallback: use hardcoded defaults if still empty
  if (supabaseUrl.isEmpty) supabaseUrl = _defaultSupabaseUrl;
  if (supabaseAnonKey.isEmpty) supabaseAnonKey = _defaultSupabaseAnonKey;

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  runApp(const TalkBingoApp());
}


class TalkBingoApp extends StatefulWidget {
  const TalkBingoApp({super.key});

  @override
  State<TalkBingoApp> createState() => _TalkBingoAppState();
}

class _TalkBingoAppState extends State<TalkBingoApp> {
  bool _isHoveringDev = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    
    return MaterialApp(
      scrollBehavior: AppScrollBehavior(), // Enable Mouse Drag on Web
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'TalkBingo',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ko'), // Korean
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.hostPrimary, brightness: Brightness.dark), // Force Dark Theme base?
        scaffoldBackgroundColor: const Color(0xFF121212), // Ensure global dark background
        useMaterial3: true,
        // Set Alexandria as the default font, with EliceDigitalBaeum as fallback for Korean
        textTheme: GoogleFonts.alexandriaTextTheme().apply(
          fontFamilyFallback: ['EliceDigitalBaeum', 'EliceDigitalCodingverH'],
        ),
        // Fix for Dialogs being dark and unreadable
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, 
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        // Ensure SnackBars float above the banner ad (64px)
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          insetPadding: EdgeInsets.only(bottom: 72, left: 16, right: 16),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
      },
      // Handle Deep Links (e.g. /invite/123456)
      // Since we use the SPA hack, the browser URL might be /invite/123456
      // We want to force SplashScreen to handle this, as it parses Uri.base.
      onGenerateRoute: (settings) {
        // If route is not found (like /invite/...), go to SplashScreen
        // SplashScreen checks Uri.base, which still contains the full path/query
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
          settings: settings,
        );
      },
      // home: const SplashScreen(), // Removed in favor of initialRoute
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: DevConfig.isDevMode,
          builder: (context, isDev, _) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 450, // Mobile Max Width
                  maxHeight: 950, // Mobile Max Height
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black, // Changed from white to black for dark theme background compatibility
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRect(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: AdState.showAd,
                      builder: (context, showAdValue, _) {
                        // Check if keyboard is open
                        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                        // Check orientation
                        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

                        // Hide Ad if keyboard is open OR in landscape mode
                        final showAd = showAdValue && !isKeyboardOpen && !isLandscape;
                        
                        final bottomPadding = showAd ? 64.0 : 0.0;
                        
                        return Stack(
                          children: [
                            // Main Content
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: 0, // Removed bottomPadding to allow background to fill screen
                                top: 0, 
                              ),
                              child: child ?? const SizedBox.shrink(),
                            ),

                            // Ad Placeholder
                            if (showAd)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 64,
                                child: Container(
                                  color: Colors.transparent,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.only(top: 4),
                                  child: AdState.getBannerAdWidget() ?? Column(
                                    children: [
                                      Container(
                                        width: 320,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppColors.hostPrimary.withOpacity(0.8),
                                              AppColors.guestPrimary.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'TalkBingo',
                                          style: TextStyle(
                                            fontFamily: 'NURA',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white.withOpacity(0.6),
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ),
                            
                            // Dev Navigation Bar
                            if (isDev)
                              Positioned(
                                bottom: bottomPadding,
                                left: 0,
                                right: 0,
                                child: Material(
                                  elevation: 8,
                                  child: const DevNavigationBar(),
                                ),
                              ),

                            // Dev Mode Toggle Button (Hidden area, visible on hover/active)
                            if (!kReleaseMode)
                              Positioned(
                                bottom: bottomPadding + 100, // Above Ad/Nav bar
                                left: 0,
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => _isHoveringDev = true),
                                  onExit: (_) => setState(() => _isHoveringDev = false),
                                  child: GestureDetector(
                                    onTap: DevConfig.toggle,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      alignment: Alignment.topLeft,
                                      padding: const EdgeInsets.all(16),
                                      color: Colors.transparent, // Hit test target
                                      child: AnimatedOpacity(
                                        duration: const Duration(milliseconds: 200),
                                        opacity: _isHoveringDev ? 1.0 : 0.0,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isDev ? Colors.red : Colors.grey[700],
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              if (_isHoveringDev)
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                            ],
                                          ),
                                          child: Icon(
                                            isDev ? Icons.developer_mode : Icons.bug_report,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
