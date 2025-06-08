import 'package:flutter/material.dart';
import 'package:geobeep/models/station_model.dart';
import 'package:geobeep/providers/station_provider.dart';
import 'package:geobeep/screen/map.dart';
import 'package:geobeep/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedRadius = '';
  bool isNotificationOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "Stasiun Favorit",
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        automaticallyImplyLeading: false,
      ),      body: Consumer2<StationProvider, AuthService>(
        builder: (context, stationProvider, authService, child) {
          final favoriteStations = stationProvider.favoriteStations;
          final isAuthenticated = authService.isAuthenticated;

          if (!isAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Stasiun Favorit',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Fitur ini hanya tersedia untuk pengguna yang sudah login',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135E71),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text('Login Sekarang'),
                  ),
                ],
              ),
            );
          }

          return favoriteStations.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_border, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada stasiun favorit',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tambahkan stasiun favorit di halaman Stasiun',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: favoriteStations.length,
                itemBuilder: (context, index) {
                  final station = favoriteStations[index];

                  return _buildStationCard(context, station, stationProvider);
                },
              );
        },
      ),
    );
  }

  Widget _buildStationCard(
    BuildContext context,
    StationModel station,
    StationProvider provider,
  ) {
    // Format distance if available
    String distanceText = "";
    if (provider.stationDistances.containsKey(station.id)) {
      final distance = provider.stationDistances[station.id]!;
      distanceText =
          distance < 1000
              ? "${distance.toStringAsFixed(0)} m"
              : "${(distance / 1000).toStringAsFixed(2)} km";
    }

    // Determine if alarm is active
    final isAlarmActive = station.isAlarmActive;

    // Format radius text if alarm is active
    String radiusText = "";
    if (isAlarmActive) {
      radiusText = "(${station.radiusInMeters}m)";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF508AA7),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
        // Add subtle border if alarm is active
        border:
            isAlarmActive ? Border.all(color: Colors.yellow, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Station name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Show alarm badge if active
                        if (isAlarmActive)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  color: Colors.black,
                                  size: 12,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Aktif $radiusText',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],                    ),
                    if (station.line.isNotEmpty)
                      Text(
                        station.line,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Add spacing
          SizedBox(height: 12),

          // Bottom row with distance and buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show distance if available
              if (distanceText.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    distanceText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Spacer
              Spacer(),

              // Action buttons
              Row(
                children: [
                  // Toggle alarm button with different icon based on active state
                  GestureDetector(
                    onTap: () => _showStationModal(context, station),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isAlarmActive
                                ? Colors.yellow
                                : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isAlarmActive
                            ? Icons.notifications_active
                            : Icons.add_alert,
                        color: isAlarmActive ? Colors.black : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),                  SizedBox(width: 8),
                  // Remove from favorites
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      return GestureDetector(
                        onTap: () {
                          if (authService.isAuthenticated) {
                            provider.toggleFavorite(station);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${station.name} dihapus dari favorit'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            // Show guest mode restriction dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Fitur Premium'),
                                content: Text('Anda perlu login untuk mengelola stasiun favorit.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Nanti'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/login');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF135E71),
                                    ),
                                    child: Text('Login Sekarang'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.star, color: Colors.yellow, size: 20),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStationModal(BuildContext context, StationModel station) {
    // Default radius value
    selectedRadius = '100';

    // Use the current alarm radius if active
    final provider = Provider.of<StationProvider>(context, listen: false);
    if (station.isAlarmActive && station.radiusInMeters > 0) {
      selectedRadius = station.radiusInMeters.toString();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF508AA7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Stasiun Tujuan
                    Text(
                      'Stasiun Tujuan: ${station.name}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Pilih Radius
                    const Text(
                      'Pilih Radius (dalam meter)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    // 3. Input angka
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        selectedRadius = value;
                      },
                      controller: TextEditingController(text: selectedRadius),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Masukkan radius dalam meter',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Notifikasi
                    const Text(
                      'Notifikasi',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    // 5. Dropdown On/Off
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isNotificationOn ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: isNotificationOn ? 'ON' : 'OFF',
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'ON',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: const Text(
                                  'ON',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'OFF',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: const Text(
                                  'OFF',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              isNotificationOn = newValue == 'ON';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 6. Button row with more options
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Get radius value
                              int radius = 100;
                              try {
                                radius = int.parse(selectedRadius);
                                if (radius <= 0) radius = 100;
                              } catch (e) {
                                // Use default radius
                              }

                              // Set up the alarm
                              provider.addStationAlarm(station, radius);

                              // Close dialog
                              Navigator.of(context).pop();

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Alarm untuk ${station.name} telah diaktifkan (${radius}m)',
                                  ),
                                  duration: Duration(seconds: 3),
                                  action: SnackBarAction(
                                    label: 'Lihat di Peta',
                                    onPressed: () {
                                      // Optional: Navigate to map if user wants to see it
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => MapPage(
                                                selectedStations: [station],
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Aktifkan Alarm'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Batalkan'),
                          ),
                        ),
                      ],
                    ),

                    // Add Map button
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        // Close the dialog
                        Navigator.of(context).pop();

                        // Navigate to map
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    MapPage(selectedStations: [station]),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Lihat di Peta',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
