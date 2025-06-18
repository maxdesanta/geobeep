import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geobeep/models/station_model.dart';
import 'package:geobeep/providers/station_provider.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class MapPage extends StatefulWidget {
  final List<StationModel>? selectedStations;

  const MapPage({super.key, this.selectedStations});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int selectedRadius = 100;
  TextEditingController customRadiusController = TextEditingController(
    text: '100',
  );
  bool isCustomRadius = false;

  // For test station
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  StationModel? testStation;

  // Map controller
  final mapController = MapController();

  // Default center position (Jakarta)
  LatLng centerPosition = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<StationProvider>(context, listen: false);
      testStation = provider.testStation;

      if (testStation != null) {
        latController.text = testStation!.latitude.toString();
        lngController.text = testStation!.longitude.toString();
      }

      // Start location tracking
      final success = await provider.startMonitoring();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tidak dapat mengakses lokasi. Periksa izin lokasi.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      // If we have current position, center the map there
      if (provider.currentPosition != null) {
        setState(() {
          centerPosition = LatLng(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          );
        });
        mapController.move(centerPosition, 14);
      }
    });
  }

  @override
  void dispose() {
    customRadiusController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  void _updateRadius(int radius) {
    setState(() {
      selectedRadius = radius;
      isCustomRadius = false;
      customRadiusController.text = radius.toString();
    });
  }

  void _setCustomRadius() {
    try {
      final radius = int.parse(customRadiusController.text);
      if (radius > 0) {
        setState(() {
          selectedRadius = radius;
          isCustomRadius = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan nilai radius yang valid')),
      );
    }
  }

  void _updateTestStationCoordinates() {
    try {
      final lat = double.parse(latController.text);
      final lng = double.parse(lngController.text);

      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Koordinat tidak valid')));
        return;
      }

      final provider = Provider.of<StationProvider>(context, listen: false);
      provider.updateTestStationCoordinates(lat, lng);

      // Move map to the new test station location
      mapController.move(LatLng(lat, lng), 14);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Koordinat stasiun uji berhasil diperbarui')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan nilai koordinat yang valid')),
      );
    }
  }

  void _activateAlarms() {
    if (widget.selectedStations == null || widget.selectedStations!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak ada stasiun yang dipilih')));
      return;
    }

    final provider = Provider.of<StationProvider>(context, listen: false);
    int successCount = 0;

    for (final station in widget.selectedStations!) {
      provider.addStationAlarm(station, selectedRadius);
      successCount++;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$successCount alarm stasiun berhasil diaktifkan'),
      ),
    );

    // Start monitoring
    provider.startMonitoring();

    // Navigate back to previous screen
    Navigator.pop(context);
  }

  // Calculate distance between two coordinates in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Convert meters to degrees for the map
  double _metersToMapUnits(double meters, double latitude) {
    // Convert meters to degrees at the given latitude
    // Earth's circumference at the equator is about 40,075 km
    // 1 degree of latitude is approximately 111,111 meters
    // 1 degree of longitude varies with latitude
    double latRadians = latitude * (pi / 180);
    double metersPerDegree = 111111;
    double degreesPerMeter = 1 / metersPerDegree;

    // Return the degrees equivalent to the meters
    return meters * degreesPerMeter;
  }

  void _refreshLocation() async {
    final provider = Provider.of<StationProvider>(context, listen: false);

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memperbarui lokasi...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Force update current position
      await provider.refreshLocation();

      // If we have current position, center the map there
      if (provider.currentPosition != null) {
        mapController.move(
          LatLng(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          ),
          mapController.camera.zoom,
        );

        // Show success message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lokasi berhasil diperbarui')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat mendapatkan lokasi terbaru')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui lokasi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Pengaturan Alarm"),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Real Map with Flutter Map
          Expanded(
            child: Consumer<StationProvider>(
              builder: (context, provider, child) {
                // Get current position if available
                LatLng? currentUserPosition;
                if (provider.currentPosition != null) {
                  currentUserPosition = LatLng(
                    provider.currentPosition!.latitude,
                    provider.currentPosition!.longitude,
                  );
                }

                // Prepare markers for stations
                List<Marker> stationMarkers = [];

                // Add selected stations markers
                if (widget.selectedStations != null) {
                  for (var station in widget.selectedStations!) {
                    // Check if this is the test station
                    bool isTestStation = station.id == 'TST';

                    // Calculate distance if user position is available
                    String distanceText = "";
                    if (currentUserPosition != null) {
                      double distance = _calculateDistance(
                        currentUserPosition.latitude,
                        currentUserPosition.longitude,
                        station.latitude,
                        station.longitude,
                      );

                      // Format distance text
                      if (distance < 1000) {
                        distanceText = "${distance.toStringAsFixed(0)} m";
                      } else {
                        distanceText =
                            "${(distance / 1000).toStringAsFixed(1)} km";
                      }
                    }

                    stationMarkers.add(
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(station.latitude, station.longitude),
                        child: Container(
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_on,
                                color:
                                    isTestStation ? Colors.orange : Colors.blue,
                                size: 30.0,
                              ),
                              Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      station.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (distanceText.isNotEmpty)
                                      Text(
                                        distanceText,
                                        style: TextStyle(fontSize: 9),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }

                // Add user location marker if available
                if (currentUserPosition != null) {
                  stationMarkers.add(
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: currentUserPosition,
                      child: Container(
                        child: Icon(
                          Icons.my_location,
                          color: Colors.red,
                          size: 20.0,
                        ),
                      ),
                    ),
                  );
                }

                // Add circle overlays for each selected station to show radius
                List<CircleMarker> circleMarkers = [];

                if (widget.selectedStations != null) {
                  for (var station in widget.selectedStations!) {
                    circleMarkers.add(
                      CircleMarker(
                        point: LatLng(station.latitude, station.longitude),
                        color: Colors.blue.withOpacity(0.2),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2.0,
                        radius: selectedRadius.toDouble(),
                        useRadiusInMeter:
                            true, // This is key - make sure it's true
                      ),
                    );
                  }
                }

                // Add circle for test station if active
                if (provider.testStation != null &&
                    provider.testStation!.isAlarmActive) {
                  double testRadiusInDegrees = _metersToMapUnits(
                    provider.testStation!.radiusInMeters.toDouble(),
                    provider.testStation!.latitude,
                  );

                  circleMarkers.add(
                    CircleMarker(
                      point: LatLng(
                        provider.testStation!.latitude,
                        provider.testStation!.longitude,
                      ),
                      color: Colors.orange.withOpacity(0.2),
                      borderColor: Colors.orange,
                      borderStrokeWidth: 2.0,
                      radius: testRadiusInDegrees,
                      useRadiusInMeter: true,
                    ),
                  );
                }

                return Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: centerPosition,
                        initialZoom: 13.0,
                        maxZoom: 18.0,
                        minZoom: 10.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.geobeep.app',
                          tileProvider: NetworkTileProvider(),
                        ),
                        CircleLayer(circles: circleMarkers),
                        MarkerLayer(markers: stationMarkers),
                      ],
                    ),

                    // Location info box with distances
                    if (provider.currentPosition != null)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Lokasi Anda:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Add refresh button
                                  IconButton(
                                    icon: Icon(Icons.refresh, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: _refreshLocation,
                                    tooltip: 'Perbarui lokasi',
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                              Text(
                                'Lat: ${provider.currentPosition!.latitude.toStringAsFixed(6)}',
                              ),
                              Text(
                                'Lng: ${provider.currentPosition!.longitude.toStringAsFixed(6)}',
                              ),
                              if (widget.selectedStations != null &&
                                  widget.selectedStations!.isNotEmpty &&
                                  provider.currentPosition != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(),
                                    Text(
                                      'Jarak ke Stasiun:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ...widget.selectedStations!.map((station) {
                                      double distance = _calculateDistance(
                                        provider.currentPosition!.latitude,
                                        provider.currentPosition!.longitude,
                                        station.latitude,
                                        station.longitude,
                                      );
                                      String distanceText =
                                          distance < 1000
                                              ? "${distance.toStringAsFixed(0)} m"
                                              : "${(distance / 1000).toStringAsFixed(2)} km";

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              station.name,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              distanceText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    distance <= selectedRadius
                                                        ? Colors.red
                                                        : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                    // If location tracking is not active, show start button
                    if (provider.currentPosition == null)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success = await provider.startMonitoring();
                            if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tidak dapat mengakses lokasi. Periksa izin lokasi.',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.location_searching),
                          label: Text('Mulai Tracking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                    // Center on user button
                    if (provider.currentPosition != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: FloatingActionButton(
                          heroTag: "centerButton",
                          mini: true,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.center_focus_strong,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            mapController.move(
                              LatLng(
                                provider.currentPosition!.latitude,
                                provider.currentPosition!.longitude,
                              ),
                              14.0,
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Pilihan radius alarm
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  "Pilih Radius Alarm:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _radiusButton(100)),
                    SizedBox(width: 8),
                    Expanded(child: _radiusButton(300)),
                    SizedBox(width: 8),
                    Expanded(child: _radiusButton(500)),
                  ],
                ),
                const SizedBox(height: 8),

                // Custom radius input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customRadiusController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Radius kustom (meter)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.black, // Pastikan teks terlihat
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _setCustomRadius,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Set',
                        style: TextStyle(
                          color: Colors.white, // Pastikan teks tombol terlihat
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Test station coordinates - only show if test station is selected
                if (widget.selectedStations != null &&
                    widget.selectedStations!.any((s) => s.id == 'TST'))
                  ExpansionTile(
                    title: Text('Stasiun Uji'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: latController,
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: lngController,
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _updateTestStationCoordinates,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Text('Perbarui Koordinat'),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final provider =
                                          Provider.of<StationProvider>(
                                            context,
                                            listen: false,
                                          );
                                      if (provider.testStation != null) {
                                        // Make sure alarm is active
                                        if (!provider
                                            .testStation!
                                            .isAlarmActive) {
                                          provider.addStationAlarm(
                                            provider.testStation!,
                                            selectedRadius,
                                          );
                                        }
                                        // Simulate being near the test station
                                        provider.simulateNearStation('TST');
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Simulasi alarm stasiun uji dijalankan',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: Text('Test Alarm'),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Button to set test station to current location
                            if (Provider.of<StationProvider>(
                                  context,
                                ).currentPosition !=
                                null)
                              ElevatedButton(
                                onPressed: () {
                                  final provider = Provider.of<StationProvider>(
                                    context,
                                    listen: false,
                                  );
                                  if (provider.currentPosition != null) {
                                    setState(() {
                                      latController.text =
                                          provider.currentPosition!.latitude
                                              .toString();
                                      lngController.text =
                                          provider.currentPosition!.longitude
                                              .toString();
                                    });
                                    _updateTestStationCoordinates();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: Size(double.infinity, 40),
                                ),
                                child: Text('Gunakan Lokasi Saat Ini'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Activate alarm button
                if (widget.selectedStations != null &&
                    widget.selectedStations!.isNotEmpty)
                  ElevatedButton(
                    onPressed: _activateAlarms,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Color(0xFF135E71),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Aktifkan Alarm untuk ${widget.selectedStations!.length} Stasiun',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radiusButton(int radius) {
    bool isSelected = selectedRadius == radius && !isCustomRadius;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _updateRadius(radius),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$radius m',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (isSelected) Icon(Icons.check, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}
