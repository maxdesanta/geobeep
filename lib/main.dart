import 'package:flutter/material.dart';
import 'package:geobeep/screen/home.dart';
import 'package:geobeep/screen/login.dart';
import 'package:geobeep/screen/profile.dart';
import 'package:geobeep/screen/register.dart';
import 'package:geobeep/screen/riwayat.dart';
import 'package:geobeep/screen/forgot-password.dart';
import 'package:geobeep/screen/reset-password.dart';
import 'package:geobeep/screen/stasiun.dart';
import 'package:geobeep/screens/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:geobeep/providers/station_provider.dart';
import 'package:geobeep/services/notification_service.dart';
import 'package:geobeep/services/auth_service.dart';
import 'package:geobeep/services/foreground_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:geobeep/utils/app_logger.dart';
import 'package:geobeep/screen/settings.dart';

// import icon
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/heroicons.dart';

// Global navigator key for navigating from outside of widget context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi service secara berurutan untuk memastikan semuanya berjalan dengan benar

  // 1. Initialize notification service terlebih dahulu
  await NotificationService.instance.initialize();

  // 2. Initialize foreground service - hanya inisialisasi, tidak autostart
  await ForegroundService.instance.initialize();

  // 3. Pre-initialize the StationProvider
  final stationProvider = StationProvider();
  await stationProvider.initialize();

  // 4. Start monitoring untuk tracking lokasi
  await stationProvider.startMonitoring();

  // 5. Start foreground service untuk menampilkan notifikasi aplikasi berjalan
  await ForegroundService.instance.startService();

  // Initialize AuthService
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StationProvider>.value(value: stationProvider),
        Provider<AuthService>.value(value: authService),
        // Provider.value(value: AlarmService.instance),
        // Other providers...
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoBeep',
      navigatorKey: navigatorKey, // Add global navigator key
      theme: ThemeData(
        primaryColor: Color(0xFF508AA7),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF508AA7),
          secondary: Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
      ),
      // Start with splash screen
      initialRoute: '/splash',

      // Route definitions
      routes: {
        '/splash': (context) => SplashScreen(),
        '/': (context) => AuthWrapper(),
        '/main': (context) => MainPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/riwayat': (context) => const RiwayatPage(),
        '/stasiun': (context) => const StasiunPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

// Splash Screen Widget with Animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _bellController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();

    AppLogger.log("SplashScreen initialized");

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _bellController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _bellAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.bounceOut),
    );

    // Start animations with delays
    _startAnimations(); // Navigate after animations complete
    Future.delayed(Duration(seconds: 3), () {
      AppLogger.log("SplashScreen navigation delay completed");
      if (mounted) {
        AppLogger.log("Navigating from SplashScreen to AuthWrapper");
        Navigator.pushReplacementNamed(context, '/');
      } else {
        AppLogger.log("SplashScreen not mounted, skipping navigation");
      }
    });
  }

  void _startAnimations() async {
    _fadeController.forward();

    await Future.delayed(Duration(milliseconds: 300));
    _scaleController.forward();

    await Future.delayed(Duration(milliseconds: 800));
    _bellController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimation,
        _scaleAnimation,
        _bellAnimation,
      ]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // GeoBeep Text
                    Row(
                      children: [
                        // "Geo" text with blue color and black outline
                        Stack(
                          children: [
                            // Black outline
                            Text(
                              'Geo',
                              style: TextStyle(
                                fontSize: 52,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.bold,
                                foreground:
                                    Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 4
                                      ..color = Colors.black,
                              ),
                            ),
                            // Blue fill
                            Text(
                              'Geo',
                              style: TextStyle(
                                fontSize: 52,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF508AA7),
                              ),
                            ),
                          ],
                        ),
                        // "Beep" text with black color and black outline
                        Stack(
                          children: [
                            // Black outline
                            Text(
                              'Beep',
                              style: TextStyle(
                                fontSize: 52,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.bold,
                                foreground:
                                    Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 4
                                      ..color = Colors.black,
                              ),
                            ),
                            // Black fill
                            Text(
                              'Beep',
                              style: TextStyle(
                                fontSize: 52,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 20),
                    // Animated Bell Icon
                    Transform.scale(
                      scale: _bellAnimation.value,
                      child: Transform.rotate(
                        angle: _bellAnimation.value * 0.2,
                        child: Iconify(
                          Mdi.bell,
                          size: 56,
                          color: Color(0xFF508AA7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Bottom navigation page class
class MyPage {
  final String title;
  final String icon;
  final Widget page;

  MyPage(this.title, this.icon, this.page);
}

// Main page with bottom navigation
class MainPage extends StatefulWidget {
  final PageStorageBucket _page = PageStorageBucket();

  // Fill content from MyPage class array
  final List<MyPage> halaman = [
    MyPage(
      "Beranda",
      Heroicons.home_20_solid,
      HomePage(key: PageStorageKey('key--home')),
    ),
    MyPage(
      "Stasiun",
      Mdi.train,
      StasiunPage(key: PageStorageKey('key--stasiun')),
    ),
    MyPage(
      "Riwayat",
      Mdi.history,
      RiwayatPage(key: PageStorageKey('key--riwayat')),
    ),
    MyPage(
      "Profil",
      Mdi.user,
      ProfilePage(key: PageStorageKey('key--profile')),
    ),
  ];

  MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int screen = 0;

  @override
  void initState() {
    super.initState();
    // Register observer untuk lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Pastikan foreground service berjalan
    _ensureForegroundServiceRunning();
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handle application lifecycle state changes  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App kembali ke foreground, start notification service
      _startForegroundService();
    } else if (state == AppLifecycleState.detached) {
      // App benar-benar ditutup, stop notification service
      _stopForegroundService();
    }
  }

  // Mulai foreground service dengan notifikasi
  Future<void> _startForegroundService() async {
    debugPrint('Starting foreground service for app notification');
    await ForegroundService.instance.startService();
  }

  // Hentikan foreground service saat app ditutup
  Future<void> _stopForegroundService() async {
    debugPrint('Stopping foreground service');
    await ForegroundService.instance.stopService();
  }

  // Memastikan foreground service berjalan saat app aktif  // Memastikan foreground service berjalan saat app aktif
  Future<void> _ensureForegroundServiceRunning() async {
    final isRunning = await ForegroundService.instance.isRunning;
    if (!isRunning) {
      debugPrint('Foreground service not running, starting it');
      await _startForegroundService();
    } else {
      debugPrint('Foreground service already running');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: widget._page,
        child: widget.halaman[screen].page,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        child: Container(
          color: Color(0xFF508AA7),
          height: 65,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            currentIndex: screen,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Theme.of(context).colorScheme.secondary,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
              fontFamily: "Inter",
              fontWeight: FontWeight.w400,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              fontFamily: "Inter",
              fontWeight: FontWeight.w400,
            ),
            items:
                widget.halaman
                    .map(
                      (e) => BottomNavigationBarItem(
                        icon: Iconify(
                          e.icon,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        label: e.title,
                      ),
                    )
                    .toList(),
            onTap: (index) {
              setState(() {
                screen = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
