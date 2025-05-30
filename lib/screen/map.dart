import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int selectedRadius = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: null,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Gambar Google Maps statis
          Expanded(
            child: Image.asset(
              'assets/map.png', // Pastikan sudah di-include di pubspec.yaml
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          // Pilihan radius alarm
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  "Pilih Radius Alarm Menyaya :",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _radiusButton(100),
                const SizedBox(height: 8),
                _radiusButton(300),
                const SizedBox(height: 8),
                _radiusButton(500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radiusButton(int radius) {
    bool isSelected = selectedRadius == radius;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        setState(() {
          selectedRadius = radius;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$radius meter',
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, color: Colors.white)
          else
            const SizedBox(width: 24), // Placeholder agar tombol tidak bergeser
        ],
      ),
    );
  }
}
