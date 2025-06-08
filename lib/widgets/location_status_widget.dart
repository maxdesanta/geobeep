import 'package:flutter/material.dart';
import 'package:geobeep/providers/station_provider.dart';
import 'package:provider/provider.dart';

class LocationStatusWidget extends StatelessWidget {
  const LocationStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StationProvider>(
      builder: (context, provider, child) {
        if (!provider.isMonitoring) {
          return ElevatedButton.icon(
            icon: Icon(Icons.location_off),
            label: Text('Aktifkan Lokasi'),
            onPressed: () async {
              await provider.startMonitoring();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'Lokasi Aktif',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.refresh, size: 16),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  provider.refreshLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lokasi diperbarui'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Perbarui lokasi',
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}
