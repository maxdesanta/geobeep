import 'package:flutter/material.dart';
import 'package:geobeep/services/foreground_service.dart';

class AppStatusIndicator extends StatelessWidget {
  final Color? backgroundColor;

  const AppStatusIndicator({super.key, this.backgroundColor});

  Future<bool> _getServiceStatus() async {
    return await ForegroundService.instance.isRunning;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<bool>(
        future: _getServiceStatus(),
        builder: (context, snapshot) {
          final isRunning = snapshot.data ?? false;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isRunning ? 'GeoBeep Aktif' : 'GeoBeep Nonaktif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isRunning ? Colors.black87 : Colors.black54,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
