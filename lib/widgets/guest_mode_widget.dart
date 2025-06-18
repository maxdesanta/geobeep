import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geobeep/services/auth_service.dart';

/// Widget helper untuk menampilkan pesan mode guest
class GuestModeWarning extends StatelessWidget {
  final String featureName;
  final VoidCallback? onLoginPressed;

  const GuestModeWarning({
    super.key,
    required this.featureName,
    this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange[600],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur $featureName Terbatas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Masuk atau daftar akun untuk mengakses fitur lengkap',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onLoginPressed ?? () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Masuk Sekarang'),
          ),
        ],
      ),
    );
  }
}

/// Fungsi helper untuk mengecek dan menampilkan peringatan mode guest
void showGuestModeDialog(BuildContext context, String featureName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Fitur Terbatas'),
          ],
        ),
        content: Text(
          'Fitur $featureName hanya tersedia untuk pengguna yang sudah masuk. '
          'Masuk atau daftar akun untuk mengakses fitur lengkap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Masuk Sekarang'),
          ),
        ],
      );
    },
  );
}

/// Widget untuk membatasi akses fitur premium
class PremiumFeatureGuard extends StatelessWidget {
  final Widget child;
  final String featureName;
  final Widget? fallback;

  const PremiumFeatureGuard({
    super.key,
    required this.child,
    required this.featureName,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isAuthenticated) {
          return child;
        }
        
        return fallback ?? GuestModeWarning(featureName: featureName);
      },
    );
  }
}
