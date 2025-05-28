import 'package:flutter/material.dart';
import 'package:gobeap/screen/home.dart';
import 'package:gobeap/screen/login.dart';
import 'package:gobeap/screen/profile.dart';
import 'package:gobeap/screen/register.dart';
import 'package:gobeap/screen/riwayat.dart';
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
      // default nama router
      initialRoute: '/',

      // daftar nama router
      routes: <String, WidgetBuilder>{
        '/': (context) => MainPage(),
        // '/splash': (context) => SplashScreen(),
        '/stasiun': (context) => StasiunPage(),
        '/riwayat': (context) => RiwayatPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
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
            backgroundColor:
                Colors.transparent, 
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
