import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GuideDialog extends StatefulWidget {
  const GuideDialog({super.key});

  @override
  State<GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends State<GuideDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  int currentStep = 0;

  final List<GuideStep> steps = [
    GuideStep(
      title: 'Selamat Datang di GeoBeep!',
      description:
          'Aplikasi alarm pintar berbasis lokasi untuk perjalanan Anda',
      icon: Icons.location_on,
      animationUrl: 'https://assets9.lottiefiles.com/packages/lf20_V9t630.json',
    ),
    GuideStep(
      title: 'Login & Sinkronisasi',
      description: 'Masuk dengan akun Google untuk menyimpan data di cloud',
      icon: Icons.cloud_sync,
      animationUrl:
          'https://assets2.lottiefiles.com/packages/lf20_jcikwtux.json',
    ),
    GuideStep(
      title: 'Tambah Stasiun Favorit',
      description: 'Pilih stasiun yang sering dikunjungi di halaman Stasiun',
      icon: Icons.star,
      animationUrl: 'https://assets1.lottiefiles.com/packages/lf20_x62chJ.json',
    ),
    GuideStep(
      title: 'Aktifkan Alarm',
      description:
          'Atur alarm dan radius untuk notifikasi saat mendekati stasiun',
      icon: Icons.notifications_active,
      animationUrl:
          'https://assets4.lottiefiles.com/packages/lf20_1pxqjqps.json',
    ),
    GuideStep(
      title: 'Pengaturan Lanjutan',
      description: 'Kustomisasi profil, suara alarm, dan pengaturan lainnya',
      icon: Icons.settings,
      animationUrl:
          'https://assets6.lottiefiles.com/packages/lf20_qp1q7mct.json',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (currentStep < steps.length - 1) {
      setState(() {
        currentStep++;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _prevStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF508AA7), Color(0xFF135E71)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with progress indicator
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Panduan GeoBeep',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Progress indicator
                  Row(
                    children: List.generate(steps.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color:
                                index <= currentStep
                                    ? Colors.white
                                    : Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animation
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: Lottie.network(
                          step.animationUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step.icon,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 24),

                      // Title
                      Text(
                        step.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 16),

                      // Description
                      Text(
                        step.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 32),

                      // Tips section for specific steps
                      if (currentStep == 3) _buildTipsSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  TextButton(
                    onPressed: currentStep > 0 ? _prevStep : null,
                    child: Text(
                      'Sebelumnya',
                      style: TextStyle(
                        color: currentStep > 0 ? Colors.white : Colors.white30,
                      ),
                    ),
                  ),

                  // Step indicator
                  Text(
                    '${currentStep + 1} / ${steps.length}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  // Next/Close button
                  ElevatedButton(
                    onPressed:
                        currentStep < steps.length - 1
                            ? _nextStep
                            : () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF135E71),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      currentStep < steps.length - 1
                          ? 'Selanjutnya'
                          : 'Selesai',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
              SizedBox(width: 8),
              Text(
                'Tips Penting:',
                style: TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Pastikan GPS dan notifikasi aktif\n• Jangan tutup aplikasi dari recent apps\n• Atur radius sesuai kecepatan kendaraan',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class GuideStep {
  final String title;
  final String description;
  final IconData icon;
  final String animationUrl;

  GuideStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.animationUrl,
  });
}
