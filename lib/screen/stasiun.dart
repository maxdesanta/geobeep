import 'package:flutter/material.dart';
import 'package:gobeap/screen/map.dart';

class StasiunPage extends StatefulWidget {
  const StasiunPage({super.key});

  @override
  State<StasiunPage> createState() => _StasiunPageState();
}

class _StasiunPageState extends State<StasiunPage> {
  final List<String> stasiun = [
    "Manggarai",
    "Universitas Pancasila",
    "Universitas Indonesia",
    "Bogor",
    "Bekasi",
    "Kebayoran",
    "Tangerang",
    "Duri",
    "Pasar Minggu",
  ];

  // mengganti icon star
  late List<bool> isFavorite;

  // memilih statiun
  List<String> selectedStasiun = [];

  @override
  void initState() {
    super.initState();
    isFavorite = List<bool>.filled(stasiun.length, false);
  }

  void addStation(String station) {
    setState(() {
      if (!selectedStasiun.contains(station)) {
        if (selectedStasiun.length >= 3) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Maaf hanya bisa 3 stasiun')));
          return;
        }
        selectedStasiun.add(station);
      }
    });
  }

  void removeStation(String station) {
    setState(() {
      selectedStasiun.remove(station);
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
      body: SafeArea(
        child: Column(
          children: [
            // tampilan stasiun
            Expanded(
              child: ListView.builder(
                itemCount: stasiun.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedStasiun.contains(stasiun[index]);
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
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stasiun[index],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isFavorite[index] = !isFavorite[index];
                                });
                              },
                              child: Icon(
                                isFavorite[index]
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                if (!isSelected) {
                                  addStation(stasiun[index]);
                                }
                              },
                              child: Icon(
                                Icons.add,
                                color: Colors.black,
                                size: 24,
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
            if (selectedStasiun.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                      itemCount: selectedStasiun.length,
                      itemBuilder: (context, selectedIdx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  selectedStasiun[selectedIdx],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.remove_circle,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedStasiun.removeAt(selectedIdx);
                                  });
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
                        // Logika untuk mengaktifkan alarm bisa ditambahkan di sini
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text(
                        //       'Alarm diaktifkan untuk stasiun terpilih',
                        //     ),
                        //   ),
                        // ),
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MapPage()),
                        );
                      },
                      child: Text(
                        'Aktifkan Alarm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 40),
                        backgroundColor: Color(0xFF135E71),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
}
