import 'package:flutter/material.dart';
import 'package:geobeep/models/station_model.dart';
import 'package:geobeep/providers/station_provider.dart';
import 'package:geobeep/screen/map.dart';
import 'package:geobeep/services/auth_service.dart';
import 'package:provider/provider.dart';

class StasiunPage extends StatefulWidget {
  const StasiunPage({super.key});

  @override
  State<StasiunPage> createState() => _StasiunPageState();
}

class _StasiunPageState extends State<StasiunPage> {
  // memilih statiun
  List<StationModel> selectedStations = [];

  // Filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLine = 'Semua Jalur';

  // Line options for filter
  final List<String> _lineOptions = [
    'Semua Jalur',
    'Lin Bogor',
    'Lin Cikarang',
    'Lin Rangkasbitung',
    'Lin Tangerang',
    'Lin Tanjung Priok',
    'Lin Loop',
  ];

  @override
  void initState() {
    super.initState();
    // Load the provider data if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StationProvider>(context, listen: false);
      if (provider.allStations.isEmpty) {
        provider.initialize();
      }
    });

    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Filter stations based on search query and selected line
  List<StationModel> _getFilteredStations(List<StationModel> allStations) {
    return allStations.where((station) {
      // Filter by name
      final nameMatches = station.name.toLowerCase().contains(_searchQuery);

      // Filter by line
      final lineMatches =
          _selectedLine == 'Semua Jalur' ||
          station.line.contains(_selectedLine);

      return nameMatches && lineMatches;
    }).toList();
  }

  void addStation(StationModel station) {
    setState(() {
      if (!selectedStations.any((s) => s.id == station.id)) {
        if (selectedStations.length >= 3) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Maaf hanya bisa 3 stasiun')));
          return;
        }
        selectedStations.add(station);
      }
    });
  }

  void removeStation(StationModel station) {
    setState(() {
      selectedStations.removeWhere((s) => s.id == station.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "Stasiun",
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
      body: Consumer<StationProvider>(
        builder: (context, stationProvider, child) {
          if (stationProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final filteredStations = _getFilteredStations(
            stationProvider.allStations,
          );

          return SafeArea(
            child: Column(
              children: [
                // Search and filter section
                Container(
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari Stasiun...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Line filter dropdown
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLine,
                            icon: Icon(Icons.train, size: 18),
                            isExpanded: true,
                            hint: Text('Pilih Jalur'),
                            items:
                                _lineOptions.map((String line) {
                                  return DropdownMenuItem<String>(
                                    value: line,
                                    child: Text(line),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLine = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      // Results count
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Menampilkan ${filteredStations.length} dari ${stationProvider.allStations.length} stasiun',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Station list
                Expanded(
                  child:
                      filteredStations.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tidak ada stasiun yang sesuai dengan kriteria pencarian',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: filteredStations.length,
                            itemBuilder: (context, index) {
                              final station = filteredStations[index];
                              bool isSelected = selectedStations.any(
                                (s) => s.id == station.id,
                              );
                              bool isFavorite = station.isFavorite;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 21,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  // Highlight selected stations
                                  border:
                                      isSelected
                                          ? Border.all(
                                            color: Colors.yellow,
                                            width: 2,
                                          )
                                          : null,
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
                                            station.line,
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
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 12,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.secondary,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${(stationProvider.stationDistances[station.id]! / 1000).toStringAsFixed(2)} km',
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.secondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [                                        // Favorite toggle
                                        Consumer<AuthService>(
                                          builder: (context, authService, child) {
                                            final isAuthenticated = authService.isAuthenticated;
                                            
                                            return GestureDetector(
                                              onTap: () {
                                                if (isAuthenticated) {
                                                  stationProvider.toggleFavorite(
                                                    station,
                                                  );
                                                } else {
                                                  // Show login prompt
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text('Fitur dikunci'),
                                                      content: Text('Yuk login untuk menambahkan stasiun favorit.'),
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
                                                          child: Text(
                                                          'Login Sekarang',
                                                          style: TextStyle(color: Colors.white),
                                                          ),
                                                        ),
                                                        
                                                      ],
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isFavorite
                                                          ? Colors.yellow
                                                              .withOpacity(0.3)
                                                          : Colors.white
                                                              .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Icon(
                                                      isFavorite
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                      color:
                                                          isFavorite
                                                              ? Colors.yellow
                                                              : Colors.black,
                                                      size: 24,
                                                    ),
                                                    if (!isAuthenticated)
                                                      Positioned(
                                                        right: 0,
                                                        bottom: 0,
                                                        child: Container(
                                                          padding: EdgeInsets.all(2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape.circle,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.black26,
                                                                blurRadius: 2,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Icon(Icons.lock, size: 10, color: Colors.grey[700]),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(width: 8),

                                        // Add/Remove button
                                        GestureDetector(
                                          onTap: () {
                                            if (isSelected) {
                                              removeStation(station);
                                            } else {
                                              addStation(station);
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? Colors.red.withOpacity(
                                                        0.3,
                                                      )
                                                      : Colors.white
                                                          .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              isSelected
                                                  ? Icons.remove
                                                  : Icons.add,
                                              color: Colors.black,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),

                // alarm stasiun terpilih
                if (selectedStations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.alarm_on,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Alarm Stasiun Terpilih',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        const Divider(color: Colors.white),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: selectedStations.length,
                          itemBuilder: (context, selectedIdx) {
                            final station = selectedStations[selectedIdx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      station.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      removeStation(station);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedStations.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pilih minimal satu stasiun terlebih dahulu',
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MapPage(
                                      selectedStations: selectedStations,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Color(0xFF135E71),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Lihat di Peta & Aktifkan Alarm',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
