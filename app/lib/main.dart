import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/utils/dev_config.dart';
import 'package:talkbingo_app/widgets/dev_navigation_bar.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/screens/splash_screen.dart';
import 'package:talkbingo_app/screens/home_screen.dart';

import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdState.initialize(); // Initialize Ads
  await dotenv.load(fileName: ".env");
  
  // Enable Immersive Sticky Mode (Hides Status Bar, Swiping reveals it transparently)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Transparent status bar
    systemNavigationBarColor: Colors.transparent, // Transparent nav bar
  ));
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const TalkBingoApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

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
    
    // Listen to auth state changes for Magic Link redirection
    // Commented out to let LoginScreen handle the flow for now
    // Listen to auth state changes for Magic Link redirection and Realtime Login
    // Listen to auth state changes for Magic Link redirection and Realtime Login
    /* 
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      
      // If we are signed in...
      if (session != null && (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.passwordRecovery)) {
         // IGNORE Anonymous users (Guests) - let them stay on their flow (Invite/GuestInfo)
         if (session.user.isAnonymous == true) {
            debugPrint('Auth State Change: $event (Anonymous). No global redirect.');
            return;
         }

         // For verified users (Host), redirect to Home
         // NOTE: Disabled global redirect because it forces Home even for new users who need HostInfo Setup.
         // Let SignupScreen/SplashScreen handle the routing.
         debugPrint('Auth State Change: $event. Global redirect DISABLED.');
         // navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }); 
    */
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TalkBingo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.hostPrimary),
        useMaterial3: true,
        // Set Alexandria as the default font, with EliceDigitalBaeum as fallback for Korean
        textTheme: GoogleFonts.alexandriaTextTheme().apply(
          fontFamilyFallback: ['EliceDigitalBaeum'],
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
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
                    color: Colors.white,
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
                      builder: (context, showAd, _) {
                        final bottomPadding = showAd ? 94.0 : 0.0;
                        
                        return Stack(
                          children: [
                            // Main Content
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: bottomPadding,
                                top: 32.0, 
                              ),
                              child: child ?? const SizedBox.shrink(),
                            ),

                            // Ad Placeholder
                            if (showAd)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 94,
                                child: Container(
                                  color: Colors.grey[200],
                                  alignment: Alignment.topCenter,
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 320,
                                        height: 50,
                                        color: Colors.grey[400],
                                        alignment: Alignment.center,
                                        child: const Text('Banner Ad Space', style: TextStyle(color: Colors.white)),
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

                            // Dev Mode Toggle Button (Hidden, Top-Left)
                            Positioned(
                              top: 0,
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
