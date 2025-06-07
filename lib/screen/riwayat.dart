import 'package:flutter/material.dart';
import 'package:gobeap/models/alarm_history.dart';
import 'package:gobeap/models/station_model.dart';
import 'package:gobeap/providers/station_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeap/screen/map.dart';
import 'package:gobeap/services/alarm_service.dart'; // Make sure this import points to your AlarmService

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  // Controller untuk input di modal
  final TextEditingController radiusController = TextEditingController();

  void _showAlarmDetailDialog(StationModel station, AlarmHistory? history) {
    radiusController.text = station.radiusInMeters.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Detail Alarm',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (history != null)
                  Text(
                    'Hi, wahid kamu sudah tiba di stasiun ${station.name} pada tanggal ${DateFormat('dd MMMM yyyy').format(history.triggeredAt)} pada pukul ${DateFormat('HH:mm').format(history.triggeredAt)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'Informasi Stasiun ${station.name}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                Text(
                  'Radius (dalam meter)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: radiusController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.secondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Get the radius value
                  int radius = 100;
                  try {
                    radius = int.parse(radiusController.text);
                    if (radius <= 0) radius = 100;
                  } catch (e) {
                    // Use default radius
                  }

                  // Add alarm
                  final provider = Provider.of<StationProvider>(
                    context,
                    listen: false,
                  );
                  provider.addStationAlarm(station, radius);

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Alarm untuk stasiun ${station.name} telah diaktifkan',
                      ),
                    ),
                  );
                },
                child: const Text('Aktifkan Kembali'),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to clear alarm history
  Future<void> _clearAlarmHistory() async {
    try {
      // Confirm with a dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Text(
              'Hapus Riwayat',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus semua riwayat alarm?',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Hapus'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Clear history in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('alarm_history');

        // Clear history in provider
        final provider = Provider.of<StationProvider>(context, listen: false);
        provider.clearAlarmHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Riwayat alarm berhasil dihapus')),
        );
      }
    } catch (e) {
      print('Error clearing alarm history: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus riwayat alarm')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "Riwayat",
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        actions: [
          Consumer<AlarmService?>(
            builder: (context, alarmService, child) {
              if (alarmService?.isPlaying == true) {
                return IconButton(
                  icon: Icon(Icons.volume_off, color: Colors.red),
                  onPressed: () {
                    alarmService?.stopAlarm();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Alarm dimatikan')));
                  },
                  tooltip: 'Matikan Alarm',
                );
              }
              return SizedBox.shrink();
            },
          ),
          // Clear history button
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: _clearAlarmHistory,
            tooltip: 'Hapus semua riwayat',
          ),
        ],
      ),
      body: Consumer<StationProvider>(
        builder: (context, stationProvider, child) {
          final activeAlarms = stationProvider.activeAlarms;
          final alarmHistory = stationProvider.alarmHistory;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Bagian Alarm Aktif dengan scrollable ListView di dalam Container
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.notifications,
                      size: 42,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Alarm Aktif',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 240, // Atur tinggi container agar ListView scrollable
                  child:
                      activeAlarms.isEmpty
                          ? Center(
                            child: Text(
                              'Tidak ada alarm aktif',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: activeAlarms.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final station = activeAlarms[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 21,
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            station.name,
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Radius: ${station.radiusInMeters} meter',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (stationProvider.stationDistances
                                              .containsKey(station.id))
                                            Text(
                                              'Jarak: ${(stationProvider.stationDistances[station.id]! / 1000).toStringAsFixed(2)} km',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        stationProvider.removeStationAlarm(
                                          station.id,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.clear,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 24),

                // Bagian Riwayat tanpa scroll internal
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.notifications,
                      size: 42,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Riwayat',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                alarmHistory.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'Belum ada riwayat alarm',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                    : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: alarmHistory.length,
                      itemBuilder: (context, index) {
                        final history = alarmHistory[index];
                        final station = stationProvider.getStationById(
                          history.stationId,
                        );

                        if (station == null) return SizedBox();

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 21,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      station.name,
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'dd MMMM yyyy, HH:mm',
                                      ).format(history.triggeredAt),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showAlarmDetailDialog(station, history);
                                },
                                child: Text(
                                  'Aktifkan Kembali',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
