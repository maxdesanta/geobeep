import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Selamat Datang di GeoBeep!",
          body:
              "Aplikasi alarm pintar berbasis lokasi untuk membantu perjalanan Anda",
          image: _buildImage(
            'https://assets9.lottiefiles.com/packages/lf20_V9t630.json',
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Login & Sinkronisasi",
          body:
              "Masuk dengan akun Google untuk menyimpan data favorit dan pengaturan Anda di cloud",
          image: _buildImage(
            'https://assets2.lottiefiles.com/packages/lf20_jcikwtux.json',
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Tambah Stasiun Favorit",
          body:
              "Pilih dan tambahkan stasiun-stasiun yang sering Anda kunjungi sebagai favorit",
          image: _buildImage(
            'https://assets1.lottiefiles.com/packages/lf20_x62chJ.json',
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Atur Alarm Lokasi",
          body:
              "Aktifkan alarm dan tentukan radius untuk mendapat notifikasi saat mendekati stasiun tujuan",
          image: _buildImage(
            'https://assets4.lottiefiles.com/packages/lf20_1pxqjqps.json',
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Kustomisasi Pengaturan",
          body:
              "Atur foto profil, suara alarm custom, dan pengaturan lainnya sesuai preferensi Anda",
          image: _buildImage(
            'https://assets6.lottiefiles.com/packages/lf20_qp1q7mct.json',
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Siap Digunakan!",
          body:
              "GeoBeep akan bekerja di background untuk membangunkan Anda saat mendekati tujuan. Selamat berpergian!",
          image: _buildImage(
            'https://assets7.lottiefiles.com/packages/lf20_xlkxtmul.json',
          ),
          decoration: _getPageDecoration(),
        ),
      ],
      showSkipButton: true,
      skip: const Text("Lewati", style: TextStyle(color: Colors.white)),
      next: const Icon(Icons.arrow_forward, color: Colors.white),
      done: const Text(
        "Mulai",
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(22.0, 10.0),
        activeColor: Colors.white,
        color: Colors.white54,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      globalBackgroundColor: const Color(0xFF135E71),
      skipOrBackFlex: 0,
      nextFlex: 0,
      animationDuration: 1000,
      curve: Curves.fastOutSlowIn,
    );
  }

  Widget _buildImage(String assetName) {
    return Center(
      child: SizedBox(
        height: 250,
        width: 250,
        child: Lottie.network(
          assetName,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.location_on, size: 100, color: Colors.white70);
          },
        ),
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      bodyTextStyle: TextStyle(fontSize: 18.0, color: Colors.white),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Color(0xFF135E71),
      imagePadding: EdgeInsets.zero,
    );
  }

  void _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    Navigator.of(context).pushReplacementNamed('/');
  }
}
