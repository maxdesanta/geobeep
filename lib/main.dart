import 'package:flutter/material.dart';
import 'package:gobeap/screen/home.dart';
import 'package:gobeap/screen/login.dart';
import 'package:gobeap/screen/profile.dart';
import 'package:gobeap/screen/register.dart';
import 'package:gobeap/screen/riwayat.dart';
import 'package:gobeap/screen/forgot-password.dart';
import 'package:gobeap/screen/reset-password.dart';
import 'package:gobeap/screen/stasiun.dart';

// import icon
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/heroicons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoBeep',
      theme: ThemeData(
        primaryColor: Color(0xFF508AA7), // Warna utama
        colorScheme: ColorScheme.light(
          primary: Color(0xFF508AA7), // Warna utama
          secondary: Color(0xFFFFFFFF), // Warna sekunder
        ),
      ),
      // default nama router - mulai dengan splash screen
      initialRoute: '/splash',

      // daftar nama router
      routes: <String, WidgetBuilder>{
        '/splash': (context) => SplashScreen(),
        '/': (context) => MainPage(),
        '/stasiun': (context) => StasiunPage(),
        '/riwayat': (context) => RiwayatPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/forgot-password': (context) => ForgotPasswordPage(),
        '/reset-password': (context) => ResetPasswordPage(), // Tambahkan ini

      },
    );
  }
}

// Splash Screen Widget dengan Animasi
class SplashScreen extends StatefulWidget {
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
    _startAnimations();

    // Navigate after animations complete
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/');
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

// inisiasi variabel untuk bottomnavigation
class MyPage {
  final String title;
  final String icon;
  final Widget page;

  MyPage(this.title, this.icon, this.page);
}

// bottom navigasi
class MainPage extends StatefulWidget {
  final PageStorageBucket _page = PageStorageBucket();

  // mengisi kontent variabel di array dari class MyPage
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

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int screen = 0;

  @override
  void initState() {
    super.initState();
    // Navigate to the main page after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/main');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        child: widget.halaman[screen].page,
        bucket: widget._page,
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
            backgroundColor:Colors.transparent,
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
